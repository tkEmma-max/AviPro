// lib/models/rapport.dart
class Rapport {
  final String id;
  final String cycle;
  final String? cycleNom;
  final DateTime periodeDebut;
  final DateTime periodeFin;
  final double alimentConsomme;
  final double eauConsommee;
  final String? maladieObservee;
  final String? medicamentsAdministres;
  final int nbSujetsMalades;
  final String? observations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rapport({
    required this.id,
    required this.cycle,
    this.cycleNom,
    required this.periodeDebut,
    required this.periodeFin,
    this.alimentConsomme = 0,
    this.eauConsommee = 0,
    this.maladieObservee,
    this.medicamentsAdministres,
    this.nbSujetsMalades = 0,
    this.observations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rapport.fromJson(Map<String, dynamic> json) {
    return Rapport(
      id: json['id'] ?? '',
      cycle: json['cycle'] ?? '',
      cycleNom: json['cycle_nom'],
      periodeDebut: json['periode_debut'] != null
          ? DateTime.parse(json['periode_debut'])
          : DateTime.now(),
      periodeFin: json['periode_fin'] != null
          ? DateTime.parse(json['periode_fin'])
          : DateTime.now(),
      alimentConsomme: _parseDouble(json['aliment_consomme']),
      eauConsommee: _parseDouble(json['eau_consommee']),
      maladieObservee: json['maladie_observee'],
      medicamentsAdministres: json['medicaments_administres'],
      nbSujetsMalades: json['nb_sujets_malades'] ?? 0,
      observations: json['observations'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'cycle': cycle,
      'periode_debut': periodeDebut.toIso8601String(),
      'periode_fin': periodeFin.toIso8601String(),
      'aliment_consomme': alimentConsomme,
      'eau_consommee': eauConsommee,
      'maladie_observee': maladieObservee,
      'medicaments_administres': medicamentsAdministres,
      'nb_sujets_malades': nbSujetsMalades,
      'observations': observations,
    };
  }
}