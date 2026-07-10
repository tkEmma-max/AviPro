#!/bin/bash
# build.sh

echo "🚀 Installation des dépendances..."
pip install --upgrade pip
pip install -r requirements.txt

echo "📦 Collecte des fichiers statiques..."
python manage.py collectstatic --noinput

echo "🗄️  Suppression des anciennes migrations..."
rm -f */migrations/0*.py

echo "🗄️  Recréation des migrations..."
python manage.py makemigrations

echo "🗄️  Application des migrations..."
python manage.py migrate --noinput

echo "✅ Build terminé avec succès !"