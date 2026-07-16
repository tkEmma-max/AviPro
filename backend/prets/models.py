# prets/models.py
from django.db import models
import uuid

class Pret(models.Model):
    """
    Prêt contracté pour financer l'élevage
    """
    TYPE_PRETEUR_CHOICES = [
        ('BANQUE', 'Banque'),
        ('MICROFINANCE', 'Microfinance'),
        ('FAMILLE', 'Famille'),
        ('TONTINE', 'Tontine'),
        ('AUTRE', 'Autre'),
    ]

    MODE_CHOICES = [
        ('IMPOSE', 'Échéances imposées'),
        ('PROPOSE', 'Échéances proposées'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    preteur = models.CharField(max_length=100)
    type_preteur = models.CharField(max_length=20, choices=TYPE_PRETEUR_CHOICES)
    montant_total = models.DecimalField(max_digits=12, decimal_places=0)
    date_deblocage = models.DateField()
    taux_interet = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    mode_remboursement = models.CharField(max_length=20, choices=MODE_CHOICES)
    duree_totale_mois = models.IntegerField(null=True, blank=True)
    periodicite = models.CharField(max_length=20, blank=True, null=True)
    montant_restant = models.DecimalField(max_digits=12, decimal_places=0)
    is_rembourse = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    cycles_affectes = models.ManyToManyField(
        'cycles.Cycle',
        related_name='prets',
        blank=True
    )

    # Type de taux d'intérêt
    type_taux = models.CharField(
        max_length=10, default='MENSUEL',
        choices=[('MENSUEL', 'Mensuel'), ('ANNUEL', 'Annuel')]
    )

    # Date limite de remboursement
    date_limite = models.DateField(null=True, blank=True)

    # Champs visionnaires
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='prets_crees'
    )

    class Meta:
        db_table = 'prets'
        verbose_name = 'Prêt'
        verbose_name_plural = 'Prêts'
        ordering = ['-created_at']

    def __str__(self):
        return f"Prêt {self.preteur} - {self.montant_total} FCFA"

    @property
    def total_rembourse(self):
        """Total des remboursements effectués"""
        return sum(r.montant for r in self.remboursements.all())

    @property
    def montant_restant_calcule(self):
        """Montant restant calculé automatiquement"""
        return self.montant_total - self.total_rembourse

    @property
    def prochaine_echeance(self):
        """Prochaine échéance non payée"""
        echeance = self.echeances.filter(est_payee=False).order_by('date_echeance').first()
        return echeance

    @property
    def est_en_retard(self):
        """Vérifie si le prêt a des échéances en retard"""
        if self.is_rembourse:
            return False
        echeance = self.prochaine_echeance
        if echeance:
            from django.utils import timezone
            return echeance.date_echeance < timezone.now().date()
        return False


class Echeance(models.Model):
    """
    Échéance d'un prêt
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    pret = models.ForeignKey(
        'prets.Pret',
        on_delete=models.CASCADE,
        related_name='echeances'
    )
    date_echeance = models.DateField()
    montant_due = models.DecimalField(max_digits=12, decimal_places=0)
    est_payee = models.BooleanField(default=False)
    date_paiement = models.DateField(null=True, blank=True)
    # Lien futur vers transaction mobile
    transaction_mobile_id = models.UUIDField(null=True, blank=True, help_text="ID de la transaction mobile associée")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'echeances'
        verbose_name = 'Échéance'
        verbose_name_plural = 'Échéances'
        ordering = ['date_echeance']

    def __str__(self):
        return f"Échéance {self.pret.preteur} - {self.date_echeance}"

    @property
    def est_en_retard(self):
        """Vérifie si l'échéance est en retard"""
        if self.est_payee:
            return False
        from django.utils import timezone
        return self.date_echeance < timezone.now().date()


class RemboursementPret(models.Model):
    """
    Remboursement d'un prêt
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    pret = models.ForeignKey(
        'prets.Pret',
        on_delete=models.CASCADE,
        related_name='remboursements'
    )
    montant = models.DecimalField(max_digits=12, decimal_places=0)
    date = models.DateField()
    source = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Source du remboursement: vente_cycle, manuel, etc."
    )
    cycle_source = models.ForeignKey(
        'cycles.Cycle',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='remboursements_prets'
    )
    vente_source = models.ForeignKey(
        'ventes.Vente',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='remboursements_prets'
    )
    echeance = models.ForeignKey(
        'prets.Echeance',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='remboursements'
    )
    description = models.TextField(blank=True, null=True)
    is_manually_confirmed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='remboursements_crees'
    )

    class Meta:
        db_table = 'remboursements'
        verbose_name = 'Remboursement'
        verbose_name_plural = 'Remboursements'
        ordering = ['-date']

    def __str__(self):
        return f"Remboursement {self.pret.preteur} - {self.montant} FCFA"

    def save(self, *args, **kwargs):
        """Met à jour le montant restant du prêt après sauvegarde"""
        super().save(*args, **kwargs)
        # Mettre à jour le montant restant du prêt
        self.pret.montant_restant = self.pret.montant_total - self.pret.total_rembourse
        if self.pret.montant_restant <= 0:
            self.pret.montant_restant = 0
            self.pret.is_rembourse = True
        self.pret.save()