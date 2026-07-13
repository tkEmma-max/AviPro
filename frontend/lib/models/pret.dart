// lib/models/pret.dart
class Pret {
  final String id;
  final String preteur;
  final String typePreteur;
  final double montantTotal;
  final DateTime dateDeblocage;
  final double tauxInteret;
  final String modeRemboursement;
  final int? dureeTotaleMois;
  final String? periodicite;
  final double montantRestant;
  final bool isRembourse;
  final List<String> cyclesAffectes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pret({
    required this.id,
    required this.preteur,
    required this.typePreteur,
    required this.montantTotal,
    required this.dateDeblocage,
    required this.tauxInteret,
    required this.modeRemboursement,
    this.dureeTotaleMois,
    this.periodicite,
    required this.montantRestant,
    this.isRembourse = false,
    this.cyclesAffectes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pret.fromJson(Map<String, dynamic> json) {
    return Pret(
      id: json['id'] ?? '',
      preteur: json['preteur'] ?? '',
      typePreteur: json['type_preteur'] ?? 'BANQUE',
      montantTotal: _parseDouble(json['montant_total']),
      dateDeblocage: json['date_deblocage'] != null
          ? DateTime.parse(json['date_deblocage'])
          : DateTime.now(),
      tauxInteret: _parseDouble(json['taux_interet']),
      modeRemboursement: json['mode_remboursement'] ?? 'PROPOSE',
      dureeTotaleMois: json['duree_totale_mois'],
      periodicite: json['periodicite'],
      montantRestant: _parseDouble(json['montant_restant']),
      isRembourse: json['is_rembourse'] ?? false,
      cyclesAffectes: List<String>.from(json['cycles_affectes'] ?? []),
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
      'preteur': preteur,
      'type_preteur': typePreteur,
      'montant_total': montantTotal,
      'date_deblocage': dateDeblocage.toIso8601String(),
      'taux_interet': tauxInteret,
      'mode_remboursement': modeRemboursement,
      'duree_totale_mois': dureeTotaleMois,
      'periodicite': periodicite,
      'cycles_affectes': cyclesAffectes,
    };
  }
}