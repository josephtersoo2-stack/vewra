from django.urls import path
from apps.ai_service.views import ListModelsAPIView, GenerateKeywordsAPIView, AISettingsAPIView

urlpatterns = [
    path('models/', ListModelsAPIView.as_view(), name='ai-models-list'),
    path('generate-keywords/', GenerateKeywordsAPIView.as_view(), name='ai-generate-keywords'),
    path('settings/', AISettingsAPIView.as_view(), name='ai-settings'),
]
