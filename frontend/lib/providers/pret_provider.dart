// lib/providers/pret_provider.dart
import 'package:flutter/material.dart';
import '../models/pret.dart';
import '../services/api_service.dart';

class PretProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Pret> _prets = [];

  List<Pret> get prets => _prets;

  PretProvider() {
    _loadPrets();
  }

  Future<void> _loadPrets() async {
    try {
      final response = await _apiService.get('prets/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('results')) {
          final List results = data['results'];
          _prets = results.map((json) => Pret.fromJson(json)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des prêts: $e');
    }
  }

  Future<void> refreshPrets() async {
    await _loadPrets();
  }

  Future<void> addPret(Pret pret) async {
    try {
      final response = await _apiService.post(
        'prets/',
        data: pret.toJson(),
      );
      if (response.statusCode == 201) {
        final newPret = Pret.fromJson(response.data);
        _prets.add(newPret);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la création du prêt: $e');
      rethrow;
    }
  }
}