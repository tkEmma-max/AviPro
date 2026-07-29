// lib/models/comparaison.dart
class Comparaison {
  final String cycleId;
  final String cycleNom;
  final String? typePoulet;
  final int nbSujets;
  final String statut;
  final ComparaisonPrevisions previsions;
  final ComparaisonReel reel;
  final ComparaisonEcarts ecarts;
  final String analyse;
  final DateTime dateComparaison;

  Comparaison({
    required this.cycleId,
    required this.cycleNom,
    this.typePoulet,
    required this.nbSujets,
    required this.statut,
    required this.previsions,
    required this.reel,
    required this.ecarts,
    required this.analyse,
    required this.dateComparaison,
  });

  factory Comparaison.fromJson(Map<String, dynamic> json) {
    return Comparaison(
      cycleId: json['cycle_id']?.toString() ?? '',
      cycleNom: json['cycle_nom'] ?? '',
      typePoulet: json['type_poulet'],
      nbSujets: json['nb_sujets'] ?? 0,
      statut: json['statut'] ?? '',
      previsions: ComparaisonPrevisions.fromJson(json['previsions'] ?? {}),
      reel: ComparaisonReel.fromJson(json['reel'] ?? {}),
      ecarts: ComparaisonEcarts.fromJson(json['ecarts'] ?? {}),
      analyse: json['analyse'] ?? '',
      dateComparaison: json['date_comparaison'] != null
          ? DateTime.parse(json['date_comparaison'])
          : DateTime.now(),
    );
  }
}

class ComparaisonPrevisions {
  final double depensesTotales;
  final double ventesTotales;
  final double benefice;
  final double? coutProductionUnitaire;
  final double? mortaliteEstimee;
  final String fiabilite;

  ComparaisonPrevisions({
    required this.depensesTotales,
    required this.ventesTotales,
    required this.benefice,
    this.coutProductionUnitaire,
    this.mortaliteEstimee,
    required this.fiabilite,
  });

  factory ComparaisonPrevisions.fromJson(Map<String, dynamic> json) {
    return ComparaisonPrevisions(
      depensesTotales: _parseDouble(json['depenses_totales']),
      ventesTotales: _parseDouble(json['ventes_totales']),
      benefice: _parseDouble(json['benefice']),
      coutProductionUnitaire: json['cout_production_unitaire'] != null
          ? _parseDouble(json['cout_production_unitaire'])
          : null,
      mortaliteEstimee: json['mortalite_estimee'] != null
          ? _parseDouble(json['mortalite_estimee'])
          : null,
      fiabilite: json['fiabilite'] ?? 'INDISPONIBLE',
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

class ComparaisonReel {
  final double depensesTotales;
  final double ventesTotales;
  final double benefice;
  final double coutProductionUnitaire;
  final double mortaliteReelle;

  ComparaisonReel({
    required this.depensesTotales,
    required this.ventesTotales,
    required this.benefice,
    required this.coutProductionUnitaire,
    required this.mortaliteReelle,
  });

  factory ComparaisonReel.fromJson(Map<String, dynamic> json) {
    return ComparaisonReel(
      depensesTotales: _parseDouble(json['depenses_totales']),
      ventesTotales: _parseDouble(json['ventes_totales']),
      benefice: _parseDouble(json['benefice']),
      coutProductionUnitaire: _parseDouble(json['cout_production_unitaire']),
      mortaliteReelle: _parseDouble(json['mortalite_reelle']),
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

class ComparaisonEcarts {
  final EcartDetail depenses;
  final EcartDetail ventes;
  final EcartDetail benefice;
  final EcartDetail coutProduction;
  final EcartDetail mortalite;

  ComparaisonEcarts({
    required this.depenses,
    required this.ventes,
    required this.benefice,
    required this.coutProduction,
    required this.mortalite,
  });

  factory ComparaisonEcarts.fromJson(Map<String, dynamic> json) {
    return ComparaisonEcarts(
      depenses: EcartDetail.fromJson(json['depenses'] ?? {}),
      ventes: EcartDetail.fromJson(json['ventes'] ?? {}),
      benefice: EcartDetail.fromJson(json['benefice'] ?? {}),
      coutProduction: EcartDetail.fromJson(json['cout_production'] ?? {}),
      mortalite: EcartDetail.fromJson(json['mortalite'] ?? {}),
    );
  }
}

class EcartDetail {
  final double absolu;
  final double pourcentage;

  EcartDetail({required this.absolu, required this.pourcentage});

  factory EcartDetail.fromJson(Map<String, dynamic> json) {
    return EcartDetail(
      absolu: _parseDouble(json['absolu']),
      pourcentage: _parseDouble(json['pourcentage']),
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