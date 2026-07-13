# backend/recreate_test_data.py
"""
Script pour recréer les données de test dans Django Shell.
Exécuter avec : python manage.py shell < recreate_test_data.py
"""

from django.contrib.auth import get_user_model
from poulaillers.models import Poulailler
from cycles.models import Cycle
from depenses.models import Depense
from ventes.models import Vente
from datetime import date
import uuid

User = get_user_model()

print("=" * 50)
print("🔄 RECRÉATION DES DONNÉES DE TEST")
print("=" * 50)

# ============================================================
# 1. RÉCUPÉRER OU CRÉER L'UTILISATEUR
# ============================================================
user, created = User.objects.get_or_create(
    email='t@gmail.com',
    defaults={
        'first_name': 'Test',
        'last_name': 'User',
        'is_active': True,
        'is_staff': True,
        'is_superuser': True,
    }
)

if created:
    user.set_password('tester')
    user.save()
    print("✅ Utilisateur 't@gmail.com' créé")
else:
    print("✅ Utilisateur 't@gmail.com' déjà existant")

# ============================================================
# 2. SUPPRIMER LES ANCIENNES DONNÉES (optionnel)
# ============================================================
print("\n🗑️  Suppression des anciennes données...")
Poulailler.objects.filter(created_by=user).delete()
Cycle.objects.filter(created_by=user).delete()
Depense.objects.filter(created_by=user).delete()
Vente.objects.filter(created_by=user).delete()
print("✅ Anciennes données supprimées")

# ============================================================
# 3. CRÉER UN POULAILLER
# ============================================================
print("\n🏠 Création du poulailler...")
poulailler = Poulailler.objects.create(
    id=uuid.uuid4(),
    nom='Poulailler Test',
    longueur=10.0,
    largeur=8.0,
    hauteur=3.0,
    localisation='Test Location',
    type_sol='Ciment',
    nombre_mangeoires=4,
    nombre_abreuvoirs=6,
    created_by=user,
)
print(f"✅ Poulailler créé : {poulailler.nom} (ID: {poulailler.id})")

# ============================================================
# 4. CRÉER UN CYCLE
# ============================================================
print("\n🔄 Création du cycle...")
cycle = Cycle.objects.create(
    id=uuid.uuid4(),
    poulailler=poulailler,
    nom='Cycle Test',
    type='CHAIR',
    date_debut=date(2026, 7, 13),
    nombre_sujets_initiaux=50,
    nombre_sujets_actuels=50,
    duree_estimee_jours=45,
    created_by=user,
)
print(f"✅ Cycle créé : {cycle.nom} (ID: {cycle.id})")

# ============================================================
# 5. CRÉER UNE DÉPENSE
# ============================================================
print("\n💸 Création d'une dépense...")
depense = Depense.objects.create(
    id=uuid.uuid4(),
    cycle=cycle,
    categorie='ALIMENT',
    montant=25000,
    date=date(2026, 7, 13),
    description='Achat aliment test',
    created_by=user,
)
print(f"✅ Dépense créée : {depense.get_categorie_display()} - {depense.montant} FCFA")

# ============================================================
# 6. CRÉER UNE VENTE
# ============================================================
print("\n💰 Création d'une vente...")
vente = Vente.objects.create(
    id=uuid.uuid4(),
    cycle=cycle,
    type='POULETS',
    quantite=10,
    prix_unitaire=3000,
    montant_total=30000,
    date=date(2026, 7, 13),
    description='Vente test',
    created_by=user,
)
print(f"✅ Vente créée : {vente.get_type_display()} - {vente.montant_total} FCFA")

# ============================================================
# 7. RÉSUMÉ FINAL
# ============================================================
print("\n" + "=" * 50)
print("📊 RÉSUMÉ DES DONNÉES CRÉÉES")
print("=" * 50)
print(f"👤 Utilisateur : {user.email}")
print(f"🏠 Poulailler : {poulailler.nom}")
print(f"🔄 Cycle      : {cycle.nom} ({cycle.nombre_sujets_initiaux} sujets)")
print(f"💸 Dépense    : {depense.montant} FCFA")
print(f"💰 Vente      : {vente.montant_total} FCFA")
print("=" * 50)
print("✅ Toutes les données de test ont été recréées !")