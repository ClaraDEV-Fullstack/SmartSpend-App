# users/urls.py
from django.urls import path        # Django function to define URL patterns
from . import views                # Import views from the current app

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    register_user,
    login_user,
    user_profile,
    google_login,
    delete_account,
    logout_user,
    ProfileImageView,
)

urlpatterns = [
    path('register/', register_user, name='register'),
    path('login/', login_user, name='login'),
    path('logout/', logout_user, name='logout'),
    path('me/', user_profile, name='user-profile'),
    path('me/delete/', delete_account, name='delete-account'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('auth/google/', google_login, name='google_login'),
    path('profile/image/', ProfileImageView.as_view(), name='profile-image'),
]