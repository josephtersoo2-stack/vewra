from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.accounts.views import RegisterView, LoginView, MeView, LogoutAllView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='auth_register'),
    path('login/', LoginView.as_view(), name='auth_login'),
    path('logout-all/', LogoutAllView.as_view(), name='auth_logout_all'),
    path('refresh/', TokenRefreshView.as_view(), name='auth_refresh'),
    path('token/refresh/', TokenRefreshView.as_view(), name='auth_token_refresh'),
    path('me/', MeView.as_view(), name='auth_me'),
]
