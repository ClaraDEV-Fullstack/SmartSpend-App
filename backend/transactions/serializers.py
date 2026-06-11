from rest_framework import serializers
from .models import Transaction
from categories.models import Category
from categories.serializers import CategorySerializer
from .models import Transaction, RecurringTransaction # Import the new model
class TransactionSerializer(serializers.ModelSerializer):
    """
    Serializer for Transaction model.
    Includes nested category data for frontend convenience.
    """

    # Read-only nested serializer for GET requests
    category = CategorySerializer(read_only=True)

    # Write-only field for POST/PUT — accepts category ID
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='category',
        write_only=True,
        required=True,
        allow_null=False
    )

    # Optional legacy recurring fields on Transaction
    is_recurring = serializers.BooleanField(required=False, default=False)
    recurrence = serializers.CharField(required=False, allow_null=True, allow_blank=True)

    class Meta:
        model = Transaction
        fields = [
            'id',
            'type',
            'amount',
            'description',
            'date',
            'category',
            'category_id',
            'currency',
            'is_recurring',
            'recurrence',
            'created_at',
            'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero.")
        return value

    def validate(self, attrs):
        """
        Validate transaction ownership and currency.
        """
        user = self.context['request'].user
        category = attrs.get('category')

        if not category:
            raise serializers.ValidationError("Category is required.")

        if category.user != user:
            raise serializers.ValidationError("You can only use your own categories.")

        currency = attrs.get('currency', 'USD')
        if not self.is_valid_currency(currency):
            raise serializers.ValidationError(
                "Invalid currency code. Use ISO 4217 format (e.g., USD, EUR)."
            )

        return attrs

    def is_valid_currency(self, currency_code):
        """
        Validate currency code against ISO 4217 standard
        """
        # Common currencies for validation
        common_currencies = ['USD', 'EUR', 'CFA', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'MXN']
        return currency_code in common_currencies

    def create(self, validated_data):
        """
        Set the user when creating a transaction
        """
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)



class RecurringTransactionSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='category',
        write_only=True
    )

    class Meta:
        model = RecurringTransaction
        fields = [
            'id', 'type', 'amount', 'description', 'category', 'category_id',
            'currency', 'frequency', 'next_run_date', 'end_date',
            'total_executions', 'execution_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'execution_count']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
