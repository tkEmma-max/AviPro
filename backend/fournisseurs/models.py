# fournisseurs/models.py
from django.db import models
import uuid

class Fournisseur(models.Model):
    """
    Fournisseur de produits pour l'élevage
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=100)
    telephone = models.CharField(max_length=20, blank=True, null=True)
    adresse = models.TextField(blank=True, null=True)
    type_fournisseur = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Ex: Aliment, Poussins, Vaccins, etc."
    )
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='fournisseurs_crees'
    )

    class Meta:
        db_table = 'fournisseurs'
        verbose_name = 'Fournisseur'
        verbose_name_plural = 'Fournisseurs'
        ordering = ['nom']

    def __str__(self):
        return self.nom