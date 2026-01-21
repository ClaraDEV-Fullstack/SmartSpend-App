# reports/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('summary/', views.report_summary, name='report-summary'),

]