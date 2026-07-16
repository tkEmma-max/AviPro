# cycles/services.py
from django.db.models import Sum
from depenses.models import Depense
from rapports.models import RapportSuivi
from .models import Cycle


class PrevisionService:
    """
    Service de calcul des prévisions pour un cycle.
    Utilise les cycles terminés et les rapports de suivi.
    """

    def __init__(self, type_poulet, nb_sujets, age_debut=None, age_fin=None):
        self.type_poulet = type_poulet
        self.nb_sujets = nb_sujets
        self.age_debut = age_debut if age_debut is not None else 0
        self.age_fin = age_fin

    def get_previsions(self):
        """Retourne les prévisions complètes"""
        cycles_historique = self._get_cycles_historique()
        rapports_historique = self._get_rapports_historique()

        nb_cycles = cycles_historique.count()
        nb_rapports = rapports_historique.count()

        methode, fiabilite = self._get_methode_fiabilite(nb_cycles, nb_rapports)

        if nb_cycles == 0 and nb_rapports == 0:
            return {
                'type_poulet': self.type_poulet.nom if self.type_poulet else 'Inconnu',
                'nb_sujets': self.nb_sujets,
                'methode': 'AUCUNE',
                'fiabilite': 'INDISPONIBLE',
                'message': "Aucune donnée historique disponible. Les prévisions seront disponibles après avoir complété au moins un cycle avec des rapports de suivi réguliers.",
                'nb_cycles_historique': 0,
                'nb_rapports_utilises': 0,
                'consommations': None,
                'depenses': None,
                'ventes': None,
                'benefice_previsionnel': None,
                'mortalite_estimee': None,
            }

        consommations = self._prevoir_consommations(rapports_historique, nb_rapports)
        depenses = self._prevoir_depenses(cycles_historique, nb_cycles)
        ventes = self._prevoir_ventes(cycles_historique, nb_cycles)
        mortalite = self._prevoir_mortalite(cycles_historique, nb_cycles)
        benefice = (ventes['total'] or 0) - (depenses['total'] or 0)

        duree_estimee = self.type_poulet.duree_estimee_jours if self.type_poulet else 45

        return {
            'type_poulet': self.type_poulet.nom if self.type_poulet else 'Inconnu',
            'periode': {
                'debut': self.age_debut,
                'fin': self.age_fin if self.age_fin else duree_estimee,
                'jours': (self.age_fin or duree_estimee) - self.age_debut
            },
            'nb_sujets': self.nb_sujets,
            'nb_cycles_historique': nb_cycles,
            'nb_rapports_utilises': nb_rapports,
            'methode': methode,
            'fiabilite': fiabilite,
            'consommations': consommations,
            'depenses': depenses,
            'ventes': ventes,
            'benefice_previsionnel': round(benefice) if benefice else None,
            'cout_production_unitaire': round(depenses['total'] / self.nb_sujets) if depenses['total'] and self.nb_sujets > 0 else None,
            'mortalite_estimee': round(mortalite, 1) if mortalite else None,
            'duree_estimee_jours': duree_estimee,
            'message': self._get_message(nb_cycles, nb_rapports, fiabilite),
        }

    def _get_cycles_historique(self):
        return Cycle.objects.filter(
            type_poulet=self.type_poulet,
            is_archived=True,
            is_deleted=False
        )

    def _get_rapports_historique(self):
        rapports = RapportSuivi.objects.filter(
            cycle__type_poulet=self.type_poulet,
            cycle__is_archived=True,
            cycle__is_deleted=False,
            is_deleted=False
        )

        if self.age_fin is not None:
            rapports_filtres = []
            for rapport in rapports:
                age_debut = rapport.age_debut
                age_fin = rapport.age_fin
                if age_fin >= self.age_debut and age_debut <= self.age_fin:
                    rapports_filtres.append(rapport.id)
            rapports = rapports.filter(id__in=rapports_filtres)

        return rapports

    def _get_methode_fiabilite(self, nb_cycles, nb_rapports):
        if nb_cycles == 0:
            if nb_rapports == 0:
                return 'AUCUNE', 'INDISPONIBLE'
            elif nb_rapports < 5:
                return 'RAPPORTS_SEULS', 'FAIBLE'
            else:
                return 'RAPPORTS_SEULS', 'MOYENNE'
        elif nb_cycles == 1:
            if nb_rapports < 5:
                return 'REGLE_DE_3', 'FAIBLE'
            else:
                return 'REGLE_DE_3', 'MOYENNE'
        elif nb_cycles <= 3:
            if nb_rapports < 10:
                return 'MOYENNE_SIMPLE', 'MOYENNE'
            else:
                return 'MOYENNE_SIMPLE', 'BONNE'
        else:
            if nb_rapports < 15:
                return 'MOYENNE_PONDEREE', 'BONNE'
            else:
                return 'MOYENNE_PONDEREE', 'ELEVEE'

    def _prevoir_consommations(self, rapports, nb_rapports):
        if nb_rapports == 0:
            return None

        total_aliment = 0
        total_eau = 0
        total_ratio = 0
        count_ratio = 0

        for rapport in rapports:
            total_aliment += rapport.aliment_par_sujet_par_jour
            total_eau += rapport.eau_par_sujet_par_jour
            ratio = rapport.ratio_eau_aliment
            if ratio > 0:
                total_ratio += ratio
                count_ratio += 1

        aliment_par_jour = total_aliment / nb_rapports
        eau_par_jour = total_eau / nb_rapports
        ratio_moyen = total_ratio / count_ratio if count_ratio > 0 else 0

        duree = (self.age_fin or self.type_poulet.duree_estimee_jours) - self.age_debut

        return {
            'aliment_par_sujet_par_jour': round(aliment_par_jour, 3),
            'eau_par_sujet_par_jour': round(eau_par_jour, 3),
            'ratio_eau_aliment': round(ratio_moyen, 2),
            'aliment_total_estime': round(aliment_par_jour * self.nb_sujets * duree, 1),
            'eau_total_estimee': round(eau_par_jour * self.nb_sujets * duree, 1),
        }

    def _prevoir_depenses(self, cycles, nb_cycles):
        if nb_cycles == 0:
            return {'total': None, 'par_categorie': [], 'message': 'Aucun cycle terminé'}

        depenses_par_sujet = []
        for cycle in cycles:
            if cycle.nombre_sujets_initiaux > 0:
                depenses_par_sujet.append(float(cycle.total_depenses) / cycle.nombre_sujets_initiaux)

        if nb_cycles == 1:
            total = round(depenses_par_sujet[0] * self.nb_sujets)
        elif nb_cycles <= 3:
            total = round(sum(depenses_par_sujet) / len(depenses_par_sujet) * self.nb_sujets)
        else:
            poids = list(range(1, len(depenses_par_sujet) + 1))
            moyenne_ponderee = sum(d * p for d, p in zip(depenses_par_sujet, poids)) / sum(poids)
            total = round(moyenne_ponderee * self.nb_sujets)

        par_categorie = []
        try:
            categories = Depense.objects.filter(
                cycle__in=cycles,
                is_deleted=False,
                categorie_depense__isnull=False
            ).values('categorie_depense__nom').annotate(
                total=Sum('montant')
            ).order_by('-total')

            for cat in categories[:5]:
                nom = cat['categorie_depense__nom'] or 'Non catégorisé'
                par_categorie.append({
                    'categorie': nom,
                    'montant_estime': round(cat['total'] / nb_cycles),
                })
        except Exception:
            pass

        return {
            'total': total,
            'par_categorie': par_categorie,
        }

    def _prevoir_ventes(self, cycles, nb_cycles):
        if nb_cycles == 0:
            return {'total': None, 'par_type': [], 'message': 'Aucun cycle terminé'}

        ventes_par_sujet = []
        for cycle in cycles:
            if cycle.nombre_sujets_actuels > 0:
                ventes_par_sujet.append(float(cycle.total_ventes) / cycle.nombre_sujets_actuels)

        if nb_cycles == 1:
            total = round(ventes_par_sujet[0] * self.nb_sujets)
        elif nb_cycles <= 3:
            total = round(sum(ventes_par_sujet) / len(ventes_par_sujet) * self.nb_sujets)
        else:
            poids = list(range(1, len(ventes_par_sujet) + 1))
            moyenne_ponderee = sum(d * p for d, p in zip(ventes_par_sujet, poids)) / sum(poids)
            total = round(moyenne_ponderee * self.nb_sujets)

        return {
            'total': total,
            'par_type': [],
        }

    def _prevoir_mortalite(self, cycles, nb_cycles):
        if nb_cycles == 0:
            return None

        taux = [float(c.taux_mortalite) for c in cycles if c.taux_mortalite > 0]
        if not taux:
            return 0

        return sum(taux) / len(taux)

    def _get_message(self, nb_cycles, nb_rapports, fiabilite):
        messages = {
            'INDISPONIBLE': "Aucune donnée disponible. Lancez un cycle complet et soumettez des rapports de suivi réguliers pour obtenir des prévisions.",
            'FAIBLE': "Peu de données disponibles. Les prévisions sont approximatives.",
            'MOYENNE': "Données suffisantes. Les prévisions sont raisonnablement fiables.",
            'BONNE': "Bonne base de données. Les prévisions sont fiables.",
            'ELEVEE': "Excellente base de données. Les prévisions sont très fiables !",
        }

        if nb_rapports == 0 and nb_cycles > 0:
            return "Vous avez des cycles terminés mais aucun rapport de suivi. Les rapports permettent d'affiner les prévisions de consommation."

        return messages.get(fiabilite, "")