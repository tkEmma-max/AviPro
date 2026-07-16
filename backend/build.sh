#!/bin/bash

echo "📦 Installation des dépendances..."
pip install --upgrade pip
pip install -r requirements.txt

echo "🧹 Nettoyage de la base de données..."
rm -f db.sqlite3

echo "🔄 Migrations..."
python manage.py migrate --noinput

echo "📁 Fichiers statiques..."
python manage.py collectstatic --noinput

echo "👤 Création du superuser..."
echo "from users.models import User; User.objects.create_superuser(email='admin@avipro.com', first_name='Admin', password='Avipro2026!')" | python manage.py shell

echo "✅ Build terminé !"