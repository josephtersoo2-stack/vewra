from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser

from apps.ai_service.models import AISettings
from apps.ai_service.services import get_available_models, generate_video_keywords, extract_youtube_metadata

class ListModelsAPIView(APIView):
    """
    Dynamically queries available models from Gemini or OpenRouter without hardcoding.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        provider = request.query_params.get('provider', 'gemini')
        api_key = request.query_params.get('api_key', None)

        try:
            models = get_available_models(provider=provider, api_key=api_key)
            return Response({
                'status': 'success',
                'provider': provider,
                'total_models': len(models),
                'models': models
            })
        except Exception as e:
            return Response({
                'status': 'error',
                'message': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class GenerateKeywordsAPIView(APIView):
    """
    Fetches YouTube video metadata and generates 6-10 high-relevance search keywords via LLM.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        youtube_url = request.data.get('youtube_url', '').strip()
        if not youtube_url:
            return Response({
                'status': 'error',
                'message': 'youtube_url is required.'
            }, status=status.HTTP_400_BAD_REQUEST)

        title_override = request.data.get('title', None)
        provider = request.data.get('provider', None)
        model = request.data.get('model', None)

        try:
            result = generate_video_keywords(
                youtube_url_or_id=youtube_url,
                title_override=title_override,
                provider_override=provider,
                model_override=model,
            )
            return Response({
                'status': 'success',
                **result
            })
        except Exception as e:
            return Response({
                'status': 'error',
                'message': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class AISettingsAPIView(APIView):
    """
    Get or update AI settings.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        s = AISettings.get_settings()
        return Response({
            'active_provider': s.active_provider,
            'selected_model': s.selected_model,
            'has_gemini_key': bool(s.get_effective_gemini_key()),
            'has_openrouter_key': bool(s.get_effective_openrouter_key()),
            'is_active': s.is_active,
            'custom_system_prompt': s.custom_system_prompt,
        })

    def post(self, request):
        s = AISettings.get_settings()
        if 'active_provider' in request.data:
            s.active_provider = request.data['active_provider']
        if 'gemini_api_key' in request.data:
            s.gemini_api_key = request.data['gemini_api_key']
        if 'openrouter_api_key' in request.data:
            s.openrouter_api_key = request.data['openrouter_api_key']
        if 'selected_model' in request.data:
            s.selected_model = request.data['selected_model']
        if 'is_active' in request.data:
            s.is_active = request.data['is_active']
        if 'custom_system_prompt' in request.data:
            s.custom_system_prompt = request.data['custom_system_prompt']
        s.save()

        return Response({
            'status': 'success',
            'message': 'AI Settings updated successfully.',
            'active_provider': s.active_provider,
            'selected_model': s.selected_model,
        })
