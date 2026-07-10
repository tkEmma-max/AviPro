# users/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


@admin.register(User)
class UserAdmin(UserAdmin):
    """
    Interface d'administration pour le modèle User personnalisé
    """
    list_display = ['email', 'first_name', 'last_name', 'telephone', 'is_staff']

    list_filter = ['is_active', 'is_staff', 'is_superuser', 'date_joined']
    search_fields = ['username', 'email', 'telephone']
    ordering = ['-date_joined']

    fieldsets = (
        ('Informations de connexion', {
            'fields': ('username', 'email', 'password')
        }),
        ('Informations personnelles', {
            'fields': ('first_name', 'last_name', 'telephone', 'adresse')
        }),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')
        }),
        ('Dates', {
            'fields': ('last_login', 'date_joined'),
            'classes': ('collapse',)
        }),
    )

    add_fieldsets = (
        ('Création d\'un utilisateur', {
            'fields': ('username', 'email', 'telephone', 'password1', 'password2')
        }),
    )

    readonly_fields = ['id', 'date_joined', 'last_login']


from django.contrib import admin

# Register your models here.
