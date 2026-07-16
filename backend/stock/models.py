# stock/models.py
from django.db import models
import uuid


class ProduitStock(models.Model):
    """
    Produit en stock (aliment, médicament, vaccin, etc.)
    """
    TYPE_CHOICES = [
        ('ALIMENT', 'Aliment'),
        ('MEDICAMENT', 'Médicament'),
        ('VACCIN', 'Vaccin'),
        ('LITIERE', 'Litière'),
        ('AUTRE', 'Autre'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nom = models.CharField(max_length=100)
    type_produit = models.CharField(max_length=20, choices=TYPE_CHOICES, default='ALIMENT')
    quantite = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    unite = models.CharField(max_length=20, default='kg')
    prix_unitaire = models.DecimalField(max_digits=10, decimal_places=0, default=0)
    seuil_alerte = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='produits_stock_crees'
    )

    class Meta:
        db_table = 'produits_stock'
        verbose_name = 'Produit en stock'
        verbose_name_plural = 'Produits en stock'
        ordering = ['nom']

    def __str__(self):
        return f"{self.nom} ({self.quantite} {self.unite})"

    @property
    def est_sous_seuil(self):
        """Vérifie si le produit est sous le seuil d'alerte"""
        return self.quantite <= self.seuil_alerte


class MouvementStock(models.Model):
    """
    Entrée ou sortie de stock
    """
    TYPE_MOUVEMENT = [
        ('ENTREE', 'Entrée'),
        ('SORTIE', 'Sortie'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    produit = models.ForeignKey(
        ProduitStock, on_delete=models.CASCADE, related_name='mouvements'
    )
    type_mouvement = models.CharField(max_length=10, choices=TYPE_MOUVEMENT)
    quantite = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateTimeField(auto_now_add=True)
    raison = models.TextField(blank=True, null=True)
    cycle = models.ForeignKey(
        'cycles.Cycle', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='mouvements_stock'
    )
    depense = models.ForeignKey(
        'depenses.Depense', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='mouvements_stock'
    )
    created_by = models.ForeignKey(
        'users.User', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='mouvements_stock_crees'
    )

    class Meta:
        db_table = 'mouvements_stock'
        verbose_name = 'Mouvement de stock'
        verbose_name_plural = 'Mouvements de stock'
        ordering = ['-date']

    def __str__(self):
        return f"{self.get_type_mouvement_display()} - {self.produit.nom} ({self.quantite})"

    def save(self, *args, **kwargs):
        """Met à jour la quantité du produit après le mouvement"""
        is_new = self.pk is None
        if is_new:
            if self.type_mouvement == 'ENTREE':
                self.produit.quantite += self.quantite
            else:
                self.produit.quantite -= self.quantite
            self.produit.save()
        super().save(*args, **kwargs)