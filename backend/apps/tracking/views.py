from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.core.exceptions import ValidationError
from apps.tracking.serializers import ProgressUpdateSerializer
from apps.tracking.services import process_watch_progress
from apps.core.throttling import TrackingProgressThrottle
from apps.core.idempotency import get_idempotent_result, set_idempotent_result

class ProgressTrackingView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [TrackingProgressThrottle]

    def post(self, request):
        # 1. Idempotency Check (FIX-13)
        idempotency_key = request.headers.get('X-Idempotency-Key') or request.data.get('idempotency_key')
        if idempotency_key:
            is_cached, cached_data = get_idempotent_result(request.user.id, idempotency_key)
            if is_cached:
                return Response(cached_data, status=status.HTTP_200_OK)

        serializer = ProgressUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        try:
            result = process_watch_progress(
                user=request.user,
                session_id=data['session_id'],
                current_time=data['current_time'],
                delta_seconds=data['delta_seconds'],
                request_ip=request.META.get('REMOTE_ADDR')
            )
            
            if idempotency_key:
                set_idempotent_result(request.user.id, idempotency_key, result)

            return Response(result, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': f"Tracking processing error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
