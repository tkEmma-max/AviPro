# ventes/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum
from django.utils import timezone
from django.core.exceptions import ValidationError
from .models import Vente, TypeVente
from django.db import transaction

from .serializers import (
    VenteSerializer, VenteListSerializer, VenteCreateSerializer,
    VenteStatsSerializer, TypeVenteSerializer
)


class TypeVenteViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les types de ventes.
    - Utilisateurs authentifiés : GET (lecture seule)
    - Admin : GET, POST, PUT, DELETE
    """
    queryset = TypeVente.objects.filter(is_active=True)
    serializer_class = TypeVenteSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def get_queryset(self):
        if self.request.user.is_staff and self.request.query_params.get('show_all'):
            return TypeVente.objects.all()
        return TypeVente.objects.filter(is_active=True)


class VenteViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des ventes.
    - Utilisateurs : CRUD sur leurs propres ventes
    - Admin : accès à TOUTES les ventes
    """
    queryset = Vente.objects.filter(is_deleted=False)
    serializer_class = VenteSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['cycle', 'type', 'type_vente', 'client', 'date']
    search_fields = ['description', 'facture_numero']
    ordering_fields = ['-date', 'montant_total']
    ordering = ['-date']

    def get_serializer_class(self):
        if self.action == 'list':
            return VenteListSerializer
        elif self.action == 'create':
            return VenteCreateSerializer
        return VenteSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return Vente.objects.filter(is_deleted=False)
        return Vente.objects.filter(created_by=self.request.user, is_deleted=False)

    @transaction.atomic
    def perform_create(self, serializer):
        vente = serializer.save(created_by=self.request.user)

        est_oeuf = vente.type_vente and vente.type_vente.nom.upper() in ['OEUFS', 'ŒUFS']
        if not est_oeuf and vente.cycle:
            cycle = vente.cycle

            # Vérifier si le cycle est archivé
            if cycle.is_archived:
                raise ValidationError({'cycle': 'Ce cycle est clôturé. Aucune vente possible.'})

            # Vérifier le stock
            if vente.quantite > cycle.nombre_sujets_actuels:
                raise ValidationError({
                    'quantite': f'Stock insuffisant. Disponible : {cycle.nombre_sujets_actuels} sujets.'
                })

            # Déduire les sujets
            sous_bande = cycle.sous_bandes.filter(est_active=True).first()
            if sous_bande:
                sous_bande.nombre_sujets -= int(vente.quantite)
                if sous_bande.nombre_sujets <= 0:
                    sous_bande.nombre_sujets = 0
                    sous_bande.est_active = False
                sous_bande.save()

            # Archiver si stock = 0
            if cycle.nombre_sujets_actuels <= 0:
                cycle.is_active = False
                cycle.is_archived = True
                cycle.date_fin = timezone.now().date()
                cycle.save()
                
                
    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        total = Vente.objects.filter(is_deleted=False).aggregate(total=Sum('montant_total'))['total'] or 0
        par_type = Vente.objects.filter(is_deleted=False).values('type_vente__nom').annotate(total=Sum('montant_total')).order_by('-total')
        mois_courant = timezone.now().month
        annee_courante = timezone.now().year
        ventes_mois = Vente.objects.filter(is_deleted=False, date__month=mois_courant, date__year=annee_courante).aggregate(total=Sum('montant_total'))['total'] or 0
        data = {
            'total_ventes': total,
            'ventes_mois_courant': ventes_mois,
            'par_type': list(par_type),
            'nombre_transactions': Vente.objects.filter(is_deleted=False).count()
        }
        return Response(data)

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        vente = self.get_object()
        vente.is_deleted = True
        vente.save()
        return Response({'message': 'Vente supprimée.'})

    @action(detail=False, methods=['get'])
    def analyse_prix(self, request):
        ventes = Vente.objects.filter(is_deleted=False)
        data = []
        for vente in ventes:
            data.append({
                'id': str(vente.id),
                'type': vente.get_type_display(),
                'prix_unitaire': vente.prix_unitaire,
                'prix_de_revient': vente.prix_de_revient,
                'marge': vente.marge_unitaire,
                'est_rentable': vente.est_rentable
            })
        return Response(data)