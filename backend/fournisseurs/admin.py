# fournisseurs/admin.py
from django.contrib import admin
from .models import Fournisseur


@admin.register(Fournisseur)
class FournisseurAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les fournisseurs
    """
    list_display = ['nom', 'telephone', 'type_fournisseur', 'created_at']
    list_filter = ['type_fournisseur', 'created_at']
    search_fields = ['nom', 'telephone', 'adresse']
    ordering = ['nom']

    readonly_fields = ['id', 'created_at', 'updated_at']

    fieldsets = (
        ('Informations générales', {
            'fields': ('nom', 'telephone', 'adresse', 'type_fournisseur')
        }),
        ('Métadonnées', {
            'fields': ('id', 'is_deleted', 'created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    def get_queryset(self, request):
        """Exclut les fournisseurs supprimés par défaut"""
        qs = super().get_queryset(request)
        return qs.filter(is_deleted=False)