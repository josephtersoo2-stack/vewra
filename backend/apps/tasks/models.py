from django.db import models
from django.contrib.auth.models import User
from apps.tasks.services import extract_youtube_video_id

class VideoTask(models.Model):
    REWARD_TYPE_CHOICES = [
        ('per_time', 'Per Time'),
        ('watch_all', 'Watch All'),
        ('target', 'Target'),
    ]

    youtube_url = models.URLField()
    video_id = models.CharField(max_length=20, unique=True, db_index=True)
    title = models.CharField(max_length=300)
    keywords = models.JSONField(default=list, blank=True)
    thumbnail_url = models.URLField(blank=True)
    
    reward_type = models.CharField(max_length=20, choices=REWARD_TYPE_CHOICES, default='per_time')
    reward_config = models.JSONField(default=dict, blank=True)
    
    is_active = models.BooleanField(default=True)
    is_deleted = models.BooleanField(default=False, db_index=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def clean(self):
        super().clean()
        if self.reward_type == 'watch_all':
            cfg = self.reward_config or {}
            duration = cfg.get('duration')
            if duration is None:
                from django.core.exceptions import ValidationError
                raise ValidationError({
                    'reward_config': "Reward config must specify a valid 'duration' in seconds for 'watch_all' reward type."
                })
            try:
                duration_val = float(duration)
                if duration_val <= 0:
                    raise ValueError()
            except (ValueError, TypeError):
                from django.core.exceptions import ValidationError
                raise ValidationError({
                    'reward_config': "'duration' must be a positive number of seconds for 'watch_all' reward type."
                })

    def save(self, *args, **kwargs):
        if not self.video_id and self.youtube_url:
            self.video_id = extract_youtube_video_id(self.youtube_url)
        elif self.youtube_url and not self.video_id:
            self.video_id = extract_youtube_video_id(self.youtube_url)
            
        # Auto-fetch title/keywords/thumbnail if missing
        if self.video_id and (not self.title or not self.keywords):
            try:
                from apps.ai_service.services import generate_video_keywords
                ai_data = generate_video_keywords(self.youtube_url or self.video_id, title_override=self.title or None)
                if not self.title and ai_data.get('title'):
                    self.title = ai_data['title']
                if not self.thumbnail_url and ai_data.get('thumbnail_url'):
                    self.thumbnail_url = ai_data['thumbnail_url']
                if not self.keywords and ai_data.get('keywords'):
                    self.keywords = ai_data['keywords']
            except Exception:
                pass

        if not self.thumbnail_url and self.video_id:
            self.thumbnail_url = f"https://img.youtube.com/vi/{self.video_id}/hqdefault.jpg"
            
        self.clean()
        super().save(*args, **kwargs)


    @property
    def reward_summary(self) -> str:
        cfg = self.reward_config or {}
        if self.reward_type == 'per_time':
            coins = cfg.get('coins', 10)
            seconds = cfg.get('seconds', 60)
            return f"+{coins} coins / {seconds}s"
        elif self.reward_type == 'watch_all':
            coins = cfg.get('coins', 150)
            return f"+{coins} coins (Full Watch)"
        elif self.reward_type == 'target':
            coins = cfg.get('coins', 100)
            target_sec = cfg.get('target_seconds', 300)
            return f"+{coins} coins for {target_sec}s"
        return "Watch Reward"

    def __str__(self):
        return f"{self.title} ({self.video_id}) [{self.get_reward_type_display()}]"

class WatchSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='watch_sessions')
    video_task = models.ForeignKey(VideoTask, on_delete=models.CASCADE, related_name='sessions')
    
    current_position = models.FloatField(default=0.0)          # highest second reached
    total_watched_seconds = models.FloatField(default=0.0)     # total unique seconds watched
    is_completed = models.BooleanField(default=False, db_index=True)
    
    last_watched_at = models.DateTimeField(null=True, blank=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'video_task')
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['last_watched_at', 'is_completed']),
            models.Index(fields=['user', 'last_watched_at']),
        ]

    def __str__(self):
        return f"User: {self.user.username} | Task: {self.video_task.video_id} | Watched: {self.total_watched_seconds:.1f}s | Completed: {self.is_completed}"
