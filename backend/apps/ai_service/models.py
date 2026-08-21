import os
from django.db import models

DEFAULT_SYSTEM_PROMPT = """You are a YouTube search expert.
Given the YouTube video's title, channel, and description, generate 6 to 10 natural, highly-relevant search query phrases that real viewers would type into the YouTube search bar to find this exact video.

Rules:
1. Every query must be a complete, realistic search term (e.g. "Flutter in 100 seconds Fireship", "Never Gonna Give You Up official video Rick Astley").
2. Queries must be specific enough so the video ranks at or near the top of YouTube search results.
3. Include title-focused queries, channel-focused queries, and topic/question queries.
4. Do NOT output numbered lists, markdown explanations, or preamble. Return ONLY a valid JSON array of strings: ["phrase 1", "phrase 2", "phrase 3", ...]
"""

class AISettings(models.Model):
    PROVIDER_CHOICES = [
        ('gemini', 'Google Gemini'),
        ('openrouter', 'OpenRouter'),
    ]

    active_provider = models.CharField(
        max_length=20,
        choices=PROVIDER_CHOICES,
        default='gemini',
        help_text="Active LLM provider for generating video keywords."
    )
    gemini_api_key = models.CharField(
        max_length=255,
        blank=True,
        help_text="Google Gemini API Key (or set GEMINI_API_KEY environment variable)."
    )
    openrouter_api_key = models.CharField(
        max_length=255,
        blank=True,
        help_text="OpenRouter API Key (or set OPENROUTER_API_KEY environment variable)."
    )
    selected_model = models.CharField(
        max_length=150,
        blank=True,
        help_text="Dynamic Model ID chosen from the live provider model list (e.g. gemini-2.5-flash or meta-llama/llama-3.3-70b-instruct)."
    )
    custom_system_prompt = models.TextField(
        default=DEFAULT_SYSTEM_PROMPT,
        blank=True,
        help_text="Prompt instructions sent to the LLM for keyword extraction."
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Enable/disable AI keyword generation."
    )
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "AI Keyword Settings"
        verbose_name_plural = "AI Keyword Settings"

    def __str__(self):
        return f"AI Settings ({self.get_active_provider_display()} - {self.selected_model or 'Default Model'})"

    def get_effective_gemini_key(self) -> str:
        return (self.gemini_api_key or os.environ.get('GEMINI_API_KEY', '')).strip()

    def get_effective_openrouter_key(self) -> str:
        return (self.openrouter_api_key or os.environ.get('OPENROUTER_API_KEY', '')).strip()

    @classmethod
    def get_settings(cls) -> 'AISettings':
        settings, _ = cls.objects.get_or_create(id=1)
        return settings
