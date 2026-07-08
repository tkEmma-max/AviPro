# ventes/models.py
from django.db import models
import uuid

class Vente(models.Model):
    """
    Vente / gain lié à un cycle de production
    """
    TYPE_CHOICES = [
        ('OEUFS', "Vente d'œufs"),
        ('POULETS', 'Vente de poulets'),
        ('POULE_REFORME', 'Vente de poules de réforme'),
        ('POUSSINS', 'Vente de poussins'),
        ('FIANTES', 'Vente de fientes'),
        ('AUTRE', 'Autre'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle = models.ForeignKey(
        'cycles.Cycle',
        on_delete=models.CASCADE,
        related_name='ventes'
    )
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    quantite = models.FloatField()
    prix_unitaire = models.DecimalField(max_digits=12, decimal_places=0)
    montant_total = models.DecimalField(max_digits=12, decimal_places=0, blank=True, null=True)
    date = models.DateField()
    description = models.TextField(blank=True, null=True)
    client = models.ForeignKey(
        'clients.Client',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='ventes'
    )
    facture_numero = models.CharField(max_length=100, blank=True, null=True)
    facture_photo = models.URLField(blank=True, null=True)
    signature = models.URLField(blank=True, null=True)
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='ventes_crees'
    )
    synced_at = models.DateTimeField(null=True, blank=True)

    # Prêt / remboursement
    remboursement_confirme = models.BooleanField(default=False)
    remboursement_cycle_id = models.UUIDField(null=True, blank=True)

    class Meta:
        db_table = 'ventes'
        verbose_name = 'Vente'
        verbose_name_plural = 'Ventes'
        ordering = ['-date']

    def save(self, *args, **kwargs):
        """Calcul automatique du montant total avant sauvegarde"""
        if not self.montant_total:
            self.montant_total = self.quantite * self.prix_unitaire
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.get_type_display()} - {self.montant_total} FCFA"

    @property
    def prix_de_revient(self):
        """Prix de revient par sujet (basé sur les dépenses du cycle)"""
        if self.cycle and self.cycle.nombre_sujets_actuels > 0:
            return self.cycle.total_depenses / self.cycle.nombre_sujets_actuels
        return 0

    @property
    def est_rentable(self):
        """Vérifie si la vente est rentable par rapport au prix de revient"""
        if self.prix_de_revient > 0:
            return self.prix_unitaire >= self.prix_de_revient
        return True

    @property
    def marge_unitaire(self):
        """Marge par unité vendue (prix vente - prix de revient)"""
        if self.prix_de_revient > 0:
            return self.prix_unitaire - self.prix_de_revient
        return self.prix_unitaire