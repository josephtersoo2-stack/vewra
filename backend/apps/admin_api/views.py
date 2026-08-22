import time
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone
from django.db.models import Sum, Count, Q
from django.contrib.auth import get_user_model
from rest_framework import viewsets, status, permissions
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken

from apps.tasks.models import VideoTask, WatchSession
from apps.wallet.models import Wallet, WalletTransaction
from apps.ai_service.models import AISettings
from apps.ai_service.services import generate_video_keywords, extract_youtube_metadata, get_available_models
from apps.ai_service.providers.gemini import fetch_gemini_models
from apps.ai_service.providers.openrouter import fetch_openrouter_models
from .serializers import (
    AdminUserSerializer,
    AdminUserBalanceAdjustmentSerializer,
    AdminVideoTaskSerializer,
    AdminWatchSessionSerializer,
    AdminWalletTransactionSerializer,
    AdminAISettingsSerializer,
    AdminTestPromptSerializer,
)

User = get_user_model()

class IsAdminOrStaff(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and (request.user.is_staff or request.user.is_superuser))


def get_chart_intervals(range_key):
    now = timezone.now()
    intervals = []

    if range_key == '1h':
        # 6 intervals of 10 minutes
        for i in range(6):
            start = now - timedelta(minutes=(6 - i) * 10)
            end = now - timedelta(minutes=(5 - i) * 10)
            label = start.strftime('%H:%M')
            intervals.append((start, end, label))
    elif range_key in ['1d', '24h']:
        # 12 intervals of 2 hours
        for i in range(12):
            start = now - timedelta(hours=(12 - i) * 2)
            end = now - timedelta(hours=(11 - i) * 2)
            label = start.strftime('%H:%M')
            intervals.append((start, end, label))
    elif range_key in ['30d', '1m']:
        # 10 intervals of 3 days
        for i in range(10):
            start = now - timedelta(days=(10 - i) * 3)
            end = now - timedelta(days=(9 - i) * 3)
            label = start.strftime('%b %d')
            intervals.append((start, end, label))
    elif range_key in ['6m']:
        # 6 intervals of 30 days
        for i in range(6):
            start = now - timedelta(days=(6 - i) * 30)
            end = now - timedelta(days=(5 - i) * 30)
            label = start.strftime('%b %Y')
            intervals.append((start, end, label))
    elif range_key in ['1y', '12m']:
        # 12 intervals of 30 days
        for i in range(12):
            start = now - timedelta(days=(12 - i) * 30)
            end = now - timedelta(days=(11 - i) * 30)
            label = start.strftime('%b %Y')
            intervals.append((start, end, label))
    else:  # default '7d'
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        seven_days_ago = today_start - timedelta(days=6)
        for i in range(7):
            start = seven_days_ago + timedelta(days=i)
            end = start + timedelta(days=1)
            label = start.strftime('%b %d')
            intervals.append((start, end, label))

    return intervals


class DashboardStatsView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request):
        now = timezone.now()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        five_secs_ago = now - timedelta(seconds=5)
        range_key = request.query_params.get('range', '7d').lower()

        # KPIs
        total_users = User.objects.count()
        new_users_today = User.objects.filter(date_joined__gte=today_start).count()
        active_sessions_now = WatchSession.objects.filter(
            last_watched_at__gte=five_secs_ago,
            is_completed=False
        ).count()
        
        total_coins_distributed = WalletTransaction.objects.filter(
            transaction_type__in=['earned_watch', 'reward', 'admin_credit']
        ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

        total_wallet_liabilities = Wallet.objects.aggregate(Sum('balance'))['balance__sum'] or Decimal('0.00')
        tasks_completed_today = WatchSession.objects.filter(
            is_completed=True,
            updated_at__gte=today_start
        ).count()
        active_tasks_count = VideoTask.objects.filter(is_active=True).count()
        total_watch_seconds_all_videos = WatchSession.objects.filter(video_task__isnull=False).aggregate(Sum('total_watched_seconds'))['total_watched_seconds__sum'] or 0.0

        # Dynamic Range Trend Buckets
        intervals = get_chart_intervals(range_key)
        daily_trends = []
        for start_dt, end_dt, label in intervals:
            watch_sec = WatchSession.objects.filter(
                updated_at__gte=start_dt,
                updated_at__lt=end_dt
            ).aggregate(Sum('total_watched_seconds'))['total_watched_seconds__sum'] or 0.0

            coins_amt = WalletTransaction.objects.filter(
                created_at__gte=start_dt,
                created_at__lt=end_dt,
                transaction_type__in=['earned_watch', 'reward', 'admin_credit']
            ).aggregate(Sum('amount'))['amount__sum'] or Decimal('0.00')

            daily_trends.append({
                'date': label,
                'watch_seconds': round(float(watch_sec), 1),
                'watch_minutes': round(float(watch_sec) / 60.0, 1),
                'watch_hours': round(float(watch_sec) / 3600.0, 2),
                'coins_earned': float(coins_amt),
            })

        # Recent activity stream
        recent_sessions = WatchSession.objects.select_related('user', 'video_task').order_by('-updated_at')[:10]
        recent_activity = [
            {
                'id': s.id,
                'username': s.user.username,
                'task_title': s.video_task.title if s.video_task else 'Unknown Task',
                'watched_seconds': round(s.total_watched_seconds, 1),
                'is_completed': s.is_completed,
                'is_live': bool(s.last_watched_at and s.last_watched_at >= five_secs_ago and not s.is_completed),
                'updated_at': s.updated_at.isoformat(),
            }
            for s in recent_sessions
        ]

        return Response({
            'kpis': {
                'total_users': total_users,
                'new_users_today': new_users_today,
                'active_sessions_now': active_sessions_now,
                'total_coins_distributed': str(total_coins_distributed),
                'total_wallet_liabilities': str(total_wallet_liabilities),
                'tasks_completed_today': tasks_completed_today,
                'active_tasks_count': active_tasks_count,
                'total_watch_seconds_all_videos': round(float(total_watch_seconds_all_videos), 1),
            },
            'daily_trends': daily_trends,
            'recent_activity': recent_activity,
            'range': range_key,
        })


class AdminVideoTaskViewSet(viewsets.ModelViewSet):
    queryset = VideoTask.objects.all().order_by('-created_at')
    serializer_class = AdminVideoTaskSerializer
    permission_classes = [IsAdminOrStaff]

    @action(detail=True, methods=['post'], url_path='regenerate-keywords')
    def regenerate_keywords(self, request, pk=None):
        task = self.get_object()
        res = generate_video_keywords(
            youtube_url_or_id=task.youtube_url or task.video_id,
            title_override=task.title
        )
        keywords = res.get('keywords', [])
        task.keywords = keywords
        task.save(update_fields=['keywords', 'updated_at'])
        return Response({
            'success': True,
            'keywords': keywords,
            'message': f'Successfully refreshed {len(keywords)} keywords for "{task.title}".'
        })

    @action(detail=False, methods=['post'], url_path='fetch-youtube-meta')
    def fetch_youtube_meta(self, request):
        url = request.data.get('youtube_url', '').strip()
        if not url:
            return Response({'error': 'youtube_url is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            meta = extract_youtube_metadata(url)
            return Response(meta)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminWatchSessionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = WatchSession.objects.select_related('user', 'video_task').all().order_by('-updated_at')
    serializer_class = AdminWatchSessionSerializer
    permission_classes = [IsAdminOrStaff]

    def get_queryset(self):
        qs = super().get_queryset()
        user_id = self.request.query_params.get('user_id')
        video_task_id = self.request.query_params.get('video_task_id')
        is_completed = self.request.query_params.get('is_completed')
        search = self.request.query_params.get('search')

        if user_id:
            qs = qs.filter(user_id=user_id)
        if video_task_id:
            qs = qs.filter(video_task_id=video_task_id)
        if is_completed is not None:
            qs = qs.filter(is_completed=(is_completed.lower() == 'true'))
        if search:
            qs = qs.filter(
                Q(user__username__icontains=search) |
                Q(video_task__title__icontains=search)
            )
        return qs

    @action(detail=False, methods=['get'], url_path='live')
    def live_sessions(self, request):
        five_secs_ago = timezone.now() - timedelta(seconds=5)
        qs = WatchSession.objects.select_related('user', 'video_task').filter(
            last_watched_at__gte=five_secs_ago,
            is_completed=False
        ).order_by('-updated_at')
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='video-telemetry')
    def video_telemetry(self, request):
        now = timezone.now()
        five_secs_ago = now - timedelta(seconds=5)
        search = request.query_params.get('search', '').strip()

        tasks = VideoTask.objects.all()
        if search:
            tasks = tasks.filter(Q(title__icontains=search) | Q(video_id__icontains=search))

        results = []
        for task in tasks:
            sessions = task.sessions.all()
            total_unique_users = sessions.values('user').distinct().count()
            total_watch_seconds = sessions.aggregate(Sum('total_watched_seconds'))['total_watched_seconds__sum'] or 0.0
            
            # Real-time live viewers currently streaming (heartbeat <= 5s ago and not finished)
            live_viewers_count = sessions.filter(
                last_watched_at__gte=five_secs_ago,
                is_completed=False
            ).count()

            completed_count = sessions.filter(is_completed=True).count()
            latest_session = sessions.order_by('-last_watched_at', '-updated_at').first()

            results.append({
                'id': task.id,
                'title': task.title,
                'video_id': task.video_id,
                'youtube_url': task.youtube_url,
                'thumbnail_url': task.thumbnail_url,
                'reward_type': task.reward_type,
                'reward_config': task.reward_config,
                'is_active': task.is_active,
                'live_viewers_count': live_viewers_count,
                'is_live_now': live_viewers_count > 0,
                'total_unique_users_watched': total_unique_users,
                'total_watch_seconds': round(float(total_watch_seconds), 1),
                'completed_count': completed_count,
                'last_activity': latest_session.last_watched_at.isoformat() if (latest_session and latest_session.last_watched_at) else None,
                'created_at': task.created_at.isoformat(),
            })

        # Sort: Currently playing videos at the top (by live_viewers_count desc), then highest total views
        results.sort(
            key=lambda x: (
                1 if x['live_viewers_count'] > 0 else 0,
                x['live_viewers_count'],
                x['total_watch_seconds'],
                x['total_unique_users_watched']
            ),
            reverse=True
        )

        return Response(results)

    @action(detail=False, methods=['get'], url_path='video-viewers')
    def video_viewers(self, request):
        task_id = request.query_params.get('video_task_id')
        if not task_id:
            return Response({'error': 'video_task_id parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)

        now = timezone.now()
        five_secs_ago = now - timedelta(seconds=5)
        
        sessions = WatchSession.objects.select_related('user', 'video_task').filter(video_task_id=task_id).order_by('-last_watched_at', '-updated_at')
        
        users_list = []
        for s in sessions:
            is_live = bool(s.last_watched_at and s.last_watched_at >= five_secs_ago and not s.is_completed)
            
            if s.is_completed:
                status_label = 'Completed'
                status_variant = 'emerald'
            elif is_live:
                status_label = 'Watching Live'
                status_variant = 'rose'
            else:
                status_label = 'Not Watching'
                status_variant = 'amber'

            coins_earned = 0.0
            if s.video_task:
                r_type = s.video_task.reward_type
                r_cfg = s.video_task.reward_config or {}
                if r_type == 'per_time':
                    coin_unit = float(r_cfg.get('coins', 10))
                    sec_unit = float(r_cfg.get('seconds', 60))
                    coins_earned = round((s.total_watched_seconds // sec_unit) * coin_unit, 2)
                elif r_type == 'watch_all' and s.is_completed:
                    coins_earned = float(r_cfg.get('coins', 150))
                elif r_type == 'target' and (s.total_watched_seconds >= float(r_cfg.get('target_seconds', 300)) or s.is_completed):
                    coins_earned = float(r_cfg.get('coins', 100))

            users_list.append({
                'session_id': s.id,
                'user_id': s.user.id,
                'username': s.user.username,
                'email': s.user.email,
                'total_watched_seconds': round(s.total_watched_seconds, 1),
                'current_position_seconds': round(s.current_position, 1),
                'highest_position_seconds': round(s.current_position, 1),
                'is_completed': s.is_completed,
                'is_live': is_live,
                'status_label': status_label,
                'status_variant': status_variant,
                'coins_earned': coins_earned,
                'last_watched_at': s.last_watched_at.isoformat() if s.last_watched_at else s.updated_at.isoformat(),
                'created_at': s.created_at.isoformat(),
                'updated_at': s.updated_at.isoformat(),
            })

        # Sort: live watching users first, then highest watch time
        users_list.sort(
            key=lambda u: (1 if u['is_live'] else 0, u['total_watched_seconds']),
            reverse=True
        )

        return Response({
            'video_task_id': int(task_id),
            'total_viewers': len(users_list),
            'viewers': users_list
        })


class AdminUserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminOrStaff]

    def get_queryset(self):
        qs = super().get_queryset()
        search = self.request.query_params.get('search')
        if search:
            qs = qs.filter(
                Q(username__icontains=search) |
                Q(email__icontains=search)
            )
        return qs

    @action(detail=True, methods=['post'], url_path='adjust-balance')
    def adjust_balance(self, request, pk=None):
        user = self.get_object()
        serializer = AdminUserBalanceAdjustmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        amount = serializer.validated_data['amount']
        action_type = serializer.validated_data['action']
        reason = serializer.validated_data['reason']

        wallet, _ = Wallet.objects.get_or_create(user=user)

        if action_type == 'add':
            wallet.balance += amount
            wallet.total_earned += amount
            tx_type = 'admin_credit'
            ref = f"ADMIN_GRANT: {reason}"
        else:
            if wallet.balance < amount:
                return Response(
                    {'error': f'Cannot deduct {amount}. User current balance is only {wallet.balance}.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            wallet.balance -= amount
            tx_type = 'admin_debit'
            ref = f"ADMIN_DEDUCT: {reason}"

        wallet.save(update_fields=['balance', 'updated_at'])

        WalletTransaction.objects.create(
            wallet=wallet,
            amount=amount if action_type == 'add' else -amount,
            balance_after=wallet.balance,
            transaction_type=tx_type,
            description=ref,
            reference_id=f"ADM_{int(time.time())}"
        )

        return Response({
            'success': True,
            'new_balance': str(wallet.balance),
            'message': f'Successfully {action_type}ed {amount} coins to {user.username}.'
        })

    @action(detail=True, methods=['post'], url_path='toggle-status')
    def toggle_status(self, request, pk=None):
        user = self.get_object()
        if user == request.user:
            return Response({'error': 'Cannot ban/deactivate your own admin account.'}, status=status.HTTP_400_BAD_REQUEST)
        user.is_active = not user.is_active
        user.save(update_fields=['is_active'])
        return Response({
            'success': True,
            'is_active': user.is_active,
            'message': f'User {user.username} is now {"Active" if user.is_active else "Banned/Inactive"}.'
        })


class AdminWalletTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = WalletTransaction.objects.select_related('wallet__user').all().order_by('-created_at')
    serializer_class = AdminWalletTransactionSerializer
    permission_classes = [IsAdminOrStaff]

    def get_queryset(self):
        qs = super().get_queryset()
        tx_type = self.request.query_params.get('type')
        user_id = self.request.query_params.get('user_id')
        search = self.request.query_params.get('search')

        if tx_type:
            qs = qs.filter(transaction_type=tx_type)
        if user_id:
            qs = qs.filter(wallet__user_id=user_id)
        if search:
            qs = qs.filter(
                Q(wallet__user__username__icontains=search) |
                Q(description__icontains=search) |
                Q(reference_id__icontains=search)
            )
        return qs


class AdminAISettingsView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request):
        settings_obj = AISettings.get_settings()
        serializer = AdminAISettingsSerializer(settings_obj)
        return Response(serializer.data)

    def patch(self, request):
        settings_obj = AISettings.get_settings()
        serializer = AdminAISettingsSerializer(settings_obj, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class AdminAIFetchModelsView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request):
        provider = request.query_params.get('provider', 'gemini').lower()
        api_key = request.query_params.get('api_key')
        try:
            models = get_available_models(provider, api_key=api_key or None)
            return Response({'success': True, 'provider': provider, 'models': models, 'count': len(models)})
        except Exception as e:
            return Response({'success': False, 'error': str(e), 'models': []}, status=status.HTTP_400_BAD_REQUEST)

    def post(self, request):
        provider = request.data.get('provider', 'gemini').lower()
        api_key = request.data.get('api_key')
        try:
            models = get_available_models(provider, api_key=api_key or None)
            return Response({'success': True, 'provider': provider, 'models': models, 'count': len(models)})
        except Exception as e:
            return Response({'success': False, 'error': str(e), 'models': []}, status=status.HTTP_400_BAD_REQUEST)


class AdminAITestSandboxView(APIView):
    permission_classes = [IsAdminOrStaff]

    def post(self, request):
        serializer = AdminTestPromptSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        url = serializer.validated_data['youtube_url']
        provider = serializer.validated_data.get('provider')
        model_name = serializer.validated_data.get('model_name')
        custom_prompt = serializer.validated_data.get('custom_prompt')

        meta = extract_youtube_metadata(url)
        start_time = time.time()

        res = generate_video_keywords(
            youtube_url_or_id=url,
            provider_override=provider,
            model_override=model_name
        )

        latency_ms = int((time.time() - start_time) * 1000)

        return Response({
            'success': True,
            'metadata': meta,
            'provider_used': res.get('provider', provider),
            'model_used': res.get('model', model_name),
            'keywords': res.get('keywords', []),
            'latency_ms': latency_ms,
        })


class AdminTokenBlacklistView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request):
        outstanding = OutstandingToken.objects.select_related('user').order_by('-created_at')[:50]
        blacklisted = BlacklistedToken.objects.select_related('token__user').order_by('-blacklisted_at')[:50]

        outstanding_data = [
            {
                'id': t.id,
                'user_id': t.user_id,
                'username': t.user.username if t.user else 'Unknown',
                'jti': t.jti,
                'created_at': t.created_at.isoformat(),
                'expires_at': t.expires_at.isoformat(),
            }
            for t in outstanding
        ]

        blacklisted_data = [
            {
                'id': b.id,
                'token_id': b.token_id,
                'username': b.token.user.username if (b.token and b.token.user) else 'Unknown',
                'blacklisted_at': b.blacklisted_at.isoformat(),
            }
            for b in blacklisted
        ]

        return Response({
            'outstanding_tokens': outstanding_data,
            'blacklisted_tokens': blacklisted_data,
        })

    def post(self, request):
        token_id = request.data.get('token_id')
        if not token_id:
            return Response({'error': 'token_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            token = OutstandingToken.objects.get(id=token_id)
            BlacklistedToken.objects.get_or_create(token=token)
            return Response({
                'success': True,
                'message': f'Token {token.jti} has been revoked and blacklisted.'
            })
        except OutstandingToken.DoesNotExist:
            return Response({'error': 'Token not found.'}, status=status.HTTP_404_NOT_FOUND)
