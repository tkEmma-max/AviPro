# fournisseurs/serializers.py
from rest_framework import serializers
from .models import Fournisseur


class FournisseurSerializer(serializers.ModelSerializer):
    """
    Serializer pour les fournisseurs
    """
    nb_fournitures = serializers.SerializerMethodField()
    total_fournitures = serializers.SerializerMethodField()

    class Meta:
        model = Fournisseur
        fields = [
            'id', 'nom', 'telephone', 'adresse', 'type_fournisseur',
            'nb_fournitures', 'total_fournitures',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_nb_fournitures(self, obj):
        """Nombre de fournitures effectuées par ce fournisseur"""
        return obj.depenses.filter(is_deleted=False).count()

    def get_total_fournitures(self, obj):
        """Total des fournitures effectuées par ce fournisseur"""
        total = obj.depenses.filter(is_deleted=False).aggregate(
            total=serializers.models.Sum('montant')
        )['total']
        return total or 0


class FournisseurListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des fournisseurs
    """

    class Meta:
        model = Fournisseur
        fields = ['id', 'nom', 'telephone', 'type_fournisseur']


class FournisseurCreateSerializer(serializers.ModelSerializer):
    """
    Serializer pour la création d'un fournisseur
    """

    class Meta:
        model = Fournisseur
        fields = ['nom', 'telephone', 'adresse', 'type_fournisseur']