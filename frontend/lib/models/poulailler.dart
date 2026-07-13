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
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      longueur: (json['longueur'] ?? 0.0).toDouble(),
      largeur: (json['largeur'] ?? 0.0).toDouble(),
      hauteur: json['hauteur']?.toDouble(),
      localisation: json['localisation'],
      typeSol: json['type_sol'],
      nombreMangeoires: json['nombre_mangeoires'] ?? 0,
      nombreAbreuvoirs: json['nombre_abreuvoirs'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      statut: json['statut'] ?? 'LIBRE',
      nbPouletsActuels: json['nb_poulets_actuels'] ?? 0,
      surface: json['surface']?.toDouble(),
      densiteActuelle: json['densite_actuelle']?.toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
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