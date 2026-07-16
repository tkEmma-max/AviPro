# stock/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ProduitStockViewSet, MouvementStockViewSet

router = DefaultRouter()
router.register(r'produits', ProduitStockViewSet, basename='produits-stock')
router.register(r'mouvements', MouvementStockViewSet, basename='mouvements-stock')

urlpatterns = [
    path('', include(router.urls)),
]