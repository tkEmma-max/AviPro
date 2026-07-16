# avipro/urls.py
from django.contrib import admin
from django.urls import path, include
from api.views import PeuplerDBView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('api.urls')),

    # Peuplement (endpoint temporaire)
    path('api/peupler/', PeuplerDBView.as_view(), name='peupler-db'),

    # Routes des apps
    path('api/users/', include('users.urls')),
    path('api/poulaillers/', include('poulaillers.urls')),
    path('api/cycles/', include('cycles.urls')),
    path('api/depenses/', include('depenses.urls')),
    path('api/ventes/', include('ventes.urls')),
    path('api/clients/', include('clients.urls')),
    path('api/fournisseurs/', include('fournisseurs.urls')),
    path('api/prets/', include('prets.urls')),
    path('api/rapports/', include('rapports.urls')),
    path('api/stock/', include('stock.urls')),
    path('api/', include('sync.urls')),
]