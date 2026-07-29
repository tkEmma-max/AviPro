// lib/models/type_poulet.dart
class TypePoulet {
  final String id;
  final String nom;
  final String? description;
  final int dureeEstimeeJours;
  final double densiteRecommandee;
  final double prixPoussinMoyen;
  final bool isActive;

  TypePoulet({
    required this.id,
    required this.nom,
    this.description,
    required this.dureeEstimeeJours,
    required this.densiteRecommandee,
    required this.prixPoussinMoyen,
    required this.isActive,
  });

  factory TypePoulet.fromJson(Map<String, dynamic> json) {
    return TypePoulet(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      dureeEstimeeJours: json['duree_estimee_jours'] ?? 0,
      densiteRecommandee: _parseDouble(json['densite_recommandee']),
      prixPoussinMoyen: _parseDouble(json['prix_poussin_moyen']),
      isActive: json['is_active'] ?? true,
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