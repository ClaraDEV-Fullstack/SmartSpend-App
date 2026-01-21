"""
URL configuration for expense_tracker project.
"""

from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from django.conf import settings
from django.conf.urls.static import static

from settings_app import views
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

# ✅ Import google_login from users app
from users.views import google_login

# ✅ Import the new ViewSet from the transactions app
from transactions.views import RecurringTransactionViewSet

# ✅ Create a router for the recurring transactions
router = DefaultRouter()
router.register(r'recurring-transactions', RecurringTransactionViewSet, basename='recurring-transaction')

# Swagger/OpenAPI imports for API documentation
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework import permissions
from rest_framework_simplejwt.authentication import JWTAuthentication
from settings_app.views import user_settings

# --------------------------
# Configure Swagger/OpenAPI schema view
# --------------------------
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

    # This creates /api/recurring-transactions/ automatically
    path('api/', include(router.urls)),

    # JWT login/refresh
    path('api/users/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/users/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # ✅ Google Sign-In endpoint
    path('api/auth/google/', google_login, name='google_login'),

    # Swagger docs
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    # Other API endpoints
    path('api/categories/', include('categories.urls')),
    path('api/transactions/', include('transactions.urls')),
    path('api/reports/', include('reports.urls')),
    path('api/settings/', include('settings_app.urls')),
    path('user/', views.user_settings, name='user-settings'),
    path('user/update/', views.update_user_settings, name='update-user-settings'),
    path('password/change/', views.change_password, name='change-password'),

    path('api/ai/', include('ai.urls')),
]

# ✅ Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)