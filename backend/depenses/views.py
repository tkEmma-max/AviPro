# depenses/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum
from .models import Depense
from .serializers import DepenseSerializer, DepenseListSerializer, DepenseCreateSerializer


class DepenseViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des dépenses
    """
    queryset = Depense.objects.filter(is_deleted=False)
    serializer_class = DepenseSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['cycle', 'categorie', 'date']
    search_fields = ['description', 'facture_numero']
    ordering_fields = ['-date', 'montant']
    ordering = ['-date']

    def get_serializer_class(self):
        if self.action == 'list':
            return DepenseListSerializer
        elif self.action == 'create':
            return DepenseCreateSerializer
        return DepenseSerializer

    def get_queryset(self):
        queryset = Depense.objects.filter(
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
        Récupère les statistiques des dépenses
        """
        # Total des dépenses
        total = Depense.objects.filter(is_deleted=False).aggregate(
            total=Sum('montant')
        )['total'] or 0

        # Total par catégorie
        par_categorie = Depense.objects.filter(is_deleted=False).values('categorie').annotate(
            total=Sum('montant')
        ).order_by('-total')

        # Dépenses du mois en cours
        from django.utils import timezone
        mois_courant = timezone.now().month
        annee_courante = timezone.now().year
        depenses_mois = Depense.objects.filter(
            is_deleted=False,
            date__month=mois_courant,
            date__year=annee_courante
        ).aggregate(total=Sum('montant'))['total'] or 0

        # Dépenses du cycle en cours (si spécifié)
        cycle_id = request.query_params.get('cycle')
        depenses_cycle = 0
        if cycle_id:
            depenses_cycle = Depense.objects.filter(
                is_deleted=False,
                cycle_id=cycle_id
            ).aggregate(total=Sum('montant'))['total'] or 0

        data = {
            'total_depenses': total,
            'depenses_mois_courant': depenses_mois,
            'depenses_cycle': depenses_cycle,
            'par_categorie': list(par_categorie),
            'nombre_transactions': Depense.objects.filter(is_deleted=False).count()
        }
        return Response(data)

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        """
        Suppression logique d'une dépense
        """
        depense = self.get_object()
        depense.is_deleted = True
        depense.save()
        return Response({'message': 'Dépense supprimée avec succès.'})