from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from apps.tasks.models import VideoTask, WatchSession
from apps.tasks.serializers import (
    VideoTaskListSerializer,
    VideoTaskDetailSerializer,
    WatchSessionSerializer
)

class TaskListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        tasks = VideoTask.objects.filter(is_active=True)
        serializer = VideoTaskListSerializer(tasks, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

class TaskDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        task = get_object_or_404(VideoTask, pk=pk, is_active=True)
        serializer = VideoTaskDetailSerializer(task, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

class TaskStartView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        task = get_object_or_404(VideoTask, pk=pk, is_active=True)
        session, created = WatchSession.objects.get_or_create(
            user=request.user,
            video_task=task
        )
        serializer = WatchSessionSerializer(session)
        return Response({
            'message': 'Watch session started' if created else 'Existing session retrieved',
            'session': serializer.data
        }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
