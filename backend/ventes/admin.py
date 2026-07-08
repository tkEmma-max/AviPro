# ventes/admin.py
from django.contrib import admin
from .models import Vente


@admin.register(Vente)
class VenteAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les ventes
    """
    list_display = [
        'cycle', 'type', 'quantite', 'prix_unitaire',
        'montant_total', 'client', 'date'
    ]
    list_filter = ['type', 'date', 'created_at']
    search_fields = ['cycle__nom', 'client__nom', 'description']
    ordering = ['-date']

    readonly_fields = [
        'id', 'montant_total', 'prix_de_revient',
        'est_rentable', 'marge_unitaire', 'created_at', 'updated_at'
    ]

    fieldsets = (
        ('Informations générales', {
            'fields': ('cycle', 'type', 'date')
        }),
        ('Vente', {
            'fields': ('quantite', 'prix_unitaire', 'montant_total')
        }),
        ('Analyse', {
            'fields': ('prix_de_revient', 'est_rentable', 'marge_unitaire'),
            'classes': ('collapse',)
        }),
        ('Client / Facture', {
            'fields': ('client', 'facture_numero', 'facture_photo', 'signature')
        }),
        ('Métadonnées', {
            'fields': ('id', 'is_deleted', 'created_at', 'updated_at', 'synced_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    def get_queryset(self, request):
        """Exclut les ventes supprimées par défaut"""
        qs = super().get_queryset(request)
        return qs.filter(is_deleted=False)

    def est_rentable(self, obj):
        if obj.est_rentable:
            return "✅ Rentable"
        return "❌ Perte"

    est_rentable.short_description = "Rentabilité"
    est_rentable.boolean = True