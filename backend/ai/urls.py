from django.urls import path
from .views import AIAssistView, AIHistoryView, AIStatusView

urlpatterns = [
    path('assist/', AIAssistView.as_view(), name='ai-assist'),
    path('history/', AIHistoryView.as_view(), name='ai-history'),
    path('status/', AIStatusView.as_view(), name='ai-status'),
]
