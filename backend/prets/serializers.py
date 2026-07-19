# prets/serializers.py
from rest_framework import serializers
from .models import Pret, Echeance, RemboursementPret


class EcheanceSerializer(serializers.ModelSerializer):
    """
    Serializer pour les échéances
    """
    est_en_retard = serializers.ReadOnlyField()

    class Meta:
        model = Echeance
        fields = [
            'id', 'pret', 'date_echeance', 'montant_due',
            'est_payee', 'date_paiement', 'est_en_retard'
        ]
        read_only_fields = ['id']


class RemboursementPretSerializer(serializers.ModelSerializer):
    """
    Serializer pour les remboursements de prêts
    """
    pret_preteur = serializers.ReadOnlyField(source='pret.preteur')
    echeance_date = serializers.ReadOnlyField(source='echeance.date_echeance')

    class Meta:
        model = RemboursementPret
        fields = [
            'id', 'pret', 'pret_preteur', 'montant', 'date',
            'source', 'cycle_source', 'vente_source',
            'echeance', 'echeance_date',
            'description', 'is_manually_confirmed',
            'created_at', 'transaction_mobile_id', 'metadata',
        ]
        read_only_fields = ['id', 'created_at']


class PretSerializer(serializers.ModelSerializer):
    """
    Serializer pour les prêts
    """
    echeances = EcheanceSerializer(many=True, read_only=True)
    remboursements = RemboursementPretSerializer(many=True, read_only=True)
    total_rembourse = serializers.ReadOnlyField()
    montant_restant_calcule = serializers.ReadOnlyField()
    prochaine_echeance = serializers.SerializerMethodField()
    est_en_retard = serializers.ReadOnlyField()

    class Meta:
        model = Pret
        fields = [
            'id', 'preteur', 'type_preteur',
            'montant_total', 'date_deblocage', 'taux_interet',
            'type_taux', 'date_limite',
            'mode_remboursement', 'duree_totale_mois', 'periodicite',
            'montant_restant', 'total_rembourse', 'montant_restant_calcule',
            'prochaine_echeance', 'est_en_retard',
            'is_rembourse', 'cycles_affectes',
            'echeances', 'remboursements',
            'created_at', 'updated_at',
            'metadata',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_prochaine_echeance(self, obj):
        echeance = obj.prochaine_echeance
        if echeance:
            return {
                'id': str(echeance.id),
                'date': echeance.date_echeance.isoformat(),
                'montant': echeance.montant_due
            }
        return None


class PretListSerializer(serializers.ModelSerializer):
    """
    Serializer simplifié pour la liste des prêts
    """
    prochaine_echeance = serializers.SerializerMethodField()
    est_en_retard = serializers.ReadOnlyField()

    class Meta:
        model = Pret
        fields = [
            'id', 'preteur', 'type_preteur', 'montant_total',
            'montant_restant', 'prochaine_echeance', 'est_en_retard',
            'is_rembourse', 'created_at'
        ]

    def get_prochaine_echeance(self, obj):
        echeance = obj.prochaine_echeance
        if echeance:
            return {
                'date': echeance.date_echeance.isoformat(),
                'montant': echeance.montant_due
            }
        return None


class PretCreateSerializer(serializers.ModelSerializer):
    """
    Serializer pour la création d'un prêt
    """

    class Meta:
        model = Pret
        fields = [
            'preteur', 'type_preteur', 'montant_total', 'date_deblocage',
            'taux_interet', 'mode_remboursement', 'duree_totale_mois',
            'periodicite', 'cycles_affectes'
        ]