# cycles/models.py
from django.db import models
from django.utils import timezone
import uuid

class Cycle(models.Model):
    """
    Cycle de production d'une bande de poulets
    """
    TYPE_CHOICES = [
        ('CHAIR', 'Poulet de chair'),
        ('PONDEUSE', 'Poule pondeuse'),
        ('LOCAL', 'Poulet local'),
        ('AUTRE', 'Autre'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    poulailler = models.ForeignKey(
        'poulaillers.Poulailler',
        on_delete=models.CASCADE,
        related_name='cycles'
    )
    nom = models.CharField(max_length=100)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='CHAIR')
    date_debut = models.DateField()
    date_fin = models.DateField(null=True, blank=True)
    nombre_sujets_initiaux = models.IntegerField()
    nombre_sujets_actuels = models.IntegerField()
    duree_estimee_jours = models.IntegerField(help_text="Durée estimée du cycle en jours")
    is_active = models.BooleanField(default=True)
    is_archived = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='cycles_crees'
    )

    class Meta:
        db_table = 'cycles'
        verbose_name = 'Cycle'
        verbose_name_plural = 'Cycles'
        ordering = ['-date_debut']

    def __str__(self):
        return f"{self.nom} - {self.poulailler.nom}"

    @property
    def jours_ecoules(self):
        """Nombre de jours écoulés depuis le début du cycle"""
        if self.date_debut:
            return (timezone.now().date() - self.date_debut).days
        return 0

    @property
    def progression(self):
        """Pourcentage de progression du cycle"""
        if self.duree_estimee_jours > 0:
            progression = (self.jours_ecoules / self.duree_estimee_jours) * 100
            return min(progression, 100)  # Ne pas dépasser 100%
        return 0

    @property
    def mortalites(self):
        """Nombre de mortalités depuis le début"""
        return self.nombre_sujets_initiaux - self.nombre_sujets_actuels

    @property
    def taux_mortalite(self):
        """Taux de mortalité en pourcentage"""
        if self.nombre_sujets_initiaux > 0:
            return (self.mortalites / self.nombre_sujets_initiaux) * 100
        return 0

    @property
    def total_depenses(self):
        """Total des dépenses du cycle"""
        return sum(d.montant for d in self.depenses.filter(is_deleted=False))

    @property
    def total_ventes(self):
        """Total des ventes du cycle"""
        return sum(v.montant_total for v in self.ventes.filter(is_deleted=False))

    @property
    def benefice(self):
        """Bénéfice net du cycle (ventes - dépenses)"""
        return self.total_ventes - self.total_depenses

    @property
    def est_rentable(self):
        """Vérifie si le cycle est rentable"""
        return self.benefice > 0

    @property
    def cout_production_unitaire(self):
        """Coût de production par sujet vivant"""
        if self.nombre_sujets_actuels > 0:
            return self.total_depenses / self.nombre_sujets_actuels
        return 0

    @property
    def prix_vente_moyen(self):
        """Prix de vente moyen par sujet"""
        if self.total_ventes > 0 and self.nombre_sujets_actuels > 0:
            return self.total_ventes / self.nombre_sujets_actuels
        return 0