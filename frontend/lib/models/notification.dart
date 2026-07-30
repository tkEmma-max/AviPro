// lib/models/notification.dart
class NotificationModel {
  final String id;
  final String type;
  final String typeLabel;
  final String titre;
  final String message;
  final Map<String, dynamic>? donnees;
  final bool estLue;
  final DateTime dateCreation;

  NotificationModel({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.titre,
    required this.message,
    this.donnees,
    required this.estLue,
    required this.dateCreation,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      typeLabel: json['type_label'] ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      donnees: json['donnees'] is Map ? Map<String, dynamic>.from(json['donnees']) : null,
      estLue: json['est_lue'] ?? false,
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
    );
  }
  
  // Dans notification.dart, ajouter cette méthode :
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'type_label': typeLabel,
      'titre': titre,
      'message': message,
      'donnees': donnees,
      'est_lue': estLue,
      'date_creation': dateCreation.toIso8601String(),
    };
  }
}