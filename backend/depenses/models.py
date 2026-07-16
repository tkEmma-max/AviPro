# depenses/models.py
from django.db import models
import uuid


class CategorieDepense(models.Model):
    """
    Catégorie de dépense personnalisable (CRUDable par l'admin)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True, null=True)
    icone = models.CharField(max_length=50, blank=True, null=True, help_text="Nom de l'icône Flutter")
    couleur = models.CharField(max_length=7, blank=True, null=True, help_text="Code couleur hex (#FF0000)")
    is_active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='categories_depense_crees'
    )

    class Meta:
        db_table = 'categories_depense'
        verbose_name = 'Catégorie de dépense'
        verbose_name_plural = 'Catégories de dépenses'
        ordering = ['nom']

    def __str__(self):
        return self.nom


class RoutineDepense(models.Model):
    """
    Dépense de routine : modèle de dépense récurrente liée à un type de poulet et un âge
    """
    MODE_CHOICES = [
        ('PAR_SUJET', 'Par sujet'),
        ('PAR_TRANCHE', 'Par tranche (ex: 1 sac pour X poulets)'),
        ('FIXE', 'Montant fixe'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type_poulet = models.ForeignKey(
        'cycles.TypePoulet', on_delete=models.CASCADE, related_name='routines_depense'
    )
    categorie_depense = models.ForeignKey(
        CategorieDepense, on_delete=models.CASCADE, related_name='routines'
    )
    nom = models.CharField(max_length=100, help_text="Ex: Achat poussins, Vaccin J21, Aliment démarrage")
    age_jour = models.IntegerField(default=0, help_text="Âge du cycle auquel appliquer cette routine")
    
    # Mode de calcul
    mode_calcul = models.CharField(max_length=20, choices=MODE_CHOICES, default='PAR_SUJET')
    montant_par_sujet = models.DecimalField(max_digits=10, decimal_places=0, default=0, help_text="Montant par sujet si mode PAR_SUJET")
    seuil_tranche = models.IntegerField(default=50, help_text="Nombre de poulets par tranche (ex: 1 sac pour 50 poulets)")
    montant_par_tranche = models.DecimalField(max_digits=10, decimal_places=0, default=0, help_text="Montant par tranche si mode PAR_TRANCHE")
    montant_fixe = models.DecimalField(max_digits=10, decimal_places=0, default=0, help_text="Montant fixe si mode FIXE")
    
    est_obligatoire = models.BooleanField(default=False, help_text="Si vrai, appliqué automatiquement sans confirmation")
    is_active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='routines_depense_crees'
    )

    class Meta:
        db_table = 'routines_depense'
        verbose_name = 'Routine de dépense'
        verbose_name_plural = 'Routines de dépenses'
        ordering = ['type_poulet', 'age_jour']

    def __str__(self):
        return f"{self.nom} - {self.type_poulet.nom} (J{self.age_jour})"

    def calculer_montant(self, nb_poulets):
        """Calcule le montant en fonction du mode et du nombre de poulets"""
        if self.mode_calcul == 'PAR_SUJET':
            return nb_poulets * self.montant_par_sujet
        elif self.mode_calcul == 'PAR_TRANCHE':
            nb_tranches = (nb_poulets + self.seuil_tranche - 1) // self.seuil_tranche
            return nb_tranches * self.montant_par_tranche
        else:  # FIXE
            return self.montant_fixe


class RoutineAppliquee(models.Model):
    """
    Trace qu'une routine a été appliquée à un cycle
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    routine = models.ForeignKey(
        RoutineDepense, on_delete=models.CASCADE, related_name='applications'
    )
    cycle = models.ForeignKey(
        'cycles.Cycle', on_delete=models.CASCADE, related_name='routines_appliquees'
    )
    depense_generee = models.ForeignKey(
        'Depense', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='routine_source'
    )
    montant_calcule = models.DecimalField(max_digits=10, decimal_places=0)
    nb_poulets_au_moment = models.IntegerField()
    date_application = models.DateTimeField(auto_now_add=True)
    confirmee_par = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True
    )

    class Meta:
        db_table = 'routines_appliquees'
        verbose_name = 'Routine appliquée'
        verbose_name_plural = 'Routines appliquées'
        ordering = ['-date_application']
        unique_together = ['routine', 'cycle']  # Une routine ne peut être appliquée qu'une fois par cycle

    def __str__(self):
        return f"{self.routine.nom} → {self.cycle.nom}"


class Depense(models.Model):
    """
    Dépense liée à un cycle de production
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle = models.ForeignKey(
        'cycles.Cycle', on_delete=models.CASCADE, related_name='depenses'
    )
    categorie = models.CharField(max_length=20, blank=True, null=True)
    categorie_depense = models.ForeignKey(
        CategorieDepense, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='depenses', help_text="Catégorie personnalisée"
    )
    montant = models.DecimalField(max_digits=12, decimal_places=0)
    date = models.DateField()
    description = models.TextField(blank=True, null=True)
    facture_numero = models.CharField(max_length=100, blank=True, null=True)
    facture_photo = models.URLField(blank=True, null=True)
    fournisseur = models.ForeignKey(
        'fournisseurs.Fournisseur', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='depenses'
    )
    is_deleted = models.BooleanField(default=False)
    metadata = models.JSONField(default=dict, blank=True)
    est_depense_routine = models.BooleanField(default=False, help_text="Dépense générée automatiquement")
    routine_id = models.UUIDField(null=True, blank=True, help_text="ID de la routine parente")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='depenses_crees'
    )
    synced_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'depenses'
        verbose_name = 'Dépense'
        verbose_name_plural = 'Dépenses'
        ordering = ['-date']

    def __str__(self):
        label = self.categorie_depense.nom if self.categorie_depense else self.categorie
        return f"{label or 'Dépense'} - {self.montant} FCFA"