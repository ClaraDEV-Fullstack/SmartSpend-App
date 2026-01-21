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

    # Optional field for recurring transactions
    next_run_date = serializers.DateField(
        required=False,    # only required if is_recurring=True
        allow_null=True,
        help_text="Next date this recurring transaction should occur"
    )

    class Meta:
        model = Transaction
        fields = [
            'id',
            'type',
            'amount',
            'description',
            'date',
            'category',      # Read-only nested object
            'category_id',   # Write-only ID field
            'currency',      # Currency field
            'next_run_date',
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
        Validate transaction and map next_run_date → date if recurring.
        """
        user = self.context['request'].user
        category = attrs.get('category')

        if not category:
            raise serializers.ValidationError("Category is required.")

        if category.user != user:
            raise serializers.ValidationError("You can only use your own categories.")

        # Validate currency
        currency = attrs.get('currency', 'USD')
        if not self.is_valid_currency(currency):
            raise serializers.ValidationError(
                "Invalid currency code. Use ISO 4217 format (e.g., USD, EUR)."
            )

        # Map next_run_date → date for recurring transactions
        if attrs.get('is_recurring') and attrs.get('next_run_date'):
            attrs['date'] = attrs['next_run_date']

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
