from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    display_name = models.CharField(max_length=100, blank=True)
    avatar_url = models.URLField(blank=True, default='')
    
    # XP & Leveling (1.3)
    xp = models.BigIntegerField(default=0, db_index=True)
    level = models.IntegerField(default=1, db_index=True)
    
    # Streak Freezes (1.6)
    streak_freeze_count = models.IntegerField(default=0)
    
    # Showcase badges (up to 3 badge keys)
    showcase_badges = models.JSONField(default=list, blank=True)
    
    # Aggregated Stats
    lifetime_coins_earned = models.DecimalField(max_digits=14, decimal_places=2, default=0.00)
    total_watch_seconds = models.FloatField(default=0.0)
    tasks_completed_count = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"

    def __str__(self):
        return f"{self.user.username} | Level {self.level} ({self.xp} XP)"

    @property
    def xp_for_next_level(self) -> int:
        # Formula: XP_required(level) = level^2 * 20
        return (self.level ** 2) * 20

    @property
    def xp_progress_percent(self) -> float:
        needed = self.xp_for_next_level
        if needed <= 0:
            return 100.0
        # XP inside current level
        prev_level_xp = ((self.level - 1) ** 2) * 20 if self.level > 1 else 0
        current_span = needed - prev_level_xp
        user_span = max(0, self.xp - prev_level_xp)
        return min(100.0, round((user_span / max(1, current_span)) * 100.0, 1))


class DailyLoginStreak(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='daily_streak')
    streak_count = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_claimed_date = models.DateField(null=True, blank=True)
    freeze_used_this_week = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} | Streak: {self.streak_count}d (Best: {self.longest_streak}d)"

    @property
    def streak_multiplier(self) -> float:
        if self.streak_count >= 100:
            return 2.0
        elif self.streak_count >= 30:
            return 1.3
        elif self.streak_count >= 7:
            return 1.1
        return 1.0


class SpinWheelClaim(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='spin_claims')
    date = models.DateField(db_index=True)
    prize_type = models.CharField(max_length=50)   # coins, freeze, xp_boost, mystery_box
    prize_value = models.CharField(max_length=50)  # e.g. "50", "1", "2x"
    segment_landed = models.IntegerField()
    claimed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'date')
        ordering = ['-claimed_at']

    def __str__(self):
        return f"{self.user.username} | Spin on {self.date} -> {self.prize_type}: {self.prize_value}"


class Badge(models.Model):
    CATEGORY_CHOICES = [
        ('onboarding', 'Onboarding'),
        ('watch', 'Watch & Retention'),
        ('social', 'Social & Referral'),
        ('earning', 'Earning & Economy'),
        ('special', 'Special & Milestones'),
    ]

    key = models.CharField(max_length=60, unique=True, db_index=True)
    name = models.CharField(max_length=100)
    description = models.TextField()
    category = models.CharField(max_length=30, choices=CATEGORY_CHOICES, default='watch')
    icon_url = models.URLField(blank=True, default='')
    is_hidden = models.BooleanField(default=False)
    
    # Tier thresholds
    target_bronze = models.FloatField(default=1.0)
    target_silver = models.FloatField(default=5.0)
    target_gold = models.FloatField(default=25.0)
    target_diamond = models.FloatField(default=100.0)

    class Meta:
        ordering = ['category', 'name']

    def __str__(self):
        return f"Badge: {self.name} ({self.key}) [{self.category}]"


class UserBadge(models.Model):
    TIER_CHOICES = [
        ('none', 'Locked'),
        ('bronze', 'Bronze'),
        ('silver', 'Silver'),
        ('gold', 'Gold'),
        ('diamond', 'Diamond'),
        ('legendary', 'Legendary'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='badges')
    badge = models.ForeignKey(Badge, on_delete=models.CASCADE, related_name='user_badges')
    tier = models.CharField(max_length=20, choices=TIER_CHOICES, default='none')
    progress_current = models.FloatField(default=0.0)
    progress_target = models.FloatField(default=1.0)
    is_unlocked = models.BooleanField(default=False)
    awarded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('user', 'badge')
        ordering = ['-awarded_at']

    def __str__(self):
        return f"{self.user.username} | {self.badge.name} [{self.tier}]"


class DailyQuest(models.Model):
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='daily_quests')
    date = models.DateField(db_index=True)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, default='easy')
    quest_type = models.CharField(max_length=40)  # watch_video, watch_seconds, complete_tasks, daily_spin, comment_video
    
    title = models.CharField(max_length=150)
    description = models.CharField(max_length=255)
    
    target_count = models.IntegerField(default=1)
    current_count = models.IntegerField(default=0)
    coin_reward = models.DecimalField(max_digits=8, decimal_places=2, default=15.00)
    xp_reward = models.IntegerField(default=25)
    
    is_completed = models.BooleanField(default=False)
    is_claimed = models.BooleanField(default=False)
    claimed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('user', 'date', 'difficulty')
        ordering = ['date', 'difficulty']

    def __str__(self):
        return f"{self.user.username} | {self.date} [{self.difficulty}] {self.title} ({self.current_count}/{self.target_count})"


class ScratchCardClaim(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='scratch_claims')
    date = models.DateField(db_index=True)
    grid_panels = models.JSONField(default=list)  # 3x3 layout of revealed symbols
    prize_type = models.CharField(max_length=50)
    prize_value = models.CharField(max_length=50)
    claimed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'date')
        ordering = ['-claimed_at']

    def __str__(self):
        return f"{self.user.username} | Scratch on {self.date} -> {self.prize_type}: {self.prize_value}"
