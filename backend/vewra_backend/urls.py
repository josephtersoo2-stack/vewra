from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView
from apps.core.views import HealthCheckView, ReadinessCheckView, AdminFraudQueueView

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Observability & Health Probes (FIX-06)
    path('health/', HealthCheckView.as_view(), name='health_check'),
    path('ready/', ReadinessCheckView.as_view(), name='readiness_check'),

    # OpenAPI 3.0 Documentation & Swagger UI (FIX-14)
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # Core API Endpoints
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/tasks/', include('apps.tasks.urls')),
    path('api/v1/tracking/', include('apps.tracking.urls')),
    path('api/v1/wallet/', include('apps.wallet.urls')),
    path('api/v1/ai/', include('apps.ai_service.urls')),
    path('api/v1/admin/fraud/', AdminFraudQueueView.as_view(), name='admin_fraud_queue'),
    path('api/v1/admin/', include('apps.admin_api.urls')),
    path('api/v1/', include('apps.gamification.urls')),
]
