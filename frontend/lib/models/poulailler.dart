// lib/models/poulailler.dart
class Poulailler {
  final String id;
  final String nom;
  final double longueur;
  final double largeur;
  final double? hauteur;
  final String? localisation;
  final String? typeSol;
  final int nombreMangeoires;
  final int nombreAbreuvoirs;
  final bool isArchived;
  final String? statut;
  final int nbPouletsActuels;
  final double? surface;
  final double? densiteActuelle;
  final DateTime createdAt;
  final DateTime updatedAt;

  Poulailler({
    required this.id,
    required this.nom,
    required this.longueur,
    required this.largeur,
    this.hauteur,
    this.localisation,
    this.typeSol,
    this.nombreMangeoires = 0,
    this.nombreAbreuvoirs = 0,
    this.isArchived = false,
    this.statut,
    this.nbPouletsActuels = 0,
    this.surface,
    this.densiteActuelle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Poulailler.fromJson(Map<String, dynamic> json) {
    return Poulailler(
      id: json['id'],
      nom: json['nom'],
      longueur: json['longueur'].toDouble(),
      largeur: json['largeur'].toDouble(),
      hauteur: json['hauteur']?.toDouble(),
      localisation: json['localisation'],
      typeSol: json['type_sol'],
      nombreMangeoires: json['nombre_mangeoires'] ?? 0,
      nombreAbreuvoirs: json['nombre_abreuvoirs'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      statut: json['statut'],
      nbPouletsActuels: json['nb_poulets_actuels'] ?? 0,
      surface: json['surface']?.toDouble(),
      densiteActuelle: json['densite_actuelle']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'longueur': longueur,
      'largeur': largeur,
      'hauteur': hauteur,
      'localisation': localisation,
      'type_sol': typeSol,
      'nombre_mangeoires': nombreMangeoires,
      'nombre_abreuvoirs': nombreAbreuvoirs,
      'is_archived': isArchived,
    };
  }
}