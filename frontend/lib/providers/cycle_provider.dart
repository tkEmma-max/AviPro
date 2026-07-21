// lib/providers/cycle_provider.dart
import 'package:flutter/material.dart';
import '../models/cycle.dart';
import '../services/api_service.dart';

class CycleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Cycle> _cycles = [];
  bool _isLoading = false;

  List<Cycle> get cycles => _cycles;
  bool get isLoading => _isLoading;

  CycleProvider() {
    print('🔵 [CycleProvider] Constructeur appelé');
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    _isLoading = true;
    notifyListeners();
    print('🔄 [CycleProvider] _loadCycles() appelé');
    try {
      final response = await _apiService.get('cycles/');
      print('📡 [CycleProvider] Réponse reçue: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('results')) {
          final List results = data['results'];
          print('📦 [CycleProvider] ${results.length} cycles trouvés');
          _cycles = results.map((json) => Cycle.fromJson(json)).toList();
          print('✅ [CycleProvider] ${_cycles.length} cycles chargés');
        } else {
          print('❌ [CycleProvider] Format de réponse inattendu');
        }
      }
    } catch (e) {
      print('❌ [CycleProvider] Exception: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshCycles() async {
    print('🔄 [CycleProvider] refreshCycles() appelé');
    await _loadCycles();
  }

  Cycle? getCycleActif(String poulaillerId) {
    print('🔍 [CycleProvider] getCycleActif pour poulailler: $poulaillerId');
    try {
      final cycleActif = _cycles.firstWhere(
            (c) => c.poulailler == poulaillerId && c.isActive && !c.isArchived,
      );
      print('✅ [CycleProvider] Cycle actif trouvé: ${cycleActif.nom}');
      return cycleActif;
    } catch (e) {
      print('ℹ️ [CycleProvider] Aucun cycle actif trouvé');
      return null;
    }
  }

  List<Cycle> getCyclesByPoulailler(String poulaillerId) {
    return _cycles.where((c) => c.poulailler == poulaillerId).toList();
  }

  Future<List<Cycle>> fetchCyclesByPoulailler(String poulaillerId) async {
    print('🔍 [CycleProvider] fetchCyclesByPoulailler: $poulaillerId');
    try {
      final response = await _apiService.get('cycles/?poulailler=$poulaillerId');
      print('📥 [CycleProvider] Réponse API cycles/?poulailler: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('results')) {
          final List results = data['results'];
          print('📦 [CycleProvider] ${results.length} cycles trouvés pour ce poulailler');
          return results.map((json) => Cycle.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ [CycleProvider] Exception fetchCyclesByPoulailler: $e');
      return [];
    }
  }

  Future<void> addCycle(Cycle cycle) async {
    print('➕ [CycleProvider] addCycle: ${cycle.nom}');
    try {
      final response = await _apiService.post('cycles/', data: cycle.toJson());
      if (response.statusCode == 201) {
        final newCycle = Cycle.fromJson(response.data);
        _cycles.add(newCycle);
        print('✅ [CycleProvider] Cycle ajouté: ${newCycle.nom}');
        notifyListeners();
      }
    } catch (e) {
      print('❌ [CycleProvider] Exception addCycle: $e');
      rethrow;
    }
  }

  Future<bool> updateCycle(String cycleId, Map<String, dynamic> data) async {
    print('✏️ [CycleProvider] updateCycle: $cycleId');
    print('📤 [CycleProvider] PUT cycles/$cycleId/ data: $data');
    try {
      final response = await _apiService.put('cycles/$cycleId/', data: data);
      print('📥 [CycleProvider] Réponse PUT: ${response.statusCode}');
      print('📥 [CycleProvider] Body: ${response.data}');
      if (response.statusCode == 200) {
        final updated = Cycle.fromJson(response.data);
        final index = _cycles.indexWhere((c) => c.id == cycleId);
        if (index != -1) {
          _cycles[index] = updated;
          print('✅ [CycleProvider] Cycle modifié');
          notifyListeners();
        }
        return true;
      }
      print('❌ [CycleProvider] Échec: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ [CycleProvider] Exception updateCycle: $e');
      return false;
    }
  }

  Future<bool> deleteCycle(String cycleId) async {
    print('🗑️ [CycleProvider] deleteCycle: $cycleId');
    try {
      final response = await _apiService.delete('cycles/$cycleId/');
      if (response.statusCode == 204) {
        _cycles.removeWhere((c) => c.id == cycleId);
        print('✅ [CycleProvider] Cycle supprimé');
        notifyListeners();
        return true;
      }
      print('❌ [CycleProvider] Échec suppression: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ [CycleProvider] Exception deleteCycle: $e');
      return false;
    }
  }

  DateTime? _lastFetch;
  static const _cacheDuration = Duration(seconds: 30);

  bool get _isCacheValid => _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<void> refreshIfNeeded() async {
    if (!_isCacheValid) {
      await refreshCycles();
      _lastFetch = DateTime.now();
    }
  }
}