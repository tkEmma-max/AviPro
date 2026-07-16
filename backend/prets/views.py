# prets/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum
from django.utils import timezone
from .models import Pret, Echeance, RemboursementPret
from .serializers import (
    PretSerializer, PretListSerializer, PretCreateSerializer,
    EcheanceSerializer, RemboursementPretSerializer
)


class PretViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des prêts
    """
    queryset = Pret.objects.filter(is_deleted=False)
    serializer_class = PretSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type_preteur', 'is_rembourse', 'mode_remboursement']
    search_fields = ['preteur']
    ordering_fields = ['-created_at', 'montant_total']
    ordering = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return PretListSerializer
        elif self.action == 'create':
            return PretCreateSerializer
        return PretSerializer
        
    def get_queryset(self):
        if self.request.user.is_staff:
            return Pret.objects.filter(is_deleted=False)
        return Pret.objects.filter(created_by=self.request.user, is_deleted=False)
    
    
    def perform_create(self, serializer):
        """Crée un prêt avec le montant restant initial"""
        serializer.save(
            created_by=self.request.user,
            montant_restant=serializer.validated_data.get('montant_total')
        )

    @action(detail=True, methods=['post'])
    def ajouter_echeance(self, request, pk=None):
        """
        Ajoute une échéance à un prêt
        """
        pret = self.get_object()
        serializer = EcheanceSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(pret=pret)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def enregistrer_remboursement(self, request, pk=None):
        """
        Enregistre un remboursement pour un prêt
        """
        pret = self.get_object()

        # Vérifier que le montant ne dépasse pas le restant dû
        montant = request.data.get('montant', 0)
        if montant > pret.montant_restant:
            return Response(
                {'error': f'Le montant dépasse le restant dû ({pret.montant_restant} FCFA).'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = RemboursementPretSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(pret=pret, created_by=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def echeances(self, request, pk=None):
        """
        Récupère toutes les échéances d'un prêt
        """
        pret = self.get_object()
        echeances = pret.echeances.all().order_by('date_echeance')
        serializer = EcheanceSerializer(echeances, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def remboursements(self, request, pk=None):
        """
        Récupère tous les remboursements d'un prêt
        """
        pret = self.get_object()
        remboursements = pret.remboursements.all().order_by('-date')
        serializer = RemboursementPretSerializer(remboursements, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def marquer_rembourse(self, request, pk=None):
        """
        Marque un prêt comme complètement remboursé
        """
        pret = self.get_object()

        if pret.montant_restant > 0:
            # Créer un remboursement pour le solde restant
            RemboursementPret.objects.create(
                pret=pret,
                montant=pret.montant_restant,
                date=timezone.now().date(),
                source='SOLDE_FINAL',
                description='Solde final du prêt',
                created_by=request.user,
                is_manually_confirmed=True
            )

        pret.is_rembourse = True
        pret.montant_restant = 0
        pret.save()

        return Response({'message': 'Prêt marqué comme complètement remboursé.'})

    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        """
        Récupère les statistiques des prêts
        """
        # Total des prêts actifs
        prets_actifs = Pret.objects.filter(is_rembourse=False, is_deleted=False)

        total_emprunte = Pret.objects.filter(is_deleted=False).aggregate(
            total=Sum('montant_total')
        )['total'] or 0

        total_restant = prets_actifs.aggregate(
            total=Sum('montant_restant')
        )['total'] or 0

        total_rembourse = Pret.objects.filter(is_deleted=False).aggregate(
            total=Sum('montant_total') - Sum('montant_restant')
        )['total'] or 0

        # Par type de prêteur
        par_type = Pret.objects.filter(is_deleted=False).values('type_preteur').annotate(
            total=Sum('montant_total')
        ).order_by('-total')

        data = {
            'total_emprunte': total_emprunte,
            'total_restant': total_restant,
            'total_rembourse': total_rembourse,
            'nb_prets_actifs': prets_actifs.count(),
            'par_type': list(par_type)
        }
        return Response(data)


class EcheanceViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des échéances
    """
    queryset = Echeance.objects.all()
    serializer_class = EcheanceSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['pret', 'est_payee']

    @action(detail=True, methods=['post'])
    def marquer_payee(self, request, pk=None):
        """
        Marque une échéance comme payée
        """
        echeance = self.get_object()
        echeance.est_payee = True
        echeance.date_paiement = timezone.now().date()
        echeance.save()
        return Response({'message': 'Échéance marquée comme payée.'})


class RemboursementPretViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des remboursements de prêts
    """
    queryset = RemboursementPret.objects.all()
    serializer_class = RemboursementPretSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['pret', 'date']

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)