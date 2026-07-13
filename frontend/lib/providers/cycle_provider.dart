// lib/providers/cycle_provider.dart
import 'package:flutter/material.dart';
import '../models/cycle.dart';
import '../services/api_service.dart';

class CycleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Cycle> _cycles = [];

  List<Cycle> get cycles => _cycles;

  CycleProvider() {
    print('🔵 [CycleProvider] Constructeur appelé');
    _loadCycles();
  }

  Future<void> _loadCycles() async {
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
          notifyListeners();
        } else {
          print('❌ [CycleProvider] Format de réponse inattendu');
        }
      }
    } catch (e) {
      print('❌ [CycleProvider] Exception: $e');
    }
  }

  Future<void> refreshCycles() async {
    print('🔄 [CycleProvider] refreshCycles() appelé');
    await _loadCycles();
  }

  Future<void> addCycle(Cycle cycle) async {
    print('➕ [CycleProvider] addCycle: ${cycle.nom}');
    try {
      final response = await _apiService.post(
        'cycles/',
        data: cycle.toJson(),
      );
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
}