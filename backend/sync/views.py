from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.apps import apps
from django.db import transaction
from django.utils import timezone
from .models import PendingSync
import logging

logger = logging.getLogger(__name__)

class SyncView(APIView):
    def post(self, request, format=None):
        data = request.data
        
        # Accepter liste ou objet unique
        if isinstance(data, list):
            items = data
        else:
            items = [data]
        
        results = []
        for item in items:
            try:
                sync_obj = PendingSync.objects.create(
                    table_name=item.get('table_name', ''),
                    object_id=item.get('object_id', ''),
                    action=item.get('action', 'CREATE'),
                    data=item.get('data', {}),
                    created_by=request.user
                )
                success, error = self.apply_sync(sync_obj)
                if success:
                    sync_obj.status = 'SYNCED'
                    sync_obj.synced_at = timezone.now()
                else:
                    sync_obj.status = 'FAILED'
                    sync_obj.error_message = error
                sync_obj.save()
                results.append({
                    'id': str(sync_obj.id),
                    'status': sync_obj.status,
                    'error': error if not success else None
                })
            except Exception as e:
                results.append({
                    'status': 'FAILED',
                    'error': str(e)
                })
        
        return Response(results, status=status.HTTP_200_OK)

    def apply_sync(self, sync_obj):
        try:
            model = apps.get_model(sync_obj.table_name)
            if not model:
                return False, f"Table '{sync_obj.table_name}' introuvable."

            with transaction.atomic():
                if sync_obj.action == 'CREATE':
                    data = dict(sync_obj.data)
                    data.pop('id', None)
                    instance = model(**data)
                    if hasattr(instance, 'created_by'):
                        instance.created_by = sync_obj.created_by
                    instance.save()
                    sync_obj.object_id = str(instance.pk)
                    
                elif sync_obj.action == 'UPDATE':
                    try:
                        instance = model.objects.get(pk=sync_obj.object_id)
                    except model.DoesNotExist:
                        return False, f"Objet {sync_obj.object_id} introuvable."
                    for key, value in sync_obj.data.items():
                        setattr(instance, key, value)
                    instance.save()
                    
                elif sync_obj.action == 'DELETE':
                    try:
                        instance = model.objects.get(pk=sync_obj.object_id)
                        instance.delete()
                    except model.DoesNotExist:
                        pass
                else:
                    return False, f"Action '{sync_obj.action}' non supportee."
            return True, None
        except Exception as e:
            logger.exception("Erreur sync")
            return False, str(e)