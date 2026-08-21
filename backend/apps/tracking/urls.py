from django.urls import path
from apps.tracking.views import ProgressTrackingView

urlpatterns = [
    path('progress/', ProgressTrackingView.as_view(), name='tracking_progress'),
]
