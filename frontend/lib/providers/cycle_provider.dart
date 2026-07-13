// lib/providers/cycle_provider.dart
import 'package:flutter/material.dart';
import '../models/cycle.dart';
import '../services/api_service.dart';

class CycleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Cycle> _cycles = [];

  List<Cycle> get cycles => _cycles;

  CycleProvider() {
    _loadCycles();
  }

  // ═══════════════════════════════════════════════
  // CHARGER LES CYCLES DEPUIS L'API
  // ═══════════════════════════════════════════════
  Future<void> _loadCycles() async {
    try {
      final response = await _apiService.get('cycles/');
      if (response.statusCode == 200) {
        final List data = response.data;
        _cycles = data.map((json) => Cycle.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors du chargement des cycles: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // CRÉER UN CYCLE (sera utilisé dans la tâche 5)
  // ═══════════════════════════════════════════════
  Future<void> addCycle(Cycle cycle) async {
    try {
      final response = await _apiService.post(
        'cycles/',
        data: cycle.toJson(),
      );
      if (response.statusCode == 201) {
        final newCycle = Cycle.fromJson(response.data);
        _cycles.add(newCycle);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la création du cycle: $e');
      rethrow;
    }
  }
}