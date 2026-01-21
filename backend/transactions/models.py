# transactions/models.py
from django.db import models
from django.contrib.auth import get_user_model
from categories.models import Category

User = get_user_model()

class Transaction(models.Model):

    """
    Represents a single financial transaction — expense or income.
    Linked to user and category for ownership and grouping.
    """

    is_recurring = models.BooleanField(default=False)

    RECURRENCE_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly'),
    ]

    recurrence = models.CharField(
        max_length=10,
        choices=RECURRENCE_CHOICES,
        null=True,
        blank=True
    )

    TRANSACTION_TYPE_CHOICES = [
        ('expense', 'Expense'),
        ('income', 'Income'),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='transactions',
        help_text="Owner of this transaction"
    )

    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,  # Prevent deletion of categories used by transactions
        null=False,                # Disallows null values in database
        blank=False,               # Requires value in forms
        related_name='transactions',
        help_text="Category this transaction belongs to"
    )

    type = models.CharField(
        max_length=10,
        choices=TRANSACTION_TYPE_CHOICES,
        default='expense',
        help_text="Whether this is money in or out"
    )

    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="Transaction amount (positive number)"
    )

    description = models.TextField(
        blank=True,
        help_text="Optional description (e.g., 'Lunch with team', 'Freelance payment')"
    )

    date = models.DateField(
        help_text="Date when transaction occurred"
    )

    # 👇 NEW: Add currency field
    currency = models.CharField(
        max_length=3,
        default='USD',
        help_text="Currency code (e.g., USD, EUR, GBP)"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-created_at']
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions"

    def __str__(self):
        category_name = self.category.name if self.category else "Uncategorized"
        return f"{self.type.title()} | {category_name} | {self.amount} {self.currency} | {self.date}"

    @property
    def is_expense(self):
        return self.type == 'expense'

    @property
    def is_income(self):
        return self.type == 'income'

    def clean(self):
        """
        Custom validation: Amount must be positive
        """
        from django.core.exceptions import ValidationError
        if self.amount <= 0:
            raise ValidationError("Amount must be greater than zero.")

    def save(self, *args, **kwargs):
        self.full_clean()  # Run validations before saving
        super().save(*args, **kwargs)



class RecurringTransaction(models.Model):
    FREQUENCY_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recurring_transactions')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.CharField(max_length=255)
    type = models.CharField(max_length=10, choices=[('income', 'Income'), ('expense', 'Expense')])
    currency = models.CharField(max_length=3, default='USD')

    # Recurring specific configuration
    frequency = models.CharField(max_length=10, choices=FREQUENCY_CHOICES)
    next_run_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    total_executions = models.IntegerField(null=True, blank=True)
    execution_count = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.description} ({self.frequency})"