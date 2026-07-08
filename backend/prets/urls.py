# prets/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PretViewSet, EcheanceViewSet, RemboursementPretViewSet

router = DefaultRouter()
router.register(r'', PretViewSet, basename='prets')
router.register(r'echeances', EcheanceViewSet, basename='echeances')
router.register(r'remboursements', RemboursementPretViewSet, basename='remboursements')

urlpatterns = [
    path('', include(router.urls)),
]