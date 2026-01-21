from django.contrib import admin

# Register your models here.
# settings_app/admin.py
from django.contrib import admin
from .models import UserSetting

@admin.register(UserSetting)
class UserSettingAdmin(admin.ModelAdmin):
    list_display = ['user', 'currency', 'theme', 'notifications_enabled', 'updated_at']
    list_filter = ['currency', 'theme', 'notifications_enabled']
    search_fields = ['user__email', 'user__username']
    raw_id_fields = ['user', 'default_category']  # improves performance