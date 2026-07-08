# clients/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum, Count
from .models import Client
from .serializers import ClientSerializer, ClientListSerializer, ClientCreateSerializer


class ClientViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des clients
    """
    queryset = Client.objects.filter(is_deleted=False)
    serializer_class = ClientSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type_client']
    search_fields = ['nom', 'telephone', 'adresse']
    ordering_fields = ['nom', 'created_at']
    ordering = ['nom']

    def get_serializer_class(self):
        if self.action == 'list':
            return ClientListSerializer
        elif self.action == 'create':
            return ClientCreateSerializer
        return ClientSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['get'])
    def historique(self, request, pk=None):
        """
        Récupère l'historique des achats d'un client
        """
        client = self.get_object()
        ventes = client.ventes.filter(is_deleted=False).order_by('-date')

        from ventes.serializers import VenteListSerializer
        serializer = VenteListSerializer(ventes, many=True)

        return Response({
            'client': {
                'id': str(client.id),
                'nom': client.nom,
                'telephone': client.telephone
            },
            'historique': serializer.data,
            'total_achats': client.total_achats,
            'nb_achats': client.nb_achats
        })

    @action(detail=False, methods=['get'])
    def top_clients(self, request):
        """
        Récupère les meilleurs clients (par montant d'achat)
        """
        clients = Client.objects.filter(is_deleted=False).annotate(
            total_achats=Sum('ventes__montant_total'),
            nb_achats=Count('ventes')
        ).filter(total_achats__isnull=False).order_by('-total_achats')[:10]

        data = []
        for client in clients:
            data.append({
                'id': str(client.id),
                'nom': client.nom,
                'telephone': client.telephone,
                'total_achats': client.total_achats,
                'nb_achats': client.nb_achats
            })

        return Response(data)

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        """
        Suppression logique d'un client
        """
        client = self.get_object()
        client.is_deleted = True
        client.save()
        return Response({'message': 'Client supprimé avec succès.'})