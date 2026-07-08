# depenses/serializers.py
from rest_framework import serializers
from .models import Depense


class DepenseSerializer(serializers.ModelSerializer):
    """
    Serializer pour les dépenses
    """
    categorie_label = serializers.ReadOnlyField(source='get_categorie_display')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    fournisseur_nom = serializers.ReadOnlyField(source='fournisseur.nom')

    class Meta:
        model = Depense
        fields = [
            'id', 'cycle', 'cycle_nom', 'categorie', 'categorie_label',
            'montant', 'date', 'description',
            'facture_numero', 'facture_photo',
            'fournisseur', 'fournisseur_nom',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class DepenseListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des dépenses
    """
    categorie_label = serializers.ReadOnlyField(source='get_categorie_display')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')

    class Meta:
        model = Depense
        fields = [
            'id', 'cycle', 'cycle_nom', 'categorie', 'categorie_label',
            'montant', 'date', 'description'
        ]


class DepenseCreateSerializer(serializers.ModelSerializer):
    """
    Serializer pour la création d'une dépense
    """

    class Meta:
        model = Depense
        fields = [
            'id', 'cycle', 'categorie', 'montant', 'date',
            'description', 'facture_numero', 'facture_photo',
            'fournisseur'
        ]