from django.contrib import admin
from .models import Transaction, RecurringTransaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'type', 'category', 'amount', 'date', 'description']
    list_filter = ['type', 'category', 'date', 'user']
    search_fields = ['description', 'user__email', 'category__name']
    date_hierarchy = 'date'
    ordering = ['-date']


@admin.register(RecurringTransaction)
class RecurringTransactionAdmin(admin.ModelAdmin):
    list_display = [
        'user',
        'description',
        'type',
        'amount',
        'frequency',
        'next_run_date',
        'execution_count',
    ]
    list_filter = ['frequency', 'type', 'user']
    search_fields = ['description', 'user__email']
    ordering = ['next_run_date']