// lib/providers/vente_provider.dart
import 'package:flutter/material.dart';
import '../models/vente.dart';
import '../services/api_service.dart';

class VenteProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Vente? _venteDetail;
  bool _isLoading = false;
  DateTime? _lastFetch;
  String? _currentId;
  static const _cacheDuration = Duration(seconds: 30);

  Vente? get venteDetail => _venteDetail;
  bool get isLoading => _isLoading;

  bool get _isCacheValid =>
      _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  /// Récupère le détail d'une vente par son ID (avec cache 30s)
  Future<Vente?> getVenteById(String id) async {
    // Cache valide pour la même vente
    if (_isCacheValid && _currentId == id && _venteDetail != null) {
      return _venteDetail;
    }

    _isLoading = true;
    _currentId = id;
    notifyListeners();

    try {
      final response = await _apiService.get('ventes/$id/');
      if (response.statusCode == 200 && response.data != null) {
        _venteDetail = Vente.fromJson(response.data);
        _lastFetch = DateTime.now();
        _isLoading = false;
        notifyListeners();
        return _venteDetail;
      }
    } catch (e) {
      print('❌ [VenteProvider] Erreur getVenteById: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Force le rafraîchissement (ignore le cache)
  Future<Vente?> refreshVente(String id) async {
    _lastFetch = null; // Invalide le cache
    return getVenteById(id);
  }

  /// Vide le cache
  void clearCache() {
    _venteDetail = null;
    _lastFetch = null;
    _currentId = null;
  }
}