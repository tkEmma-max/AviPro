# cycles/models.py
from django.db import models
from django.utils import timezone
import uuid


class TypePoulet(models.Model):
    """
    Type de poulet personnalisable (CRUDable)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True, null=True)
    duree_estimee_jours = models.IntegerField(default=45, help_text="Durée standard du cycle pour ce type")
    densite_recommandee = models.FloatField(default=8.0, help_text="Densité recommandée en poulets/m²")
    prix_poussin_moyen = models.DecimalField(max_digits=10, decimal_places=0, default=0, help_text="Prix moyen d'un poussin")
    is_active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    nb_mangeoires = models.IntegerField(default=0, help_text="Nombre de mangeoires utilisées pour ce cycle")
    nb_abreuvoirs = models.IntegerField(default=0, help_text="Nombre d'abreuvoirs utilisés pour ce cycle")
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='types_poulet_crees'
    )

    class Meta:
        db_table = 'types_poulet'
        verbose_name = 'Type de poulet'
        verbose_name_plural = 'Types de poulets'
        ordering = ['nom']

    def __str__(self):
        return self.nom


class Cycle(models.Model):
    """
    Cycle de production d'une bande de poulets
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    poulailler = models.ForeignKey(
        'poulaillers.Poulailler', on_delete=models.CASCADE, related_name='cycles'
    )
    nom = models.CharField(max_length=100)
    
    # Ancien champ (gardé pour rétrocompatibilité)
    type = models.CharField(max_length=20, blank=True, null=True)
    
    # Nouveau champ lié à TypePoulet
    type_poulet = models.ForeignKey(
        TypePoulet, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='cycles', help_text="Type de poulet personnalisé"
    )
    
    date_debut = models.DateField()
    date_fin = models.DateField(null=True, blank=True)
    nombre_sujets_initiaux = models.IntegerField()
    nombre_sujets_actuels = models.IntegerField()
    duree_estimee_jours = models.IntegerField(help_text="Durée estimée du cycle en jours")
    is_active = models.BooleanField(default=True)
    is_archived = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    
    # Champs visionnaires
    metadata = models.JSONField(default=dict, blank=True)
    est_publie_marketplace = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='cycles_crees'
    )
    nb_morts = models.IntegerField(default=0, help_text="Nombre de sujets morts (maladie, accident)")

    class Meta:
        db_table = 'cycles'
        verbose_name = 'Cycle'
        verbose_name_plural = 'Cycles'
        ordering = ['-date_debut']

    def __str__(self):
        return f"{self.nom} - {self.poulailler.nom}"

    @property
    def jours_ecoules(self):
        if self.date_debut:
            return (timezone.now().date() - self.date_debut).days
        return 0

    @property
    def progression(self):
        if self.duree_estimee_jours > 0:
            progression = (self.jours_ecoules / self.duree_estimee_jours) * 100
            return min(progression, 100)
        return 0

    @property
    def mortalites(self):
        return self.nb_morts
    @property
    def taux_mortalite(self):
        if self.nombre_sujets_initiaux > 0:
            return (self.nb_morts / self.nombre_sujets_initiaux) * 100
        return 0

    @property
    def total_depenses(self):
        return sum(d.montant for d in self.depenses.filter(is_deleted=False))

    @property
    def total_ventes(self):
        return sum(v.montant_total for v in self.ventes.filter(is_deleted=False))

    @property
    def benefice(self):
        return self.total_ventes - self.total_depenses

    @property
    def est_rentable(self):
        return self.benefice > 0

    @property
    def cout_production_unitaire(self):
        if self.nombre_sujets_actuels > 0:
            return self.total_depenses / self.nombre_sujets_actuels
        return 0

    @property
    def prix_vente_moyen(self):
        if self.total_ventes > 0 and self.nombre_sujets_actuels > 0:
            return self.total_ventes / self.nombre_sujets_actuels
        return 0

    @property
    def nombre_sujets_actuels(self):
        """Nombre total de sujets actifs (somme des sous-bandes actives)"""
        total = self.sous_bandes.filter(est_active=True).aggregate(
            total=models.Sum('nombre_sujets')
        )['total']
        return total or 0

class SousBande(models.Model):
    """
    Une partie d'un cycle, localisée dans un poulailler spécifique.
    Permet de diviser un cycle en plusieurs lots dans différents poulaillers.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle = models.ForeignKey(
        Cycle, on_delete=models.CASCADE, related_name='sous_bandes'
    )
    poulailler = models.ForeignKey(
        'poulaillers.Poulailler', on_delete=models.CASCADE, related_name='sous_bandes'
    )
    nombre_sujets = models.IntegerField()
    est_active = models.BooleanField(default=True)
    date_creation = models.DateTimeField(auto_now_add=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = 'sous_bandes'
        verbose_name = 'Sous-bande'
        verbose_name_plural = 'Sous-bandes'
        ordering = ['date_creation']

    def __str__(self):
        return f"Sous-bande {self.poulailler.nom} - {self.nombre_sujets} sujets"


class Migration(models.Model):
    """
    Trace un déplacement de poulets entre deux poulaillers.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle = models.ForeignKey(
        Cycle, on_delete=models.CASCADE, related_name='migrations'
    )
    poulailler_source = models.ForeignKey(
        'poulaillers.Poulailler', on_delete=models.CASCADE, related_name='migrations_sortantes'
    )
    poulailler_cible = models.ForeignKey(
        'poulaillers.Poulailler', on_delete=models.CASCADE, related_name='migrations_entrantes'
    )
    nombre_sujets = models.IntegerField()
    age_sujets = models.IntegerField(help_text="Âge des poulets au moment de la migration")
    raison = models.TextField(blank=True, null=True)
    date = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='migrations_crees'
    )

    class Meta:
        db_table = 'migrations'
        verbose_name = 'Migration'
        verbose_name_plural = 'Migrations'
        ordering = ['-date']

    def __str__(self):
        return f"Migration {self.poulailler_source.nom} → {self.poulailler_cible.nom} ({self.nombre_sujets} sujets)"