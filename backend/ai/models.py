from django.db import models

# Create your models here.
# ai/models.py

from django.db import models
from django.conf import settings


class AIConversation(models.Model):
    """
    Stores AI chat history for each user
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='ai_conversations'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['-updated_at']
        verbose_name = 'AI Conversation'
        verbose_name_plural = 'AI Conversations'

    def __str__(self):
        return f"Conversation {self.id} - {self.user.email}"


class AIMessage(models.Model):
    """
    Individual messages in a conversation
    """
    ROLE_CHOICES = [
        ('user', 'User'),
        ('assistant', 'Assistant'),
    ]

    conversation = models.ForeignKey(
        AIConversation,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    content = models.TextField()

    # Store action data if AI suggested an action
    action_type = models.CharField(max_length=50, blank=True, null=True)
    action_data = models.JSONField(blank=True, null=True)
    action_executed = models.BooleanField(default=False)

    # Track which AI service was used
    service_used = models.CharField(
        max_length=20,
        default='local',
        help_text='gemini or local'
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        verbose_name = 'AI Message'
        verbose_name_plural = 'AI Messages'

    def __str__(self):
        return f"{self.role}: {self.content[:50]}..."


class AIUsageLog(models.Model):
    """
    Track AI usage for rate limiting and analytics
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='ai_usage_logs'
    )
    service = models.CharField(
        max_length=20,
        help_text='gemini or local'
    )
    request_message = models.TextField()
    response_preview = models.CharField(max_length=200, blank=True)

    # Performance tracking
    response_time_ms = models.IntegerField(default=0)
    success = models.BooleanField(default=True)
    error_message = models.TextField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'AI Usage Log'
        verbose_name_plural = 'AI Usage Logs'

        # Index for efficient queries
        indexes = [
            models.Index(fields=['user', 'created_at']),
            models.Index(fields=['service', 'created_at']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.service} - {self.created_at}"

    @classmethod
    def get_user_usage_today(cls, user):
        """Get how many requests user made today"""
        from django.utils import timezone
        from datetime import timedelta

        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        return cls.objects.filter(
            user=user,
            created_at__gte=today_start
        ).count()