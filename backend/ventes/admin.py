# ventes/admin.py
from django.contrib import admin
from .models import Vente, TypeVente


@admin.register(TypeVente)
class TypeVenteAdmin(admin.ModelAdmin):
    list_display = ('nom', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('nom',)
    ordering = ('nom',)
    readonly_fields = ('id', 'created_at', 'updated_at', 'created_by')

    fieldsets = (
        ('Informations', {'fields': ('nom', 'description')}),
        ('Statut', {'fields': ('is_active',)}),
        ('Métadonnées', {'fields': ('id', 'metadata', 'created_at', 'updated_at', 'created_by'), 'classes': ('collapse',)}),
    )

    actions = ['desactiver', 'activer']

    def desactiver(self, request, queryset):
        queryset.update(is_active=False)
        self.message_user(request, f"{queryset.count()} types désactivés.")
    desactiver.short_description = "Désactiver"

    def activer(self, request, queryset):
        queryset.update(is_active=True)
        self.message_user(request, f"{queryset.count()} types activés.")
    activer.short_description = "Activer"


@admin.register(Vente)
class VenteAdmin(admin.ModelAdmin):
    list_display = ['cycle', 'type_vente', 'type', 'quantite', 'prix_unitaire', 'montant_total', 'client', 'date', 'rentable_display']
    list_filter = ['type_vente', 'type', 'date', 'created_at']
    search_fields = ['cycle__nom', 'client__nom', 'description', 'vendeur']
    ordering = ['-date']

    readonly_fields = ['id', 'montant_total', 'prix_de_revient', 'est_rentable', 'marge_unitaire', 'created_at', 'updated_at']

    fieldsets = (
        ('Informations générales', {'fields': ('cycle', 'type', 'type_vente', 'date')}),
        ('Vente', {'fields': ('quantite', 'prix_unitaire', 'montant_total')}),
        ('Analyse', {'fields': ('prix_de_revient', 'est_rentable', 'marge_unitaire'), 'classes': ('collapse',)}),
        ('Client / Facture', {'fields': ('client', 'facture_numero', 'facture_photo', 'signature')}),
        ('Vendeur', {'fields': ('vendeur',)}),
        ('Prêt', {'fields': ('remboursement_confirme', 'remboursement_cycle_id')}),
        ('Métadonnées', {'fields': ('id', 'metadata', 'annonce_id', 'is_deleted', 'created_at', 'updated_at', 'synced_at', 'created_by'), 'classes': ('collapse',)}),
    )

    def get_queryset(self, request):
        return super().get_queryset(request).filter(is_deleted=False)

    def rentable_display(self, obj):
        return "✅" if obj.est_rentable else "❌"
    rentable_display.short_description = "Rentable"