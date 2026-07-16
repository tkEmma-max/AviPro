from rest_framework import serializers
from .models import PendingSync

class PendingSyncSerializer(serializers.ModelSerializer):
    class Meta:
        model = PendingSync
        fields = '__all__'
        read_only_fields = ('id', 'status', 'error_message', 'retry_count', 'created_at', 'synced_at')