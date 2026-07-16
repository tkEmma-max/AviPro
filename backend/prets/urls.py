# prets/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PretViewSet, EcheanceViewSet, RemboursementPretViewSet

# Router séparé pour les remboursements (avant le routeur principal)
router_remboursements = DefaultRouter()
router_remboursements.register(r'', RemboursementPretViewSet, basename='remboursements')

# Router pour les échéances
router_echeances = DefaultRouter()
router_echeances.register(r'', EcheanceViewSet, basename='echeances')

# Router principal pour les prêts
router = DefaultRouter()
router.register(r'', PretViewSet, basename='prets')

urlpatterns = [
    path('remboursements/', include(router_remboursements.urls)),
    path('echeances/', include(router_echeances.urls)),
    path('', include(router.urls)),
]