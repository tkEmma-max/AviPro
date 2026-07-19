# cycles/views.py
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from .models import Cycle, TypePoulet, SousBande, Migration
from poulaillers.models import Poulailler
from .serializers import (
    CycleSerializer, CycleListSerializer, CycleDetailSerializer,
    CycleStatsSerializer, TypePouletSerializer,
    SousBandeSerializer, MigrationSerializer
)
from .services import PrevisionService


class TypePouletViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les types de poulets.
    - Utilisateurs authentifiés : GET (lecture seule)
    - Admin : GET, POST, PUT, DELETE
    """
    queryset = TypePoulet.objects.filter(is_active=True)
    serializer_class = TypePouletSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def get_queryset(self):
        if self.request.user.is_staff and self.request.query_params.get('show_all'):
            return TypePoulet.objects.all()
        return TypePoulet.objects.filter(is_active=True)


class CycleViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des cycles.
    - Utilisateurs : CRUD sur leurs propres cycles
    - Admin : accès à TOUS les cycles
    """
    queryset = Cycle.objects.filter(is_deleted=False)
    serializer_class = CycleSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['poulailler', 'type', 'type_poulet', 'is_active', 'is_archived']
    search_fields = ['nom', 'poulailler__nom']
    ordering_fields = ['-date_debut', 'created_at']
    ordering = ['-date_debut']

    def get_serializer_class(self):
        if self.action == 'list':
            return CycleListSerializer
        elif self.action == 'retrieve':
            return CycleDetailSerializer
        return CycleSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return Cycle.objects.filter(is_deleted=False)
        return Cycle.objects.filter(created_by=self.request.user, is_deleted=False)

    def perform_create(self, serializer):
        cycle = serializer.save(created_by=self.request.user)
        SousBande.objects.create(
            cycle=cycle,
            poulailler=cycle.poulailler,
            nombre_sujets=cycle.nombre_sujets_initiaux
        )

    @action(detail=True, methods=['get'])
    def stats(self, request, pk=None):
        cycle = self.get_object()
        serializer = CycleStatsSerializer(cycle)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def archiver(self, request, pk=None):
        cycle = self.get_object()
        cycle.is_archived = True
        cycle.is_active = False
        cycle.date_fin = timezone.now().date()
        cycle.save()
        return Response({'message': 'Cycle archivé avec succès.'})

    @action(detail=True, methods=['post'])
    def activer(self, request, pk=None):
        cycle = self.get_object()
        cycle.is_active = True
        cycle.is_archived = False
        cycle.save()
        return Response({'message': 'Cycle activé avec succès.'})

    @action(detail=True, methods=['post'])
    def enregistrer_mortalite(self, request, pk=None):
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
        sous_bande = cycle.sous_bandes.filter(est_active=True).first()
        if sous_bande:
            sous_bande.nombre_sujets -= nb_morts
            if sous_bande.nombre_sujets <= 0:
                sous_bande.nombre_sujets = 0
                sous_bande.est_active = False
            sous_bande.save()
        return Response({
            'message': f'{nb_morts} mortalité(s) enregistrée(s).',
            'sujets_restants': cycle.nombre_sujets_actuels
        })

    @action(detail=False, methods=['get'])
    def previsions(self, request):
        type_poulet_id = request.query_params.get('type_poulet_id')
        nb_sujets = request.query_params.get('nb_sujets')
        if not type_poulet_id:
            return Response({'error': 'type_poulet_id requis'}, status=status.HTTP_400_BAD_REQUEST)
        if not nb_sujets:
            return Response({'error': 'nb_sujets requis'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            nb_sujets = int(nb_sujets)
        except ValueError:
            return Response({'error': 'nb_sujets doit être un nombre'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            type_poulet = TypePoulet.objects.get(id=type_poulet_id)
        except TypePoulet.DoesNotExist:
            return Response({'error': 'Type de poulet introuvable'}, status=status.HTTP_404_NOT_FOUND)
        age_debut = request.query_params.get('age_debut')
        age_fin = request.query_params.get('age_fin')
        if age_debut is not None:
            try:
                age_debut = int(age_debut)
            except ValueError:
                age_debut = 0
        if age_fin is not None:
            try:
                age_fin = int(age_fin)
            except ValueError:
                age_fin = None
        service = PrevisionService(
            type_poulet=type_poulet,
            nb_sujets=nb_sujets,
            age_debut=age_debut,
            age_fin=age_fin
        )
        previsions = service.get_previsions()
        return Response(previsions)

    @action(detail=True, methods=['post'])
    def migrer(self, request, pk=None):
        cycle = self.get_object()
        poulailler_cible_id = request.data.get('poulailler_cible')
        nombre_sujets = request.data.get('nombre_sujets')
        raison = request.data.get('raison', '')
        if not poulailler_cible_id:
            return Response({'error': 'poulailler_cible requis'}, status=status.HTTP_400_BAD_REQUEST)
        if not nombre_sujets or int(nombre_sujets) <= 0:
            return Response({'error': 'nombre_sujets doit être > 0'}, status=status.HTTP_400_BAD_REQUEST)
        nombre_sujets = int(nombre_sujets)
        try:
            poulailler_cible = Poulailler.objects.get(id=poulailler_cible_id)
        except Poulailler.DoesNotExist:
            return Response({'error': 'Poulailler cible introuvable'}, status=status.HTTP_404_NOT_FOUND)
        sous_bande_source = cycle.sous_bandes.filter(est_active=True).first()
        if not sous_bande_source:
            return Response({'error': 'Aucune sous-bande active trouvée'}, status=status.HTTP_400_BAD_REQUEST)
        if nombre_sujets > sous_bande_source.nombre_sujets:
            return Response(
                {'error': f'Pas assez de sujets. Disponible: {sous_bande_source.nombre_sujets}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        conflit = SousBande.objects.filter(
            poulailler=poulailler_cible, est_active=True
        ).exclude(cycle=cycle).exists()
        if conflit:
            return Response(
                {'error': 'Le poulailler cible est déjà occupé par un autre cycle'},
                status=status.HTTP_400_BAD_REQUEST
            )
        alerte_age = False
        sous_bande_existante = cycle.sous_bandes.filter(
            poulailler=poulailler_cible, est_active=True
        ).first()
        if sous_bande_existante:
            alerte_age = True
        age = cycle.jours_ecoules
        if nombre_sujets == sous_bande_source.nombre_sujets:
            sous_bande_source.est_active = False
        sous_bande_source.nombre_sujets -= nombre_sujets
        sous_bande_source.save()
        if sous_bande_existante:
            sous_bande_existante.nombre_sujets += nombre_sujets
            sous_bande_existante.save()
        else:
            SousBande.objects.create(
                cycle=cycle,
                poulailler=poulailler_cible,
                nombre_sujets=nombre_sujets
            )
        Migration.objects.create(
            cycle=cycle,
            poulailler_source=sous_bande_source.poulailler,
            poulailler_cible=poulailler_cible,
            nombre_sujets=nombre_sujets,
            age_sujets=age,
            raison=raison,
            created_by=request.user
        )
        return Response({
            'message': f'{nombre_sujets} sujets migrés vers {poulailler_cible.nom}',
            'age_sujets': age,
            'alerte_age': alerte_age,
            'sous_bandes': SousBandeSerializer(
                cycle.sous_bandes.filter(est_active=True), many=True
            ).data
        })

    @action(detail=True, methods=['get'])
    def sous_bandes(self, request, pk=None):
        cycle = self.get_object()
        sous_bandes = cycle.sous_bandes.filter(est_active=True)
        return Response(SousBandeSerializer(sous_bandes, many=True).data)

    @action(detail=True, methods=['get'])
    def historique_migrations(self, request, pk=None):
        cycle = self.get_object()
        migrations = cycle.migrations.all().order_by('-date')
        return Response(MigrationSerializer(migrations, many=True).data)

    @action(detail=True, methods=['post'])
    def declarer_perte(self, request, pk=None):
        cycle = self.get_object()
        nb_morts = request.data.get('nombre', 0)
        if nb_morts <= 0:
            return Response(
                {'error': 'Le nombre de pertes doit être supérieur à 0.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        if nb_morts > cycle.nombre_sujets_actuels:
            return Response(
                {'error': f'Il n\'y a que {cycle.nombre_sujets_actuels} sujets actifs.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        raison = request.data.get('raison', 'Mortalité déclarée')
        cycle.nb_morts += nb_morts
        cycle.save()
        sous_bande = cycle.sous_bandes.filter(est_active=True).first()
        if sous_bande:
            sous_bande.nombre_sujets -= nb_morts
            if sous_bande.nombre_sujets <= 0:
                sous_bande.nombre_sujets = 0
                sous_bande.est_active = False
            sous_bande.save()
        if cycle.nombre_sujets_actuels <= 0:
            cycle.is_active = False
            cycle.is_archived = True
            cycle.date_fin = timezone.now().date()
            cycle.save()
        from depenses.models import Depense, CategorieDepense
        categorie, _ = CategorieDepense.objects.get_or_create(nom='Pertes')
        prix_unitaire = cycle.cout_production_unitaire if cycle.cout_production_unitaire > 0 else 500
        Depense.objects.create(
            cycle=cycle,
            categorie_depense=categorie,
            montant=int(nb_morts * prix_unitaire),
            date=timezone.now().date(),
            description=f'Perte de {nb_morts} sujets : {raison}',
            created_by=request.user
        )
        return Response({
            'message': f'{nb_morts} perte(s) déclarée(s).',
            'sujets_restants': cycle.nombre_sujets_actuels,
            'total_morts': cycle.nb_morts,
            'depense_creee': True
        })