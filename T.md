
# 📋 DOCUMENT DE PASSATION — AVIPRO

---

## 1. VISION DU PROJET

**AviPro** est une application mobile de gestion avicole pour les éleveurs de poulets (chair, pondeuse, local).

**Objectif :** Traçabilité absolue, prévisions intelligentes, gestion des prêts, utilisable par des non-techniciens.

**Philosophie :**
- L'utilisateur ne doit JAMAIS voir d'écran blanc ou de loader géant (cache mémoire partout)
- L'utilisateur se connecte UNE SEULE FOIS (comme DeepSeek/WhatsApp)
- Toutes les fonctionnalités doivent être CRUDables (admin peut tout modifier)
- Le backend anticipe le futur (champs metadata, modèles marketplace, mobile money)

**État actuel (29 Juillet 2026) :** Backend 100% terminé, Frontend MVP 95% terminé.

---

## 2. ARCHITECTURE TECHNIQUE

| Composant | Technologie |
|-----------|-------------|
| Mobile | Flutter/Dart |
| State management | Provider |
| HTTP | Dio (intercepteur JWT + refresh auto) |
| Backend | Django + Django REST Framework |
| Base de données | PostgreSQL sur Render |
| Authentification | JWT (Simple JWT), session persistante |
| Cache local | Mémoire statique (30s) |
| Design system | lib/core/theme/ |

**URL Render :** `https://avipro-backend.onrender.com/api/`

**Compte admin :** `admin@avipro.com` / `Avipro2026!`

---

## 3. ARBORESCENCE BACKEND (backend/)



backend/
├── api/              (auth, sync, stats, peuplement)
├── backend/          (settings.py, urls.py, wsgi.py)
├── cycles/           (Cycle, TypePoulet, SousBande, Migration, PrevisionService)
├── poulaillers/      (Poulailler)
├── depenses/         (Depense, CategorieDepense, RoutineDepense, RoutineAppliquee)
├── ventes/           (Vente, TypeVente)
├── prets/            (Pret, Echeance, RemboursementPret)
├── rapports/         (RapportSuivi, TypeMaladie)
├── clients/          (Client)
├── fournisseurs/     (Fournisseur)
├── users/            (User, ParametreUtilisateur)
├── stock/            (ProduitStock, MouvementStock)
├── sync/             (PendingSync)
├── build.sh          (script de build Render)
├── requirements.txt  (psycopg2-binary obligatoire)
└── runtime.txt       (python-3.12.0)

```

---

## 4. ARBORESCENCE FRONTEND (lib/)

```

lib/
├── main.dart
├── core/
│   ├── constants/    (app_constants.dart, app_icons.dart)
│   └── theme/        (app_colors, app_text_styles, app_spacing, app_borders, app_shadows, app_theme)
├── models/           (poulailler, cycle, depense, vente, pret, rapport)
├── providers/        (auth, poulailler, cycle, depense, vente, pret, rapport)
├── services/         (api_service, densite_service, equipement_service, local_db_service, sync_service)
├── screens/
│   ├── login/register/splash/home/profile_settings
│   ├── poulaillers/  (list, create, detail, edit, migration)
│   ├── cycles/       (list, create, detail, edit, report_form, report_history, performance_report)
│   ├── finances/     (hub, depense, vente, loan_dashboard, loan_create, loan_detail)
│   └── rapports/     (list, detail)
└── widgets/          (custom_button, custom_text_field, custom_search_field, stat_card, quick_action_card)



---

## 5. MODÈLES DJANGO PRINCIPAUX

### Poulailler
- id, nom, longueur, largeur, surface (@property)
- statut (@property via SousBande), nb_poulets_actuels (@property via SousBande)
- densite_actuelle (@property)

### Cycle
- id, nom, poulailler (FK), type_poulet (FK TypePoulet)
- date_debut, nombre_sujets_initiaux, duree_estimee_jours
- nb_morts, nb_mangeoires, nb_abreuvoirs
- jours_ecoules (@property), progression (@property)
- total_depenses (@property), total_ventes (@property), benefice (@property)
- nombre_sujets_actuels (@property via SousBande)

### SousBande
- cycle (FK), poulailler (FK), nombre_sujets, est_active

### Vente
- cycle (FK), type_vente (FK TypeVente), quantite, prix_unitaire, date
- vendeur, client
- prix_de_revient (@property), marge_unitaire (@property)
- pourcentage_benefice (@property), status_vente (@property)
- potentiel_restant (@property), poulailler_nom (@property)

### Depense
- cycle (FK), categorie_depense (FK CategorieDepense), montant, date
- cumul_depenses_avant (@property), prix_revient_apres (@property)
- impact_pourcentage (@property), poulailler_nom (@property)

### Pret
- preteur, type_preteur, montant_total, taux_interet
- type_taux (MENSUEL/ANNUEL), date_limite, mode_remboursement
- montant_restant, is_rembourse

---

## 6. ENDPOINTS API PRINCIPAUX

| Endpoint | Méthodes | Description |
|----------|----------|-------------|
| /api/auth/auth/login/ | POST | Login |
| /api/auth/auth/register/ | POST | Register |
| /api/poulaillers/ | GET, POST | CRUD Poulaillers |
| /api/cycles/ | GET, POST | CRUD Cycles |
| /api/cycles/{id}/migrer/ | POST | Migration poulets |
| /api/cycles/{id}/declarer_perte/ | POST | Déclarer perte |
| /api/cycles/previsions/ | GET | Prévisions |
| /api/depenses/ | GET, POST | CRUD Dépenses |
| /api/depenses/routines/ | GET, POST | Routines |
| /api/depenses/routines/a_appliquer/ | GET | Routines à appliquer |
| /api/depenses/routines/appliquer/ | POST | Appliquer routines |
| /api/ventes/ | GET, POST | CRUD Ventes |
| /api/prets/ | GET, POST | CRUD Prêts |
| /api/prets/{id}/enregistrer_remboursement/ | POST | Remboursement |
| /api/rapports/ | GET, POST | CRUD Rapports |
| /api/users/parametres/ | GET, PATCH | Paramètres |
| /api/stock/ | GET, POST | Stock |
| /api/sync/ | POST | Synchronisation |

---

## 7. RÈGLES MÉTIER (RG)

1. Statut poulailler via SousBande (0 = LIBRE, >0 = OCCUPÉ)
2. Capacité = Surface × Densité recommandée (âge/type)
3. Alerte si densité > capacité
4. Suppression poulailler si vide
5. Migration tracée (date, source, cible, nombre, raison)
6. Âge automatique depuis date début
7. Vente déduit les sujets de la sous-bande
8. Perte déduit les sujets + crée dépense
9. Cycle archivé si stock = 0
10. Prêt avec intérêts : capital × (1 + taux/100 × nb_mois)
11. Taux annuel sur 1 an minimum
12. Date limite = 1 mois minimum
13. Remboursement réduit le capital restant
14. Dépenses routine proposées selon type/âge
15. Routine non réappliquée (unique_together)
16. Prévisions adaptatives selon nb cycles
17. Cache mémoire pour affichage immédiat
18. Session persistante (refresh token auto)
19. Vendeur par défaut = utilisateur connecté
20. Équipements liés au cycle (pas au poulailler)
21. Âge poussins : utilisateur entre l'âge, date début calculée
22. Vente à perte détectée + prix suggérés

---

## 8. BUGS CONNUS

Voir fichier bugs.txt fourni séparément.

---

## 9. NOTRE MANIÈRE DE TRAVAILLER

1. Tester chaque modification avec curl avant de passer au frontend
2. Demander l'avis du collègue (autre DeepSeek) pour valider les changements
3. Fichier complet plutôt que modifications partielles (évite les erreurs d'indentation)
4. Commit + push fréquents pour que Render redéploie
5. Ne pas mélanger backend et frontend dans la même session
6. Utiliser les variables de design system (AppColors, AppTextStyles, AppSpacing...)
7. Ne pas mettre de styles en dur dans les widgets

---

## 10. PROCHAINES PRIORITÉS

1. Résoudre les bugs listés dans bugs.txt
2. Corriger le bug APK release (usesCleartextTraffic)
3. Icônes Lucide (fichier app_icons.dart prêt)
4. Fiche détail vente/dépense (backend prêt, frontend à créer)
5. Dépenses de routine (frontend)
6. Prévisions (frontend - page simple)

---

## 🔑 COMMANDES UTILES

bash
# Login + récupérer token
TOKEN=$(curl -s -X POST https://avipro-backend.onrender.com/api/auth/auth/login/ -H "Content-Type: application/json" -d '{"email":"admin@avipro.com","password":"Avipro2026!"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['access'])")

# Tester n'importe quel endpoint
curl -X GET https://avipro-backend.onrender.com/api/poulaillers/ -H "Authorization: Bearer $TOKEN"


