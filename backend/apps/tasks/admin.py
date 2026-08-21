from django.contrib import admin
from apps.tasks.models import VideoTask, WatchSession

@admin.register(VideoTask)
class VideoTaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'video_id', 'reward_type', 'reward_summary', 'is_active', 'created_at')
    list_filter = ('reward_type', 'is_active', 'created_at')
    search_fields = ('title', 'video_id', 'keywords')
    readonly_fields = ('created_at', 'updated_at')
    actions = ['generate_ai_keywords_action']

    fieldsets = (
        ('Video Information', {
            'fields': ('youtube_url', 'video_id', 'title', 'keywords', 'thumbnail_url', 'is_active'),
            'description': 'Leave Title and Keywords blank to automatically fetch real video metadata and generate AI search phrases on save.'
        }),
        ('Reward Configuration', {
            'fields': ('reward_type', 'reward_config')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    @admin.action(description="✨ Generate/Refresh AI Keywords & Metadata for selected tasks")
    def generate_ai_keywords_action(self, request, queryset):
        from apps.ai_service.services import generate_video_keywords
        updated = 0
        for task in queryset:
            try:
                ai_data = generate_video_keywords(task.youtube_url or task.video_id)
                task.title = ai_data.get('title', task.title)
                task.thumbnail_url = ai_data.get('thumbnail_url', task.thumbnail_url)
                task.keywords = ai_data.get('keywords', task.keywords)
                task.save()
                updated += 1
            except Exception as e:
                self.message_user(request, f"Error updating task {task.id}: {e}", level='ERROR')
        self.message_user(request, f"Successfully refreshed AI metadata and keywords for {updated} task(s).")

@admin.register(WatchSession)
class WatchSessionAdmin(admin.ModelAdmin):
    list_display = ('user', 'video_task', 'current_position', 'total_watched_seconds', 'is_completed', 'last_watched_at')
    list_filter = ('is_completed', 'created_at', 'last_watched_at')
    search_fields = ('user__username', 'video_task__title', 'video_task__video_id')
    readonly_fields = ('created_at', 'updated_at')
