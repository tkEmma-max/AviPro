# backend/notifications/services.py
from django.utils import timezone
from datetime import timedelta
from .models import Notification


class NotificationService:
    """Service de génération automatique des notifications."""

    @staticmethod
    def _notifier(user, type_notif, titre, message, donnees=None):
        """Crée une notification sans doublon (même type + mêmes données)."""
        filtre = Notification.objects.filter(
            user=user,
            type=type_notif,
            est_lue=False,
        )
        if donnees:
            filtre = filtre.filter(donnees=donnees)
        
        if not filtre.exists():
            Notification.objects.create(
                user=user,
                type=type_notif,
                titre=titre,
                message=message,
                donnees=donnees or {},
            )

    # ═══════════════════════════════════════════
    # ÉCHÉANCES DE PRÊTS
    # ═══════════════════════════════════════════
    @staticmethod
    def verifier_echeances(pret):
        """Vérifie les échéances d'un prêt et crée des notifications si nécessaire."""
        from prets.models import Echeance
        echeances = Echeance.objects.filter(pret=pret, est_payee=False)
        aujourdhui = timezone.now().date()

        for echeance in echeances:
            jours_restants = (echeance.date_echeance - aujourdhui).days

            if jours_restants < 0:
                type_notif = 'ECHEANCE_RETARD'
                titre = f'Échéance en retard'
                message = f'L\'échéance du prêt « {pret.pret_texte} » est en retard de {abs(jours_restants)} jour(s) ({echeance.montant:,.0f} FCFA).'
            elif jours_restants == 0:
                type_notif = 'ECHEANCE_JOURJ'
                titre = 'Échéance aujourd\'hui'
                message = f'L\'échéance du prêt « {pret.pret_texte} » est aujourd\'hui ({echeance.montant:,.0f} FCFA).'
            elif jours_restants == 1:
                type_notif = 'ECHEANCE_J1'
                titre = 'Échéance demain'
                message = f'L\'échéance du prêt « {pret.pret_texte} » est demain ({echeance.montant:,.0f} FCFA).'
            elif jours_restants == 3:
                type_notif = 'ECHEANCE_J3'
                titre = 'Échéance dans 3 jours'
                message = f'L\'échéance du prêt « {pret.pret_texte} » est dans 3 jours ({echeance.montant:,.0f} FCFA).'
            elif jours_restants == 7:
                type_notif = 'ECHEANCE_J7'
                titre = 'Échéance dans 7 jours'
                message = f'L\'échéance du prêt « {pret.pret_texte} » est dans 7 jours ({echeance.montant:,.0f} FCFA).'
            else:
                continue  # Pas dans la fenêtre de notification

            NotificationService._notifier(
                user=pret.created_by,
                type_notif=type_notif,
                titre=titre,
                message=message,
                donnees={'pret_id': str(pret.id), 'echeance_id': str(echeance.id)},
            )

    # ═══════════════════════════════════════════
    # ALERTE DENSITÉ
    # ═══════════════════════════════════════════
    @staticmethod
    def verifier_densite(poulailler, cycle):
        """Alerte si la densité dépasse la recommandation."""
        if poulailler.surface <= 0 or cycle.nombre_sujets_actuels <= 0:
            return

        densite = cycle.nombre_sujets_actuels / poulailler.surface
        densite_recommandee = 8.0  # Valeur par défaut
        if cycle.type_poulet and cycle.type_poulet.densite_recommandee:
            densite_recommandee = float(cycle.type_poulet.densite_recommandee)

        if densite > densite_recommandee:
            NotificationService._notifier(
                user=cycle.created_by,
                type_notif='DENSITE',
                titre='Densité critique',
                message=f'Le poulailler « {poulailler.nom} » a une densité de {densite:.1f} sujets/m² (recommandé: {densite_recommandee:.0f}).',
                donnees={'poulailler_id': str(poulailler.id), 'cycle_id': str(cycle.id)},
            )

    # ═══════════════════════════════════════════
    # ALERTE CONSOMMATION
    # ═══════════════════════════════════════════
    @staticmethod
    def verifier_consommation(cycle):
        """Alerte si baisse ou hausse anormale de consommation."""
        from rapports.models import RapportSuivi
        rapports = RapportSuivi.objects.filter(cycle=cycle).order_by('-date_debut')

        if rapports.count() < 2:
            return  # Besoin d'au moins 2 rapports pour comparer

        dernier = rapports.first()
        precedent = rapports[1]

        if precedent.consommation_eau > 0:
            variation_eau = (dernier.consommation_eau - precedent.consommation_eau) / precedent.consommation_eau * 100
            if abs(variation_eau) > 25:
                sens = "Hausse" if variation_eau > 0 else "Baisse"
                NotificationService._notifier(
                    user=cycle.created_by,
                    type_notif='CONSOMMATION',
                    titre=f'{sens} anormale de consommation d\'eau',
                    message=f'{sens} de {abs(variation_eau):.0f}% de l\'eau consommée sur le cycle « {cycle.nom} ».',
                    donnees={'cycle_id': str(cycle.id)},
                )

        if precedent.consommation_aliment > 0:
            variation_aliment = (dernier.consommation_aliment - precedent.consommation_aliment) / precedent.consommation_aliment * 100
            if abs(variation_aliment) > 25:
                sens = "Hausse" if variation_aliment > 0 else "Baisse"
                NotificationService._notifier(
                    user=cycle.created_by,
                    type_notif='CONSOMMATION',
                    titre=f'{sens} anormale de consommation d\'aliment',
                    message=f'{sens} de {abs(variation_aliment):.0f}% de l\'aliment consommé sur le cycle « {cycle.nom} ».',
                    donnees={'cycle_id': str(cycle.id)},
                )

    # ═══════════════════════════════════════════
    # RAPPEL RAPPORT
    # ═══════════════════════════════════════════
    @staticmethod
    def verifier_rappel_rapport(cycle):
        """Rappel si aucun rapport soumis depuis 7 jours."""
        from rapports.models import RapportSuivi
        dernier_rapport = RapportSuivi.objects.filter(cycle=cycle).order_by('-date_debut').first()
        aujourdhui = timezone.now().date()

        if dernier_rapport is None:
            jours_sans_rapport = (aujourdhui - cycle.date_debut).days
        else:
            jours_sans_rapport = (aujourdhui - dernier_rapport.date_debut).days

        if jours_sans_rapport >= 7:
            NotificationService._notifier(
                user=cycle.created_by,
                type_notif='RAPPEL_RAPPORT',
                titre='Rappel de rapport',
                message=f'Aucun rapport soumis depuis {jours_sans_rapport} jours pour le cycle « {cycle.nom} ».',
                donnees={'cycle_id': str(cycle.id)},
            )

    # ═══════════════════════════════════════════
    # FIN DE CYCLE
    # ═══════════════════════════════════════════
    @staticmethod
    def verifier_fin_cycle(cycle):
        """Alerte à J-7 et J-3 avant la fin estimée du cycle."""
        if not cycle.is_active or cycle.is_archived:
            return

        jours_ecoules = cycle.jours_ecoules
        jours_restants = cycle.duree_estimee_jours - jours_ecoules

        if jours_restants in (7, 3):
            NotificationService._notifier(
                user=cycle.created_by,
                type_notif='FIN_CYCLE',
                titre=f'Fin de cycle dans {jours_restants} jours',
                message=f'Le cycle « {cycle.nom} » se termine dans {jours_restants} jours. Préparez la clôture.',
                donnees={'cycle_id': str(cycle.id)},
            )

    # ═══════════════════════════════════════════
    # PRÊT FLEXIBLE (rappel mensuel)
    # ═══════════════════════════════════════════
    @staticmethod
    def verifier_pret_flexible(pret):
        """Rappel mensuel pour les prêts flexibles non remboursés."""
        if not pret.est_flexible:
            return

        if pret.capital_restant_du > 0:
            NotificationService._notifier(
                user=pret.created_by,
                type_notif='PRET_FLEXIBLE',
                titre='Rappel prêt flexible',
                message=f'Le prêt flexible « {pret.pret_texte} » a encore {pret.capital_restant_du:,.0f} FCFA à rembourser.',
                donnees={'pret_id': str(pret.id)},
            )

    # ═══════════════════════════════════════════
    # SUGGESTION D'OPTIMISATION
    # ═══════════════════════════════════════════
    @staticmethod
    def verifier_suggestions(cycle):
        """Suggère des optimisations basées sur l'historique."""
        if cycle.type_poulet is None:
            return

        cycles_precedents = type(cycle).objects.filter(
            created_by=cycle.created_by,
            type_poulet=cycle.type_poulet,
            is_archived=True,
        ).exclude(id=cycle.id)

        if cycles_precedents.exists() and cycle.cout_production_unitaire > 0:
            cout_moyen = sum(c.cout_production_unitaire for c in cycles_precedents) / cycles_precedents.count()
            if cycle.cout_production_unitaire > cout_moyen * 1.2:
                NotificationService._notifier(
                    user=cycle.created_by,
                    type_notif='SUGGESTION',
                    titre='Coût de production élevé',
                    message=f'Votre coût de production ({cycle.cout_production_unitaire:,.0f} FCFA) dépasse de 20% la moyenne de vos cycles précédents ({cout_moyen:,.0f} FCFA).',
                    donnees={'cycle_id': str(cycle.id)},
                )