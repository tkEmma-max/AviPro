# prets/admin.py
from django.contrib import admin
from .models import Pret, Echeance, RemboursementPret


class EcheanceInline(admin.TabularInline):
    """Affiche les échéances dans la page du prêt"""
    model = Echeance
    extra = 0
    fields = ['date_echeance', 'montant_due', 'est_payee', 'date_paiement']
    readonly_fields = ['created_at']
    ordering = ['date_echeance']


class RemboursementInline(admin.TabularInline):
    """Affiche les remboursements dans la page du prêt"""
    model = RemboursementPret
    extra = 0
    fields = ['montant', 'date', 'source', 'echeance']
    readonly_fields = ['created_at']


@admin.register(Pret)
class PretAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les prêts
    """
    list_display = [
        'preteur', 'type_preteur', 'montant_total',
        'montant_restant', 'is_rembourse', 'est_en_retard', 'created_at'
    ]
    list_filter = ['type_preteur', 'mode_remboursement', 'is_rembourse', 'created_at']
    search_fields = ['preteur']
    ordering = ['-created_at']

    inlines = [EcheanceInline, RemboursementInline]

    readonly_fields = [
        'id', 'montant_restant', 'total_rembourse',
        'prochaine_echeance', 'est_en_retard', 'created_at', 'updated_at'
    ]

    fieldsets = (
        ('Informations générales', {
            'fields': ('preteur', 'type_preteur', 'montant_total', 'date_deblocage')
        }),
        ('Remboursement', {
            'fields': ('mode_remboursement', 'duree_totale_mois', 'periodicite')
        }),
        ('Intérêts', {
            'fields': ('taux_interet',)
        }),
        ('Suivi', {
            'fields': ('montant_restant', 'total_rembourse', 'prochaine_echeance', 'est_en_retard', 'is_rembourse')
        }),
        ('Cycles affectés', {
            'fields': ('cycles_affectes',)
        }),
        ('Métadonnées', {
            'fields': ('id', 'metadata', 'is_deleted', 'created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )

    actions = ['marquer_rembourse']

    def marquer_rembourse(self, request, queryset):
        """Action : Marquer les prêts comme remboursés"""
        queryset.update(is_rembourse=True, montant_restant=0)
        self.message_user(request, f"{queryset.count()} prêts marqués comme remboursés.")

    marquer_rembourse.short_description = "Marquer comme remboursé"


@admin.register(Echeance)
class EcheanceAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les échéances
    """
    list_display = ['pret', 'date_echeance', 'montant_due', 'est_payee', 'est_en_retard']
    list_filter = ['est_payee', 'date_echeance']
    search_fields = ['pret__preteur']
    ordering = ['date_echeance']
    readonly_fields = ['id', 'created_at']


@admin.register(RemboursementPret)
class RemboursementPretAdmin(admin.ModelAdmin):
    """
    Interface d'administration pour les remboursements
    """
    list_display = ['pret', 'montant', 'date', 'source', 'echeance']
    list_filter = ['date', 'source']
    search_fields = ['pret__preteur', 'description']
    ordering = ['-date']
    readonly_fields = ['id', 'created_at']