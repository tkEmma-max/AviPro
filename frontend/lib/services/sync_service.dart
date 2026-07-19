// lib/services/sync_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'local_db_service.dart';
import 'api_service.dart';

class SyncService {
  final LocalDbService _localDb;
  final ApiService _api;
  bool _isSyncing = false;

  static const Map<String, String> _tableToEndpoint = {
    'poulaillers': 'poulaillers/',
    'cycles': 'cycles/',
    'depenses': 'depenses/',
    'ventes': 'ventes/',
    'prets': 'prets/',
    'rapports': 'rapports/',
    'clients': 'clients/',
    'fournisseurs': 'fournisseurs/',
  };

  SyncService(this._localDb, this._api);

  bool get isSyncing => _isSyncing;

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingOps = await _localDb.getPendingSync();

      for (var op in pendingOps) {
        final tableName = op['table_name'] as String;
        final objectId = op['object_id'] as String;
        final action = op['action'] as String;
        final dataJson = op['data_json'] as String;
        final data = jsonDecode(dataJson) as Map<String, dynamic>;

        final endpoint = _tableToEndpoint[tableName];
        if (endpoint == null) {
          print('❌ Table inconnue: $tableName');
          continue;
        }

        try {
          switch (action) {
            case 'CREATE':
              await _api.post(endpoint, data: data);
              break;
            case 'UPDATE':
              await _api.put('$endpoint$objectId/', data: data);
              break;
            case 'DELETE':
              await _api.delete('$endpoint$objectId/');
              break;
            default:
              print('❌ Action inconnue: $action');
              continue;
          }

          await _localDb.markPendingSyncAsDone(op['id'] as int);
          print('✅ Sync réussie: $tableName/$objectId ($action)');
        } catch (e) {
          if (e is DioException) {
            final statusCode = e.response?.statusCode;
            if (statusCode == 409) {
              print('⚠️ Conflit détecté sur $tableName/$objectId');
              await _resolveConflict(tableName, objectId);
            } else if (statusCode == 412) {
              print('⚠️ Version obsolète: $tableName/$objectId');
              await _fetchAndUpdateLocal(tableName, objectId);
            } else if (statusCode == 404) {
              print('ℹ️ Objet $tableName/$objectId déjà supprimé');
              await _localDb.hardDelete(tableName, objectId);
            } else {
              print('❌ Erreur sync $tableName/$objectId: $e');
            }
          } else {
            print('❌ Erreur sync $tableName/$objectId: $e');
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════
  // GESTION DES CONFLITS
  // ═══════════════════════════════════════════

  Future<void> _resolveConflict(String tableName, String objectId) async {
    try {
      final endpoint = _tableToEndpoint[tableName];
      if (endpoint == null) return;

      final response = await _api.get('$endpoint$objectId/');
      if (response.statusCode == 200) {
        final serverData = response.data;
        await _localDb.update(tableName, {
          'id': objectId,
          ...serverData,
          'data_json': jsonEncode(serverData),
          'synced': 1,
        });
        print('✅ Conflit résolu: $tableName/$objectId');
      }
    } catch (e) {
      print('❌ Erreur lors de la résolution du conflit: $e');
    }
  }

  Future<void> _fetchAndUpdateLocal(String tableName, String objectId) async {
    await _resolveConflict(tableName, objectId);
  }
}