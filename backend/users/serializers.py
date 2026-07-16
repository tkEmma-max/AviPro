# users/serializers.py
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User, ParametreUtilisateur


class UserSerializer(serializers.ModelSerializer):
    """Serializer pour l'utilisateur"""
    full_name = serializers.SerializerMethodField()
    password = serializers.CharField(write_only=True, required=False, validators=[validate_password])

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'password', 'first_name', 'last_name',
            'full_name', 'telephone', 'mobile_money_provider', 'mobile_money_number',
            'is_active', 'is_staff', 'is_superuser', 'date_joined', 'last_login',
            'metadata'
        ]
        read_only_fields = ['id', 'date_joined', 'last_login', 'is_active']
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def get_full_name(self, obj):
        return obj.full_name

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class UserListSerializer(serializers.ModelSerializer):
    """Serializer simplifié pour la liste des utilisateurs"""
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'full_name', 'telephone', 'is_active']
        extra_kwargs = {
            'password': {'write_only': True},
            'username': {'required': True},
        }

    def get_full_name(self, obj):
        return obj.full_name


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer pour le changement de mot de passe"""
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("L'ancien mot de passe est incorrect.")
        return value


class ParametreUtilisateurSerializer(serializers.ModelSerializer):
    """Serializer pour les paramètres utilisateur"""
    class Meta:
        model = ParametreUtilisateur
        fields = [
            'id', 'frequence_rappel_rapport', 'rappel_rapport_actif',
            'notif_echeance_pret', 'notif_densite',
            'notif_consommation', 'notif_fin_cycle',
            'unite_aliment', 'unite_eau', 'devise',
            'metadata'
        ]
        read_only_fields = ('id',)