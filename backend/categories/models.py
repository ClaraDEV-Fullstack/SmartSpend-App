from django.db import models

# Create your models here.
# categories/models.py

from django.db import models
from django.contrib.auth import get_user_model  # 👉 Always use this to get User model — supports custom User

User = get_user_model()  # 👉 Gets the active User model (even if you change AUTH_USER_MODEL later)

class Category(models.Model):
    """
    Represents a user-defined category for expenses or income.
    Each user owns their own categories — no sharing.
    """

    # 🔹 Define choices for 'type' field — clean, readable, and validated
    TYPE_CHOICES = [
        ('expense', 'Expense'),   # Stored in DB as 'expense', shown in Admin as 'Expense'
        ('income', 'Income'),
    ]

    # 🔹 Link category to its owner — critical for multi-user apps
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,        # 👉 If user is deleted, delete their categories too
        related_name='categories',       # 👉 Allows: user.categories.all()
        help_text="The user who owns this category"
    )

    # 🔹 Name of the category — e.g., "Food", "Salary"
    name = models.CharField(
        max_length=100,
        help_text="Display name for the category (e.g., 'Groceries', 'Freelance Income')"
    )

    # 🔹 Type — expense or income — used for filtering and reports
    type = models.CharField(
        max_length=10,
        choices=TYPE_CHOICES,            # 👉 Restricts values to predefined choices
        default='expense',               # 👉 Default to expense if not specified
        help_text="Whether this category is for incoming or outgoing money"
    )

    # 🔹 Optional: Color for UI (Flutter/Web) — stored as HEX code
    color = models.CharField(
        max_length=7,
        default='#000000',               # 👉 Black as default
        help_text="HEX color code for UI display (e.g., '#FF5733')"
    )

    # 🔹 Optional: Icon name for UI — e.g., 'fastfood', 'attach_money'
    icon = models.CharField(
        max_length=50,
        blank=True,                      # 👉 Not required
        help_text="Icon identifier for frontend (e.g., 'restaurant', 'flight')"
    )

    # 🔹 Auto timestamps — always useful
    created_at = models.DateTimeField(auto_now_add=True)  # 👉 Set once on creation
    updated_at = models.DateTimeField(auto_now=True)      # 👉 Updated every time .save() is called

    class Meta:
        ordering = ['name']              # 👉 Default sort order: A-Z by name
        unique_together = ['user', 'name']  # 👉 Prevent duplicate category names per user

    def __str__(self):
        # 👉 Human-readable representation in Admin and shell
        return f"{self.name} ({self.type}) - {self.user.email}"

    @property
    def is_expense(self):
        # 👉 Helper property for cleaner logic in views/templates
        return self.type == 'expense'

    @property
    def is_income(self):
        # 👉 Helper property for cleaner logic
        return self.type == 'income'