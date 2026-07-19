# depenses/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum
from django.utils import timezone
from django.db import transaction
from .models import Depense, CategorieDepense, RoutineDepense, RoutineAppliquee
from cycles.models import Cycle
from django.db import transaction
from django.core.exceptions import ValidationError

from .serializers import (
    DepenseSerializer, DepenseListSerializer, DepenseCreateSerializer,
    CategorieDepenseSerializer,
    RoutineDepenseSerializer, RoutineDepenseCreateSerializer,
    RoutineAppliqueeSerializer
)


class CategorieDepenseViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les catégories de dépenses.
    - Utilisateurs : GET
    - Admin : GET, POST, PUT, DELETE
    """
    queryset = CategorieDepense.objects.filter(is_active=True)
    serializer_class = CategorieDepenseSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def get_queryset(self):
        if self.request.user.is_staff and self.request.query_params.get('show_all'):
            return CategorieDepense.objects.all()
        return CategorieDepense.objects.filter(is_active=True)


class RoutineDepenseViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les routines de dépenses.
    - Utilisateurs : GET
    - Admin : GET, POST, PUT, DELETE
    """
    queryset = RoutineDepense.objects.filter(is_active=True)
    serializer_class = RoutineDepenseSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action == 'create':
            return RoutineDepenseCreateSerializer
        return RoutineDepenseSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def get_queryset(self):
        if self.request.user.is_staff and self.request.query_params.get('show_all'):
            return RoutineDepense.objects.all()
        return RoutineDepense.objects.filter(is_active=True)

    @action(detail=False, methods=['get'])
    def a_appliquer(self, request):
        """
        Retourne les routines à appliquer pour un cycle donné
        Paramètre requis : cycle_id
        """
        cycle_id = request.query_params.get('cycle_id')
        if not cycle_id:
            return Response({'error': 'cycle_id requis'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            cycle = Cycle.objects.get(id=cycle_id)
        except Cycle.DoesNotExist:
            return Response({'error': 'Cycle introuvable'}, status=status.HTTP_404_NOT_FOUND)

        if not cycle.type_poulet:
            return Response({'routines': [], 'message': 'Aucun type de poulet défini pour ce cycle'})

        age = cycle.jours_ecoules
        
        # Routines non appliquées pour ce type et cet âge (avec tolérance de ±3 jours)
        routines = RoutineDepense.objects.filter(
            type_poulet=cycle.type_poulet,
            is_active=True,
            age_jour__lte=age + 3,
            age_jour__gte=age - 3
        ).exclude(
            applications__cycle=cycle
        )

        result = []
        for routine in routines:
            montant = routine.calculer_montant(cycle.nombre_sujets_actuels)
            result.append({
                'id': str(routine.id),
                'nom': routine.nom,
                'age_jour': routine.age_jour,
                'categorie': routine.categorie_depense.nom if routine.categorie_depense else None,
                'mode_calcul': routine.mode_calcul,
                'montant_calcule': montant,
                'est_obligatoire': routine.est_obligatoire,
            })

        return Response({
            'cycle_id': str(cycle.id),
            'cycle_nom': cycle.nom,
            'age_actuel': age,
            'nb_poulets': cycle.nombre_sujets_actuels,
            'nb_routines': len(result),
            'routines': result
        })

    @action(detail=False, methods=['post'])
    def appliquer(self, request):
        """
        Applique une ou plusieurs routines à un cycle
        Body : { cycle_id: "...", routine_ids: ["...", "..."] }
        """
        cycle_id = request.data.get('cycle_id')
        routine_ids = request.data.get('routine_ids', [])

        if not cycle_id or not routine_ids:
            return Response({'error': 'cycle_id et routine_ids requis'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            cycle = Cycle.objects.get(id=cycle_id)
        except Cycle.DoesNotExist:
            return Response({'error': 'Cycle introuvable'}, status=status.HTTP_404_NOT_FOUND)

        resultats = []
        with transaction.atomic():
            for routine_id in routine_ids:
                try:
                    routine = RoutineDepense.objects.get(id=routine_id, is_active=True)
                except RoutineDepense.DoesNotExist:
                    resultats.append({'routine_id': routine_id, 'status': 'ERREUR', 'message': 'Routine introuvable'})
                    continue

                # Vérifier si déjà appliquée
                if RoutineAppliquee.objects.filter(routine=routine, cycle=cycle).exists():
                    resultats.append({'routine_id': routine_id, 'status': 'DEJA_APPLIQUEE'})
                    continue

                # Calculer le montant
                montant = routine.calculer_montant(cycle.nombre_sujets_actuels)

                # Créer la dépense
                depense = Depense.objects.create(
                    cycle=cycle,
                    categorie_depense=routine.categorie_depense,
                    montant=montant,
                    date=timezone.now().date(),
                    description=f"[ROUTINE] {routine.nom} (J{routine.age_jour})",
                    est_depense_routine=True,
                    routine_id=routine.id,
                    created_by=request.user
                )

                # Marquer comme appliquée
                RoutineAppliquee.objects.create(
                    routine=routine,
                    cycle=cycle,
                    depense_generee=depense,
                    montant_calcule=montant,
                    nb_poulets_au_moment=cycle.nombre_sujets_actuels,
                    confirmee_par=request.user
                )

                resultats.append({
                    'routine_id': str(routine_id),
                    'routine_nom': routine.nom,
                    'status': 'APPLIQUEE',
                    'montant': montant,
                    'depense_id': str(depense.id)
                })

        return Response({'resultats': resultats}, status=status.HTTP_200_OK)


class DepenseViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des dépenses.
    """
    queryset = Depense.objects.filter(is_deleted=False)
    serializer_class = DepenseSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['cycle', 'categorie', 'categorie_depense', 'date', 'est_depense_routine']
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
        if self.request.user.is_staff:
            return Depense.objects.filter(is_deleted=False)
        return Depense.objects.filter(created_by=self.request.user, is_deleted=False)

    @transaction.atomic
    def perform_create(self, serializer):
        depense = serializer.save(created_by=self.request.user)

        # Vérifier si le cycle est archivé
        if depense.cycle and depense.cycle.is_archived:
            raise ValidationError({'cycle': 'Ce cycle est clôturé. Aucune dépense possible.'})

    @action(detail=False, methods=['get'])
    def statistiques(self, request):
        total = Depense.objects.filter(is_deleted=False).aggregate(total=Sum('montant'))['total'] or 0
        par_categorie = Depense.objects.filter(is_deleted=False).values('categorie_depense__nom').annotate(total=Sum('montant')).order_by('-total')
        mois_courant = timezone.now().month
        annee_courante = timezone.now().year
        depenses_mois = Depense.objects.filter(is_deleted=False, date__month=mois_courant, date__year=annee_courante).aggregate(total=Sum('montant'))['total'] or 0
        data = {
            'total_depenses': total,
            'depenses_mois_courant': depenses_mois,
            'par_categorie': list(par_categorie),
            'nombre_transactions': Depense.objects.filter(is_deleted=False).count()
        }
        return Response(data)

    @action(detail=True, methods=['post'])
    def supprimer(self, request, pk=None):
        depense = self.get_object()
        depense.is_deleted = True
        depense.save()
        return Response({'message': 'Dépense supprimée.'})