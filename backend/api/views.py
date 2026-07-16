# api/views.py
from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone

# Imports des modèles (absolus - avec le nom du projet)
from users.models import User
from poulaillers.models import Poulailler
from cycles.models import Cycle
from depenses.models import Depense
from ventes.models import Vente
from prets.models import Pret, Echeance, RemboursementPret

# Imports des serializers
from users.serializers import UserSerializer
from .serializers import SyncRequestSerializer


# ============ AUTHENTIFICATION ============
class CustomTokenObtainPairView(TokenObtainPairView):
    """Vue personnalisée pour l'obtention du token JWT"""
    permission_classes = [AllowAny]


class RegisterView(generics.CreateAPIView):
    """Vue d'inscription d'un nouvel utilisateur"""
    queryset = User.objects.all()
    permission_classes = [AllowAny]
    serializer_class = UserSerializer


# ============ STATISTIQUES GLOBALES ============
class StatsView(APIView):
    """Vue pour les statistiques globales"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Cycles
        nb_cycles_actifs = Cycle.objects.filter(
            is_active=True, is_archived=False, is_deleted=False
        ).count()
        nb_cycles_total = Cycle.objects.filter(is_deleted=False).count()

        # Poulaillers
        nb_poulaillers_occupees = 0
        for p in Poulailler.objects.filter(is_deleted=False):
            if p.statut == 'OCCUPÉ':
                nb_poulaillers_occupees += 1
        nb_poulaillers_total = Poulailler.objects.filter(is_deleted=False).count()

        # Finances
        total_depenses = Depense.objects.filter(is_deleted=False).aggregate(
            total=Sum('montant')
        )['total'] or 0

        total_ventes = Vente.objects.filter(is_deleted=False).aggregate(
            total=Sum('montant_total')
        )['total'] or 0

        solde = total_ventes - total_depenses

        # Prêts
        total_prets_restants = Pret.objects.filter(
            is_rembourse=False, is_deleted=False
        ).aggregate(total=Sum('montant_restant'))['total'] or 0

        nb_prets_actifs = Pret.objects.filter(
            is_rembourse=False, is_deleted=False
        ).count()

        data = {
            'cycles': {
                'actifs': nb_cycles_actifs,
                'total': nb_cycles_total
            },
            'poulaillers': {
                'occupes': nb_poulaillers_occupees,
                'total': nb_poulaillers_total
            },
            'finances': {
                'total_depenses': total_depenses,
                'total_ventes': total_ventes,
                'solde': solde,
                'est_positif': solde >= 0
            },
            'prets': {
                'restant_dû': total_prets_restants,
                'prets_actifs': nb_prets_actifs
            }
        }
        return Response(data)


# ============ SYNCHRONISATION ============
class SyncView(APIView):
    """
    Endpoint de synchronisation des données entre le mobile et le backend
    """
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        """
        Reçoit les opérations du mobile, les traite, et renvoie les mises à jour du serveur
        """
        serializer = SyncRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        server_ops = []
        conflicts = []
        processed = []

        # 1. Traiter les opérations du client
        for op in data['ops']:
            try:
                model_name = op['model']
                operation = op['operation']
                op_data = op['data']
                op_id = str(op['id'])

                # Traiter selon le modèle
                if model_name == 'Poulailler':
                    self._process_poulailler(operation, op_data, request.user)
                elif model_name == 'Cycle':
                    self._process_cycle(operation, op_data, request.user)
                elif model_name == 'Depense':
                    self._process_depense(operation, op_data, request.user)
                elif model_name == 'Vente':
                    self._process_vente(operation, op_data, request.user)
                elif model_name == 'Pret':
                    self._process_pret(operation, op_data, request.user)
                elif model_name == 'Echeance':
                    self._process_echeance(operation, op_data, request.user)
                elif model_name == 'RemboursementPret':
                    self._process_remboursement(operation, op_data, request.user)
                elif model_name == 'Client':
                    self._process_client(operation, op_data, request.user)
                elif model_name == 'Fournisseur':
                    self._process_fournisseur(operation, op_data, request.user)
                elif model_name == 'RapportSuivi':
                    self._process_rapport(operation, op_data, request.user)
                else:
                    raise ValueError(f"Modèle inconnu: {model_name}")

                processed.append(op_id)

            except Exception as e:
                # Gérer les erreurs (conflits)
                conflicts.append({
                    'id': op.get('id', ''),
                    'model': op.get('model', ''),
                    'error': str(e)
                })

        # 2. Récupérer les opérations du serveur (modifications faites ailleurs)
        since = data['timestamp']
        server_ops = self._get_server_ops(since, request.user)

        # 3. Mettre à jour les timestamps de synchronisation
        self._update_sync_timestamps(processed, since)

        return Response({
            'timestamp': timezone.now().isoformat(),
            'server_ops': server_ops,
            'conflicts': conflicts,
            'processed': processed
        }, status=status.HTTP_200_OK)

    # ============ PROCESSUS DES OPÉRATIONS ============

    def _process_poulailler(self, operation, data, user):
        from backend.poulaillers.models import Poulailler

        if operation == 'CREATE':
            Poulailler.objects.create(
                id=data['id'],
                nom=data['nom'],
                longueur=data['longueur'],
                largeur=data['largeur'],
                hauteur=data.get('hauteur'),
                localisation=data.get('localisation'),
                type_sol=data.get('type_sol'),
                nombre_mangeoires=data.get('nombre_mangeoires', 0),
                nombre_abreuvoirs=data.get('nombre_abreuvoirs', 0),
                created_by=user
            )
        elif operation == 'UPDATE':
            Poulailler.objects.filter(id=data['id']).update(
                nom=data.get('nom'),
                longueur=data.get('longueur'),
                largeur=data.get('largeur'),
                hauteur=data.get('hauteur'),
                localisation=data.get('localisation'),
                type_sol=data.get('type_sol'),
                nombre_mangeoires=data.get('nombre_mangeoires'),
                nombre_abreuvoirs=data.get('nombre_abreuvoirs'),
                is_archived=data.get('is_archived', False)
            )
        elif operation == 'DELETE':
            Poulailler.objects.filter(id=data['id']).update(is_deleted=True)

    def _process_cycle(self, operation, data, user):
        from backend.cycles.models import Cycle

        if operation == 'CREATE':
            Cycle.objects.create(
                id=data['id'],
                poulailler_id=data['poulailler'],
                nom=data['nom'],
                type=data['type'],
                date_debut=data['date_debut'],
                date_fin=data.get('date_fin'),
                nombre_sujets_initiaux=data['nombre_sujets_initiaux'],
                nombre_sujets_actuels=data['nombre_sujets_actuels'],
                duree_estimee_jours=data['duree_estimee_jours'],
                is_active=data.get('is_active', True),
                created_by=user
            )
        elif operation == 'UPDATE':
            Cycle.objects.filter(id=data['id']).update(
                nom=data.get('nom'),
                type=data.get('type'),
                date_debut=data.get('date_debut'),
                date_fin=data.get('date_fin'),
                nombre_sujets_initiaux=data.get('nombre_sujets_initiaux'),
                nombre_sujets_actuels=data.get('nombre_sujets_actuels'),
                duree_estimee_jours=data.get('duree_estimee_jours'),
                is_active=data.get('is_active', True),
                is_archived=data.get('is_archived', False)
            )
        elif operation == 'DELETE':
            Cycle.objects.filter(id=data['id']).update(is_deleted=True)

    def _process_depense(self, operation, data, user):
        from backend.depenses.models import Depense

        if operation == 'CREATE':
            Depense.objects.create(
                id=data['id'],
                cycle_id=data['cycle'],
                categorie=data['categorie'],
                montant=data['montant'],
                date=data['date'],
                description=data.get('description'),
                facture_numero=data.get('facture_numero'),
                facture_photo=data.get('facture_photo'),
                fournisseur_id=data.get('fournisseur'),
                created_by=user
            )
        elif operation == 'UPDATE':
            Depense.objects.filter(id=data['id']).update(
                categorie=data.get('categorie'),
                montant=data.get('montant'),
                date=data.get('date'),
                description=data.get('description'),
                facture_numero=data.get('facture_numero'),
                facture_photo=data.get('facture_photo'),
                fournisseur_id=data.get('fournisseur')
            )
        elif operation == 'DELETE':
            Depense.objects.filter(id=data['id']).update(is_deleted=True)

    def _process_vente(self, operation, data, user):
        from backend.ventes.models import Vente

        if operation == 'CREATE':
            Vente.objects.create(
                id=data['id'],
                cycle_id=data['cycle'],
                type=data['type'],
                quantite=data['quantite'],
                prix_unitaire=data['prix_unitaire'],
                montant_total=data.get('montant_total', data['quantite'] * data['prix_unitaire']),
                date=data['date'],
                description=data.get('description'),
                client_id=data.get('client'),
                facture_numero=data.get('facture_numero'),
                facture_photo=data.get('facture_photo'),
                signature=data.get('signature'),
                remboursement_confirme=data.get('remboursement_confirme', False),
                created_by=user
            )
        elif operation == 'UPDATE':
            Vente.objects.filter(id=data['id']).update(
                type=data.get('type'),
                quantite=data.get('quantite'),
                prix_unitaire=data.get('prix_unitaire'),
                montant_total=data.get('montant_total'),
                date=data.get('date'),
                description=data.get('description'),
                client_id=data.get('client'),
                facture_numero=data.get('facture_numero'),
                facture_photo=data.get('facture_photo'),
                signature=data.get('signature'),
                remboursement_confirme=data.get('remboursement_confirme', False)
            )
        elif operation == 'DELETE':
            Vente.objects.filter(id=data['id']).update(is_deleted=True)

    def _process_pret(self, operation, data, user):
        from backend.prets.models import Pret

        if operation == 'CREATE':
            Pret.objects.create(
                id=data['id'],
                preteur=data['preteur'],
                type_preteur=data['type_preteur'],
                montant_total=data['montant_total'],
                date_deblocage=data['date_deblocage'],
                taux_interet=data.get('taux_interet', 0),
                mode_remboursement=data['mode_remboursement'],
                duree_totale_mois=data.get('duree_totale_mois'),
                periodicite=data.get('periodicite'),
                montant_restant=data['montant_total'],
                created_by=user
            )
        elif operation == 'UPDATE':
            Pret.objects.filter(id=data['id']).update(
                preteur=data.get('preteur'),
                type_preteur=data.get('type_preteur'),
                montant_total=data.get('montant_total'),
                date_deblocage=data.get('date_deblocage'),
                taux_interet=data.get('taux_interet'),
                mode_remboursement=data.get('mode_remboursement'),
                duree_totale_mois=data.get('duree_totale_mois'),
                periodicite=data.get('periodicite'),
                is_rembourse=data.get('is_rembourse', False)
            )
        elif operation == 'DELETE':
            Pret.objects.filter(id=data['id']).update(is_deleted=True)

    def _process_echeance(self, operation, data, user):
        from backend.prets.models import Echeance

        if operation == 'CREATE':
            Echeance.objects.create(
                id=data['id'],
                pret_id=data['pret'],
                date_echeance=data['date_echeance'],
                montant_due=data['montant_due'],
                est_payee=data.get('est_payee', False),
                date_paiement=data.get('date_paiement')
            )
        elif operation == 'UPDATE':
            Echeance.objects.filter(id=data['id']).update(
                date_echeance=data.get('date_echeance'),
                montant_due=data.get('montant_due'),
                est_payee=data.get('est_payee', False),
                date_paiement=data.get('date_paiement')
            )
        elif operation == 'DELETE':
            Echeance.objects.filter(id=data['id']).delete()

    def _process_remboursement(self, operation, data, user):
        from backend.prets.models import RemboursementPret

        if operation == 'CREATE':
            RemboursementPret.objects.create(
                id=data['id'],
                pret_id=data['pret'],
                montant=data['montant'],
                date=data['date'],
                source=data.get('source'),
                cycle_source_id=data.get('cycle_source'),
                vente_source_id=data.get('vente_source'),
                echeance_id=data.get('echeance'),
                description=data.get('description'),
                is_manually_confirmed=data.get('is_manually_confirmed', False),
                created_by=user
            )
        elif operation == 'UPDATE':
            RemboursementPret.objects.filter(id=data['id']).update(
                montant=data.get('montant'),
                date=data.get('date'),
                source=data.get('source'),
                cycle_source_id=data.get('cycle_source'),
                vente_source_id=data.get('vente_source'),
                echeance_id=data.get('echeance'),
                description=data.get('description'),
                is_manually_confirmed=data.get('is_manually_confirmed', False)
            )
        elif operation == 'DELETE':
            RemboursementPret.objects.filter(id=data['id']).delete()

    def _process_client(self, operation, data, user):
        from backend.clients.models import Client

        if operation == 'CREATE':
            Client.objects.create(
                id=data['id'],
                nom=data['nom'],
                telephone=data.get('telephone'),
                adresse=data.get('adresse'),
                type_client=data.get('type_client'),
                created_by=user
            )
        elif operation == 'UPDATE':
            Client.objects.filter(id=data['id']).update(
                nom=data.get('nom'),
                telephone=data.get('telephone'),
                adresse=data.get('adresse'),
                type_client=data.get('type_client')
            )
        elif operation == 'DELETE':
            Client.objects.filter(id=data['id']).update(is_deleted=True)

    def _process_fournisseur(self, operation, data, user):
        from backend.fournisseurs.models import Fournisseur

        if operation == 'CREATE':
            Fournisseur.objects.create(
                id=data['id'],
                nom=data['nom'],
                telephone=data.get('telephone'),
                adresse=data.get('adresse'),
                type_fournisseur=data.get('type_fournisseur'),
                created_by=user
            )
        elif operation == 'UPDATE':
            Fournisseur.objects.filter(id=data['id']).update(
                nom=data.get('nom'),
                telephone=data.get('telephone'),
                adresse=data.get('adresse'),
                type_fournisseur=data.get('type_fournisseur')
            )
        elif operation == 'DELETE':
            Fournisseur.objects.filter(id=data['id']).update(is_deleted=True)

    def _process_rapport(self, operation, data, user):
        from backend.rapports.models import RapportSuivi

        if operation == 'CREATE':
            RapportSuivi.objects.create(
                id=data['id'],
                cycle_id=data['cycle'],
                periode_debut=data['periode_debut'],
                periode_fin=data['periode_fin'],
                aliment_consomme=data.get('aliment_consomme', 0),
                eau_consommee=data.get('eau_consommee', 0),
                maladie_observee=data.get('maladie_observee'),
                medicaments_administres=data.get('medicaments_administres'),
                nb_sujets_malades=data.get('nb_sujets_malades', 0),
                observations=data.get('observations'),
                created_by=user
            )
        elif operation == 'UPDATE':
            RapportSuivi.objects.filter(id=data['id']).update(
                periode_debut=data.get('periode_debut'),
                periode_fin=data.get('periode_fin'),
                aliment_consomme=data.get('aliment_consomme', 0),
                eau_consommee=data.get('eau_consommee', 0),
                maladie_observee=data.get('maladie_observee'),
                medicaments_administres=data.get('medicaments_administres'),
                nb_sujets_malades=data.get('nb_sujets_malades', 0),
                observations=data.get('observations')
            )
        elif operation == 'DELETE':
            RapportSuivi.objects.filter(id=data['id']).update(is_deleted=True)

    # ============ RÉCUPÉRATION DES OPÉRATIONS SERVEUR ============

    def _get_server_ops(self, since, user):
        """Récupère les modifications faites sur le serveur depuis un timestamp"""
        server_ops = []
        timestamp = since

        # Récupérer les modifications de chaque modèle
        from backend.poulaillers.models import Poulailler
        from backend.cycles.models import Cycle
        from backend.depenses.models import Depense
        from backend.ventes.models import Vente
        from backend.prets.models import Pret, Echeance, RemboursementPret
        from backend.clients.models import Client
        from backend.fournisseurs.models import Fournisseur
        from backend.rapports.models import RapportSuivi

        # Poulaillers
        for obj in Poulailler.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'Poulailler',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'nom': obj.nom,
                    'longueur': float(obj.longueur),
                    'largeur': float(obj.largeur),
                    'hauteur': float(obj.hauteur) if obj.hauteur else None,
                    'localisation': obj.localisation,
                    'type_sol': obj.type_sol,
                    'nombre_mangeoires': obj.nombre_mangeoires,
                    'nombre_abreuvoirs': obj.nombre_abreuvoirs,
                    'is_archived': obj.is_archived
                }
            })

        # Cycles
        for obj in Cycle.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'Cycle',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'poulailler': str(obj.poulailler.id),
                    'nom': obj.nom,
                    'type': obj.type,
                    'date_debut': obj.date_debut.isoformat(),
                    'date_fin': obj.date_fin.isoformat() if obj.date_fin else None,
                    'nombre_sujets_initiaux': obj.nombre_sujets_initiaux,
                    'nombre_sujets_actuels': obj.nombre_sujets_actuels,
                    'duree_estimee_jours': obj.duree_estimee_jours,
                    'is_active': obj.is_active,
                    'is_archived': obj.is_archived
                }
            })

        # Dépenses
        for obj in Depense.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'Depense',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'cycle': str(obj.cycle.id),
                    'categorie': obj.categorie,
                    'montant': float(obj.montant),
                    'date': obj.date.isoformat(),
                    'description': obj.description,
                    'facture_numero': obj.facture_numero,
                    'facture_photo': obj.facture_photo,
                    'fournisseur': str(obj.fournisseur.id) if obj.fournisseur else None
                }
            })

        # Ventes
        for obj in Vente.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'Vente',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'cycle': str(obj.cycle.id),
                    'type': obj.type,
                    'quantite': float(obj.quantite),
                    'prix_unitaire': float(obj.prix_unitaire),
                    'montant_total': float(obj.montant_total),
                    'date': obj.date.isoformat(),
                    'description': obj.description,
                    'client': str(obj.client.id) if obj.client else None,
                    'facture_numero': obj.facture_numero,
                    'facture_photo': obj.facture_photo,
                    'signature': obj.signature,
                    'remboursement_confirme': obj.remboursement_confirme
                }
            })

        # Prêts
        for obj in Pret.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'Pret',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'preteur': obj.preteur,
                    'type_preteur': obj.type_preteur,
                    'montant_total': float(obj.montant_total),
                    'date_deblocage': obj.date_deblocage.isoformat(),
                    'taux_interet': float(obj.taux_interet),
                    'mode_remboursement': obj.mode_remboursement,
                    'duree_totale_mois': obj.duree_totale_mois,
                    'periodicite': obj.periodicite,
                    'montant_restant': float(obj.montant_restant),
                    'is_rembourse': obj.is_rembourse
                }
            })

        # Échéances
        for obj in Echeance.objects.filter(created_at__gt=timestamp):
            server_ops.append({
                'model': 'Echeance',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'pret': str(obj.pret.id),
                    'date_echeance': obj.date_echeance.isoformat(),
                    'montant_due': float(obj.montant_due),
                    'est_payee': obj.est_payee,
                    'date_paiement': obj.date_paiement.isoformat() if obj.date_paiement else None
                }
            })

        # Remboursements
        for obj in RemboursementPret.objects.filter(created_at__gt=timestamp):
            server_ops.append({
                'model': 'RemboursementPret',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'pret': str(obj.pret.id),
                    'montant': float(obj.montant),
                    'date': obj.date.isoformat(),
                    'source': obj.source,
                    'cycle_source': str(obj.cycle_source.id) if obj.cycle_source else None,
                    'vente_source': str(obj.vente_source.id) if obj.vente_source else None,
                    'echeance': str(obj.echeance.id) if obj.echeance else None,
                    'description': obj.description,
                    'is_manually_confirmed': obj.is_manually_confirmed
                }
            })

        # Clients
        for obj in Client.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'Client',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'nom': obj.nom,
                    'telephone': obj.telephone,
                    'adresse': obj.adresse,
                    'type_client': obj.type_client
                }
            })

        # Fournisseurs
        for obj in Fournisseur.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'Fournisseur',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'nom': obj.nom,
                    'telephone': obj.telephone,
                    'adresse': obj.adresse,
                    'type_fournisseur': obj.type_fournisseur
                }
            })

        # Rapports
        for obj in RapportSuivi.objects.filter(updated_at__gt=timestamp, is_deleted=False):
            server_ops.append({
                'model': 'RapportSuivi',
                'operation': 'CREATE' if obj.created_at > timestamp else 'UPDATE',
                'data': {
                    'id': str(obj.id),
                    'cycle': str(obj.cycle.id),
                    'periode_debut': obj.periode_debut.isoformat(),
                    'periode_fin': obj.periode_fin.isoformat(),
                    'aliment_consomme': float(obj.aliment_consomme),
                    'eau_consommee': float(obj.eau_consommee),
                    'maladie_observee': obj.maladie_observee,
                    'medicaments_administres': obj.medicaments_administres,
                    'nb_sujets_malades': obj.nb_sujets_malades,
                    'observations': obj.observations
                }
            })

        return server_ops

    def _update_sync_timestamps(self, processed, since):
        """Met à jour les timestamps de synchronisation"""
        from backend.depenses.models import Depense
        from backend.ventes.models import Vente
        from backend.rapports.models import RapportSuivi

        # Mettre à jour synced_at pour les modèles qui ont ce champ
        for model in [Depense, Vente, RapportSuivi]:
            model.objects.filter(id__in=processed).update(synced_at=timezone.now())



# ═══════════════════════════════════════════════
# PEUPLEMENT DE LA BASE (ENDPOINT TEMPORAIRE)
# ═══════════════════════════════════════════════
class PeuplerDBView(APIView):
    """Endpoint temporaire pour peupler la base de données de test"""
    permission_classes = [AllowAny]

    def get(self, request):
        email = request.query_params.get('email', 'admin@avipro.com')
        from datetime import date, timedelta
        import random

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': f'Utilisateur {email} introuvable'}, status=404)

        aujourdhui = date.today()
        result = {'actions': []}

        # Types de poulets
        from cycles.models import TypePoulet, SousBande
        type_chair, _ = TypePoulet.objects.get_or_create(nom='Poulet de chair', defaults={'duree_estimee_jours': 45, 'densite_recommandee': 8.0, 'prix_poussin_moyen': 500})
        type_pondeuse, _ = TypePoulet.objects.get_or_create(nom='Poule pondeuse', defaults={'duree_estimee_jours': 490, 'densite_recommandee': 6.0, 'prix_poussin_moyen': 1500})
        result['actions'].append('Types poulets OK')

        # Catégories
        from depenses.models import CategorieDepense
        cats = {}
        for code, nom in [('POUSSIN', 'Achat de poussins'), ('ALIMENT', 'Aliment'), ('VACCIN', 'Vaccins'), ('LITIERE', 'Litière'), ('TRANSPORT', 'Transport'), ('CHAUFFAGE', 'Chauffage')]:
            cats[code], _ = CategorieDepense.objects.get_or_create(nom=nom)
        result['actions'].append('Categories OK')

        # Poulaillers
        poulaillers = []
        for i, (nom, l, la) in enumerate([('Poulailler A', 10, 5), ('Poulailler B', 8, 4), ('Poulailler C', 12, 6)]):
            p, _ = Poulailler.objects.get_or_create(nom=nom, defaults={'longueur': l, 'largeur': la, 'nombre_mangeoires': 5, 'nombre_abreuvoirs': 3, 'created_by': user})
            poulaillers.append(p)
        result['actions'].append(f'{len(poulaillers)} poulaillers')

        # Cycles
        cycles = []
        configs = [
            ('Bande Chair Mars', poulaillers[0], type_chair, 300, -35, 45, False),
            ('Bande Chair Février', poulaillers[1], type_chair, 250, -60, 45, True),
            ('Pondeuses Avril', poulaillers[2], type_pondeuse, 200, -30, 490, False),
            ('Bande Chair Janvier', poulaillers[0], type_chair, 400, -90, 45, True),
        ]
        for nom, poul, tp, nb, offset, duree, archive in configs:
            debut = aujourdhui + timedelta(days=offset)
            fin = debut + timedelta(days=duree) if archive else None
            c, created = Cycle.objects.get_or_create(nom=nom, poulailler=poul, defaults={
                'type_poulet': tp, 'date_debut': debut, 'date_fin': fin,
                'nombre_sujets_initiaux': nb, 'nombre_sujets_actuels': nb - random.randint(5, 15) if archive else nb,
                'duree_estimee_jours': duree, 'is_active': not archive, 'is_archived': archive, 'created_by': user,
            })
            if created:
                SousBande.objects.create(cycle=c, poulailler=c.poulailler, nombre_sujets=c.nombre_sujets_actuels)
            cycles.append(c)
        result['actions'].append(f'{len(cycles)} cycles')

        # Dépenses
        dep_configs = [
            (cycles[0], cats['POUSSIN'], 500 * 300, 'Achat poussins', 0),
            (cycles[0], cats['ALIMENT'], 80000, 'Aliment demarrage', 0),
            (cycles[0], cats['VACCIN'], 30000, 'Vaccin J1', 1),
            (cycles[0], cats['CHAUFFAGE'], 25000, 'Chauffage', 0),
            (cycles[0], cats['ALIMENT'], 60000, 'Aliment croissance', 14),
            (cycles[0], cats['VACCIN'], 30000, 'Vaccin J21', 21),
            (cycles[1], cats['POUSSIN'], 500 * 250, 'Achat poussins', 0),
            (cycles[1], cats['ALIMENT'], 120000, 'Aliment total', 0),
            (cycles[1], cats['VACCIN'], 25000, 'Vaccins', 1),
            (cycles[1], cats['TRANSPORT'], 15000, 'Transport', 0),
            (cycles[2], cats['POUSSIN'], 1500 * 200, 'Achat poulettes', 0),
            (cycles[2], cats['ALIMENT'], 90000, 'Aliment ponte', 0),
            (cycles[3], cats['POUSSIN'], 500 * 400, 'Achat poussins', 0),
            (cycles[3], cats['ALIMENT'], 180000, 'Aliment total', 0),
            (cycles[3], cats['VACCIN'], 40000, 'Vaccins', 1),
        ]
        for cycle, cat, montant, desc, offset_j in dep_configs:
            Depense.objects.get_or_create(cycle=cycle, categorie_depense=cat, date=cycle.date_debut + timedelta(days=offset_j), defaults={'montant': montant, 'description': desc, 'created_by': user})
        result['actions'].append(f'{len(dep_configs)} depenses')

        # Ventes
        from ventes.models import Vente
        for cycle_idx, nb, prix, offset_j in [(1, 100, 3500, 40), (1, 120, 3400, 43), (3, 180, 3500, 40), (3, 195, 3400, 43)]:
            Vente.objects.get_or_create(cycle=cycles[cycle_idx], date=cycles[cycle_idx].date_debut + timedelta(days=offset_j), defaults={'quantite': nb, 'prix_unitaire': prix, 'montant_total': nb * prix, 'created_by': user})
        result['actions'].append('4 ventes')

        # Rapports
        from rapports.models import RapportSuivi
        nb_rap = 0
        for cycle in cycles:
            for r in range(random.randint(1, 2)):
                offset = 7 * (r + 1)
                debut = cycle.date_debut + timedelta(days=offset)
                fin = debut + timedelta(days=7)
                if fin > aujourdhui: continue
                aliment = round(random.uniform(0.04, 0.07) * cycle.nombre_sujets_actuels * 7, 1)
                RapportSuivi.objects.get_or_create(cycle=cycle, periode_debut=debut, periode_fin=fin, defaults={'aliment_consomme': aliment, 'eau_consommee': round(aliment * 2, 1), 'observations': 'Rapport auto', 'created_by': user})
                nb_rap += 1
        result['actions'].append(f'{nb_rap} rapports')

        result['status'] = 'success'
        result['message'] = f'Base peuplée pour {user.email} ! Rafraîchis le dashboard !'
        return Response(result)