# api/urls.py (version finale)
from django.urls import path, include
from rest_framework_simplejwt.views import TokenRefreshView
from .views import CustomTokenObtainPairView, RegisterView, SyncView, StatsView

urlpatterns = [
    # Authentification
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='token_obtain'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', RegisterView.as_view(), name='register'),

    # Synchronisation
    path('sync/', SyncView.as_view(), name='sync'),

    # Statistiques globales
    path('stats/', StatsView.as_view(), name='stats'),
]