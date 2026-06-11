"""
URL configuration for expense_tracker project.
"""

from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from django.conf import settings
from django.conf.urls.static import static

from rest_framework import permissions
from rest_framework_simplejwt.authentication import JWTAuthentication
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

from users.views import google_login
from transactions.views import RecurringTransactionViewSet

# ✅ Create a router for the recurring transactions
router = DefaultRouter()
router.register(r'recurring-transactions', RecurringTransactionViewSet, basename='recurring-transaction')

schema_view = get_schema_view(
    openapi.Info(
        title="Smart Spend API",
        default_version='v1',
        description="API for Smart Spend",
        terms_of_service="https://www.google.com/policies/terms/",
        contact=openapi.Contact(email="contact@smartspend.local"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
    authentication_classes=(JWTAuthentication,),
)

# --------------------------
# URL Patterns
# --------------------------
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/', include(router.urls)),

    # Legacy alias kept for mobile clients
    path('api/auth/google/', google_login, name='google_login'),

    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    path('api/categories/', include('categories.urls')),
    path('api/transactions/', include('transactions.urls')),
    path('api/reports/', include('reports.urls')),
    path('api/settings/', include('settings_app.urls')),
    path('api/ai/', include('ai.urls')),
]

# ✅ Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)