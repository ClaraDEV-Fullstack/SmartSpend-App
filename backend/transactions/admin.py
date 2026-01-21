# transactions/admin.py
from django.contrib import admin
from .models import Transaction

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'type', 'category', 'amount', 'date', 'description']
    list_filter = ['type', 'category', 'date', 'user']
    search_fields = ['description', 'user__email', 'category__name']
    date_hierarchy = 'date'  # 👉 Nice date drilldown
    ordering = ['-date']