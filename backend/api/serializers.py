# api/serializers.py (version finale - beaucoup plus courte)
from rest_framework import serializers


# ============ SYNCHRONISATION ============
class SyncOperationSerializer(serializers.Serializer):
    """Serializer pour une opération de synchronisation"""
    id = serializers.UUIDField()
    model = serializers.CharField()
    operation = serializers.ChoiceField(choices=['CREATE', 'UPDATE', 'DELETE'])
    data = serializers.JSONField()
    timestamp = serializers.DateTimeField()


class SyncRequestSerializer(serializers.Serializer):
    """Serializer pour la requête de synchronisation"""
    timestamp = serializers.DateTimeField()
    ops = SyncOperationSerializer(many=True)


class SyncConflictSerializer(serializers.Serializer):
    """Serializer pour un conflit de synchronisation"""
    id = serializers.UUIDField()
    model = serializers.CharField()
    field = serializers.CharField()
    server_value = serializers.JSONField()
    client_value = serializers.JSONField()
    resolution = serializers.CharField()