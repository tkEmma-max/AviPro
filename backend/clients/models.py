# clients/models.py
from django.db import models
import uuid

class Client(models.Model):
    """
    Client / acheteur de produits avicoles
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=100)
    telephone = models.CharField(max_length=20, blank=True, null=True)
    adresse = models.TextField(blank=True, null=True)
    type_client = models.CharField(max_length=50, blank=True, null=True, help_text="Ex: Particulier, Grossiste, Restaurant, etc.")
    
    # Champs visionnaires
    metadata = models.JSONField(default=dict, blank=True)
    user = models.OneToOneField('users.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='client')
    total_achats = models.DecimalField(max_digits=12, decimal_places=0, default=0)
    derniere_visite = models.DateField(null=True, blank=True)
    
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='clients_crees'
    )

    class Meta:
        db_table = 'clients'
        verbose_name = 'Client'
        verbose_name_plural = 'Clients'
        ordering = ['nom']

    def __str__(self):
        return self.nom