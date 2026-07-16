# rapports/admin.py
from django.contrib import admin
from .models import RapportSuivi, TypeMaladie


@admin.register(TypeMaladie)
class TypeMaladieAdmin(admin.ModelAdmin):
    list_display = ('nom', 'gravite', 'is_active')
    list_filter = ('gravite', 'is_active')
    search_fields = ('nom', 'symptomes')
    readonly_fields = ('id', 'created_at', 'updated_at', 'created_by')


@admin.register(RapportSuivi)
class RapportSuiviAdmin(admin.ModelAdmin):
    list_display = ('cycle', 'periode_debut', 'periode_fin', 'aliment_consomme', 'eau_consommee', 'maladie_observee')
    list_filter = ('type_maladie', 'periode_fin')
    search_fields = ('cycle__nom', 'observations')
    ordering = ('-periode_fin',)
    readonly_fields = ('id', 'duree_jours', 'created_at', 'updated_at')

    def get_queryset(self, request):
        return super().get_queryset(request).filter(is_deleted=False)