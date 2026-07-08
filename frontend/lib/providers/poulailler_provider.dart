// lib/providers/poulailler_provider.dart
import 'package:flutter/material.dart';
import '../models/poulailler.dart';

class PoulaillerProvider extends ChangeNotifier {
  List<Poulailler> _poulaillers = [];

  List<Poulailler> get poulaillers => _poulaillers;

  bool get isEmpty => _poulaillers.isEmpty;

  PoulaillerProvider() {
    _loadPoulaillers();
  }

  Future<void> _loadPoulaillers() async {
    // Simuler le chargement de données
    await Future.delayed(const Duration(milliseconds: 500));

    // Données de test
    _poulaillers = [
      Poulailler(
        id: '1',
        nom: 'Poulailler Nord',
        longueur: 10,
        largeur: 8,
        hauteur: 3.5,
        localisation: 'Derrière la maison',
        typeSol: 'Ciment',
        nombreMangeoires: 4,
        nombreAbreuvoirs: 6,
        isArchived: false,
        statut: 'OCCUPÉ',
        nbPouletsActuels: 1200,
        surface: 80,
        densiteActuelle: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Poulailler(
        id: '2',
        nom: 'Poulailler Sud',
        longueur: 12,
        largeur: 6,
        hauteur: 3,
        localisation: 'Près du champ',
        typeSol: 'Terre',
        nombreMangeoires: 3,
        nombreAbreuvoirs: 4,
        isArchived: false,
        statut: 'LIBRE',
        nbPouletsActuels: 0,
        surface: 72,
        densiteActuelle: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Poulailler(
        id: '3',
        nom: 'Bâtiment Est',
        longueur: 15,
        largeur: 10,
        hauteur: 4,
        localisation: 'Côté est de la ferme',
        typeSol: 'Ciment',
        nombreMangeoires: 6,
        nombreAbreuvoirs: 8,
        isArchived: false,
        statut: 'OCCUPÉ',
        nbPouletsActuels: 1800,
        surface: 150,
        densiteActuelle: 12,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    notifyListeners();
  }

  Poulailler? getPoulailler(String id) {
    try {
      return _poulaillers.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addPoulailler(Poulailler poulailler) async {
    _poulaillers.add(poulailler);
    notifyListeners();
  }

  Future<void> updatePoulailler(Poulailler poulailler) async {
    final index = _poulaillers.indexWhere((p) => p.id == poulailler.id);
    if (index != -1) {
      _poulaillers[index] = poulailler;
      notifyListeners();
    }
  }

  Future<void> deletePoulailler(String id) async {
    _poulaillers.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Filtres
  List<Poulailler> get libres =>
      _poulaillers.where((p) => p.statut == 'LIBRE').toList();

  List<Poulailler> get occupes =>
      _poulaillers.where((p) => p.statut == 'OCCUPÉ').toList();
}