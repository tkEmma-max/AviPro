// lib/providers/depense_provider.dart
import 'package:flutter/material.dart';
import '../models/depense.dart';
import '../services/api_service.dart';

class DepenseProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Depense? _depenseDetail;
  bool _isLoading = false;
  DateTime? _lastFetch;
  String? _currentId;
  static const _cacheDuration = Duration(seconds: 30);

  Depense? get depenseDetail => _depenseDetail;
  bool get isLoading => _isLoading;

  bool get _isCacheValid =>
      _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  /// Récupère le détail d'une dépense par son ID (avec cache 30s)
  Future<Depense?> getDepenseById(String id) async {
    // Cache valide pour la même dépense
    if (_isCacheValid && _currentId == id && _depenseDetail != null) {
      return _depenseDetail;
    }

    _isLoading = true;
    _currentId = id;
    notifyListeners();

    try {
      final response = await _apiService.get('depenses/$id/');
      if (response.statusCode == 200 && response.data != null) {
        _depenseDetail = Depense.fromJson(response.data);
        _lastFetch = DateTime.now();
        _isLoading = false;
        notifyListeners();
        return _depenseDetail;
      }
    } catch (e) {
      print('❌ [DepenseProvider] Erreur getDepenseById: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Force le rafraîchissement (ignore le cache)
  Future<Depense?> refreshDepense(String id) async {
    _lastFetch = null; // Invalide le cache
    return getDepenseById(id);
  }

  /// Vide le cache
  void clearCache() {
    _depenseDetail = null;
    _lastFetch = null;
    _currentId = null;
  }
}