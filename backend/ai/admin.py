from django.contrib import admin
from .models import AIConversation, AIMessage, AIUsageLog


@admin.register(AIConversation)
class AIConversationAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'is_active', 'updated_at']
    list_filter = ['is_active']
    search_fields = ['user__email']


@admin.register(AIMessage)
class AIMessageAdmin(admin.ModelAdmin):
    list_display = ['id', 'conversation', 'role', 'service_used', 'created_at']
    list_filter = ['role', 'service_used']
    search_fields = ['content']


@admin.register(AIUsageLog)
class AIUsageLogAdmin(admin.ModelAdmin):
    list_display = ['user', 'service', 'success', 'response_time_ms', 'created_at']
    list_filter = ['service', 'success']
    search_fields = ['user__email', 'request_message']
