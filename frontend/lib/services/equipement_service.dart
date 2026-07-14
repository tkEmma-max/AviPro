// lib/services/equipement_service.dart
import 'densite_service.dart';

class EquipementService {

  /// Retourne le nombre de mangeoires recommandé
  static int getMangeoiresRecommandees(int nbPoulets, String typeElevage, int ageJours) {
    // Base : 1 mangeoire circulaire pour 50 poulets adultes
    // Ajustement selon l'âge : les jeunes mangent moins, donc moins de concurrence
    final ratio = _getRatioMangeoire(typeElevage, ageJours);
    return (nbPoulets / ratio).ceil();
  }

  /// Retourne le nombre d'abreuvoirs recommandé
  static int getAbreuvoirsRecommandes(int nbPoulets, String typeElevage, int ageJours) {
    // Base : 1 abreuvoir siphon pour 30 poulets adultes
    final ratio = _getRatioAbreuvoir(typeElevage, ageJours);
    return (nbPoulets / ratio).ceil();
  }

  /// Ratio mangeoires : plus l'âge augmente, plus il faut de mangeoires
  static double _getRatioMangeoire(String typeElevage, int ageJours) {
    // Jeunes : 60 poulets/mangeoire (mangent peu, moins de compétition)
    // Adultes : 40-50 poulets/mangeoire
    if (ageJours <= 7) return 60.0;
    if (ageJours <= 21) return 55.0;
    if (ageJours <= 35) return 50.0;
    return 45.0;
  }

  /// Ratio abreuvoirs : plus l'âge augmente, plus il faut d'abreuvoirs
  static double _getRatioAbreuvoir(String typeElevage, int ageJours) {
    if (ageJours <= 7) return 40.0;
    if (ageJours <= 21) return 35.0;
    if (ageJours <= 35) return 30.0;
    return 25.0;
  }

  /// Calcule les recommandations pour un poulailler vide (basé sur la capacité max)
  static Map<String, int> getRecommandationsPoulaillerVide(double surface) {
    // Pour un poulailler vide, on prend le pire cas : poussins chair (densité max = 45)
    final capaciteMax = (surface * 45.0).floor();
    return {
      'mangeoires': (capaciteMax / 60.0).ceil(),
      'abreuvoirs': (capaciteMax / 40.0).ceil(),
      'capacite_max': capaciteMax,
    };
  }
}