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
    
    # Champs visionnaires
    metadata = models.JSONField(default=dict, blank=True)
    capacite_max_recommandee = models.IntegerField(null=True, blank=True, help_text="Capacité max recommandée selon le type")
    date_construction = models.DateField(null=True, blank=True)
    cout_construction = models.DecimalField(max_digits=12, decimal_places=0, null=True, blank=True)
    
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
        return self.longueur * self.largeur

    @property
    def statut(self):
        # Vérifier si une sous-bande active est dans ce poulailler
        from cycles.models import SousBande
        sous_bande_active = SousBande.objects.filter(
            poulailler=self, est_active=True, nombre_sujets__gt=0
        ).first()
        if sous_bande_active:
            return "OCCUPÉ"
        return "LIBRE"

    @property
    def nb_poulets_actuels(self):
        from cycles.models import SousBande
        from django.db.models import Sum
        total = SousBande.objects.filter(
            poulailler=self, est_active=True
        ).aggregate(total=Sum('nombre_sujets'))['total']
        return total or 0

    @property
    def densite_actuelle(self):
        if self.surface > 0 and self.nb_poulets_actuels > 0:
            return self.nb_poulets_actuels / self.surface
        return 0