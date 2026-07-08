#!/bin/bash
# build.sh

echo "🚀 Installation des dépendances..."
pip install --upgrade pip
pip install -r requirements.txt

echo "📦 Collecte des fichiers statiques..."
python manage.py collectstatic --noinput

echo "🗄️  Migration de la base de données..."
python manage.py migrate --noinput

echo "✅ Build terminé avec succès !"