from django.contrib import admin
from django.utils.html import format_html
from apps.tasks.models import VideoTask, WatchSession

@admin.register(VideoTask)
class VideoTaskAdmin(admin.ModelAdmin):
    list_display = ('title', 'video_id', 'reward_type', 'saved_keywords_count', 'reward_summary', 'is_active', 'created_at')
    list_filter = ('reward_type', 'is_active', 'created_at')
    search_fields = ('title', 'video_id', 'keywords')
    readonly_fields = ('saved_keywords_display', 'created_at', 'updated_at')
    actions = ['generate_ai_keywords_action']

    fieldsets = (
        ('Video Information', {
            'fields': ('youtube_url', 'video_id', 'title', 'thumbnail_url', 'is_active'),
            'description': 'Leave Title and Keywords blank to automatically fetch real video metadata and generate AI search phrases on save.'
        }),
        ('Saved AI Search Keywords & Pool', {
            'fields': ('saved_keywords_display', 'keywords'),
            'description': 'These verified search phrases are saved in the DB and randomly rotated to users at 0 LLM credit cost.'
        }),
        ('Reward Configuration', {
            'fields': ('reward_type', 'reward_config')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    @admin.display(description="Saved Keywords")
    def saved_keywords_count(self, obj):
        kw = obj.keywords if isinstance(obj.keywords, list) else []
        if not kw:
            return format_html('<span style="color: #999;">No keywords</span>')
        first = kw[0] if len(kw) > 0 else ""
        return format_html('<strong>{} phrases</strong><br><small style="color: #666;">"{}"</small>', len(kw), first[:30])

    @admin.display(description="Formatted Keywords Pool")
    def saved_keywords_display(self, obj):
        kw = obj.keywords if isinstance(obj.keywords, list) else []
        if not kw:
            return format_html('<p style="color: #888;">No saved keywords. Save this task or run "Generate AI Keywords" action to populate.</p>')
        
        items_html = "".join([
            f'<li style="margin-bottom: 6px; padding: 4px 8px; background: #f0f4ff; border-radius: 4px; display: inline-block; margin-right: 8px;">'
            f'<span style="font-weight: bold; color: #3b82f6;">#{i+1}</span> <code style="font-size: 13px; color: #1e293b;">{k}</code>'
            f'</li>'
            for i, k in enumerate(kw)
        ])
        return format_html(
            '<div style="max-height: 240px; overflow-y: auto; padding: 10px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px;">'
            '<p style="margin-top: 0; font-size: 12px; color: #64748b;"><strong>Total: {} verified phrases</strong> (rotates randomly among users):</p>'
            '<ul style="list-style: none; padding-left: 0; margin-bottom: 0;">{}</ul>'
            '</div>',
            len(kw),
            format_html(items_html)
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
