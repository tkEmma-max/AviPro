# rapports/models.py
from django.db import models
import uuid


class TypeMaladie(models.Model):
    """
    Type de maladie personnalisable (CRUDable par l'admin)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    symptomes = models.TextField(blank=True, null=True)
    traitement_recommande = models.TextField(blank=True, null=True)
    gravite = models.CharField(max_length=20, default='MOYEN', choices=[
        ('FAIBLE', 'Faible'),
        ('MOYEN', 'Moyen'),
        ('ELEVE', 'Élevé'),
        ('CRITIQUE', 'Critique'),
    ])
    is_active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='types_maladie_crees'
    )

    class Meta:
        db_table = 'types_maladie'
        verbose_name = 'Type de maladie'
        verbose_name_plural = 'Types de maladies'
        ordering = ['nom']

    def __str__(self):
        return self.nom


class RapportSuivi(models.Model):
    """
    Rapport technique périodique pour le suivi d'un cycle
    (Aliment, eau, santé)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle = models.ForeignKey(
        'cycles.Cycle',
        on_delete=models.CASCADE,
        related_name='rapports'
    )
    periode_debut = models.DateField()
    periode_fin = models.DateField()

    # Consommations
    aliment_consomme = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Quantité d'aliment consommée en kg"
    )
    eau_consommee = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0,
        help_text="Quantité d'eau consommée en litres"
    )

    # Santé
    maladie_observee = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="Maladie observée (ex: Coccidiose, Gumboro, etc.)"
    )
    type_maladie = models.ForeignKey(
        TypeMaladie, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='rapports', help_text="Type de maladie identifié"
    )
    medicaments_administres = models.TextField(
        blank=True,
        null=True,
        help_text="Médicaments administrés avec dosages"
    )
    nb_sujets_malades = models.IntegerField(default=0)
    observations = models.TextField(
        blank=True,
        null=True,
        help_text="Observations générales (comportement, conditions, etc.)"
    )
    
    # Ajouter ce champ
    sous_bande = models.ForeignKey(
        'cycles.SousBande',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='rapports'
    )

    # Champs visionnaires
    metadata = models.JSONField(default=dict, blank=True)
    mortalites_periode = models.IntegerField(default=0, help_text="Nombre de morts dans la période")

    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='rapports_crees'
    )
    synced_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'rapports_suivi'
        verbose_name = 'Rapport de suivi'
        verbose_name_plural = 'Rapports de suivi'
        ordering = ['-periode_fin']

    def __str__(self):
        return f"Rapport du {self.periode_debut} au {self.periode_fin}"

    @property
    def age_debut(self):
        """Âge des poulets au début du rapport (en jours)"""
        if self.cycle and self.cycle.date_debut:
            return (self.periode_debut - self.cycle.date_debut).days
        return 0

    @property
    def age_fin(self):
        """Âge des poulets à la fin du rapport (en jours)"""
        if self.cycle and self.cycle.date_debut:
            return (self.periode_fin - self.cycle.date_debut).days
        return 0

    @property
    def duree_jours(self):
        """Nombre de jours couverts par le rapport"""
        return (self.periode_fin - self.periode_debut).days

    @property
    def aliment_moyen_par_jour(self):
        """Consommation moyenne d'aliment par jour"""
        if self.duree_jours > 0:
            return self.aliment_consomme / self.duree_jours
        return 0

    @property
    def eau_moyen_par_jour(self):
        """Consommation moyenne d'eau par jour"""
        if self.duree_jours > 0:
            return self.eau_consommee / self.duree_jours
        return 0

    @property
    def aliment_par_sujet_par_jour(self):
        """Consommation d'aliment par sujet et par jour"""
        if self.duree_jours > 0 and self.cycle.nombre_sujets_actuels > 0:
            return self.aliment_consomme / (self.duree_jours * self.cycle.nombre_sujets_actuels)
        return 0

    @property
    def eau_par_sujet_par_jour(self):
        """Consommation d'eau par sujet et par jour"""
        if self.duree_jours > 0 and self.cycle.nombre_sujets_actuels > 0:
            return self.eau_consommee / (self.duree_jours * self.cycle.nombre_sujets_actuels)
        return 0

    @property
    def ratio_eau_aliment(self):
        """Ratio eau / aliment (indicateur de santé)"""
        if self.aliment_consomme > 0:
            return self.eau_consommee / self.aliment_consomme
        return 0

    @property
    def a_alerte(self):
        """Vérifie si le rapport déclenche une alerte"""
        if self.aliment_par_sujet_par_jour > 0:
            pass
        return False
        
    @property
    def nb_sujets_reference(self):
        """Nombre de sujets à utiliser pour les calculs"""
        if self.sous_bande:
            return self.sous_bande.nombre_sujets
        return self.cycle.nombre_sujets_actuels