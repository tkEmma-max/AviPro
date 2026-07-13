# recreate_data.ps1 - Recrée toutes les données de test en une seule fois

$BASE_URL = "https://avipro-backend.onrender.com/api"
$EMAIL = "t@gmail.com"
$PASSWORD = "tester"

Write-Host "🔐 Connexion en cours..."

# 1. Récupérer le token
$login = Invoke-RestMethod -Method Post -Uri "$BASE_URL/auth/login/" -ContentType "application/json" -Body "{`"email`":`"$EMAIL`",`"password`":`"$PASSWORD`"}"
$TOKEN = $login.access

Write-Host "✅ Token récupéré"

# 2. Créer un poulailler
Write-Host "🏠 Création du poulailler..."
$poulailler = Invoke-RestMethod -Method Post -Uri "$BASE_URL/poulaillers/" -ContentType "application/json" -Headers @{Authorization = "Bearer $TOKEN"} -Body '{"nom":"Poulailler Test","longueur":10,"largeur":8,"localisation":"Test Location"}'
$POULAILLER_ID = $poulailler.id
Write-Host "✅ Poulailler créé : $POULAILLER_ID"

# 3. Créer un cycle
Write-Host "🔄 Création du cycle..."
$cycle = Invoke-RestMethod -Method Post -Uri "$BASE_URL/cycles/" -ContentType "application/json" -Headers @{Authorization = "Bearer $TOKEN"} -Body "{`"nom`":`"Cycle Test`",`"poulailler`":`"$POULAILLER_ID`",`"type`":`"CHAIR`",`"date_debut`":`"2026-07-13`",`"nombre_sujets_initiaux`":50,`"nombre_sujets_actuels`":50,`"duree_estimee_jours`":45}"
$CYCLE_ID = $cycle.id
Write-Host "✅ Cycle créé : $CYCLE_ID"

# 4. Créer une dépense
Write-Host "💸 Création de la dépense..."
Invoke-RestMethod -Method Post -Uri "$BASE_URL/depenses/" -ContentType "application/json" -Headers @{Authorization = "Bearer $TOKEN"} -Body "{`"cycle`":`"$CYCLE_ID`",`"categorie`":`"ALIMENT`",`"montant`":25000,`"date`":`"2026-07-13`",`"description`":`"Achat aliment test`"}"
Write-Host "✅ Dépense créée"

# 5. Créer une vente
Write-Host "💰 Création de la vente..."
Invoke-RestMethod -Method Post -Uri "$BASE_URL/ventes/" -ContentType "application/json" -Headers @{Authorization = "Bearer $TOKEN"} -Body "{`"cycle`":`"$CYCLE_ID`",`"type`":`"POULETS`",`"quantite`":10,`"prix_unitaire`":3000,`"date`":`"2026-07-13`",`"description`":`"Vente test`"}"
Write-Host "✅ Vente créée"

Write-Host ""
Write-Host "========================================"
Write-Host "✅ TOUTES LES DONNÉES SONT RECRÉÉES !"
Write-Host "========================================"
Write-Host "🏠 Poulailler ID : $POULAILLER_ID"
Write-Host "🔄 Cycle ID      : $CYCLE_ID"
Write-Host "========================================"