# cycles/admin.py
from django.contrib import admin
from .models import Cycle, TypePoulet


@admin.register(TypePoulet)
class TypePouletAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les types de poulets
    """
    list_display = [
        'nom', 'duree_estimee_jours', 'densite_recommandee',
        'prix_poussin_moyen', 'is_active', 'created_at'
    ]
    list_filter = ['is_active']
    search_fields = ['nom']
    ordering = ['nom']

    readonly_fields = ['id', 'created_at', 'updated_at', 'created_by']

    fieldsets = (
        ('Informations générales', {
            'fields': ('nom', 'description')
        }),
        ('Paramètres par défaut', {
            'fields': ('duree_estimee_jours', 'densite_recommandee', 'prix_poussin_moyen')
        }),
        ('Statut', {
            'fields': ('is_active',)
        }),
        ('Métadonnées', {
            'fields': ('id', 'metadata', 'created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    actions = ['desactiver_types', 'activer_types']

    def desactiver_types(self, request, queryset):
        queryset.update(is_active=False)
        self.message_user(request, f"{queryset.count()} types désactivés.")
    desactiver_types.short_description = "Désactiver les types sélectionnés"

    def activer_types(self, request, queryset):
        queryset.update(is_active=True)
        self.message_user(request, f"{queryset.count()} types activés.")
    activer_types.short_description = "Activer les types sélectionnés"


@admin.register(Cycle)
class CycleAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les cycles
    """
    list_display = [
        'nom', 'poulailler', 'type_poulet', 'type', 'date_debut',
        'jours_ecoules', 'progression_display', 'nb_sujets_actuels_display',
        'taux_mortalite', 'benefice_display'
    ]
    list_filter = ['type_poulet', 'type', 'is_active', 'is_archived', 'date_debut']
    search_fields = ['nom', 'poulailler__nom', 'type_poulet__nom']
    ordering = ['-date_debut']

    readonly_fields = [
        'id', 'jours_ecoules', 'progression', 'mortalites',
        'taux_mortalite', 'total_depenses', 'total_ventes',
        'benefice', 'est_rentable', 'cout_production_unitaire',
        'created_at', 'updated_at'
    ]

    fieldsets = (
        ('Informations générales', {
            'fields': ('nom', 'poulailler', 'type', 'type_poulet')
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
        ('Marketplace', {
            'fields': ('est_publie_marketplace', 'metadata'),
            'classes': ('collapse',)
        }),
        ('Métadonnées', {
            'fields': ('id', 'created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    actions = ['archiver_cycles', 'activer_cycles']

    def archiver_cycles(self, request, queryset):
        queryset.update(is_archived=True, is_active=False)
        self.message_user(request, f"{queryset.count()} cycles archivés.")
    archiver_cycles.short_description = "Archiver les cycles sélectionnés"

    def activer_cycles(self, request, queryset):
        queryset.update(is_active=True, is_archived=False)
        self.message_user(request, f"{queryset.count()} cycles activés.")
    activer_cycles.short_description = "Activer les cycles sélectionnés"

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.filter(is_deleted=False)

    def nb_sujets_actuels_display(self, obj):
        return obj.nombre_sujets_actuels
    nb_sujets_actuels_display.short_description = "Sujets actuels"

    def benefice_display(self, obj):
        if obj.benefice > 0:
            return f"✅ {obj.benefice} FCFA"
        elif obj.benefice < 0:
            return f"❌ {obj.benefice} FCFA"
        return "⚖️ 0 FCFA"
    benefice_display.short_description = "Bénéfice"

    def progression_display(self, obj):
        return f"{obj.progression:.0f}%"
    progression_display.short_description = "Progression"