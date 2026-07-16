# backend/peupler_db.py
"""
Script pour peupler la base de données avec des données de test réalistes.
Utilisation : python manage.py shell < peupler_db.py
Ou : copier-coller dans python manage.py shell
"""
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
import django
django.setup()

from django.utils import timezone
from datetime import date, timedelta
from users.models import User
from poulaillers.models import Poulailler
from cycles.models import Cycle, TypePoulet, SousBande
from depenses.models import Depense, CategorieDepense
from ventes.models import Vente, TypeVente
from rapports.models import RapportSuivi
import random

# ═══════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════
USER_EMAIL = 'admin@avipro.com'
NB_POULAILLERS = 3
NB_CYCLES = 4

# ═══════════════════════════════════════════════
# RÉCUPÉRER L'UTILISATEUR
# ═══════════════════════════════════════════════
try:
    user = User.objects.get(email=USER_EMAIL)
    print(f'✅ Utilisateur : {user.email}')
except User.DoesNotExist:
    print(f'❌ Utilisateur {USER_EMAIL} introuvable. Créez-le d\'abord.')
    exit()

# ═══════════════════════════════════════════════
# CRÉER TYPES DE POULETS
# ═══════════════════════════════════════════════
type_chair, _ = TypePoulet.objects.get_or_create(
    nom='Poulet de chair',
    defaults={'duree_estimee_jours': 45, 'densite_recommandee': 8.0, 'prix_poussin_moyen': 500}
)
type_pondeuse, _ = TypePoulet.objects.get_or_create(
    nom='Poule pondeuse',
    defaults={'duree_estimee_jours': 490, 'densite_recommandee': 6.0, 'prix_poussin_moyen': 1500}
)
print(f'✅ Types de poulets créés')

# ═══════════════════════════════════════════════
# CRÉER CATÉGORIES DE DÉPENSES
# ═══════════════════════════════════════════════
categories_data = [
    ('POUSSIN', 'Achat de poussins'),
    ('ALIMENT', 'Aliment'),
    ('VACCIN', 'Vaccins et médicaments'),
    ('LITIERE', 'Litière'),
    ('TRANSPORT', 'Transport'),
    ('CHAUFFAGE', 'Chauffage'),
    ('EAU', 'Eau'),
    ('MAIN_OEUVRE', "Main d'œuvre"),
]
categories = {}
for code, nom in categories_data:
    cat, _ = CategorieDepense.objects.get_or_create(nom=nom)
    categories[code] = cat
print(f'✅ {len(categories)} catégories de dépenses créées')

# ═══════════════════════════════════════════════
# CRÉER TYPES DE VENTES
# ═══════════════════════════════════════════════
types_vente_data = ['POULETS', 'OEUFS', 'POUSSINS', 'POULE_REFORME', 'FIANTES']
types_vente = {}
for tv in types_vente_data:
    vt, _ = TypeVente.objects.get_or_create(nom=tv)
    types_vente[tv] = vt
print(f'✅ Types de ventes créés')

# ═══════════════════════════════════════════════
# CRÉER POULAILLERS
# ═══════════════════════════════════════════════
poulaillers = []
for i in range(1, NB_POULAILLERS + 1):
    p, created = Poulailler.objects.get_or_create(
        nom=f'Poulailler {chr(64+i)}',
        defaults={
            'longueur': random.choice([8, 10, 12]),
            'largeur': random.choice([4, 5, 6]),
            'nombre_mangeoires': random.randint(4, 8),
            'nombre_abreuvoirs': random.randint(2, 5),
            'localisation': f'Bâtiment {i}',
            'created_by': user,
        }
    )
    poulaillers.append(p)
    print(f'  🏠 {p.nom} ({p.surface}m²) - {"créé" if created else "existant"}')

# ═══════════════════════════════════════════════
# CRÉER CYCLES (avec dates dans le passé)
# ═══════════════════════════════════════════════
aujourdhui = date.today()

cycles_data = [
    # (nom, poulailler_idx, type, nb_sujets, date_debut_offset_jours, duree, est_archive)
    ('Bande Chair Mars', 0, type_chair, 300, -35, 45, False),   # Cycle en cours J35
    ('Bande Chair Février', 1, type_chair, 250, -60, 45, True),  # Cycle terminé
    ('Pondeuses Avril', 2, type_pondeuse, 200, -30, 490, False), # Cycle en cours J30
    ('Bande Chair Janvier', 0, type_chair, 400, -90, 45, True),  # Cycle terminé
]

cycles_crees = []
for nom, p_idx, tp, nb, offset, duree, archive in cycles_data:
    debut = aujourdhui + timedelta(days=offset)
    fin = debut + timedelta(days=duree) if archive else None

    c, created = Cycle.objects.get_or_create(
        nom=nom,
        poulailler=poulaillers[p_idx],
        defaults={
            'type_poulet': tp,
            'date_debut': debut,
            'date_fin': fin,
            'nombre_sujets_initiaux': nb,
            'nombre_sujets_actuels': nb - random.randint(5, 20) if archive else nb,
            'duree_estimee_jours': duree,
            'is_active': not archive,
            'is_archived': archive,
            'created_by': user,
        }
    )
    cycles_crees.append(c)

    # Créer sous-bande si nouvelle
    if created:
        SousBande.objects.create(cycle=c, poulailler=c.poulailler, nombre_sujets=c.nombre_sujets_actuels)

    status = 'Archivé' if archive else 'Actif'
    print(f'  🐔 {c.nom} - {c.nombre_sujets_actuels} sujets - J{c.jours_ecoules} - {status}')

# ═══════════════════════════════════════════════
# CRÉER DÉPENSES POUR CHAQUE CYCLE
# ═══════════════════════════════════════════════
depenses_data = [
    # (cycle_idx, categorie_code, montant_par_sujet, jour_offset, description)
    (0, 'POUSSIN', 500, 0, 'Achat poussins'),
    (0, 'ALIMENT', 0, 0, 'Aliment démarrage'),
    (0, 'VACCIN', 100, 1, 'Vaccin J1'),
    (0, 'CHAUFFAGE', 0, 0, 'Chauffage 3 semaines'),
    (0, 'ALIMENT', 0, 14, 'Aliment croissance'),
    (0, 'VACCIN', 100, 21, 'Vaccin J21'),
    (1, 'POUSSIN', 500, 0, 'Achat poussins'),
    (1, 'ALIMENT', 0, 0, 'Aliment total'),
    (1, 'VACCIN', 100, 1, 'Vaccins'),
    (1, 'TRANSPORT', 0, 0, 'Transport poussins'),
    (2, 'POUSSIN', 1500, 0, 'Achat poulettes'),
    (2, 'ALIMENT', 0, 0, 'Aliment ponte'),
    (3, 'POUSSIN', 500, 0, 'Achat poussins'),
    (3, 'ALIMENT', 0, 0, 'Aliment total'),
    (3, 'VACCIN', 100, 1, 'Vaccins'),
]

for cycle_idx, cat_code, mps, offset_j, desc in depenses_data:
    cycle = cycles_crees[cycle_idx]
    montant = mps * cycle.nombre_sujets_initiaux if mps > 0 else random.randint(20000, 80000)
    date_depense = cycle.date_debut + timedelta(days=offset_j)

    Depense.objects.get_or_create(
        cycle=cycle,
        categorie_depense=categories[cat_code],
        date=date_depense,
        defaults={
            'montant': montant,
            'description': desc,
            'created_by': user,
        }
    )

total_depenses = Depense.objects.filter(created_by=user, is_deleted=False).count()
print(f'✅ {total_depenses} dépenses créées')

# ═══════════════════════════════════════════════
# CRÉER VENTES POUR LES CYCLES ARCHIVÉS
# ═══════════════════════════════════════════════
ventes_data = [
    # (cycle_idx, type_vente, nb, prix_unitaire, offset_j)
    (1, 'POULETS', 100, 3500, 40),
    (1, 'POULETS', 120, 3400, 43),
    (1, 'POULETS', 25, 3300, 45),
    (3, 'POULETS', 180, 3500, 40),
    (3, 'POULETS', 195, 3400, 43),
]

for cycle_idx, tv, nb, prix, offset_j in ventes_data:
    cycle = cycles_crees[cycle_idx]
    date_vente = cycle.date_debut + timedelta(days=offset_j)

    Vente.objects.get_or_create(
        cycle=cycle,
        type_vente=types_vente[tv],
        date=date_vente,
        defaults={
            'quantite': nb,
            'prix_unitaire': prix,
            'montant_total': nb * prix,
            'created_by': user,
        }
    )

total_ventes = Vente.objects.filter(created_by=user, is_deleted=False).count()
print(f'✅ {total_ventes} ventes créées')

# ═══════════════════════════════════════════════
# CRÉER RAPPORTS DE SUIVI
# ═══════════════════════════════════════════════
for cycle in cycles_crees:
    nb_rapports = random.randint(1, 3)
    for r in range(nb_rapports):
        offset = 7 * (r + 1)
        debut = cycle.date_debut + timedelta(days=offset)
        fin = debut + timedelta(days=7)

        if fin > aujourdhui:
            continue

        aliment = round(random.uniform(0.03, 0.08) * cycle.nombre_sujets_actuels * 7, 1)
        eau = round(aliment * random.uniform(1.8, 2.5), 1)

        RapportSuivi.objects.get_or_create(
            cycle=cycle,
            periode_debut=debut,
            periode_fin=fin,
            defaults={
                'aliment_consomme': aliment,
                'eau_consommee': eau,
                'observations': random.choice([
                    'Bonne croissance, pas de problème',
                    'Légère baisse de consommation',
                    'Comportement normal',
                    'Quelques éternuements observés',
                    'Bon état général',
                ]),
                'created_by': user,
            }
        )

total_rapports = RapportSuivi.objects.filter(created_by=user, is_deleted=False).count()
print(f'✅ {total_rapports} rapports créés')

# ═══════════════════════════════════════════════
# RÉSUMÉ
# ═══════════════════════════════════════════════
print('\n' + '='*50)
print('📊 RÉSUMÉ DU PEUPLEMENT')
print('='*50)
print(f'👤 Utilisateur : {user.email}')
print(f'🏠 Poulaillers : {len(poulaillers)}')
print(f'🐔 Cycles      : {len(cycles_crees)} ({sum(1 for c in cycles_crees if c.is_active)} actifs, {sum(1 for c in cycles_crees if c.is_archived)} archivés)')
print(f'💰 Dépenses    : {total_depenses}')
print(f'💵 Ventes      : {total_ventes}')
print(f'📋 Rapports    : {total_rapports}')
print('='*50)
print('✅ Peuplement terminé ! Lance l\'appli et admire le dashboard ! 🚀')