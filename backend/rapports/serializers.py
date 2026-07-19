# rapports/serializers.py
from rest_framework import serializers
from .models import RapportSuivi, TypeMaladie


class TypeMaladieSerializer(serializers.ModelSerializer):
    class Meta:
        model = TypeMaladie
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'updated_at', 'created_by')


class RapportSuiviSerializer(serializers.ModelSerializer):
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    type_maladie_nom = serializers.ReadOnlyField(source='type_maladie.nom')
    duree_jours = serializers.ReadOnlyField()
    aliment_moyen_par_jour = serializers.ReadOnlyField()
    eau_moyen_par_jour = serializers.ReadOnlyField()
    aliment_par_sujet_par_jour = serializers.ReadOnlyField()
    eau_par_sujet_par_jour = serializers.ReadOnlyField()
    ratio_eau_aliment = serializers.ReadOnlyField()
    # Infos du poulailler (via le cycle)
    surface = serializers.ReadOnlyField(source='cycle.poulailler.surface')
    nb_sujets_actuels = serializers.ReadOnlyField(source='cycle.nombre_sujets_actuels')
    nb_mangeoires = serializers.ReadOnlyField(source='cycle.poulailler.nombre_mangeoires')
    nb_abreuvoirs = serializers.ReadOnlyField(source='cycle.poulailler.nombre_abreuvoirs')
    
    class Meta:
        model = RapportSuivi
        fields = [
            'id', 'cycle', 'cycle_nom',
            'periode_debut', 'periode_fin', 'duree_jours',
            'aliment_consomme', 'eau_consommee',
            'aliment_moyen_par_jour', 'eau_moyen_par_jour',
            'aliment_par_sujet_par_jour', 'eau_par_sujet_par_jour',
            'ratio_eau_aliment',
            'maladie_observee', 'type_maladie', 'type_maladie_nom',
            'medicaments_administres', 'nb_sujets_malades',
            'observations', 'mortalites_periode',
            'metadata', 'created_at', 'updated_at',
            'surface', 'nb_sujets_actuels', 'nb_mangeoires', 'nb_abreuvoirs',
        ]
        read_only_fields = ('id', 'created_at', 'updated_at')


class RapportSuiviListSerializer(serializers.ModelSerializer):
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    duree_jours = serializers.ReadOnlyField()

    class Meta:
        model = RapportSuivi
        fields = [
            'id', 'cycle_nom', 'periode_debut', 'periode_fin',
            'duree_jours', 'aliment_consomme', 'eau_consommee',
            'maladie_observee', 'created_at'
        ]


class RapportSuiviCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = RapportSuivi
        fields = [
            'cycle', 'periode_debut', 'periode_fin',
            'aliment_consomme', 'eau_consommee',
            'maladie_observee', 'type_maladie',
            'medicaments_administres', 'nb_sujets_malades',
            'observations', 'mortalites_periode'
        ]