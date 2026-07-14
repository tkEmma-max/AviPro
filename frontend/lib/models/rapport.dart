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
  final String? medicaments;
  final int nbSujetsMalades;
  final String? observations;
  final double? surface;
  final int nbSujetsActuels;
  final int nbMangeoires;
  final int nbAbreuvoirs;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rapport({
    required this.id,
    required this.cycle,
    this.cycleNom,
    required this.periodeDebut,
    required this.periodeFin,
    required this.alimentConsomme,
    required this.eauConsommee,
    this.maladieObservee,
    this.medicaments,
    this.nbSujetsMalades = 0,
    this.observations,
    this.surface,
    this.nbSujetsActuels = 0,
    this.nbMangeoires = 0,
    this.nbAbreuvoirs = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rapport.fromJson(Map<String, dynamic> json) {
    return Rapport(
      id: json['id']?.toString() ?? '',
      cycle: json['cycle']?.toString() ?? '',
      cycleNom: json['cycle_nom'],
      periodeDebut: json['periode_debut'] != null ? DateTime.parse(json['periode_debut']) : DateTime.now(),
      periodeFin: json['periode_fin'] != null ? DateTime.parse(json['periode_fin']) : DateTime.now(),
      alimentConsomme: double.tryParse(json['aliment_consomme']?.toString() ?? '0') ?? 0,
      eauConsommee: double.tryParse(json['eau_consommee']?.toString() ?? '0') ?? 0,
      maladieObservee: json['maladie_observee'],
      medicaments: json['medicaments'],
      nbSujetsMalades: json['nb_sujets_malades'] ?? 0,
      observations: json['observations'],
      surface: json['surface']?.toDouble(),
      nbSujetsActuels: json['nb_sujets_actuels'] ?? 0,
      nbMangeoires: json['nb_mangeoires'] ?? 0,
      nbAbreuvoirs: json['nb_abreuvoirs'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'cycle': cycle,
      'periode_debut': periodeDebut.toIso8601String().split('T')[0],
      'periode_fin': periodeFin.toIso8601String().split('T')[0],
      'aliment_consomme': alimentConsomme,
      'eau_consommee': eauConsommee,
      'maladie_observee': maladieObservee,
      'medicaments': medicaments,
      'nb_sujets_malades': nbSujetsMalades,
      'observations': observations,
    };
  }
}