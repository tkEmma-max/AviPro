// lib/providers/pret_provider.dart
import 'package:flutter/material.dart';
import '../models/pret.dart';
import '../services/api_service.dart';

class PretProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Pret> _prets = [];
  bool _isLoading = false;

  List<Pret> get prets => _prets;
  bool get isLoading => _isLoading;

  PretProvider() {
    _loadPrets();
  }

  Future<void> _loadPrets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('prets/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('results')) {
          final List results = data['results'];
          _prets = results.map((json) => Pret.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Erreur chargement prêts: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshPrets() async {
    await _loadPrets();
  }

  Future<bool> addPret(Pret pret) async {
    try {
      final response = await _apiService.post('prets/', data: pret.toJson());
      if (response.statusCode == 201) {
        final newPret = Pret.fromJson(response.data);
        _prets.add(newPret);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur création prêt: $e');
      rethrow;
    }
  }

  Future<bool> addRemboursement(String pretId, double montant, {String? description}) async {
    try {
      final response = await _apiService.post('prets/$pretId/enregistrer_remboursement/', data: {
        'montant': montant.toInt(),
        'date': DateTime.now().toIso8601String().split('T')[0],
        'source': 'manuel',
        'description': description ?? 'Remboursement manuel',
      });
      return response.statusCode == 201;
    } catch (e) {
      print('Erreur remboursement: $e');
      return false;
    }
  }
}