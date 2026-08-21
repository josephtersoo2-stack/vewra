from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/tasks/', include('apps.tasks.urls')),
    path('api/v1/tracking/', include('apps.tracking.urls')),
    path('api/v1/wallet/', include('apps.wallet.urls')),
]
