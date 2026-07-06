// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'AviPro';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'http://localhost:8000/api/';

  // Clés de stockage
  static const String storageAccessToken = 'access_token';
  static const String storageRefreshToken = 'refresh_token';
  static const String storageUserData = 'user_data';
  static const String storageSyncDate = 'last_sync';

  // Types d'élevage
  static const List<String> typeElevage = ['CHAIR', 'PONDEUSE', 'LOCAL', 'AUTRE'];

  // Catégories de dépenses
  static const List<String> categoriesDepenses = [
    'ALIMENT', 'POUSSIN', 'VACCIN', 'EAU', 'ELECTRICITE',
    'MAIN_OEUVRE', 'TRANSPORT', 'ENTRETIEN', 'EQUIPEMENT', 'AUTRE'
  ];

  // Types de vente
  static const List<String> typesVente = [
    'OEUFS', 'POULETS', 'POULE_REFORME', 'POUSSINS', 'FIANTES', 'AUTRE'
  ];
}