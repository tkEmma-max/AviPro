# api/urls_peupler.py
from django.urls import path
from .views import PeuplerDBView

urlpatterns = [
    path('', PeuplerDBView.as_view(), name='peupler-db'),
]