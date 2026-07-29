// lib/models/depense.dart
class Depense {
  final String id;
  final String cycle;
  final String? cycleNom;
  final String categorie;
  final String? categorieLabel;
  final String? categorieDepense;
  final String? categorieDepenseNom;
  final double montant;
  final DateTime date;
  final String? description;
  final String? factureNumero;
  final String? facturePhoto;
  final String? fournisseur;
  final String? fournisseurNom;
  final bool estDepenseRoutine;
  final String? routineId;
  final double? cumulDepensesAvant;
  final double? cumulDepensesApres;
  final double? prixRevientAvant;
  final double? prixRevientApres;
  final double? impactPourcentage;
  final String? poulaillerNom;
  final DateTime createdAt;
  final DateTime updatedAt;

  Depense({
    required this.id,
    required this.cycle,
    this.cycleNom,
    required this.categorie,
    this.categorieLabel,
    this.categorieDepense,
    this.categorieDepenseNom,
    required this.montant,
    required this.date,
    this.description,
    this.factureNumero,
    this.facturePhoto,
    this.fournisseur,
    this.fournisseurNom,
    this.estDepenseRoutine = false,
    this.routineId,
    this.cumulDepensesAvant,
    this.cumulDepensesApres,
    this.prixRevientAvant,
    this.prixRevientApres,
    this.impactPourcentage,
    this.poulaillerNom,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Depense.fromJson(Map<String, dynamic> json) {
    return Depense(
      id: json['id']?.toString() ?? '',
      cycle: json['cycle']?.toString() ?? '',
      cycleNom: json['cycle_nom'],
      categorie: json['categorie'] ?? '',
      categorieLabel: json['categorie_label'],
      categorieDepense: json['categorie_depense'],
      categorieDepenseNom: json['categorie_depense_nom'],
      montant: _parseDouble(json['montant']),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description: json['description'],
      factureNumero: json['facture_numero'],
      facturePhoto: json['facture_photo'],
      fournisseur: json['fournisseur'],
      fournisseurNom: json['fournisseur_nom'],
      estDepenseRoutine: json['est_depense_routine'] ?? false,
      routineId: json['routine_id'],
      cumulDepensesAvant: json['cumul_depenses_avant'] != null ? _parseDouble(json['cumul_depenses_avant']) : null,
      cumulDepensesApres: json['cumul_depenses_apres'] != null ? _parseDouble(json['cumul_depenses_apres']) : null,
      prixRevientAvant: json['prix_revient_avant'] != null ? _parseDouble(json['prix_revient_avant']) : null,
      prixRevientApres: json['prix_revient_apres'] != null ? _parseDouble(json['prix_revient_apres']) : null,
      impactPourcentage: json['impact_pourcentage'] != null ? _parseDouble(json['impact_pourcentage']) : null,
      poulaillerNom: json['poulailler_nom'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'cycle': cycle,
      'categorie': categorie,
      'montant': montant,
      'date': date.toIso8601String().split('T')[0],
    };
    if (id.isNotEmpty) data['id'] = id;
    if (categorieDepense != null) data['categorie_depense'] = categorieDepense;
    if (fournisseur != null) data['fournisseur'] = fournisseur;
    if (description != null && description!.isNotEmpty) data['description'] = description;
    if (factureNumero != null) data['facture_numero'] = factureNumero;
    return data;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}