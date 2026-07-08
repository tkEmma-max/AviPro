# cycles/serializers.py
from rest_framework import serializers
from .models import Cycle
from depenses.models import Depense
from ventes.models import Vente


class CycleSerializer(serializers.ModelSerializer):
    """
    Serializer pour les cycles
    """
    poulailler_nom = serializers.ReadOnlyField(source='poulailler.nom')
    jours_ecoules = serializers.ReadOnlyField()
    progression = serializers.ReadOnlyField()
    mortalites = serializers.ReadOnlyField()
    taux_mortalite = serializers.ReadOnlyField()
    total_depenses = serializers.ReadOnlyField()
    total_ventes = serializers.ReadOnlyField()
    benefice = serializers.ReadOnlyField()
    est_rentable = serializers.ReadOnlyField()
    cout_production_unitaire = serializers.ReadOnlyField()
    prix_vente_moyen = serializers.ReadOnlyField()

    class Meta:
        model = Cycle
        fields = [
            'id', 'nom', 'poulailler', 'poulailler_nom', 'type',
            'date_debut', 'date_fin', 'duree_estimee_jours',
            'nombre_sujets_initiaux', 'nombre_sujets_actuels',
            'jours_ecoules', 'progression', 'mortalites', 'taux_mortalite',
            'total_depenses', 'total_ventes', 'benefice', 'est_rentable',
            'cout_production_unitaire', 'prix_vente_moyen',
            'is_active', 'is_archived', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CycleListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des cycles
    """
    poulailler_nom = serializers.ReadOnlyField(source='poulailler.nom')
    progression = serializers.ReadOnlyField()
    benefice = serializers.ReadOnlyField()

    class Meta:
        model = Cycle
        fields = [
            'id', 'nom', 'poulailler_nom', 'type',
            'date_debut', 'progression', 'benefice',
            'is_active', 'is_archived'
        ]


class CycleDetailSerializer(serializers.ModelSerializer):
    """
    Serializer détaillé pour un cycle avec dépenses et ventes
    """
    poulailler_nom = serializers.ReadOnlyField(source='poulailler.nom')
    jours_ecoules = serializers.ReadOnlyField()
    progression = serializers.ReadOnlyField()
    mortalites = serializers.ReadOnlyField()
    taux_mortalite = serializers.ReadOnlyField()
    total_depenses = serializers.ReadOnlyField()
    total_ventes = serializers.ReadOnlyField()
    benefice = serializers.ReadOnlyField()
    est_rentable = serializers.ReadOnlyField()
    cout_production_unitaire = serializers.ReadOnlyField()
    prix_vente_moyen = serializers.ReadOnlyField()

    # Dépenses et ventes incluses
    depenses = serializers.SerializerMethodField()
    ventes = serializers.SerializerMethodField()

    class Meta:
        model = Cycle
        fields = [
            'id', 'nom', 'poulailler', 'poulailler_nom', 'type',
            'date_debut', 'date_fin', 'duree_estimee_jours',
            'nombre_sujets_initiaux', 'nombre_sujets_actuels',
            'jours_ecoules', 'progression', 'mortalites', 'taux_mortalite',
            'total_depenses', 'total_ventes', 'benefice', 'est_rentable',
            'cout_production_unitaire', 'prix_vente_moyen',
            'depenses', 'ventes',
            'is_active', 'is_archived', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_depenses(self, obj):
        from depenses.serializers import DepenseSerializer
        depenses = obj.depenses.filter(is_deleted=False)
        return DepenseSerializer(depenses, many=True).data

    def get_ventes(self, obj):
        from ventes.serializers import VenteSerializer
        ventes = obj.ventes.filter(is_deleted=False)
        return VenteSerializer(ventes, many=True).data


class CycleStatsSerializer(serializers.Serializer):
    """
    Serializer pour les statistiques d'un cycle
    """
    id = serializers.UUIDField()
    nom = serializers.CharField()
    jours_ecoules = serializers.IntegerField()
    progression = serializers.FloatField()
    taux_mortalite = serializers.FloatField()
    total_depenses = serializers.DecimalField(max_digits=12, decimal_places=0)
    total_ventes = serializers.DecimalField(max_digits=12, decimal_places=0)
    benefice = serializers.DecimalField(max_digits=12, decimal_places=0)
    est_rentable = serializers.BooleanField()
    cout_production_unitaire = serializers.DecimalField(max_digits=12, decimal_places=0)