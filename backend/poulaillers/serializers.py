# poulaillers/serializers.py
from rest_framework import serializers
from .models import Poulailler


class PoulaillerSerializer(serializers.ModelSerializer):
    """
    Serializer pour les poulaillers
    """
    statut = serializers.ReadOnlyField()
    nb_poulets_actuels = serializers.ReadOnlyField()
    surface = serializers.ReadOnlyField()
    densite_actuelle = serializers.ReadOnlyField()

    class Meta:
        model = Poulailler
        fields = [
                    'id', 'nom', 'longueur', 'largeur', 'hauteur',
                    'localisation', 'type_sol', 'surface',
                    'nombre_mangeoires', 'nombre_abreuvoirs',
                    'statut', 'nb_poulets_actuels', 'densite_actuelle',
                    'is_archived', 'created_at', 'updated_at', 'created_by'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'created_by']


class PoulaillerListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des poulaillers
    """
    statut = serializers.ReadOnlyField()
    nb_poulets_actuels = serializers.ReadOnlyField()

    class Meta:
        model = Poulailler
        fields = [
            'id', 'nom', 'statut', 'nb_poulets_actuels',
            'localisation', 'is_archived'
        ]