# users/admin.py
from django.contrib import admin                       # Import Django admin module
from django.contrib.auth.admin import UserAdmin       # Import the built-in UserAdmin to customize user display
from .models import User                               # Import the custom User model

# Register the custom User model with the Django admin site
@admin.register(User)
class CustomUserAdmin(UserAdmin):
    # Fieldsets define the layout of fields when viewing/editing a user in admin
    readonly_fields = ('date_joined',)

    fieldsets = (
        (None, {'fields': ('email', 'password')}),  # Basic login fields
        ('Personal Info', {'fields': ('first_name', 'last_name', 'username')}),  # User's personal info
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),  # Permissions & roles
        ('Important dates', {'fields': ('last_login', 'date_joined')}),  # Track last login and join date
    )

    # Fields shown when adding a new user via admin
    add_fieldsets = (
        (None, {
            'classes': ('wide',),  # Makes the form wider in the admin interface
            'fields': ('email', 'username', 'first_name', 'last_name', 'password1', 'password2'),  # Fields required for new user creation
        }),
    )

    # Columns displayed in the user list view in admin
    list_display = ('email', 'username', 'full_name', 'is_staff', 'is_active')

    # Fields that can be searched via admin search bar
    search_fields = ('email', 'username', 'first_name', 'last_name')

    # Default ordering of users in the admin list view
    ordering = ('email',)
