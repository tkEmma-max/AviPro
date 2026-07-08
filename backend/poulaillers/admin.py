# poulaillers/admin.py
from django.contrib import admin
from .models import Poulailler


@admin.register(Poulailler)
class PoulaillerAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les poulaillers
    """
    list_display = [
        'nom', 'longueur', 'largeur', 'surface',
        'nb_poulets_actuels', 'statut', 'is_archived', 'created_at'
    ]
    list_filter = ['is_archived', 'is_deleted', 'created_at']  # <--- SUPPRIMER 'statut'
    search_fields = ['nom', 'localisation']
    ordering = ['nom']

    readonly_fields = [
        'id', 'surface', 'statut', 'nb_poulets_actuels',
        'created_at', 'updated_at'
    ]

    fieldsets = (
        ('Informations générales', {
            'fields': ('nom', 'localisation', 'type_sol')
        }),
        ('Dimensions', {
            'fields': ('longueur', 'largeur', 'hauteur', 'surface')
        }),
        ('Équipements', {
            'fields': ('nombre_mangeoires', 'nombre_abreuvoirs')
        }),
        ('Statut', {
            'fields': ('statut', 'nb_poulets_actuels', 'is_archived', 'is_deleted')
        }),
        ('Métadonnées', {
            'fields': ('id', 'created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    def get_queryset(self, request):
        """Exclut les poulaillers supprimés par défaut"""
        qs = super().get_queryset(request)
        return qs.filter(is_deleted=False)