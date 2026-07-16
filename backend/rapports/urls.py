# rapports/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RapportSuiviViewSet, TypeMaladieViewSet

router = DefaultRouter()
router.register(r'types-maladie', TypeMaladieViewSet, basename='type-maladie')
router.register(r'', RapportSuiviViewSet, basename='rapports')

urlpatterns = [
    path('', include(router.urls)),
]