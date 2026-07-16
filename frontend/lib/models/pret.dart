// lib/models/pret.dart
class Pret {
  final String id;
  final String preteur;
  final String typePreteur;
  final double montantTotal;
  final DateTime dateDeblocage;
  final double tauxInteret;
  final String typeTaux; // 'MENSUEL' ou 'ANNUEL'
  final String modeRemboursement;
  final int? dureeTotaleMois;
  final String? periodicite;
  final DateTime? dateLimite;
  final double montantRestant;
  final double? totalRembourse;
  final bool isRembourse;
  final bool? estEnRetard;
  final List<String> cyclesAffectes;
  final Map<String, dynamic>? prochaineEcheance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pret({
    required this.id,
    required this.preteur,
    required this.typePreteur,
    required this.montantTotal,
    required this.dateDeblocage,
    required this.tauxInteret,
    this.typeTaux = 'MENSUEL',
    required this.modeRemboursement,
    this.dureeTotaleMois,
    this.periodicite,
    this.dateLimite,
    required this.montantRestant,
    this.totalRembourse,
    this.isRembourse = false,
    this.estEnRetard,
    this.cyclesAffectes = const [],
    this.prochaineEcheance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pret.fromJson(Map<String, dynamic> json) {
    return Pret(
      id: json['id']?.toString() ?? '',
      preteur: json['preteur'] ?? '',
      typePreteur: json['type_preteur'] ?? 'BANQUE',
      montantTotal: _parseDouble(json['montant_total']),
      dateDeblocage: json['date_deblocage'] != null ? DateTime.parse(json['date_deblocage']) : DateTime.now(),
      tauxInteret: _parseDouble(json['taux_interet']),
      typeTaux: json['type_taux'] ?? 'MENSUEL',
      modeRemboursement: json['mode_remboursement'] ?? 'PROPOSE',
      dureeTotaleMois: json['duree_totale_mois'] is int ? json['duree_totale_mois'] : int.tryParse(json['duree_totale_mois']?.toString() ?? ''),
      periodicite: json['periodicite'],
      dateLimite: json['date_limite'] != null ? DateTime.parse(json['date_limite']) : null,
      montantRestant: _parseDouble(json['montant_restant']),
      totalRembourse: json['total_rembourse'] != null ? _parseDouble(json['total_rembourse']) : null,
      isRembourse: json['is_rembourse'] ?? false,
      estEnRetard: json['est_en_retard'],
      cyclesAffectes: json['cycles_affectes'] is List ? List<String>.from(json['cycles_affectes']) : [],
      prochaineEcheance: json['prochaine_echeance'] is Map ? Map<String, dynamic>.from(json['prochaine_echeance']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
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
    final data = <String, dynamic>{
      'preteur': preteur,
      'type_preteur': typePreteur,
      'montant_total': montantTotal.toInt(),
      'date_deblocage': dateDeblocage.toIso8601String().split('T')[0],
      'taux_interet': tauxInteret,
      'type_taux': typeTaux,
      'mode_remboursement': modeRemboursement,
    };
    if (id.isNotEmpty) data['id'] = id;
    if (dureeTotaleMois != null) data['duree_totale_mois'] = dureeTotaleMois;
    if (periodicite != null) data['periodicite'] = periodicite;
    if (dateLimite != null) data['date_limite'] = dateLimite!.toIso8601String().split('T')[0];
    if (cyclesAffectes.isNotEmpty) data['cycles_affectes'] = cyclesAffectes;
    return data;
  }
}