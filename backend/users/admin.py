# users/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, ParametreUtilisateur


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'first_name', 'last_name', 'is_staff', 'is_active')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Informations personnelles', {'fields': ('first_name', 'last_name', 'telephone')}),
        ('Mobile Money', {'fields': ('mobile_money_provider', 'mobile_money_number')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser')}),
        ('Métadonnées', {'fields': ('metadata',), 'classes': ('collapse',)}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'first_name', 'password1', 'password2'),
        }),
    )


@admin.register(ParametreUtilisateur)
class ParametreUtilisateurAdmin(admin.ModelAdmin):
    list_display = ('user', 'frequence_rappel_rapport', 'rappel_rapport_actif', 'devise')
    search_fields = ('user__email',)
    readonly_fields = ('created_at', 'updated_at')