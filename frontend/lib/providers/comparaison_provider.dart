// lib/providers/comparaison_provider.dart
import 'package:flutter/material.dart';
import '../models/comparaison.dart';
import '../services/api_service.dart';

class ComparaisonProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Comparaison? _comparaison;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetch;
  String? _currentCycleId;
  static const _cacheDuration = Duration(seconds: 30);

  Comparaison? get comparaison => _comparaison;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get _isCacheValid =>
      _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<void> getComparaison(String cycleId) async {
    if (_isCacheValid && _currentCycleId == cycleId && _comparaison != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _comparaison = null;
    _currentCycleId = cycleId;
    notifyListeners();

    try {
      final response = await _apiService.get('cycles/$cycleId/comparaison/');
      if (response.statusCode == 200 && response.data != null) {
        _comparaison = Comparaison.fromJson(response.data);
        _lastFetch = DateTime.now();
      } else if (response.statusCode == 400 && response.data != null) {
        _errorMessage = response.data['error'] ?? 'Ce cycle ne peut pas être comparé.';
      } else {
        _errorMessage = 'Erreur lors du chargement de la comparaison.';
      }
    } catch (e) {
      print('❌ [ComparaisonProvider] Erreur: $e');
      _errorMessage = 'Impossible de charger la comparaison. Vérifiez votre connexion.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshComparaison(String cycleId) async {
    _lastFetch = null;
    await getComparaison(cycleId);
  }

  void clearCache() {
    _comparaison = null;
    _lastFetch = null;
    _currentCycleId = null;
    _errorMessage = null;
  }
}