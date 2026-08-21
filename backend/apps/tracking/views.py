from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.core.exceptions import ValidationError
from apps.tracking.serializers import ProgressUpdateSerializer
from apps.tracking.services import process_watch_progress

class ProgressTrackingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ProgressUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        try:
            result = process_watch_progress(
                user=request.user,
                session_id=data['session_id'],
                current_time=data['current_time'],
                delta_seconds=data['delta_seconds']
            )
            return Response(result, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': f"Tracking processing error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
