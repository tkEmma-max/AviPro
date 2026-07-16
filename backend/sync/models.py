# sync/models.py
from django.db import models
import uuid

class PendingSync(models.Model):
    ACTION_CHOICES = [
        ('CREATE', 'Create'),
        ('UPDATE', 'Update'),
        ('DELETE', 'Delete'),
    ]
    STATUS_CHOICES = [
        ('PENDING', 'En attente'),
        ('SYNCED', 'Synchronisé'),
        ('FAILED', 'Échoué'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    table_name = models.CharField(max_length=100, help_text="Nom de la table concernée")
    object_id = models.CharField(max_length=100, help_text="ID de l'objet modifié")
    action = models.CharField(max_length=10, choices=ACTION_CHOICES)
    data = models.JSONField(help_text="Données complètes de l'objet")
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='PENDING')
    error_message = models.TextField(blank=True, null=True)
    retry_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    synced_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='pending_syncs'
    )

    class Meta:
        db_table = 'pending_sync'
        verbose_name = 'Synchronisation en attente'
        verbose_name_plural = 'Synchronisations en attente'
        ordering = ['created_at']

    def __str__(self):
        return f"{self.action} {self.table_name} ({self.object_id}) - {self.status}"