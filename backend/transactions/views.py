# transactions/views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Transaction
from .serializers import TransactionSerializer
from django.db.models import Sum
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from rest_framework import viewsets # Add this import
from .models import Transaction, RecurringTransaction # Add RecurringTransaction
from .serializers import TransactionSerializer, RecurringTransactionSerializer # Add Serializer

@swagger_auto_schema(
    method='get',
    operation_description="Get list of user's transactions with optional filters.",
    manual_parameters=[
        openapi.Parameter('category', openapi.IN_QUERY, description="Filter by category ID", type=openapi.TYPE_INTEGER),
        openapi.Parameter('type', openapi.IN_QUERY, description="Filter by type: 'income' or 'expense'", type=openapi.TYPE_STRING, enum=['income', 'expense']),
        openapi.Parameter('start_date', openapi.IN_QUERY, description="Filter transactions from this date (YYYY-MM-DD)", type=openapi.TYPE_STRING, format=openapi.FORMAT_DATE),
        openapi.Parameter('end_date', openapi.IN_QUERY, description="Filter transactions up to this date (YYYY-MM-DD)", type=openapi.TYPE_STRING, format=openapi.FORMAT_DATE),
        openapi.Parameter('currency', openapi.IN_QUERY, description="Filter by currency code", type=openapi.TYPE_STRING),
    ],
    responses={
        200: TransactionSerializer(many=True),
        401: 'Unauthorized',
    }
)
@swagger_auto_schema(
    method='post',
    operation_description="Create a new transaction for the authenticated user.",
    request_body=TransactionSerializer,
    responses={
        201: TransactionSerializer,
        400: 'Bad Request',
        401: 'Unauthorized',
    }
)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def transaction_list(request):
    """
    GET: List user's transactions (with optional filters)
    POST: Create new transaction
    """
    if request.method == 'GET':
        transactions = Transaction.objects.filter(user=request.user)

        # Optional filtering
        category_id = request.query_params.get('category')
        transaction_type = request.query_params.get('type')
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        currency = request.query_params.get('currency')

        if category_id:
            transactions = transactions.filter(category_id=category_id)
        if transaction_type:
            transactions = transactions.filter(type=transaction_type)
        if start_date:
            transactions = transactions.filter(date__gte=start_date)
        if end_date:
            transactions = transactions.filter(date__lte=end_date)
        if currency:
            transactions = transactions.filter(currency=currency)

        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        # Check if category_id is provided in request data
        if 'category_id' not in request.data:
            return Response(
                {"error": "Category ID is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create a mutable copy of request data
        data = request.data.copy()

        # Set default currency if not provided
        if 'currency' not in data:
            # Get user's preferred currency if available
            if hasattr(request.user, 'profile') and hasattr(request.user.profile, 'currency'):
                data['currency'] = request.user.profile.currency
            else:
                data['currency'] = 'CFA'  # Default to CFA

        # Pass the request context to the serializer
        serializer = TransactionSerializer(data=data, context={'request': request})
        if serializer.is_valid():
            # FIXED: Remove user parameter from save() - it's set in the serializer
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def recurring_transaction_create(request):
    """
    Create a recurring transaction
    """
    data = request.data.copy()
    data['is_recurring'] = True

    serializer = TransactionSerializer(
        data=data,
        context={'request': request}
    )

    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@swagger_auto_schema(
    method='get',
    operation_description="Retrieve a single transaction by ID.",
    responses={
        200: TransactionSerializer,
        404: 'Not Found',
        401: 'Unauthorized',
    }
)
@swagger_auto_schema(
    method='put',
    operation_description="Update a transaction (partial updates allowed).",
    request_body=TransactionSerializer,
    responses={
        200: TransactionSerializer,
        400: 'Bad Request',
        404: 'Not Found',
        401: 'Unauthorized',
    }
)
@swagger_auto_schema(
    method='delete',
    operation_description="Delete a transaction.",
    responses={
        204: 'No Content',
        404: 'Not Found',
        401: 'Unauthorized',
    }
)


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def transaction_detail(request, pk):
    """
    GET: Retrieve one transaction
    PUT: Update transaction
    DELETE: Delete transaction
    """
    try:
        transaction = Transaction.objects.get(pk=pk, user=request.user)
    except Transaction.DoesNotExist:
        return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = TransactionSerializer(transaction)
        return Response(serializer.data)

    elif request.method == 'PUT':
        # Check if category_id is provided in request data
        if 'category_id' not in request.data:
            return Response(
                {"error": "Category ID is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create a mutable copy of request data
        data = request.data.copy()

        # Pass the request context to the serializer
        serializer = TransactionSerializer(transaction, data=data, context={'request': request}, partial=True)
        if serializer.is_valid():
            # FIXED: No need to set user here as it's already set on the instance
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        transaction.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@swagger_auto_schema(
    method='get',
    operation_description="Get summary stats: total income, expenses, balance, total transactions. Supports filters by category, type, date range, month, year, and currency.",
    manual_parameters=[
        openapi.Parameter('category', openapi.IN_QUERY, description="Filter by category ID", type=openapi.TYPE_INTEGER),
        openapi.Parameter('type', openapi.IN_QUERY, description="Filter by transaction type: 'income' or 'expense'", type=openapi.TYPE_STRING, enum=['income', 'expense']),
        openapi.Parameter('start_date', openapi.IN_QUERY, description="Filter transactions from this date (YYYY-MM-DD)", type=openapi.TYPE_STRING, format=openapi.FORMAT_DATE),
        openapi.Parameter('end_date', openapi.IN_QUERY, description="Filter transactions up to this date (YYYY-MM-DD)", type=openapi.TYPE_STRING, format=openapi.FORMAT_DATE),
        openapi.Parameter('month', openapi.IN_QUERY, description="Filter by month (1-12)", type=openapi.TYPE_INTEGER),
        openapi.Parameter('year', openapi.IN_QUERY, description="Filter by year (YYYY)", type=openapi.TYPE_INTEGER),
        openapi.Parameter('currency', openapi.IN_QUERY, description="Filter by currency code", type=openapi.TYPE_STRING),
    ],
    responses={
        200: openapi.Response(
            description="Summary data grouped by currency",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={
                    'total_income': openapi.Schema(type=openapi.TYPE_NUMBER, description="Sum of all income transactions"),
                    'total_expense': openapi.Schema(type=openapi.TYPE_NUMBER, description="Sum of all expense transactions"),
                    'balance': openapi.Schema(type=openapi.TYPE_NUMBER, description="Net balance (income - expense)"),
                    'total_transactions': openapi.Schema(type=openapi.TYPE_INTEGER, description="Total number of transactions"),
                    'net_flow': openapi.Schema(type=openapi.TYPE_STRING, description="'positive', 'negative', or 'zero'"),
                }
            )
        ),
        401: 'Unauthorized',
    }
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def transaction_summary(request):
    transactions = Transaction.objects.filter(user=request.user)

    # Apply filters
    category_id = request.query_params.get('category')
    transaction_type = request.query_params.get('type')
    start_date = request.query_params.get('start_date')
    end_date = request.query_params.get('end_date')
    month = request.query_params.get('month')
    year = request.query_params.get('year')
    currency = request.query_params.get('currency')

    if category_id:
        transactions = transactions.filter(category_id=category_id)
    if transaction_type:
        transactions = transactions.filter(type=transaction_type)
    if start_date:
        transactions = transactions.filter(date__gte=start_date)
    if end_date:
        transactions = transactions.filter(date__lte=end_date)
    if month:
        transactions = transactions.filter(date__month=int(month))
    if year:
        transactions = transactions.filter(date__year=int(year))
    if currency:
        transactions = transactions.filter(currency=currency)

    # Group by currency for multi-currency support
    summary_by_currency = {}
    for transaction in transactions:
        curr = transaction.currency
        if curr not in summary_by_currency:
            summary_by_currency[curr] = {
                'total_income': 0,
                'total_expense': 0,
                'balance': 0,
                'total_transactions': 0
            }

        if transaction.type == 'income':
            summary_by_currency[curr]['total_income'] += float(transaction.amount)
        else:
            summary_by_currency[curr]['total_expense'] += float(transaction.amount)

        summary_by_currency[curr]['balance'] = summary_by_currency[curr]['total_income'] - summary_by_currency[curr]['total_expense']
        summary_by_currency[curr]['total_transactions'] += 1

    # Add net_flow for each currency
    for curr, data in summary_by_currency.items():
        data['net_flow'] = 'positive' if data['balance'] > 0 else 'negative' if data['balance'] < 0 else 'zero'

    return Response(summary_by_currency)


# ✅ ADD THIS CLASS AT THE BOTTOM
class RecurringTransactionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for handling Recurring Transactions.
    Automatically provides list, create, retrieve, update, and destroy actions.
    """
    serializer_class = RecurringTransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Only return recurring transactions for the logged-in user
        return RecurringTransaction.objects.filter(user=self.request.user)