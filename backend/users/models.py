# users/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
import uuid

class User(AbstractUser):
    # Désactiver le champ username
    username = None  # Supprimer le champ username

    # Rendre l'email obligatoire et unique
    email = models.EmailField(unique=True)

    # Prénom obligatoire
    first_name = models.CharField(max_length=150, blank=False)

    # Nom facultatif
    last_name = models.CharField(max_length=150, blank=True, null=True)

    # Autres champs
    telephone = models.CharField(max_length=20, blank=True, null=True)
    adresse = models.TextField(blank=True, null=True)

    USERNAME_FIELD = 'email'  # L'email devient l'identifiant
    REQUIRED_FIELDS = ['first_name']  # Le prénom est requis

    def __str__(self):
        return f"{self.first_name} {self.last_name or ''}".strip()