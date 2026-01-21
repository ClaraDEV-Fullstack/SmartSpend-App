from django.db import models
from django.conf import settings
from categories.models import Category
from datetime import time

class UserSetting(models.Model):
    CURRENCY_CHOICES = [
        ('USD', 'US Dollar'),
        ('EUR', 'Euro'),
        ('GBP', 'British Pound'),
        ('JPY', 'Japanese Yen'),
        ('CAD', 'Canadian Dollar'),
        ('AUD', 'Australian Dollar'),
        ('CFA', 'CFA Franc'),
        ('CNY', 'Chinese Yuan'),
        ('BRL', 'Brazilian Real'),
        ('ZAR', 'South African Rand'),
    ]

    THEME_CHOICES = [
        ('light', 'Light'),
        ('dark', 'Dark'),
        ('system', 'System'),
    ]

    START_OF_WEEK_CHOICES = [
        ('Sunday', 'Sunday'),
        ('Monday', 'Monday'),
        ('Tuesday', 'Tuesday'),
        ('Wednesday', 'Wednesday'),
        ('Thursday', 'Thursday'),
        ('Friday', 'Friday'),
        ('Saturday', 'Saturday'),
    ]

    DATE_FORMAT_CHOICES = [
        ('MM/DD/YYYY', 'MM/DD/YYYY'),
        ('DD/MM/YYYY', 'DD/MM/YYYY'),
        ('YYYY-MM-DD', 'YYYY-MM-DD'),
    ]

    REPORT_FORMAT_CHOICES = [
        ('PDF', 'PDF'),
        ('CSV', 'CSV'),
        ('Excel', 'Excel'),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='settings'
    )
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='USD')
    theme = models.CharField(max_length=10, choices=THEME_CHOICES, default='system')
    notifications_enabled = models.BooleanField(default=True)
    email_reports = models.BooleanField(default=False)
    default_category = models.ForeignKey(
        Category,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        help_text="Default category for new transactions"
    )

    # New fields from frontend
    start_of_week = models.CharField(
        max_length=10,
        choices=START_OF_WEEK_CHOICES,
        default='Sunday'
    )
    date_format = models.CharField(
        max_length=10,
        choices=DATE_FORMAT_CHOICES,
        default='MM/DD/YYYY'
    )
    notification_time = models.TimeField(default=time(9, 0))  # Default 9:00 AM
    transaction_notifications = models.BooleanField(default=True)
    weekly_reports = models.BooleanField(default=True)
    monthly_reports = models.BooleanField(default=True)
    biometric_enabled = models.BooleanField(default=False)
    budget_alerts = models.BooleanField(default=True)
    monthly_budget = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=1000.00
    )
    report_format = models.CharField(
        max_length=10,
        choices=REPORT_FORMAT_CHOICES,
        default='PDF'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s settings"

    class Meta:
        verbose_name = "User Setting"
        verbose_name_plural = "User Settings"