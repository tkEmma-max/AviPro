#!/bin/bash

echo "🧹 Nettoyage de la base de données..."

# Supprimer l'ancienne base SQLite si elle existe
rm -f db.sqlite3

# Appliquer les migrations sur une base vierge
python manage.py migrate --noinput

# Collecter les fichiers statiques
python manage.py collectstatic --noinput

# Créer le superuser automatiquement
echo "from users.models import User; User.objects.create_superuser(email='admin@avipro.com', first_name='Admin', password='Avipro2026!')" | python manage.py shell

echo "✅ Build terminé ! Superuser créé : admin@avipro.com / Avipro2026!"