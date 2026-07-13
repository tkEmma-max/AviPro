// lib/core/constants/app_constants.dart

class AppConstants {
  static const bool isProduction = true; // false = local, true = Render

  static String get apiBaseUrl {
    return isProduction
        ? 'https://avipro-backend.onrender.com/api/'
        : 'http://192.168.137.1:8000/api/';
  }

  static const String appName = 'AviPro';
  static const String appVersion = '1.0.0';

  static const String storageAccessToken = 'access_token';
  static const String storageRefreshToken = 'refresh_token';
  static const String storageUserData = 'user_data';
  static const String storageSyncDate = 'last_sync';

  static const List<String> typeElevage = ['CHAIR', 'PONDEUSE', 'LOCAL', 'AUTRE'];

  static const List<String> categoriesDepenses = [
    'ALIMENT', 'POUSSIN', 'VACCIN', 'EAU', 'ELECTRICITE',
    'MAIN_OEUVRE', 'TRANSPORT', 'ENTRETIEN', 'EQUIPEMENT', 'AUTRE'
  ];

  static const List<String> typesVente = [
    'OEUFS', 'POULETS', 'POULE_REFORME', 'POUSSINS', 'FIANTES', 'AUTRE'
  ];
}