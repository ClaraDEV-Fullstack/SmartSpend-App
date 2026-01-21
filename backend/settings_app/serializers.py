from rest_framework import serializers
from .models import UserSetting

class UserSettingSerializer(serializers.ModelSerializer):
    default_category_id = serializers.IntegerField(
        source='default_category.id',
        allow_null=True,
        required=False,
        write_only=True
    )
    default_category_name = serializers.CharField(
        source='default_category.name',
        read_only=True
    )

    # Format notification_time as string
    notification_time = serializers.TimeField(format='%H:%M', input_formats=['%H:%M'])

    class Meta:
        model = UserSetting
        fields = [
            'currency',
            'theme',
            'notifications_enabled',
            'email_reports',
            'default_category_id',
            'default_category_name',
            # New fields
            'start_of_week',
            'date_format',
            'notification_time',
            'transaction_notifications',
            'weekly_reports',
            'monthly_reports',
            'biometric_enabled',
            'budget_alerts',
            'monthly_budget',
            'report_format',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def update(self, instance, validated_data):
        # Handle nested default_category update
        if 'default_category' in validated_data:
            cat_id = validated_data.pop('default_category')['id']
            from categories.models import Category
            if cat_id is None:
                instance.default_category = None
            else:
                try:
                    category = Category.objects.get(id=cat_id, user=instance.user)
                    instance.default_category = category
                except Category.DoesNotExist:
                    raise serializers.ValidationError({
                        "default_category_id": "Category not found or does not belong to you."
                    })

        # Update all other fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.save()
        return instance