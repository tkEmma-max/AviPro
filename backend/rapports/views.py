# rapports/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum, Avg, Count
from django.utils import timezone
from .models import RapportSuivi
from .serializers import (
    RapportSuiviSerializer, RapportSuiviListSerializer,
    RapportSuiviCreateSerializer, RapportSuiviStatsSerializer
)


class RapportSuiviViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des rapports de suivi
    """
    queryset = RapportSuivi.objects.filter(is_deleted=False)
    serializer_class = RapportSuiviSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['cycle']
    search_fields = ['maladie_observee', 'observations']
    ordering_fields = ['-periode_fin']
    ordering = ['-periode_fin']

    def get_serializer_class(self):
        if self.action == 'list':
            return RapportSuiviListSerializer
        elif self.action == 'create':
            return RapportSuiviCreateSerializer
        return RapportSuiviSerializer

    def get_queryset(self):
        queryset = RapportSuivi.objects.filter(
            created_by=self.request.user,
            is_deleted=False
        )
        cycle_id = self.request.query_params.get('cycle')
        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)
        return queryset

    def perform_create(self, serializer):
        """Crée un rapport et vérifie les alertes de consommation"""
        rapport = serializer.save(created_by=self.request.user)
        self._verifier_alertes(rapport)
        return rapport

    def _verifier_alertes(self, rapport):
        """
        Vérifie les alertes de consommation anormale
        """
        # Vérifier par rapport aux rapports précédents du même cycle
        rapports_precedents = RapportSuivi.objects.filter(
            cycle=rapport.cycle,
            periode_fin__lt=rapport.periode_debut,
            is_deleted=False
        ).order_by('-periode_fin')[:3]

        if rapports_precedents.exists():
            moyenne_aliment = rapports_precedents.aggregate(
                avg=Avg('aliment_par_sujet_par_jour')
            )['avg'] or 0

            moyenne_eau = rapports_precedents.aggregate(
                avg=Avg('eau_par_sujet_par_jour')
            )['avg'] or 0

            # Alerte si baisse de 20%
            if moyenne_aliment > 0:
                baisse_aliment = 1 - (rapport.aliment_par_sujet_par_jour / moyenne_aliment)
                if baisse_aliment > 0.2:
                    # Stocker l'alerte (à implémenter avec le système de notifications)
                    pass

            if moyenne_eau > 0:
                baisse_eau = 1 - (rapport.eau_par_sujet_par_jour / moyenne_eau)
                if baisse_eau > 0.2:
                    # Stocker l'alerte (à implémenter avec le système de notifications)
                    pass

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        """
        Suppression logique d'un rapport
        """
        rapport = self.get_object()
        rapport.is_deleted = True
        rapport.save()
        return Response({'message': 'Rapport supprimé avec succès.'})

    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        """
        Récupère les statistiques des rapports
        """
        cycle_id = request.query_params.get('cycle')
        queryset = RapportSuivi.objects.filter(is_deleted=False)

        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)

        total_rapports = queryset.count()

        # Consommation moyenne d'aliment
        consommation_aliment = queryset.aggregate(
            avg=Avg('aliment_par_sujet_par_jour')
        )['avg'] or 0

        consommation_eau = queryset.aggregate(
            avg=Avg('eau_par_sujet_par_jour')
        )['avg'] or 0

        # Maladies fréquentes
        maladies = queryset.exclude(maladie_observee__isnull=True).exclude(
            maladie_observee=''
        ).values('maladie_observee').annotate(
            count=Count('id')
        ).order_by('-count')[:5]

        nb_avec_maladie = queryset.exclude(
            maladie_observee__isnull=True
        ).exclude(maladie_observee='').count()

        data = {
            'total_rapports': total_rapports,
            'consommation_moyenne_aliment': consommation_aliment,
            'consommation_moyenne_eau': consommation_eau,
            'maladies_frequentes': list(maladies),
            'nb_rapports_avec_maladie': nb_avec_maladie
        }
        return Response(data)

    @action(detail=False, methods=['get'])
    def dernier_rapport(self, request):
        """
        Récupère le dernier rapport d'un cycle
        """
        cycle_id = request.query_params.get('cycle')
        if not cycle_id:
            return Response(
                {'error': 'Le paramètre cycle est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        rapport = RapportSuivi.objects.filter(
            cycle_id=cycle_id,
            is_deleted=False
        ).order_by('-periode_fin').first()

        if rapport:
            serializer = self.get_serializer(rapport)
            return Response(serializer.data)

        return Response({'message': 'Aucun rapport trouvé pour ce cycle.'})