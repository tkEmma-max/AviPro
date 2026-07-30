// lib/models/prevision.dart
class Prevision {
  final String typePoulet;
  final PeriodePrevision periode;
  final int nbSujets;
  final int nbCyclesHistorique;
  final int nbRapportsUtilises;
  final String methode;
  final String fiabilite;
  final ConsommationsPrevision? consommations;
  final DepensesPrevision? depenses;
  final VentesPrevision? ventes;
  final double? beneficePrevisionnel;
  final double? coutProductionUnitaire;
  final double? mortaliteEstimee;
  final int dureeEstimeeJours;
  final String? message;

  Prevision({
    required this.typePoulet,
    required this.periode,
    required this.nbSujets,
    required this.nbCyclesHistorique,
    required this.nbRapportsUtilises,
    required this.methode,
    required this.fiabilite,
    this.consommations,
    this.depenses,
    this.ventes,
    this.beneficePrevisionnel,
    this.coutProductionUnitaire,
    this.mortaliteEstimee,
    required this.dureeEstimeeJours,
    this.message,
  });

  factory Prevision.fromJson(Map<String, dynamic> json) {
    return Prevision(
      typePoulet: json['type_poulet'] ?? '',
      periode: PeriodePrevision.fromJson(json['periode'] ?? {}),
      nbSujets: json['nb_sujets'] ?? 0,
      nbCyclesHistorique: json['nb_cycles_historique'] ?? 0,
      nbRapportsUtilises: json['nb_rapports_utilises'] ?? 0,
      methode: json['methode'] ?? 'AUCUNE',
      fiabilite: json['fiabilite'] ?? 'INDISPONIBLE',
      consommations: json['consommations'] != null
          ? ConsommationsPrevision.fromJson(json['consommations'])
          : null,
      depenses: json['depenses'] != null
          ? DepensesPrevision.fromJson(json['depenses'])
          : null,
      ventes: json['ventes'] != null
          ? VentesPrevision.fromJson(json['ventes'])
          : null,
      beneficePrevisionnel: json['benefice_previsionnel'] != null
          ? _parseDouble(json['benefice_previsionnel'])
          : null,
      coutProductionUnitaire: json['cout_production_unitaire'] != null
          ? _parseDouble(json['cout_production_unitaire'])
          : null,
      mortaliteEstimee: json['mortalite_estimee'] != null
          ? _parseDouble(json['mortalite_estimee'])
          : null,
      dureeEstimeeJours: json['duree_estimee_jours'] ?? 0,
      message: json['message'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class PeriodePrevision {
  final int debut;
  final int fin;
  final int jours;

  PeriodePrevision({
    required this.debut,
    required this.fin,
    required this.jours,
  });

  factory PeriodePrevision.fromJson(Map<String, dynamic> json) {
    return PeriodePrevision(
      debut: json['debut'] ?? 0,
      fin: json['fin'] ?? 0,
      jours: json['jours'] ?? 0,
    );
  }
}

class ConsommationsPrevision {
  final double alimentParSujetParJour;
  final double eauParSujetParJour;
  final double ratioEauAliment;
  final double alimentTotalEstime;
  final double eauTotalEstimee;

  ConsommationsPrevision({
    required this.alimentParSujetParJour,
    required this.eauParSujetParJour,
    required this.ratioEauAliment,
    required this.alimentTotalEstime,
    required this.eauTotalEstimee,
  });

  factory ConsommationsPrevision.fromJson(Map<String, dynamic> json) {
    return ConsommationsPrevision(
      alimentParSujetParJour: _parseDouble(json['aliment_par_sujet_par_jour']),
      eauParSujetParJour: _parseDouble(json['eau_par_sujet_par_jour']),
      ratioEauAliment: _parseDouble(json['ratio_eau_aliment']),
      alimentTotalEstime: _parseDouble(json['aliment_total_estime']),
      eauTotalEstimee: _parseDouble(json['eau_total_estimee']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class DepensesPrevision {
  final double? total;
  final List<CategoriePrevision> parCategorie;

  DepensesPrevision({
    this.total,
    required this.parCategorie,
  });

  factory DepensesPrevision.fromJson(Map<String, dynamic> json) {
    return DepensesPrevision(
      total: json['total'] != null ? _parseDouble(json['total']) : null,
      parCategorie: (json['par_categorie'] as List?)
          ?.map((e) => CategoriePrevision.fromJson(e))
          .toList() ?? [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class VentesPrevision {
  final double? total;
  final List<CategoriePrevision> parType;

  VentesPrevision({
    this.total,
    required this.parType,
  });

  factory VentesPrevision.fromJson(Map<String, dynamic> json) {
    return VentesPrevision(
      total: json['total'] != null ? _parseDouble(json['total']) : null,
      parType: (json['par_type'] as List?)
          ?.map((e) => CategoriePrevision.fromJson(e))
          .toList() ?? [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CategoriePrevision {
  final String categorie;
  final double montantEstime;

  CategoriePrevision({
    required this.categorie,
    required this.montantEstime,
  });

  factory CategoriePrevision.fromJson(Map<String, dynamic> json) {
    return CategoriePrevision(
      categorie: json['categorie'] ?? '',
      montantEstime: _parseDouble(json['montant_estime']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}