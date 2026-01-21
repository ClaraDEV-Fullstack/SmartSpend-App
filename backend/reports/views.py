# reports/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count
from transactions.models import Transaction
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

@swagger_auto_schema(
    method='get',
    tags=['reports'],
    operation_summary="Get Financial Summary",  # 👈 Added summary title
    operation_description="Retrieve a financial summary including total income, total expenses, net balance, and category-wise breakdown. Supports optional filtering by date range and category.",
    manual_parameters=[
        openapi.Parameter(
            'start_date',
            openapi.IN_QUERY,
            description="Start date in YYYY-MM-DD format",
            type=openapi.TYPE_STRING,
            format=openapi.FORMAT_DATE
        ),
        openapi.Parameter(
            'end_date',
            openapi.IN_QUERY,
            description="End date in YYYY-MM-DD format",
            type=openapi.TYPE_STRING,
            format=openapi.FORMAT_DATE
        ),
        openapi.Parameter(
            'category_id',
            openapi.IN_QUERY,
            description="Filter by category ID",
            type=openapi.TYPE_INTEGER
        ),
    ],
    responses={
        200: openapi.Response(
            description="Summary data",
            examples={
                "application/json": {
                    "summary": {
                        "total_income": 1500.0,
                        "total_expense": 230.5,
                        "net_balance": 1269.5,
                        "net_status": "positive"
                    },
                    "category_breakdown": [
                        {
                            "category_id": 1,
                            "category_name": "Food",
                            "type": "expense",
                            "color": "#FF6B6B",
                            "total": 100.0,
                            "count": 3
                        }
                    ]
                }
            }
        ),
        401: "Unauthorized"
    }
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def report_summary(request):
    """
    👉 GET: Get financial summary with optional date range.
    Query params:
      - start_date (YYYY-MM-DD)
      - end_date (YYYY-MM-DD)
      - category_id (int)
    """
    user = request.user
    transactions = Transaction.objects.filter(user=user)

    # Apply filters
    start_date = request.query_params.get('start_date')
    end_date = request.query_params.get('end_date')
    category_id = request.query_params.get('category_id')

    if start_date:
        transactions = transactions.filter(date__gte=start_date)
    if end_date:
        transactions = transactions.filter(date__lte=end_date)
    if category_id:
        transactions = transactions.filter(category_id=category_id)

    total_income = transactions.filter(type='income').aggregate(total=Sum('amount'))['total'] or 0
    total_expense = transactions.filter(type='expense').aggregate(total=Sum('amount'))['total'] or 0
    net_balance = total_income - total_expense

    # Category breakdown
    category_breakdown = transactions.values(
        'category__id',
        'category__name',
        'category__type',
        'category__color'
    ).annotate(
        total=Sum('amount'),
        count=Count('id')
    ).order_by('-total')

    return Response({
        'summary': {
            'total_income': round(total_income, 2),
            'total_expense': round(total_expense, 2),
            'net_balance': round(net_balance, 2),
            'net_status': 'positive' if net_balance > 0 else 'negative' if net_balance < 0 else 'neutral'
        },
        'category_breakdown': [
            {
                'category_id': item['category__id'],
                'category_name': item['category__name'] or 'Uncategorized',
                'type': item['category__type'] or 'expense',
                'color': item['category__color'] or '#9E9E9E',
                'total': round(item['total'], 2),
                'count': item['count']
            }
            for item in category_breakdown
        ]
    })