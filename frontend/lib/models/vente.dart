// lib/models/vente.dart
class Vente {
  final String id;
  final String cycle;
  final String? cycleNom;
  final String type;
  final String? typeLabel;
  final String? typeVente;
  final String? typeVenteNom;
  final int quantite;
  final double prixUnitaire;
  final double montantTotal;
  final DateTime date;
  final String? description;
  final String? client;
  final String? clientNom;
  final String? factureNumero;
  final String? facturePhoto;
  final String? signature;
  final double? prixDeRevient;
  final bool? estRentable;
  final double? margeUnitaire;
  final double? pourcentageBenefice;
  final String? statusVente;
  final double? cumulBeneficesCycle;
  final double? potentielRestant;
  final String? poulaillerNom;
  final bool remboursementConfirme;
  final String? vendeur;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vente({
    required this.id,
    required this.cycle,
    this.cycleNom,
    required this.type,
    this.typeLabel,
    this.typeVente,
    this.typeVenteNom,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantTotal,
    required this.date,
    this.description,
    this.client,
    this.clientNom,
    this.factureNumero,
    this.facturePhoto,
    this.signature,
    this.prixDeRevient,
    this.estRentable,
    this.margeUnitaire,
    this.pourcentageBenefice,
    this.statusVente,
    this.cumulBeneficesCycle,
    this.potentielRestant,
    this.poulaillerNom,
    this.remboursementConfirme = false,
    this.vendeur,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vente.fromJson(Map<String, dynamic> json) {
    return Vente(
      id: json['id']?.toString() ?? '',
      cycle: json['cycle']?.toString() ?? '',
      cycleNom: json['cycle_nom'],
      type: json['type'] ?? '',
      typeLabel: json['type_label'],
      typeVente: json['type_vente'],
      typeVenteNom: json['type_vente_nom'],
      quantite: (json['quantite'] is int)
          ? json['quantite']
          : (double.tryParse(json['quantite']?.toString() ?? '0') ?? 0).toInt(),
      prixUnitaire: _parseDouble(json['prix_unitaire']),
      montantTotal: _parseDouble(json['montant_total']),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description: json['description'],
      client: json['client'],
      clientNom: json['client_nom'],
      factureNumero: json['facture_numero'],
      facturePhoto: json['facture_photo'],
      signature: json['signature'],
      prixDeRevient: json['prix_de_revient'] != null ? _parseDouble(json['prix_de_revient']) : null,
      estRentable: json['est_rentable'],
      margeUnitaire: json['marge_unitaire'] != null ? _parseDouble(json['marge_unitaire']) : null,
      pourcentageBenefice: json['pourcentage_benefice'] != null ? _parseDouble(json['pourcentage_benefice']) : null,
      statusVente: json['status_vente'],
      cumulBeneficesCycle: json['cumul_benefices_cycle'] != null ? _parseDouble(json['cumul_benefices_cycle']) : null,
      potentielRestant: json['potentiel_restant'] != null ? _parseDouble(json['potentiel_restant']) : null,
      poulaillerNom: json['poulailler_nom'],
      remboursementConfirme: json['remboursement_confirme'] ?? false,
      vendeur: json['vendeur'],
      metadata: json['metadata'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'cycle': cycle,
      'type': type,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'date': date.toIso8601String().split('T')[0],
    };
    if (id.isNotEmpty) data['id'] = id;
    if (typeVente != null) data['type_vente'] = typeVente;
    if (client != null) data['client'] = client;
    if (description != null && description!.isNotEmpty) data['description'] = description;
    if (vendeur != null && vendeur!.isNotEmpty) data['vendeur'] = vendeur;
    if (factureNumero != null) data['facture_numero'] = factureNumero;
    if (signature != null) data['signature'] = signature;
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