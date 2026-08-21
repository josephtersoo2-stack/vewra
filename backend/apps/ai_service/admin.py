from django.contrib import admin
from django.utils.html import format_html
from apps.ai_service.models import AISettings

@admin.register(AISettings)
class AISettingsAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'active_provider', 'selected_model', 'is_active', 'updated_at')
    fieldsets = (
        ('Provider Selection', {
            'fields': ('active_provider', 'selected_model', 'is_active')
        }),
        ('API Keys (Zero Hardcoding)', {
            'fields': ('gemini_api_key', 'openrouter_api_key'),
            'description': 'Enter your API key here, or define GEMINI_API_KEY / OPENROUTER_API_KEY as environment variables.'
        }),
        ('Prompt Template', {
            'fields': ('custom_system_prompt',),
            'classes': ('collapse',)
        }),
    )

    def has_add_permission(self, request):
        # Only allow 1 singleton settings instance
        return not AISettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False
