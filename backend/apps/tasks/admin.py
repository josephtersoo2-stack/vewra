from django.contrib import admin
from apps.tasks.models import VideoTask, WatchSession

@admin.register(VideoTask)
class VideoTaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'video_id', 'reward_type', 'reward_summary', 'is_active', 'created_at')
    list_filter = ('reward_type', 'is_active', 'created_at')
    search_fields = ('title', 'video_id', 'keywords')
    readonly_fields = ('created_at', 'updated_at')
    fieldsets = (
        ('Video Information', {
            'fields': ('youtube_url', 'video_id', 'title', 'keywords', 'thumbnail_url', 'is_active')
        }),
        ('Reward Configuration', {
            'fields': ('reward_type', 'reward_config')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )

@admin.register(WatchSession)
class WatchSessionAdmin(admin.ModelAdmin):
    list_display = ('user', 'video_task', 'current_position', 'total_watched_seconds', 'is_completed', 'last_watched_at')
    list_filter = ('is_completed', 'created_at', 'last_watched_at')
    search_fields = ('user__username', 'video_task__title', 'video_task__video_id')
    readonly_fields = ('created_at', 'updated_at')
