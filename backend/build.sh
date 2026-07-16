#!/bin/bash

echo "📦 Installation des dépendances..."
pip install --upgrade pip
pip install -r requirements.txt

echo "🔄 Création des migrations..."
python manage.py makemigrations --noinput

echo "🔄 Application des migrations..."
python manage.py migrate --noinput

echo "📁 Collecte des fichiers statiques..."
python manage.py collectstatic --noinput

echo "✅ Build terminé !"