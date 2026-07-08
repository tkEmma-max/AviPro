# ventes/serializers.py
from rest_framework import serializers
from .models import Vente


class VenteSerializer(serializers.ModelSerializer):
    """
    Serializer pour les ventes
    """
    type_label = serializers.ReadOnlyField(source='get_type_display')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    client_nom = serializers.ReadOnlyField(source='client.nom')
    prix_de_revient = serializers.ReadOnlyField()
    est_rentable = serializers.ReadOnlyField()
    marge_unitaire = serializers.ReadOnlyField()

    class Meta:
        model = Vente
        fields = [
            'id', 'cycle', 'cycle_nom', 'type', 'type_label',
            'quantite', 'prix_unitaire', 'montant_total',
            'date', 'description',
            'client', 'client_nom',
            'facture_numero', 'facture_photo', 'signature',
            'prix_de_revient', 'est_rentable', 'marge_unitaire',
            'remboursement_confirme', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'montant_total', 'created_at', 'updated_at']


class VenteListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des ventes
    """
    type_label = serializers.ReadOnlyField(source='get_type_display')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    client_nom = serializers.ReadOnlyField(source='client.nom')

    class Meta:
        model = Vente
        fields = [
            'id', 'cycle', 'cycle_nom', 'type', 'type_label',
            'quantite', 'prix_unitaire', 'montant_total',
            'date', 'client_nom'
        ]


class VenteCreateSerializer(serializers.ModelSerializer):
    """
    Serializer pour la création d'une vente
    """

    class Meta:
        model = Vente
        fields = [
            'id', 'cycle', 'type', 'quantite', 'prix_unitaire',
            'date', 'description', 'client',
            'facture_numero', 'facture_photo', 'signature',
            'remboursement_confirme'
        ]


class VenteStatsSerializer(serializers.Serializer):
    """
    Serializer pour les statistiques des ventes
    """
    total_ventes = serializers.DecimalField(max_digits=12, decimal_places=0)
    nombre_transactions = serializers.IntegerField()
    par_type = serializers.ListField()
    ventes_mois_courant = serializers.DecimalField(max_digits=12, decimal_places=0)