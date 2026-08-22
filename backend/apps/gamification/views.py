from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from apps.gamification.models import UserProfile, Badge, DailyQuest
from apps.gamification.serializers import UserProfileSerializer, BadgeSerializer, DailyQuestSerializer
from apps.gamification.services.streak_service import get_streak_status, claim_daily_streak
from apps.gamification.services.spin_service import get_spin_status, execute_daily_spin
from apps.gamification.services.scratch_service import get_scratch_status, execute_daily_scratch
from apps.gamification.services.quest_service import get_or_create_daily_quests, claim_quest_reward
from apps.gamification.services.xp_service import get_level_rewards_catalog
from apps.gamification.services.badge_service import evaluate_user_badges

class DailyStreakStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        data = get_streak_status(request.user)
        return Response(data, status=status.HTTP_200_OK)

class DailyStreakClaimView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        result = claim_daily_streak(request.user)
        return Response(result, status=status.HTTP_200_OK)

class SpinWheelStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        data = get_spin_status(request.user)
        return Response(data, status=status.HTTP_200_OK)

class DailySpinView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        result = execute_daily_spin(request.user)
        http_status = status.HTTP_200_OK if result.get('success') else status.HTTP_400_BAD_REQUEST
        return Response(result, status=http_status)

class ScratchStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        data = get_scratch_status(request.user)
        return Response(data, status=status.HTTP_200_OK)

class DailyScratchView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        result = execute_daily_scratch(request.user)
        http_status = status.HTTP_200_OK if result.get('success') else status.HTTP_400_BAD_REQUEST
        return Response(result, status=http_status)

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = UserProfileSerializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        display_name = request.data.get('display_name')
        avatar_url = request.data.get('avatar_url')
        if display_name is not None:
            profile.display_name = display_name.strip()
        if avatar_url is not None:
            profile.avatar_url = avatar_url.strip()
        profile.save()
        return Response(UserProfileSerializer(profile).data, status=status.HTTP_200_OK)

class LevelRewardsCatalogView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        catalog = get_level_rewards_catalog()
        return Response(catalog, status=status.HTTP_200_OK)

class BadgeListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        evaluate_user_badges(request.user)
        badges = Badge.objects.all()
        serializer = BadgeSerializer(badges, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

class BadgeShowcaseView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        badges = Badge.objects.filter(key__in=profile.showcase_badges)
        serializer = BadgeSerializer(badges, many=True, context={'request': request})
        return Response({
            'showcase_keys': profile.showcase_badges,
            'badges': serializer.data
        }, status=status.HTTP_200_OK)

    def put(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        badge_keys = request.data.get('badge_keys', [])
        if not isinstance(badge_keys, list):
            return Response({'error': 'badge_keys must be a list of badge keys.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Max 3 showcase badges
        profile.showcase_badges = badge_keys[:3]
        profile.save(update_fields=['showcase_badges'])
        return Response({'success': True, 'showcase_badges': profile.showcase_badges}, status=status.HTTP_200_OK)

class DailyQuestListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        quests = get_or_create_daily_quests(request.user)
        serializer = DailyQuestSerializer(quests, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class DailyQuestClaimView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, quest_id):
        result = claim_quest_reward(request.user, quest_id)
        http_status = status.HTTP_200_OK if result.get('success') else status.HTTP_400_BAD_REQUEST
        return Response(result, status=http_status)
