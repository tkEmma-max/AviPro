# stock/serializers.py
from rest_framework import serializers
from .models import ProduitStock, MouvementStock


class ProduitStockSerializer(serializers.ModelSerializer):
    est_sous_seuil = serializers.ReadOnlyField()

    class Meta:
        model = ProduitStock
        fields = [
            'id', 'nom', 'type_produit', 'quantite', 'unite',
            'prix_unitaire', 'seuil_alerte', 'est_sous_seuil',
            'is_active', 'metadata', 'created_at', 'updated_at'
        ]
        read_only_fields = ('id', 'created_at', 'updated_at', 'est_sous_seuil')


class ProduitStockListSerializer(serializers.ModelSerializer):
    est_sous_seuil = serializers.ReadOnlyField()

    class Meta:
        model = ProduitStock
        fields = ['id', 'nom', 'type_produit', 'quantite', 'unite', 'est_sous_seuil']


class MouvementStockSerializer(serializers.ModelSerializer):
    produit_nom = serializers.ReadOnlyField(source='produit.nom')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')

    class Meta:
        model = MouvementStock
        fields = [
            'id', 'produit', 'produit_nom', 'type_mouvement',
            'quantite', 'date', 'raison', 'cycle', 'cycle_nom'
        ]
        read_only_fields = ('id', 'date')


class MouvementStockCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = MouvementStock
        fields = ['produit', 'type_mouvement', 'quantite', 'raison', 'cycle']