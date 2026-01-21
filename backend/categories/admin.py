from django.contrib import admin

# Register your models here.
# categories/admin.py

from django.contrib import admin
from .models import Category

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    """
    Customizes how Category appears in Django Admin.
    """
    list_display = ['name', 'type', 'user', 'created_at']  # 👉 Columns to show
    list_filter = ['type', 'user']                         # 👉 Filter sidebar
    search_fields = ['name', 'user__email']                # 👉 Search box
    ordering = ['user', 'name']                            # 👉 Default sort
    readonly_fields = ['created_at', 'updated_at']         # 👉 Can't edit timestamps in admin