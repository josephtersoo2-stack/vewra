from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.tasks.models import VideoTask, WatchSession
from apps.wallet.models import Wallet, WalletTransaction
from apps.ai_service.models import AISettings

User = get_user_model()

class AdminUserSerializer(serializers.ModelSerializer):
    wallet_balance = serializers.SerializerMethodField()
    total_sessions = serializers.SerializerMethodField()
    total_coins_earned = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 
            'is_staff', 'is_superuser', 'is_active', 
            'date_joined', 'last_login',
            'wallet_balance', 'total_sessions', 'total_coins_earned'
        ]

    def get_wallet_balance(self, obj):
        try:
            return str(obj.wallet.balance)
        except Exception:
            return "0.00"

    def get_total_sessions(self, obj):
        return obj.watch_sessions.count()

    def get_total_coins_earned(self, obj):
        try:
            return str(obj.wallet.total_earned)
        except Exception:
            return "0.00"


from decimal import Decimal

class AdminUserBalanceAdjustmentSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=Decimal('0.01'))
    action = serializers.ChoiceField(choices=['add', 'deduct'])
    reason = serializers.CharField(max_length=255, required=True)


class AdminVideoTaskSerializer(serializers.ModelSerializer):
    sessions_count = serializers.SerializerMethodField()

    class Meta:
        model = VideoTask
        fields = [
            'id', 'title', 'video_id', 'youtube_url',
            'thumbnail_url', 'reward_type', 'reward_config', 'keywords',
            'is_active', 'created_at', 'updated_at',
            'sessions_count'
        ]

    def get_sessions_count(self, obj):
        return obj.sessions.count()


class AdminWatchSessionSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)
    video_task_title = serializers.CharField(source='video_task.title', read_only=True)
    video_task_id = serializers.CharField(source='video_task.video_id', read_only=True)

    class Meta:
        model = WatchSession
        fields = [
            'id', 'user', 'username', 'user_email',
            'video_task', 'video_task_title', 'video_task_id',
            'current_position', 'total_watched_seconds',
            'is_completed', 'last_watched_at', 'created_at', 'updated_at'
        ]


class AdminWalletTransactionSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='wallet.user.username', read_only=True)
    user_email = serializers.CharField(source='wallet.user.email', read_only=True)

    class Meta:
        model = WalletTransaction
        fields = [
            'id', 'wallet', 'username', 'user_email',
            'amount', 'balance_after', 'transaction_type',
            'description', 'reference_id',
            'created_at'
        ]


class AdminAISettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = AISettings
        fields = [
            'id', 'active_provider', 'gemini_api_key', 'openrouter_api_key',
            'selected_model', 'custom_system_prompt', 'is_active', 'updated_at'
        ]


class AdminTestPromptSerializer(serializers.Serializer):
    youtube_url = serializers.CharField(required=True)
    provider = serializers.ChoiceField(choices=['gemini', 'openrouter'], required=False)
    model_name = serializers.CharField(required=False, allow_blank=True)
    custom_prompt = serializers.CharField(required=False, allow_blank=True)
