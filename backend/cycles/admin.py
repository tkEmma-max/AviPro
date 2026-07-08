# cycles/admin.py
from django.contrib import admin
from .models import Cycle


@admin.register(Cycle)
class CycleAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les cycles
    """
    list_display = [
        'nom', 'poulailler', 'type', 'date_debut',
        'jours_ecoules', 'progression', 'nb_sujets_actuels',
        'taux_mortalite', 'benefice'
    ]
    list_filter = ['type', 'is_active', 'is_archived', 'date_debut']
    search_fields = ['nom', 'poulailler__nom']
    ordering = ['-date_debut']

    readonly_fields = [
        'id', 'jours_ecoules', 'progression', 'mortalites',
        'taux_mortalite', 'total_depenses', 'total_ventes',
        'benefice', 'est_rentable', 'cout_production_unitaire',
        'created_at', 'updated_at'
    ]

    fieldsets = (
        ('Informations générales', {
            'fields': ('nom', 'poulailler', 'type')
        }),
        ('Période', {
            'fields': ('date_debut', 'date_fin', 'duree_estimee_jours')
        }),
        ('Sujets', {
            'fields': ('nombre_sujets_initiaux', 'nombre_sujets_actuels')
        }),
        ('Statistiques', {
            'fields': (
                'jours_ecoules', 'progression', 'mortalites',
                'taux_mortalite', 'total_depenses', 'total_ventes',
                'benefice', 'est_rentable', 'cout_production_unitaire'
            )
        }),
        ('Statut', {
            'fields': ('is_active', 'is_archived', 'is_deleted')
        }),
        ('Métadonnées', {
            'fields': ('id', 'created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    actions = ['archiver_cycles', 'activer_cycles']

    def archiver_cycles(self, request, queryset):
        """Action : Archiver les cycles sélectionnés"""
        queryset.update(is_archived=True, is_active=False)
        self.message_user(request, f"{queryset.count()} cycles archivés.")

    archiver_cycles.short_description = "Archiver les cycles sélectionnés"

    def activer_cycles(self, request, queryset):
        """Action : Activer les cycles sélectionnés"""
        queryset.update(is_active=True, is_archived=False)
        self.message_user(request, f"{queryset.count()} cycles activés.")

    activer_cycles.short_description = "Activer les cycles sélectionnés"

    def get_queryset(self, request):
        """Exclut les cycles supprimés par défaut"""
        qs = super().get_queryset(request)
        return qs.filter(is_deleted=False)

    def nb_sujets_actuels(self, obj):
        return obj.nombre_sujets_actuels

    nb_sujets_actuels.short_description = "Sujets actuels"

    def benefice(self, obj):
        if obj.benefice > 0:
            return f"✅ {obj.benefice} FCFA"
        elif obj.benefice < 0:
            return f"❌ {obj.benefice} FCFA"
        return "⚖️ 0 FCFA"

    benefice.short_description = "Bénéfice"