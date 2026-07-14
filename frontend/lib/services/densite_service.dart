// lib/services/densite_service.dart

class DensiteService {

  /// Retourne la densité recommandée (poulets/m²) selon le type et l'âge
  static double getDensiteRecommandee(String typeElevage, int ageJours) {
    switch (typeElevage.toUpperCase()) {
      case 'CHAIR':
        return _getDensiteChair(ageJours);
      case 'PONDEUSE':
        return _getDensitePondeuse(ageJours);
      case 'LOCAL':
        return _getDensiteLocal(ageJours);
      default:
        return 8.0;
    }
  }

  /// Poulet de chair (45 jours)
  static double _getDensiteChair(int ageJours) {
    if (ageJours <= 7) return 45.0;
    if (ageJours <= 21) return 22.0;
    if (ageJours <= 35) return 13.0;
    return 8.0;
  }

  /// Poule pondeuse (70 semaines = 490 jours)
  static double _getDensitePondeuse(int ageJours) {
    if (ageJours <= 7) return 45.0;
    if (ageJours <= 56) return 22.0;
    if (ageJours <= 126) return 10.0;
    if (ageJours <= 490) return 7.0;
    return 5.0;
  }

  /// Poulet local (variable)
  static double _getDensiteLocal(int ageJours) {
    if (ageJours <= 7) return 37.0;
    if (ageJours <= 84) return 17.0;
    if (ageJours <= 168) return 10.0;
    return 6.0;
  }

  /// Calcule la capacité maximale
  static int getCapaciteMax(double surface, String typeElevage, int ageJours) {
    final densite = getDensiteRecommandee(typeElevage, ageJours);
    return (surface * densite).floor();
  }

  /// Niveau d'alerte : 0 = OK, 1 = Élevée, 2 = Critique
  static int getNiveauAlerte(double surface, int nbPoulets, String typeElevage, int ageJours) {
    final capaciteMax = getCapaciteMax(surface, typeElevage, ageJours);
    if (capaciteMax == 0) return 0;

    final ratio = nbPoulets / capaciteMax;
    if (ratio <= 0.8) return 0;
    if (ratio <= 1.0) return 1;
    return 2;
  }
}