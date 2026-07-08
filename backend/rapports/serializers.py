# rapports/serializers.py
from rest_framework import serializers
from .models import RapportSuivi


class RapportSuiviSerializer(serializers.ModelSerializer):
    """
    Serializer pour les rapports de suivi
    """
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    duree_jours = serializers.ReadOnlyField()
    aliment_moyen_par_jour = serializers.ReadOnlyField()
    eau_moyen_par_jour = serializers.ReadOnlyField()
    aliment_par_sujet_par_jour = serializers.ReadOnlyField()
    eau_par_sujet_par_jour = serializers.ReadOnlyField()
    ratio_eau_aliment = serializers.ReadOnlyField()

    class Meta:
        model = RapportSuivi
        fields = [
            'id', 'cycle', 'cycle_nom',
            'periode_debut', 'periode_fin', 'duree_jours',
            'aliment_consomme', 'aliment_moyen_par_jour',
            'aliment_par_sujet_par_jour',
            'eau_consommee', 'eau_moyen_par_jour',
            'eau_par_sujet_par_jour', 'ratio_eau_aliment',
            'maladie_observee', 'medicaments_administres',
            'nb_sujets_malades', 'observations',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class RapportSuiviListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des rapports
    """
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    duree_jours = serializers.ReadOnlyField()

    class Meta:
        model = RapportSuivi
        fields = [
            'id', 'cycle', 'cycle_nom',
            'periode_debut', 'periode_fin', 'duree_jours',
            'aliment_consomme', 'eau_consommee',
            'maladie_observee'
        ]


class RapportSuiviCreateSerializer(serializers.ModelSerializer):
    """
    Serializer pour la création d'un rapport de suivi
    """

    class Meta:
        model = RapportSuivi
        fields = [
            'cycle', 'periode_debut', 'periode_fin',
            'aliment_consomme', 'eau_consommee',
            'maladie_observee', 'medicaments_administres',
            'nb_sujets_malades', 'observations'
        ]


class RapportSuiviStatsSerializer(serializers.Serializer):
    """
    Serializer pour les statistiques des rapports
    """
    total_rapports = serializers.IntegerField()
    consommation_moyenne_aliment = serializers.DecimalField(max_digits=10, decimal_places=2)
    consommation_moyenne_eau = serializers.DecimalField(max_digits=10, decimal_places=2)
    maladies_frequentes = serializers.ListField()
    nb_rapports_avec_maladie = serializers.IntegerField()