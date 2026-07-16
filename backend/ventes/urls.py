# ventes/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import VenteViewSet, TypeVenteViewSet

router = DefaultRouter()
router.register(r'types-vente', TypeVenteViewSet, basename='type-vente')
router.register(r'', VenteViewSet, basename='ventes')

urlpatterns = [
    path('', include(router.urls)),
]