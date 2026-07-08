# depenses/admin.py
from django.contrib import admin
from .models import Depense


@admin.register(Depense)
class DepenseAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les dépenses
    """
    list_display = [
        'cycle', 'categorie', 'montant', 'date',
        'fournisseur', 'created_at'
    ]
    list_filter = ['categorie', 'date', 'created_at']
    search_fields = ['cycle__nom', 'description', 'facture_numero']
    ordering = ['-date']

    readonly_fields = ['id', 'created_at', 'updated_at', 'synced_at']

    fieldsets = (
        ('Informations générales', {
            'fields': ('cycle', 'categorie', 'montant', 'date')
        }),
        ('Détails', {
            'fields': ('description', 'facture_numero', 'facture_photo')
        }),
        ('Fournisseur', {
            'fields': ('fournisseur',)
        }),
        ('Métadonnées', {
            'fields': ('id', 'is_deleted', 'created_at', 'updated_at', 'synced_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    def get_queryset(self, request):
        """Exclut les dépenses supprimées par défaut"""
        qs = super().get_queryset(request)
        return qs.filter(is_deleted=False)