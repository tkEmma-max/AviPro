# cycles/serializers.py
from rest_framework import serializers
from .models import Cycle, TypePoulet
from .models import SousBande, Migration


class TypePouletSerializer(serializers.ModelSerializer):
    class Meta:
        model = TypePoulet
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'updated_at', 'created_by')


class CycleSerializer(serializers.ModelSerializer):
    poulailler_nom = serializers.ReadOnlyField(source='poulailler.nom')
    type_poulet_nom = serializers.ReadOnlyField(source='type_poulet.nom')
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
            'id', 'nom', 'poulailler', 'poulailler_nom',
            'type', 'type_poulet', 'type_poulet_nom',
            'date_debut', 'date_fin', 'duree_estimee_jours',
            'nombre_sujets_initiaux', 'nombre_sujets_actuels',
            'jours_ecoules', 'progression', 'mortalites', 'taux_mortalite',
            'total_depenses', 'total_ventes', 'benefice', 'est_rentable',
            'cout_production_unitaire', 'prix_vente_moyen',
            'is_active', 'is_archived',
            'metadata', 'est_publie_marketplace',
            'created_at', 'updated_at',
            'nb_mangeoires', 'nb_abreuvoirs',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CycleListSerializer(serializers.ModelSerializer):
    # Tout ce qui est utile pour une carte de cycle
    poulailler_nom = serializers.ReadOnlyField(source='poulailler.nom')
    type_poulet_nom = serializers.ReadOnlyField(source='type_poulet.nom')
    progression = serializers.ReadOnlyField()
    benefice = serializers.ReadOnlyField()
    jours_ecoules = serializers.ReadOnlyField()
    taux_mortalite = serializers.ReadOnlyField()
    mortalites = serializers.ReadOnlyField()
    nombre_sujets_actuels = serializers.ReadOnlyField()
    cout_production_unitaire = serializers.ReadOnlyField()
    est_rentable = serializers.ReadOnlyField()

    class Meta:
        model = Cycle
        fields = [
            'id', 'nom', 'poulailler', 'poulailler_nom', 'type', 'type_poulet_nom',
            'date_debut', 'progression', 'benefice', 'jours_ecoules',
            'taux_mortalite', 'mortalites', 'nombre_sujets_actuels',
            'nb_mangeoires', 'nb_abreuvoirs',
            'cout_production_unitaire', 'est_rentable',
            'is_active', 'is_archived',
        ]
        
        
class CycleDetailSerializer(serializers.ModelSerializer):
    poulailler_nom = serializers.ReadOnlyField(source='poulailler.nom')
    type_poulet_nom = serializers.ReadOnlyField(source='type_poulet.nom')
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
    depenses = serializers.SerializerMethodField()
    ventes = serializers.SerializerMethodField()

    class Meta:
        model = Cycle
        fields = [
            'id', 'nom', 'poulailler', 'poulailler_nom',
            'type', 'type_poulet', 'type_poulet_nom',
            'date_debut', 'date_fin', 'duree_estimee_jours',
            'nombre_sujets_initiaux', 'nombre_sujets_actuels',
            'jours_ecoules', 'progression', 'mortalites', 'taux_mortalite',
            'total_depenses', 'total_ventes', 'benefice', 'est_rentable',
            'cout_production_unitaire', 'prix_vente_moyen',
            'depenses', 'ventes',
            'metadata', 'est_publie_marketplace',
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


class SousBandeSerializer(serializers.ModelSerializer):
    poulailler_nom = serializers.ReadOnlyField(source='poulailler.nom')

    class Meta:
        model = SousBande
        fields = ['id', 'cycle', 'poulailler', 'poulailler_nom', 'nombre_sujets', 'est_active', 'date_creation']
        read_only_fields = ('id', 'date_creation')


class MigrationSerializer(serializers.ModelSerializer):
    poulailler_source_nom = serializers.ReadOnlyField(source='poulailler_source.nom')
    poulailler_cible_nom = serializers.ReadOnlyField(source='poulailler_cible.nom')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')

    class Meta:
        model = Migration
        fields = [
            'id', 'cycle', 'cycle_nom',
            'poulailler_source', 'poulailler_source_nom',
            'poulailler_cible', 'poulailler_cible_nom',
            'nombre_sujets', 'age_sujets', 'raison', 'date'
        ]
        read_only_fields = ('id', 'date')