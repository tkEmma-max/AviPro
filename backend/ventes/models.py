# ventes/models.py
from django.db import models
import uuid


class TypeVente(models.Model):
    """
    Type de vente personnalisable (CRUDable par l'admin)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='types_vente_crees'
    )

    class Meta:
        db_table = 'types_vente'
        verbose_name = 'Type de vente'
        verbose_name_plural = 'Types de ventes'
        ordering = ['nom']

    def __str__(self):
        return self.nom


class Vente(models.Model):
    """
    Vente / gain lié à un cycle de production
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle = models.ForeignKey(
        'cycles.Cycle', on_delete=models.CASCADE, related_name='ventes'
    )
    
    # Ancien champ type (gardé pour rétrocompatibilité)
    type = models.CharField(max_length=20, blank=True, null=True)
    
    # Nouveau champ lié à TypeVente
    type_vente = models.ForeignKey(
        TypeVente, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='ventes', help_text="Type de vente personnalisé"
    )
    
    quantite = models.FloatField()
    prix_unitaire = models.FloatField()
    montant_total = models.DecimalField(max_digits=12, decimal_places=0, blank=True, null=True)
    date = models.DateField()
    description = models.TextField(blank=True, null=True)
    client = models.ForeignKey(
        'clients.Client', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='ventes'
    )
    facture_numero = models.CharField(max_length=100, blank=True, null=True)
    facture_photo = models.URLField(blank=True, null=True)
    signature = models.URLField(blank=True, null=True)
    is_deleted = models.BooleanField(default=False)
    
    # Prêt / remboursement
    remboursement_confirme = models.BooleanField(default=False)
    remboursement_cycle_id = models.UUIDField(null=True, blank=True)
    
    # Champs visionnaires
    metadata = models.JSONField(default=dict, blank=True)
    vendeur = models.CharField(max_length=100, blank=True, null=True, help_text="Nom du vendeur (si différent du propriétaire)")
    
    # Lien futur vers une annonce marketplace
    annonce_id = models.UUIDField(null=True, blank=True, help_text="ID de l'annonce marketplace liée")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='ventes_crees'
    )
    synced_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'ventes'
        verbose_name = 'Vente'
        verbose_name_plural = 'Ventes'
        ordering = ['-date']

    def save(self, *args, **kwargs):
        self.montant_total = self.quantite * float(self.prix_unitaire)
        super().save(*args, **kwargs)

    def __str__(self):
        type_label = self.type_vente.nom if self.type_vente else self.type
        return f"{type_label or 'Vente'} - {self.montant_total} FCFA"

    @property
    def prix_de_revient(self):
        if self.cycle and self.cycle.nombre_sujets_actuels > 0:
            return self.cycle.total_depenses / self.cycle.nombre_sujets_actuels
        return 0

    @property
    def est_rentable(self):
        if self.prix_de_revient > 0:
            return self.prix_unitaire >= self.prix_de_revient
        return True

    @property
    def marge_unitaire(self):
        if self.prix_de_revient > 0:
            return self.prix_unitaire - self.prix_de_revient
        return self.prix_unitaire