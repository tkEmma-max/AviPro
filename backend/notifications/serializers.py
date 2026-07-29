# backend/notifications/serializers.py
from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    type_label = serializers.ReadOnlyField(source='get_type_display')

    class Meta:
        model = Notification
        fields = [
            'id', 'type', 'type_label', 'titre', 'message',
            'donnees', 'est_lue', 'date_creation'
        ]
        read_only_fields = ['id', 'date_creation', 'type_label']