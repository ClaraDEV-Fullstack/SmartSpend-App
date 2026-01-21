# ai/urls.py

# ai/urls.py

from django.urls import path
from .views import AIAssistView, AIStatusView

urlpatterns = [
    path('assist/', AIAssistView.as_view(), name='ai-assist'),
    path('status/', AIStatusView.as_view(), name='ai-status'),
]