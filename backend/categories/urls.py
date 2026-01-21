# categories/urls.py

from django.urls import path
from . import views

app_name = "categories"

urlpatterns = [
    # Versioned endpoints: e.g., /api/v1/categories/
    path('v1/', views.category_list, name='category-list'),
    path('v1/<int:pk>/', views.category_detail, name='category-detail'),
]
