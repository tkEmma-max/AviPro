// lib/models/cycle.dart
class Cycle {
  final String id;
  final String nom;
  final String poulailler;
  final String? poulaillerNom;
  final String type;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final int nombreSujetsInitiaux;
  final int nombreSujetsActuels;
  final int dureeEstimeeJours;
  final bool isActive;
  final bool isArchived;
  final int? joursEcoules;
  final double? progression;
  final int? mortalites;
  final double? tauxMortalite;
  final double? totalDepenses;
  final double? totalVentes;
  final double? benefice;
  final bool? estRentable;
  final double? coutProductionUnitaire;
  final double? prixVenteMoyen;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cycle({
    required this.id,
    required this.nom,
    required this.poulailler,
    this.poulaillerNom,
    required this.type,
    required this.dateDebut,
    this.dateFin,
    required this.nombreSujetsInitiaux,
    required this.nombreSujetsActuels,
    required this.dureeEstimeeJours,
    this.isActive = true,
    this.isArchived = false,
    this.joursEcoules,
    this.progression,
    this.mortalites,
    this.tauxMortalite,
    this.totalDepenses,
    this.totalVentes,
    this.benefice,
    this.estRentable,
    this.coutProductionUnitaire,
    this.prixVenteMoyen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      poulailler: json['poulailler'] ?? '',
      poulaillerNom: json['poulailler_nom'],
      type: json['type'] ?? 'CHAIR',
      dateDebut: json['date_debut'] != null ? DateTime.parse(json['date_debut']) : DateTime.now(),
      dateFin: json['date_fin'] != null ? DateTime.parse(json['date_fin']) : null,
      nombreSujetsInitiaux: json['nombre_sujets_initiaux'] ?? 0,
      nombreSujetsActuels: json['nombre_sujets_actuels'] ?? 0,
      dureeEstimeeJours: json['duree_estimee_jours'] ?? 0,
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      joursEcoules: json['jours_ecoules'],
      progression: json['progression']?.toDouble(),
      mortalites: json['mortalites'],
      tauxMortalite: json['taux_mortalite']?.toDouble(),
      totalDepenses: json['total_depenses']?.toDouble(),
      totalVentes: json['total_ventes']?.toDouble(),
      benefice: json['benefice']?.toDouble(),
      estRentable: json['est_rentable'],
      coutProductionUnitaire: json['cout_production_unitaire']?.toDouble(),
      prixVenteMoyen: json['prix_vente_moyen']?.toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'poulailler': poulailler,
      'type': type,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin?.toIso8601String(),
      'nombre_sujets_initiaux': nombreSujetsInitiaux,
      'nombre_sujets_actuels': nombreSujetsActuels,
      'duree_estimee_jours': dureeEstimeeJours,
      'is_active': isActive,
      'is_archived': isArchived,
    };
  }
}