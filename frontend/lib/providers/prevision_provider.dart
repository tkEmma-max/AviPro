// lib/providers/prevision_provider.dart
import 'package:flutter/material.dart';
import '../models/prevision.dart';
import '../models/type_poulet.dart';
import '../services/api_service.dart';

class PrevisionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<TypePoulet> _typesPoulet = [];
  Prevision? _prevision;
  bool _isLoading = false;
  bool _isLoadingTypes = false;
  String? _errorMessage;

  List<TypePoulet> get typesPoulet => _typesPoulet;
  Prevision? get prevision => _prevision;
  bool get isLoading => _isLoading;
  bool get isLoadingTypes => _isLoadingTypes;
  String? get errorMessage => _errorMessage;

  Future<void> loadTypesPoulet() async {
    _isLoadingTypes = true;
    notifyListeners();

    try {
      final response = await _apiService.get('cycles/types-poulet/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['results'] != null) {
          _typesPoulet = (data['results'] as List)
              .map((json) => TypePoulet.fromJson(json))
              .where((t) => t.isActive)
              .toList();
        }
      }
    } catch (e) {
      print('❌ [PrevisionProvider] Erreur loadTypesPoulet: $e');
    }

    _isLoadingTypes = false;
    notifyListeners();
  }

  Future<void> getPrevisions({
    required String typePouletId,
    required int nbSujets,
    int? ageDebut,
    int? ageFin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _prevision = null;
    notifyListeners();

    try {
      String url = 'cycles/previsions/?type_poulet_id=$typePouletId&nb_sujets=$nbSujets';
      if (ageDebut != null) url += '&age_debut=$ageDebut';
      if (ageFin != null) url += '&age_fin=$ageFin';

      final response = await _apiService.get(url);
      if (response.statusCode == 200 && response.data != null) {
        _prevision = Prevision.fromJson(response.data);
      } else {
        _errorMessage = 'Erreur lors du chargement des prévisions';
      }
    } catch (e) {
      print('❌ [PrevisionProvider] Erreur getPrevisions: $e');
      _errorMessage = 'Impossible de charger les prévisions. Vérifiez votre connexion.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearPrevision() {
    _prevision = null;
    _errorMessage = null;
    notifyListeners();
  }
}