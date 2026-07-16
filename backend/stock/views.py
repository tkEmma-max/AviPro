# stock/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from .models import ProduitStock, MouvementStock
from .serializers import (
    ProduitStockSerializer, ProduitStockListSerializer,
    MouvementStockSerializer, MouvementStockCreateSerializer
)


class ProduitStockViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les produits en stock.
    """
    queryset = ProduitStock.objects.filter(is_active=True)
    serializer_class = ProduitStockSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type_produit']
    search_fields = ['nom']
    ordering = ['nom']

    def get_serializer_class(self):
        if self.action == 'list':
            return ProduitStockListSerializer
        return ProduitStockSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return ProduitStock.objects.filter(is_active=True)
        return ProduitStock.objects.filter(created_by=self.request.user, is_active=True)

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=False, methods=['get'])
    def alertes(self, request):
        """Liste les produits sous le seuil d'alerte"""
        produits = ProduitStock.objects.filter(
            is_active=True,
            quantite__lte=models.F('seuil_alerte')
        )
        return Response(ProduitStockSerializer(produits, many=True).data)


class MouvementStockViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les mouvements de stock.
    """
    queryset = MouvementStock.objects.all()
    serializer_class = MouvementStockSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['produit', 'type_mouvement', 'cycle']
    ordering = ['-date']

    def get_serializer_class(self):
        if self.action == 'create':
            return MouvementStockCreateSerializer
        return MouvementStockSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return MouvementStock.objects.all()
        return MouvementStock.objects.filter(created_by=self.request.user)

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)