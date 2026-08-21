from rest_framework import serializers
from apps.tasks.models import VideoTask, WatchSession
from apps.tasks.services import generate_randomized_instruction

class WatchSessionSerializer(serializers.ModelSerializer):
    task_title = serializers.CharField(source='video_task.title', read_only=True)
    video_id = serializers.CharField(source='video_task.video_id', read_only=True)

    class Meta:
        model = WatchSession
        fields = (
            'id', 'user', 'video_task', 'task_title', 'video_id',
            'current_position', 'total_watched_seconds',
            'is_completed', 'last_watched_at', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'user', 'created_at', 'updated_at')

class VideoTaskListSerializer(serializers.ModelSerializer):
    reward_summary = serializers.ReadOnlyField()
    is_completed_by_user = serializers.SerializerMethodField()
    watched_seconds = serializers.SerializerMethodField()

    class Meta:
        model = VideoTask
        fields = (
            'id', 'video_id', 'title', 'keywords', 'thumbnail_url',
            'reward_type', 'reward_config', 'reward_summary',
            'is_completed_by_user', 'watched_seconds', 'created_at'
        )

    def get_is_completed_by_user(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            session = obj.sessions.filter(user=request.user).first()
            return session.is_completed if session else False
        return False

    def get_watched_seconds(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            session = obj.sessions.filter(user=request.user).first()
            return session.total_watched_seconds if session else 0.0
        return 0.0

class VideoTaskDetailSerializer(serializers.ModelSerializer):
    reward_summary = serializers.ReadOnlyField()
    instruction = serializers.SerializerMethodField()
    session = serializers.SerializerMethodField()

    class Meta:
        model = VideoTask
        fields = (
            'id', 'youtube_url', 'video_id', 'title', 'keywords', 'thumbnail_url',
            'reward_type', 'reward_config', 'reward_summary',
            'instruction', 'session', 'is_active', 'created_at'
        )

    def get_instruction(self, obj):
        request = self.context.get('request')
        user = request.user if request and request.user.is_authenticated else None
        return generate_randomized_instruction(obj, user=user)

    def get_session(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            session = obj.sessions.filter(user=request.user).first()
            if session:
                return WatchSessionSerializer(session).data
        return None
