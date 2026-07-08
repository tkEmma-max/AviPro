# rapports/admin.py
from django.contrib import admin
from .models import RapportSuivi


@admin.register(RapportSuivi)
class RapportSuiviAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les rapports de suivi
    """
    list_display = [
        'cycle', 'periode_debut', 'periode_fin', 'duree_jours',
        'aliment_consomme', 'eau_consommee', 'maladie_observee'
    ]
    list_filter = ['periode_debut', 'created_at']
    search_fields = ['cycle__nom', 'maladie_observee', 'observations']
    ordering = ['-periode_fin']

    readonly_fields = [
        'id', 'duree_jours', 'aliment_moyen_par_jour',
        'eau_moyen_par_jour', 'aliment_par_sujet_par_jour',
        'eau_par_sujet_par_jour', 'ratio_eau_aliment',
        'created_at', 'updated_at'
    ]

    fieldsets = (
        ('Période', {
            'fields': ('cycle', 'periode_debut', 'periode_fin', 'duree_jours')
        }),
        ('Consommations', {
            'fields': (
                'aliment_consomme', 'aliment_moyen_par_jour',
                'aliment_par_sujet_par_jour'
            )
        }),
        ('Eau', {
            'fields': (
                'eau_consommee', 'eau_moyen_par_jour',
                'eau_par_sujet_par_jour', 'ratio_eau_aliment'
            )
        }),
        ('Santé', {
            'fields': ('maladie_observee', 'medicaments_administres', 'nb_sujets_malades')
        }),
        ('Observations', {
            'fields': ('observations',)
        }),
        ('Métadonnées', {
            'fields': ('id', 'is_deleted', 'created_at', 'updated_at', 'synced_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    def get_queryset(self, request):
        """Exclut les rapports supprimés par défaut"""
        qs = super().get_queryset(request)
        return qs.filter(is_deleted=False)