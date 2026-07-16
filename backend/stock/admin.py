# stock/admin.py
from django.contrib import admin
from .models import ProduitStock, MouvementStock


@admin.register(ProduitStock)
class ProduitStockAdmin(admin.ModelAdmin):
    list_display = ('nom', 'type_produit', 'quantite', 'unite', 'seuil_alerte', 'est_sous_seuil')
    list_filter = ('type_produit', 'is_active')
    search_fields = ('nom',)
    readonly_fields = ('id', 'created_at', 'updated_at')


@admin.register(MouvementStock)
class MouvementStockAdmin(admin.ModelAdmin):
    list_display = ('produit', 'type_mouvement', 'quantite', 'date', 'cycle')
    list_filter = ('type_mouvement', 'date')
    search_fields = ('produit__nom', 'raison')
    readonly_fields = ('id', 'date')