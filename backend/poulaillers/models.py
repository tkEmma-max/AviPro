# poulaillers/models.py
from django.db import models
import uuid

class Poulailler(models.Model):
    """
    Infrastructure physique d'un poulailler
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=100)
    longueur = models.FloatField(help_text="Longueur en mètres")
    largeur = models.FloatField(help_text="Largeur en mètres")
    hauteur = models.FloatField(null=True, blank=True, help_text="Hauteur en mètres")
    localisation = models.CharField(max_length=200, blank=True, null=True)
    type_sol = models.CharField(max_length=50, blank=True, null=True)
    nombre_mangeoires = models.IntegerField(default=0)
    nombre_abreuvoirs = models.IntegerField(default=0)
    is_archived = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='poulaillers_crees'
    )

    class Meta:
        db_table = 'poulaillers'
        verbose_name = 'Poulailler'
        verbose_name_plural = 'Poulaillers'
        ordering = ['nom']

    def __str__(self):
        return self.nom

    @property
    def surface(self):
        """Calcule la surface en m²"""
        return self.longueur * self.largeur

    @property
    def statut(self):
        """
        Calcul automatique du statut :
        - LIBRE si pas de cycle actif ou nb poulets = 0
        - OCCUPÉ si cycle actif avec poulets > 0
        """
        cycle_actif = self.cycles.filter(is_active=True, is_archived=False).first()
        if cycle_actif and cycle_actif.nombre_sujets_actuels > 0:
            return "OCCUPÉ"
        return "LIBRE"

    @property
    def nb_poulets_actuels(self):
        """Récupère le nombre de poulets actuellement dans le poulailler"""
        cycle_actif = self.cycles.filter(is_active=True, is_archived=False).first()
        return cycle_actif.nombre_sujets_actuels if cycle_actif else 0

    @property
    def densite_actuelle(self):
        """Calcule la densité actuelle (poulets/m²)"""
        if self.surface > 0 and self.nb_poulets_actuels > 0:
            return self.nb_poulets_actuels / self.surface
        return 0