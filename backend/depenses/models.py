# depenses/models.py
from django.db import models
import uuid

class Depense(models.Model):
    """
    Dépense liée à un cycle de production
    """
    CATEGORIE_CHOICES = [
        ('ALIMENT', 'Aliment'),
        ('POUSSIN', 'Achat de poussins'),
        ('VACCIN', 'Vaccins et médicaments'),
        ('EAU', 'Eau'),
        ('ELECTRICITE', 'Électricité'),
        ('MAIN_OEUVRE', "Main-d'œuvre"),
        ('TRANSPORT', 'Transport'),
        ('ENTRETIEN', 'Entretien'),
        ('EQUIPEMENT', 'Équipement'),
        ('AUTRE', 'Autre'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cycle = models.ForeignKey(
        'cycles.Cycle',
        on_delete=models.CASCADE,
        related_name='depenses'
    )
    categorie = models.CharField(max_length=20, choices=CATEGORIE_CHOICES)
    montant = models.DecimalField(max_digits=12, decimal_places=0)
    date = models.DateField()
    description = models.TextField(blank=True, null=True)
    facture_numero = models.CharField(max_length=100, blank=True, null=True)
    facture_photo = models.URLField(blank=True, null=True)
    fournisseur = models.ForeignKey(
        'fournisseurs.Fournisseur',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='depenses'
    )
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='depenses_crees'
    )
    synced_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'depenses'
        verbose_name = 'Dépense'
        verbose_name_plural = 'Dépenses'
        ordering = ['-date']

    def __str__(self):
        return f"{self.get_categorie_display()} - {self.montant} FCFA"