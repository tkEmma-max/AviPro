# backend/notifications/models.py
from django.db import models
import uuid


class Notification(models.Model):
    TYPE_CHOICES = [
        ('ECHEANCE_J7', 'Échéance J-7'),
        ('ECHEANCE_J3', 'Échéance J-3'),
        ('ECHEANCE_J1', 'Échéance J-1'),
        ('ECHEANCE_JOURJ', 'Échéance jour J'),
        ('ECHEANCE_RETARD', 'Échéance en retard'),
        ('DENSITE', 'Alerte densité'),
        ('CONSOMMATION', 'Alerte consommation'),
        ('RAPPEL_RAPPORT', 'Rappel de rapport'),
        ('FIN_CYCLE', 'Fin de cycle'),
        ('PRET_FLEXIBLE', 'Rappel prêt flexible'),
        ('SUGGESTION', 'Suggestion d\'optimisation'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        'users.User', on_delete=models.CASCADE, related_name='notifications'
    )
    type = models.CharField(max_length=30, choices=TYPE_CHOICES)
    titre = models.CharField(max_length=200)
    message = models.TextField()
    donnees = models.JSONField(default=dict, blank=True)
    est_lue = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-date_creation']

    def __str__(self):
        return f"[{self.get_type_display()}] {self.titre}"