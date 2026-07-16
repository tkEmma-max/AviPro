# avipro/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('api.urls')),
    path('api/peupler/', include('api.urls_peupler')),  # Route spécifique

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
    path('api/', include('sync.urls')),  # TOUJOURS EN DERNIER
]