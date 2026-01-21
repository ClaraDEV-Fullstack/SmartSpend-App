# categories/serializers.py

from rest_framework import serializers
from .models import Category

class CategorySerializer(serializers.ModelSerializer):
    """
    Converts Category model ↔ JSON.
    Handles validation and serialization.
    """

    class Meta:
        model = Category
        fields = [
            'id',          # 👉 Auto-generated primary key
            'name',
            'type',
            'color',
            'icon',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']  # 👉 These are auto-set

    def validate_name(self, value):
        """
        👉 Custom validation: Ensure category name is unique per user.
        Case-insensitive to avoid "Food" vs "food".
        """
        user = self.context['request'].user  # 👉 Get current user from request context
        if Category.objects.filter(user=user, name__iexact=value).exists():
            raise serializers.ValidationError("You already have a category with this name.")
        return value

    def create(self, validated_data):
        """
        👉 Override to auto-assign user from request.
        Frontend doesn't send 'user' — we set it server-side.
        """
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)