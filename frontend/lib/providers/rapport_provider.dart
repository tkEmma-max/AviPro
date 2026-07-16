// lib/providers/rapport_provider.dart
import 'package:flutter/material.dart';
import '../models/rapport.dart';
import '../services/api_service.dart';

class RapportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Rapport> _rapports = [];

  List<Rapport> get rapports => _rapports;

  RapportProvider() {
    _loadRapports();
  }

  Future<void> _loadRapports() async {
    try {
      final response = await _apiService.get('rapports/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('results')) {
          final List results = data['results'];
          _rapports = results.map((json) => Rapport.fromJson(json)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des rapports: $e');
    }
  }

  Future<void> refreshRapports() async {
    await _loadRapports();
  }

  Future<void> addRapport(Rapport rapport) async {
    try {
      final response = await _apiService.post(
        'rapports/',
        data: rapport.toJson(),
      );
      if (response.statusCode == 201) {
        final newRapport = Rapport.fromJson(response.data);
        _rapports.add(newRapport);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la création du rapport: $e');
      rethrow;
    }
  }

  DateTime? _lastFetch;
  static const _cacheDuration = Duration(seconds: 30);

  bool get _isCacheValid => _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<void> refreshIfNeeded() async {
    if (!_isCacheValid) {
      await refreshRapports();
      _lastFetch = DateTime.now();
    }
  }
}