# fournisseurs/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum, Count
from .models import Fournisseur
from .serializers import FournisseurSerializer, FournisseurListSerializer, FournisseurCreateSerializer


class FournisseurViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des fournisseurs
    """
    queryset = Fournisseur.objects.filter(is_deleted=False)
    serializer_class = FournisseurSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type_fournisseur']
    search_fields = ['nom', 'telephone', 'adresse']
    ordering_fields = ['nom', 'created_at']
    ordering = ['nom']

    def get_serializer_class(self):
        if self.action == 'list':
            return FournisseurListSerializer
        elif self.action == 'create':
            return FournisseurCreateSerializer
        return FournisseurSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['get'])
    def historique(self, request, pk=None):
        """
        Récupère l'historique des fournitures d'un fournisseur
        """
        fournisseur = self.get_object()
        depenses = fournisseur.depenses.filter(is_deleted=False).order_by('-date')

        from depenses.serializers import DepenseListSerializer
        serializer = DepenseListSerializer(depenses, many=True)

        return Response({
            'fournisseur': {
                'id': str(fournisseur.id),
                'nom': fournisseur.nom,
                'telephone': fournisseur.telephone
            },
            'historique': serializer.data,
            'total_fournitures': fournisseur.total_fournitures,
            'nb_fournitures': fournisseur.nb_fournitures
        })

    @action(detail=False, methods=['get'])
    def top_fournisseurs(self, request):
        """
        Récupère les meilleurs fournisseurs (par montant de fourniture)
        """
        fournisseurs = Fournisseur.objects.filter(is_deleted=False).annotate(
            total_fournitures=Sum('depenses__montant'),
            nb_fournitures=Count('depenses')
        ).filter(total_fournitures__isnull=False).order_by('-total_fournitures')[:10]

        data = []
        for fournisseur in fournisseurs:
            data.append({
                'id': str(fournisseur.id),
                'nom': fournisseur.nom,
                'telephone': fournisseur.telephone,
                'total_fournitures': fournisseur.total_fournitures,
                'nb_fournitures': fournisseur.nb_fournitures
            })

        return Response(data)

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        """
        Suppression logique d'un fournisseur
        """
        fournisseur = self.get_object()
        fournisseur.is_deleted = True
        fournisseur.save()
        return Response({'message': 'Fournisseur supprimé avec succès.'})