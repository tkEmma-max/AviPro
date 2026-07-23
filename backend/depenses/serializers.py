# depenses/serializers.py
from rest_framework import serializers
from .models import Depense, CategorieDepense, RoutineDepense, RoutineAppliquee


class CategorieDepenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategorieDepense
        fields = '__all__'
        read_only_fields = ('id', 'created_at', 'updated_at', 'created_by')


class RoutineDepenseSerializer(serializers.ModelSerializer):
    type_poulet_nom = serializers.ReadOnlyField(source='type_poulet.nom')
    categorie_depense_nom = serializers.ReadOnlyField(source='categorie_depense.nom')

    class Meta:
        model = RoutineDepense
        fields = [
            'id', 'type_poulet', 'type_poulet_nom',
            'categorie_depense', 'categorie_depense_nom',
            'nom', 'age_jour', 'mode_calcul',
            'montant_par_sujet', 'seuil_tranche', 'montant_par_tranche', 'montant_fixe',
            'est_obligatoire', 'is_active', 'metadata',
            'created_at', 'updated_at'
        ]
        read_only_fields = ('id', 'created_at', 'updated_at', 'created_by')


class RoutineDepenseCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoutineDepense
        fields = [
            'type_poulet', 'categorie_depense', 'nom', 'age_jour',
            'mode_calcul', 'montant_par_sujet', 'seuil_tranche',
            'montant_par_tranche', 'montant_fixe', 'est_obligatoire'
        ]


class RoutineAppliqueeSerializer(serializers.ModelSerializer):
    routine_nom = serializers.ReadOnlyField(source='routine.nom')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')

    class Meta:
        model = RoutineAppliquee
        fields = [
            'id', 'routine', 'routine_nom', 'cycle', 'cycle_nom',
            'montant_calcule', 'nb_poulets_au_moment', 'date_application'
        ]
        read_only_fields = ('id', 'date_application')


class DepenseSerializer(serializers.ModelSerializer):
    categorie_label = serializers.ReadOnlyField(source='get_categorie_display')
    categorie_depense_nom = serializers.ReadOnlyField(source='categorie_depense.nom')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')
    fournisseur_nom = serializers.ReadOnlyField(source='fournisseur.nom')
    cumul_depenses_avant = serializers.ReadOnlyField()
    cumul_depenses_apres = serializers.ReadOnlyField()
    prix_revient_avant = serializers.ReadOnlyField()
    prix_revient_apres = serializers.ReadOnlyField()
    impact_pourcentage = serializers.ReadOnlyField()
    poulailler_nom = serializers.ReadOnlyField()

    class Meta:
        model = Depense
        fields = [
            'id', 'cycle', 'cycle_nom',
            'categorie', 'categorie_label',
            'categorie_depense', 'categorie_depense_nom',
            'montant', 'date', 'description',
            'facture_numero', 'facture_photo',
            'fournisseur', 'fournisseur_nom',
            'est_depense_routine', 'routine_id',
            'cumul_depenses_avant', 'cumul_depenses_apres',
            'prix_revient_avant', 'prix_revient_apres',
            'impact_pourcentage', 'poulailler_nom',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class DepenseListSerializer(serializers.ModelSerializer):
    categorie_label = serializers.ReadOnlyField(source='get_categorie_display')
    categorie_depense_nom = serializers.ReadOnlyField(source='categorie_depense.nom')
    cycle_nom = serializers.ReadOnlyField(source='cycle.nom')

    class Meta:
        model = Depense
        fields = [
            'id', 'cycle', 'cycle_nom',
            'categorie', 'categorie_label', 'categorie_depense_nom',
            'montant', 'date', 'description', 'poulailler_nom',
        ]


class DepenseCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Depense
        fields = [
            'id', 'cycle', 'categorie', 'categorie_depense',
            'montant', 'date', 'description',
            'facture_numero', 'facture_photo', 'fournisseur'
        ]