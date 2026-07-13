# poulaillers/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from .models import Poulailler
from .serializers import PoulaillerSerializer, PoulaillerListSerializer


class PoulaillerViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des poulaillers
    """
    queryset = Poulailler.objects.filter(is_deleted=False)
    serializer_class = PoulaillerSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_archived']
    search_fields = ['nom', 'localisation']
    ordering_fields = ['nom', 'created_at', 'longueur', 'largeur']
    ordering = ['nom']

    def get_serializer_class(self):
        if self.action == 'list':
            return PoulaillerListSerializer
        return PoulaillerSerializer

    def get_queryset(self):
            # ✅ Filtrer par l'utilisateur connecté
            return Poulailler.objects.filter(
                created_by=self.request.user,
                is_deleted=False
    )

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_update(self, serializer):
        serializer.save(updated_by=self.request.user)

    @action(detail=True, methods=['get'])
    def statistiques(self, request, pk=None):
        """
        Récupère les statistiques d'un poulailler
        """
        poulailler = self.get_object()
        cycles_actifs = poulailler.cycles.filter(is_active=True, is_archived=False, is_deleted=False)

        data = {
            'id': str(poulailler.id),
            'nom': poulailler.nom,
            'surface': poulailler.surface,
            'nb_cycles_actifs': cycles_actifs.count(),
            'nb_poulets_actuels': poulailler.nb_poulets_actuels,
            'statut': poulailler.statut,
            'densite_actuelle': poulailler.densite_actuelle,
            'nb_mangeoires': poulailler.nombre_mangeoires,
            'nb_abreuvoirs': poulailler.nombre_abreuvoirs,
            'capacite_recommandee': poulailler.surface * 8,  # 8 poulets/m² par défaut
            'is_archived': poulailler.is_archived,
        }
        return Response(data)

    @action(detail=True, methods=['post'])
    def archiver(self, request, pk=None):
        """
        Archive un poulailler
        """
        poulailler = self.get_object()
        if poulailler.nb_poulets_actuels > 0:
            return Response(
                {'error': 'Impossible d\'archiver un poulailler occupé.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        poulailler.is_archived = True
        poulailler.save()
        return Response({'message': 'Poulailler archivé avec succès.'})