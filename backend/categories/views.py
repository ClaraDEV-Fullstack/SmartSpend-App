# categories/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from .models import Category
from .serializers import CategorySerializer

# drf_yasg imports
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

# --------------------------
# Pagination class
# --------------------------
class CategoryPagination(PageNumberPagination):
    page_size = 10  # default items per page
    page_size_query_param = 'page_size'
    max_page_size = 50

# --------------------------
# List & Create Categories
# --------------------------
@swagger_auto_schema(
    method='post',
    request_body=CategorySerializer,
    responses={201: CategorySerializer, 400: "Validation Error", 401: "Unauthorized"}
)
@swagger_auto_schema(
    method='get',
    responses={200: CategorySerializer(many=True), 401: "Unauthorized"}
)
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def category_list(request, version=None):
    """
    GET: List all categories for current user (with optional type filter & pagination)
    POST: Create a new category
    """
    if request.method == 'GET':
        categories = Category.objects.filter(user=request.user)

        # Optional filter by type: ?type=expense or ?type=income
        category_type = request.GET.get('type')
        if category_type:
            categories = categories.filter(type=category_type)

        # Pagination
        paginator = CategoryPagination()
        result_page = paginator.paginate_queryset(categories, request)
        serializer = CategorySerializer(result_page, many=True)
        return paginator.get_paginated_response(serializer.data)

    elif request.method == 'POST':
        serializer = CategorySerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# --------------------------
# Retrieve, Update, Delete Category
# --------------------------
@swagger_auto_schema(
    method='get',
    responses={200: CategorySerializer, 401: "Unauthorized", 404: "Don't Exist"}
)
@swagger_auto_schema(
    method='put',
    request_body=CategorySerializer,
    responses={200: CategorySerializer, 400: "Validation Error", 401: "Unauthorized", 404: "Don't Exist"}
)
@swagger_auto_schema(
    method='delete',
    responses={204: "No Content", 401: "Unauthorized", 404: "Don't Exist"}
)
@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def category_detail(request, pk, version=None):
    """
    GET: Retrieve one category
    PUT: Update category
    DELETE: Delete category
    """
    try:
        category = Category.objects.get(pk=pk, user=request.user)
    except Category.DoesNotExist:
        return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = CategorySerializer(category)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = CategorySerializer(category, data=request.data, context={'request': request}, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        category.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
