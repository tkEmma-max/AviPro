# clients/serializers.py
from rest_framework import serializers
from .models import Client


class ClientSerializer(serializers.ModelSerializer):
    """
    Serializer pour les clients
    """
    nb_achats = serializers.SerializerMethodField()
    total_achats = serializers.SerializerMethodField()

    class Meta:
        model = Client
        fields = [
            'id', 'nom', 'telephone', 'adresse', 'type_client',
            'nb_achats', 'total_achats',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_nb_achats(self, obj):
        """Nombre d'achats effectués par ce client"""
        return obj.ventes.filter(is_deleted=False).count()

    def get_total_achats(self, obj):
        """Total des achats effectués par ce client"""
        total = obj.ventes.filter(is_deleted=False).aggregate(
            total=serializers.models.Sum('montant_total')
        )['total']
        return total or 0


class ClientListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des clients
    """

    class Meta:
        model = Client
        fields = ['id', 'nom', 'telephone', 'type_client']


class ClientCreateSerializer(serializers.ModelSerializer):
    """
    Serializer pour la création d'un client
    """

    class Meta:
        model = Client
        fields = ['nom', 'telephone', 'adresse', 'type_client']