# ventes/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum
from django.utils import timezone
from .models import Vente
from .serializers import VenteSerializer, VenteListSerializer, VenteCreateSerializer, VenteStatsSerializer


class VenteViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des ventes
    """
    queryset = Vente.objects.filter(is_deleted=False)
    serializer_class = VenteSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['cycle', 'type', 'client', 'date']
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
        queryset = Vente.objects.filter(
            created_by=self.request.user,
            is_deleted=False
        )
        cycle_id = self.request.query_params.get('cycle')
        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)
        return queryset

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        """
        Récupère les statistiques des ventes
        """
        # Total des ventes
        total = Vente.objects.filter(is_deleted=False).aggregate(
            total=Sum('montant_total')
        )['total'] or 0

        # Total par type
        par_type = Vente.objects.filter(is_deleted=False).values('type').annotate(
            total=Sum('montant_total')
        ).order_by('-total')

        # Ventes du mois en cours
        mois_courant = timezone.now().month
        annee_courante = timezone.now().year
        ventes_mois = Vente.objects.filter(
            is_deleted=False,
            date__month=mois_courant,
            date__year=annee_courante
        ).aggregate(total=Sum('montant_total'))['total'] or 0

        # Ventes du cycle en cours (si spécifié)
        cycle_id = request.query_params.get('cycle')
        ventes_cycle = 0
        if cycle_id:
            ventes_cycle = Vente.objects.filter(
                is_deleted=False,
                cycle_id=cycle_id
            ).aggregate(total=Sum('montant_total'))['total'] or 0

        data = {
            'total_ventes': total,
            'ventes_mois_courant': ventes_mois,
            'ventes_cycle': ventes_cycle,
            'par_type': list(par_type),
            'nombre_transactions': Vente.objects.filter(is_deleted=False).count()
        }
        return Response(data)

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        """
        Suppression logique d'une vente
        """
        vente = self.get_object()
        vente.is_deleted = True
        vente.save()
        return Response({'message': 'Vente supprimée avec succès.'})

    @action(detail=False, methods=['get'])
    def analyse_prix(self, request):
        """
        Analyse les prix de vente par rapport aux prix de revient
        """
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