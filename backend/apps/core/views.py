import time
from django.db import connection
from django.core.cache import cache
from rest_framework import status, viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from apps.admin_api.permissions import IsAdminOrStaff
from apps.core.fraud import UserFraudProfile

class HealthCheckView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        start_time = time.time()
        health_data = {
            'status': 'healthy',
            'timestamp': time.time(),
            'components': {
                'database': {'status': 'healthy'},
                'cache': {'status': 'healthy'},
            }
        }

        # 1. Test Database
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        except Exception as e:
            health_data['status'] = 'unhealthy'
            health_data['components']['database'] = {'status': 'down', 'error': str(e)}

        # 2. Test Cache
        try:
            cache.set('health_check_ping', 'pong', timeout=5)
            val = cache.get('health_check_ping')
            if val != 'pong':
                raise ValueError("Cache set/get mismatch")
        except Exception as e:
            health_data['status'] = 'degraded' if health_data['status'] == 'healthy' else 'unhealthy'
            health_data['components']['cache'] = {'status': 'down', 'error': str(e)}

        health_data['latency_ms'] = round((time.time() - start_time) * 1000, 2)
        http_status = status.HTTP_200_OK if health_data['status'] != 'unhealthy' else status.HTTP_503_SERVICE_UNAVAILABLE
        return Response(health_data, status=http_status)


class ReadinessCheckView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            return Response({'ready': True}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'ready': False, 'error': str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class AdminFraudQueueView(APIView):
    permission_classes = [IsAdminOrStaff]

    def get(self, request):
        profiles = UserFraudProfile.objects.select_related('user').order_by('-fraud_score', '-updated_at')
        flagged_only = request.query_params.get('flagged', 'false').lower() == 'true'
        if flagged_only:
            profiles = profiles.filter(is_flagged=True)

        results = [
            {
                'id': p.id,
                'user_id': p.user.id,
                'username': p.user.username,
                'email': p.user.email,
                'fraud_score': p.fraud_score,
                'is_flagged': p.is_flagged,
                'flag_reason': p.flag_reason,
                'last_ip_hash': p.last_known_ip_hash,
                'suspicious_pings': p.suspicious_pings_count,
                'total_pings': p.total_pings_count,
                'updated_at': p.updated_at.isoformat(),
            }
            for p in profiles[:100]
        ]
        return Response({
            'total_count': profiles.count(),
            'flagged_count': UserFraudProfile.objects.filter(is_flagged=True).count(),
            'profiles': results
        })
