// lib/providers/poulailler_provider.dart
import 'package:flutter/material.dart';
import '../models/poulailler.dart';
import '../services/api_service.dart';

class PoulaillerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Poulailler> _poulaillers = [];

  List<Poulailler> get poulaillers => _poulaillers;

  PoulaillerProvider() {
    print('🔵 [PoulaillerProvider] Constructeur appelé');
    _loadPoulaillers();
  }

  // ============================================================
  // CHARGER LES POULAILLERS DEPUIS L'API
  // ============================================================
  Future<void> _loadPoulaillers() async {
    print('🔄 [PoulaillerProvider] _loadPoulaillers() appelé');
    try {
      final response = await _apiService.get('poulaillers/');
      print('📡 [PoulaillerProvider] Réponse reçue: ${response.statusCode}');
      if (response.statusCode == 200) {
        // ✅ CORRECTION : Utiliser response.data['results'] au lieu de response.data
        final data = response.data;
        if (data is Map && data.containsKey('results')) {
          final List results = data['results'];
          print('📦 [PoulaillerProvider] ${results.length} poulaillers trouvés');
          _poulaillers = results.map((json) => Poulailler.fromJson(json)).toList();
          print('✅ [PoulaillerProvider] ${_poulaillers.length} poulaillers chargés');
          notifyListeners();
        } else {
          print('❌ [PoulaillerProvider] Format de réponse inattendu');
        }
      } else {
        print('❌ [PoulaillerProvider] Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PoulaillerProvider] Exception: $e');
    }
  }

  // ============================================================
  // RECHARGER LES POULAILLERS
  // ============================================================
  Future<void> refreshPoulaillers() async {
    print('🔄 [PoulaillerProvider] refreshPoulaillers() appelé');
    await _loadPoulaillers();
  }

  // ============================================================
  // RÉCUPÉRER UN POULAILLER PAR ID
  // ============================================================
  Poulailler? getPoulailler(String id) {
    print('🔍 [PoulaillerProvider] getPoulailler($id)');
    try {
      final result = _poulaillers.firstWhere((p) => p.id == id);
      print('✅ [PoulaillerProvider] Poulailler trouvé: ${result.nom}');
      return result;
    } catch (e) {
      print('❌ [PoulaillerProvider] Poulailler non trouvé');
      return null;
    }
  }

  // ============================================================
  // AJOUTER UN POULAILLER
  // ============================================================
  Future<void> addPoulailler(Poulailler poulailler) async {
    print('➕ [PoulaillerProvider] addPoulailler: ${poulailler.nom}');
    try {
      final response = await _apiService.post(
        'poulaillers/',
        data: poulailler.toJson(),
      );
      print('📡 [PoulaillerProvider] Réponse POST: ${response.statusCode}');
      if (response.statusCode == 201) {
        final newPoulailler = Poulailler.fromJson(response.data);
        _poulaillers.add(newPoulailler);
        print('✅ [PoulaillerProvider] Poulailler ajouté: ${newPoulailler.nom}');
        notifyListeners();
      } else {
        print('❌ [PoulaillerProvider] Erreur POST: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PoulaillerProvider] Exception addPoulailler: $e');
      rethrow;
    }
  }

  // ============================================================
  // MODIFIER UN POULAILLER
  // ============================================================
  Future<void> updatePoulailler(Poulailler poulailler) async {
    print('✏️ [PoulaillerProvider] updatePoulailler: ${poulailler.id}');
    try {
      final response = await _apiService.put(
        'poulaillers/${poulailler.id}/',
        data: poulailler.toJson(),
      );
      if (response.statusCode == 200) {
        final updated = Poulailler.fromJson(response.data);
        final index = _poulaillers.indexWhere((p) => p.id == poulailler.id);
        if (index != -1) {
          _poulaillers[index] = updated;
          print('✅ [PoulaillerProvider] Poulailler modifié');
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ [PoulaillerProvider] Exception updatePoulailler: $e');
    }
  }

  // ============================================================
  // SUPPRIMER UN POULAILLER
  // ============================================================
  Future<void> deletePoulailler(String id) async {
    print('🗑️ [PoulaillerProvider] deletePoulailler: $id');
    try {
      final response = await _apiService.delete('poulaillers/$id/');
      if (response.statusCode == 204) {
        _poulaillers.removeWhere((p) => p.id == id);
        print('✅ [PoulaillerProvider] Poulailler supprimé');
        notifyListeners();
      }
    } catch (e) {
      print('❌ [PoulaillerProvider] Exception deletePoulailler: $e');
    }
  }

  // ============================================================
  // FILTRES
  // ============================================================
  List<Poulailler> get libres {
    print('🔍 [PoulaillerProvider] get libres');
    return _poulaillers.where((p) => p.statut == 'LIBRE').toList();
  }

  List<Poulailler> get occupes {
    print('🔍 [PoulaillerProvider] get occupes');
    return _poulaillers.where((p) => p.statut == 'OCCUPÉ').toList();
  }
}