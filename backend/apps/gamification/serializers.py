from rest_framework import serializers
from apps.gamification.models import UserProfile, DailyLoginStreak, Badge, UserBadge, DailyQuest

class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    xp_for_next_level = serializers.IntegerField(read_only=True)
    xp_progress_percent = serializers.FloatField(read_only=True)

    class Meta:
        model = UserProfile
        fields = (
            'id', 'username', 'email', 'display_name', 'avatar_url',
            'xp', 'level', 'xp_for_next_level', 'xp_progress_percent',
            'streak_freeze_count', 'showcase_badges',
            'lifetime_coins_earned', 'total_watch_seconds', 'tasks_completed_count',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'xp', 'level', 'created_at', 'updated_at')


class BadgeSerializer(serializers.ModelSerializer):
    tier = serializers.SerializerMethodField()
    progress_current = serializers.SerializerMethodField()
    progress_target = serializers.SerializerMethodField()
    is_unlocked = serializers.SerializerMethodField()

    class Meta:
        model = Badge
        fields = (
            'id', 'key', 'name', 'description', 'category', 'icon_url',
            'target_bronze', 'target_silver', 'target_gold', 'target_diamond',
            'tier', 'progress_current', 'progress_target', 'is_unlocked'
        )

    def get_tier(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if user and user.is_authenticated:
            ub = obj.user_badges.filter(user=user).first()
            return ub.tier if ub else 'none'
        return 'none'

    def get_progress_current(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if user and user.is_authenticated:
            ub = obj.user_badges.filter(user=user).first()
            return ub.progress_current if ub else 0.0
        return 0.0

    def get_progress_target(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if user and user.is_authenticated:
            ub = obj.user_badges.filter(user=user).first()
            return ub.progress_target if ub else obj.target_bronze
        return obj.target_bronze

    def get_is_unlocked(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if user and user.is_authenticated:
            ub = obj.user_badges.filter(user=user).first()
            return ub.is_unlocked if ub else False
        return False


class DailyQuestSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyQuest
        fields = (
            'id', 'date', 'difficulty', 'quest_type', 'title', 'description',
            'target_count', 'current_count', 'coin_reward', 'xp_reward',
            'is_completed', 'is_claimed', 'claimed_at'
        )
