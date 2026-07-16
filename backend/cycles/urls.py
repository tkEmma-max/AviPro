# cycles/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CycleViewSet, TypePouletViewSet

router = DefaultRouter()
router.register(r'types-poulet', TypePouletViewSet, basename='type-poulet')
router.register(r'', CycleViewSet, basename='cycles')

urlpatterns = [
    path('', include(router.urls)),
]