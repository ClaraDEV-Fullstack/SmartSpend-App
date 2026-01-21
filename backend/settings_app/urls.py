# settings_app/urls.py
from django.urls import path
from . import views


urlpatterns = [
    path('user/', views.user_settings, name='user-settings'),
    path('user/update/', views.update_user_settings, name='update-user-settings'),
    path('auth/password/change/', views.change_password, name='change-password'),
]