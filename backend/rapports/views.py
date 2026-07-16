# rapports/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum, Avg, Count
from django.utils import timezone
from .models import RapportSuivi, TypeMaladie
from .serializers import (
    RapportSuiviSerializer, RapportSuiviListSerializer,
    RapportSuiviCreateSerializer, TypeMaladieSerializer
)


class TypeMaladieViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les types de maladies.
    - Utilisateurs : GET (lecture seule)
    - Admin : GET, POST, PUT, DELETE
    """
    queryset = TypeMaladie.objects.filter(is_active=True)
    serializer_class = TypeMaladieSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def get_queryset(self):
        if self.request.user.is_staff and self.request.query_params.get('show_all'):
            return TypeMaladie.objects.all()
        return TypeMaladie.objects.filter(is_active=True)


class RapportSuiviViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des rapports de suivi.
    - Utilisateurs : CRUD sur leurs propres rapports
    - Admin : accès à TOUS les rapports
    """
    queryset = RapportSuivi.objects.filter(is_deleted=False)
    serializer_class = RapportSuiviSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['cycle', 'type_maladie']
    search_fields = ['maladie_observee', 'observations']
    ordering_fields = ['-periode_fin', 'created_at']
    ordering = ['-periode_fin']

    def get_serializer_class(self):
        if self.action == 'list':
            return RapportSuiviListSerializer
        elif self.action == 'create':
            return RapportSuiviCreateSerializer
        return RapportSuiviSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return RapportSuivi.objects.filter(is_deleted=False)
        return RapportSuivi.objects.filter(created_by=self.request.user, is_deleted=False)

    def perform_create(self, serializer):
        rapport = serializer.save(created_by=self.request.user)
        self._verifier_alertes(rapport)
        return rapport

    def _verifier_alertes(self, rapport):
        rapports_precedents = RapportSuivi.objects.filter(
            cycle=rapport.cycle,
            periode_fin__lt=rapport.periode_debut,
            is_deleted=False
        ).order_by('-periode_fin')[:3]

        if rapports_precedents.exists():
            moyenne_aliment = rapports_precedents.aggregate(avg=Avg('aliment_par_sujet_par_jour'))['avg'] or 0
            moyenne_eau = rapports_precedents.aggregate(avg=Avg('eau_par_sujet_par_jour'))['avg'] or 0

            if moyenne_aliment > 0:
                baisse_aliment = 1 - (rapport.aliment_par_sujet_par_jour / moyenne_aliment)
                if baisse_aliment > 0.2:
                    pass  # Future notification

            if moyenne_eau > 0:
                baisse_eau = 1 - (rapport.eau_par_sujet_par_jour / moyenne_eau)
                if baisse_eau > 0.2:
                    pass  # Future notification

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        rapport = self.get_object()
        rapport.is_deleted = True
        rapport.save()
        return Response({'message': 'Rapport supprimé.'})

    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        cycle_id = request.query_params.get('cycle')
        queryset = RapportSuivi.objects.filter(is_deleted=False)
        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)

        total_rapports = queryset.count()
        consommation_aliment = queryset.aggregate(avg=Avg('aliment_par_sujet_par_jour'))['avg'] or 0
        consommation_eau = queryset.aggregate(avg=Avg('eau_par_sujet_par_jour'))['avg'] or 0

        maladies = queryset.exclude(type_maladie__isnull=True).values('type_maladie__nom').annotate(count=Count('id')).order_by('-count')[:5]
        nb_avec_maladie = queryset.exclude(type_maladie__isnull=True).count()

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
        cycle_id = request.query_params.get('cycle')
        if not cycle_id:
            return Response({'error': 'Le paramètre cycle est requis.'}, status=status.HTTP_400_BAD_REQUEST)

        rapport = RapportSuivi.objects.filter(cycle_id=cycle_id, is_deleted=False).order_by('-periode_fin').first()
        if rapport:
            serializer = self.get_serializer(rapport)
            return Response(serializer.data)
        return Response({'message': 'Aucun rapport trouvé pour ce cycle.'})