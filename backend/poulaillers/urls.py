# poulaillers/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PoulaillerViewSet

router = DefaultRouter()
router.register(r'', PoulaillerViewSet, basename='poulaillers')

urlpatterns = [
    path('', include(router.urls)),
]