# depenses/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DepenseViewSet, CategorieDepenseViewSet, RoutineDepenseViewSet

router = DefaultRouter()
router.register(r'categories', CategorieDepenseViewSet, basename='categorie-depense')
router.register(r'routines', RoutineDepenseViewSet, basename='routine-depense')
router.register(r'', DepenseViewSet, basename='depenses')

urlpatterns = [
    path('', include(router.urls)),
]