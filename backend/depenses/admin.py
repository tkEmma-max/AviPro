# depenses/admin.py
from django.contrib import admin
from .models import Depense, CategorieDepense, RoutineDepense, RoutineAppliquee


@admin.register(CategorieDepense)
class CategorieDepenseAdmin(admin.ModelAdmin):
    list_display = ('nom', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('nom',)
    readonly_fields = ('id', 'created_at', 'updated_at', 'created_by')
    actions = ['desactiver', 'activer']

    def desactiver(self, request, queryset):
        queryset.update(is_active=False)
        self.message_user(request, f"{queryset.count()} catégories désactivées.")
    desactiver.short_description = "Désactiver"

    def activer(self, request, queryset):
        queryset.update(is_active=True)
        self.message_user(request, f"{queryset.count()} catégories activées.")
    activer.short_description = "Activer"


@admin.register(RoutineDepense)
class RoutineDepenseAdmin(admin.ModelAdmin):
    list_display = ('nom', 'type_poulet', 'categorie_depense', 'age_jour', 'mode_calcul', 'is_active')
    list_filter = ('type_poulet', 'mode_calcul', 'is_active')
    search_fields = ('nom',)
    readonly_fields = ('id', 'created_at', 'updated_at', 'created_by')
    actions = ['desactiver', 'activer']

    def desactiver(self, request, queryset):
        queryset.update(is_active=False)
    desactiver.short_description = "Désactiver"

    def activer(self, request, queryset):
        queryset.update(is_active=True)
    activer.short_description = "Activer"


@admin.register(RoutineAppliquee)
class RoutineAppliqueeAdmin(admin.ModelAdmin):
    list_display = ('routine', 'cycle', 'montant_calcule', 'date_application')
    list_filter = ('date_application',)
    readonly_fields = ('id', 'date_application')


@admin.register(Depense)
class DepenseAdmin(admin.ModelAdmin):
    list_display = ('cycle', 'categorie_depense', 'montant', 'date', 'est_depense_routine')
    list_filter = ('categorie_depense', 'date', 'est_depense_routine')
    search_fields = ('cycle__nom', 'description')
    ordering = ('-date',)
    readonly_fields = ('id', 'created_at', 'updated_at')

    def get_queryset(self, request):
        return super().get_queryset(request).filter(is_deleted=False)