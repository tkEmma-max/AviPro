# cycles/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CycleViewSet

router = DefaultRouter()
router.register(r'', CycleViewSet, basename='cycles')

urlpatterns = [
    path('', include(router.urls)),
]