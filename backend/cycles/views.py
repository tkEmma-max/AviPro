# cycles/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from .models import Cycle
from .serializers import (
    CycleSerializer, CycleListSerializer, CycleDetailSerializer,
    CycleStatsSerializer
)


class CycleViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des cycles
    """
    queryset = Cycle.objects.filter(is_deleted=False)
    serializer_class = CycleSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['poulailler', 'type', 'is_active', 'is_archived']
    search_fields = ['nom', 'poulailler__nom']
    ordering_fields = ['-date_debut', 'created_at']
    ordering = ['-date_debut']

    def get_serializer_class(self):
        if self.action == 'list':
            return CycleListSerializer
        elif self.action == 'retrieve':
            return CycleDetailSerializer
        return CycleSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_update(self, serializer):
        serializer.save(updated_by=self.request.user)

    @action(detail=True, methods=['get'])
    def stats(self, request, pk=None):
        """
        Récupère les statistiques d'un cycle
        """
        cycle = self.get_object()
        serializer = CycleStatsSerializer(cycle)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def archiver(self, request, pk=None):
        """
        Archive un cycle
        """
        cycle = self.get_object()
        cycle.is_archived = True
        cycle.is_active = False
        cycle.date_fin = timezone.now().date()
        cycle.save()
        return Response({'message': 'Cycle archivé avec succès.'})

    @action(detail=True, methods=['post'])
    def activer(self, request, pk=None):
        """
        Active un cycle
        """
        cycle = self.get_object()
        cycle.is_active = True
        cycle.is_archived = False
        cycle.save()
        return Response({'message': 'Cycle activé avec succès.'})

    @action(detail=True, methods=['post'])
    def enregistrer_mortalite(self, request, pk=None):
        """
        Enregistre une mortalité dans le cycle
        """
        cycle = self.get_object()
        nb_morts = request.data.get('nombre', 0)

        if nb_morts <= 0:
            return Response(
                {'error': 'Le nombre de mortalités doit être supérieur à 0.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if nb_morts > cycle.nombre_sujets_actuels:
            return Response(
                {'error': f'Il n\'y a que {cycle.nombre_sujets_actuels} sujets actifs.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        cycle.nombre_sujets_actuels -= nb_morts
        cycle.save()

        return Response({
            'message': f'{nb_morts} mortalité(s) enregistrée(s).',
            'sujets_restants': cycle.nombre_sujets_actuels
        })