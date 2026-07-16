# users/models.py
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, email, first_name, password=None, **extra_fields):
        if not email:
            raise ValueError('L\'email est obligatoire')
        email = self.normalize_email(email)
        user = self.model(email=email, first_name=first_name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, first_name, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, first_name, password, **extra_fields)


class User(AbstractUser):
    username = None
    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150, blank=True, null=True)
    telephone = models.CharField(max_length=20, blank=True, null=True)

    # Paiement mobile
    mobile_money_provider = models.CharField(
        max_length=20, blank=True, null=True,
        choices=[
            ('OM', 'Orange Money'),
            ('MOMO', 'MTN Mobile Money'),
            ('AUTRE', 'Autre'),
        ],
        help_text="Fournisseur de paiement mobile"
    )
    mobile_money_number = models.CharField(
        max_length=20, blank=True, null=True,
        help_text="Numéro de téléphone mobile money"
    )

    # Métadonnées extensibles
    metadata = models.JSONField(default=dict, blank=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name']

    objects = UserManager()

    def __str__(self):
        return self.email

    @property
    def full_name(self):
        if self.last_name:
            return f"{self.first_name} {self.last_name}"
        return self.first_name


class ParametreUtilisateur(models.Model):
    """
    Paramètres et préférences de l'utilisateur
    """
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name='parametres'
    )

    # Rappels de rapports
    frequence_rappel_rapport = models.IntegerField(
        default=7,
        help_text="Fréquence de rappel en jours pour soumettre un rapport"
    )
    rappel_rapport_actif = models.BooleanField(
        default=True,
        help_text="Recevoir des rappels pour soumettre un rapport"
    )

    # Notifications
    notif_echeance_pret = models.BooleanField(default=True)
    notif_densite = models.BooleanField(default=True)
    notif_consommation = models.BooleanField(default=True)
    notif_fin_cycle = models.BooleanField(default=True)

    # Unités de mesure
    unite_aliment = models.CharField(default='kg', max_length=10)
    unite_eau = models.CharField(default='L', max_length=10)
    devise = models.CharField(default='FCFA', max_length=10)

    # Métadonnées
    metadata = models.JSONField(default=dict, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'parametres_utilisateur'
        verbose_name = 'Paramètre utilisateur'
        verbose_name_plural = 'Paramètres utilisateurs'

    def __str__(self):
        return f"Paramètres de {self.user.email}"