// lib/screens/poulaillers/poulailler_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';

class PoulaillerDetailScreen extends StatelessWidget {
  final Poulailler poulailler;

  const PoulaillerDetailScreen({
    super.key,
    required this.poulailler,
  });

  @override
  Widget build(BuildContext context) {
    final isOccupied = poulailler.statut == 'OCCUPÉ';
    final statutColor = isOccupied ? AppColors.warning : AppColors.success;
    final statutLabel = isOccupied ? 'OCCUPÉ' : 'LIBRE';
    final statutBg = isOccupied
        ? AppColors.warning.withOpacity(0.1)
        : AppColors.success.withOpacity(0.1);

    // Vérification équipements (F49)
    final nbMangeoiresRecommandees = (poulailler.nbPouletsActuels / 50).ceil();
    final nbAbreuvoirsRecommandes = (poulailler.nbPouletsActuels / 30).ceil();
    final alerteMangeoires = poulailler.nbPouletsActuels > 0 &&
        poulailler.nombreMangeoires < nbMangeoiresRecommandees;
    final alerteAbreuvoirs = poulailler.nbPouletsActuels > 0 &&
        poulailler.nombreAbreuvoirs < nbAbreuvoirsRecommandes;
    final hasAlerteEquipement = alerteMangeoires || alerteAbreuvoirs;

    // Densité
    final densite = poulailler.densiteActuelle ?? 0;
    Color densiteColor;
    String densiteLabel;
    if (densite < 5) {
      densiteColor = AppColors.success;
      densiteLabel = 'OK';
    } else if (densite < 10) {
      densiteColor = AppColors.warning;
      densiteLabel = 'Élevée';
    } else {
      densiteColor = AppColors.error;
      densiteLabel = 'Critique';
    }

    // Occupation (pour la jauge)
    final capaciteMax = poulailler.surface ?? 0 * 8;
    final tauxOccupation = capaciteMax > 0
        ? (poulailler.nbPouletsActuels / capaciteMax).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails du poulailler',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // ============================================================
            // EN-TÊTE DYNAMIQUE
            // ============================================================
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poulailler.nom,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: statutBg,
                              borderRadius: AppBorders.buttonRadius,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statutColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statutLabel,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: statutColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isOccupied) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '• Bande en cours',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ============================================================
            // BLOC RATIOS & ALERTES ÉQUIPEMENTS
            // ============================================================
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppBorders.cardRadius,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppShadows.shadowCard,
              ),
              child: Column(
                children: [
                  // Densité
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Densité actuelle',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${densite.toStringAsFixed(1)} sujets/m²',
                              style: AppTextStyles.numberMedium.copyWith(
                                color: densiteColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: densiteColor.withOpacity(0.1),
                          borderRadius: AppBorders.buttonRadius,
                        ),
                        child: Text(
                          densiteLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: densiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Jauge d'occupation
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Occupation',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(tauxOccupation * 100).toInt()}%',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: tauxOccupation,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tauxOccupation > 0.8
                              ? AppColors.error
                              : tauxOccupation > 0.6
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                        minHeight: 8,
                        borderRadius: AppBorders.buttonRadius,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Équipements
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mangeoires',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${poulailler.nombreMangeoires}',
                              style: AppTextStyles.numberSmall.copyWith(
                                color: alerteMangeoires
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Abreuvoirs',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${poulailler.nombreAbreuvoirs}',
                              style: AppTextStyles.numberSmall.copyWith(
                                color: alerteAbreuvoirs
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surface',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${poulailler.surface?.toStringAsFixed(1) ?? '0'} m²',
                              style: AppTextStyles.numberSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============================================================
            // ALERTE ÉQUIPEMENT (F49)
            // ============================================================
            if (hasAlerteEquipement)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '⚠️ Matériel insuffisant : ${alerteMangeoires ? 'Ajoutez au moins ${nbMangeoiresRecommandees - poulailler.nombreMangeoires} mangeoires' : ''}${alerteMangeoires && alerteAbreuvoirs ? ' et ' : ''}${alerteAbreuvoirs ? 'Ajoutez au moins ${nbAbreuvoirsRecommandes - poulailler.nombreAbreuvoirs} abreuvoirs' : ''} pour ce volume de sujets.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            // ============================================================
            // HISTORIQUE DES CYCLES PASSÉS
            // ============================================================
            Text(
              'Historique des cycles',
              style: AppTextStyles.subtitleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppBorders.cardRadius,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppShadows.shadowCard,
              ),
              child: Column(
                children: [
                  _buildHistoriqueItem(
                    nom: 'Bande Championne 2',
                    periode: '15 Jan - 28 Fév 2026',
                    mortalite: '5%',
                    benefice: '+245 000 FCFA',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildHistoriqueItem(
                    nom: 'Lot Poussins Décembre',
                    periode: '01 Déc - 14 Jan 2026',
                    mortalite: '8%',
                    benefice: '+180 000 FCFA',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildHistoriqueItem(
                    nom: 'Bande Automne 2025',
                    periode: '15 Sep - 30 Oct 2025',
                    mortalite: '3%',
                    benefice: '+320 000 FCFA',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),

      // ============================================================
      // BARRE D'ACTIONS FLOTTANTE
      // ============================================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Modifier
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/poulailler/edit',
                    arguments: poulailler,
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Migrer
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isOccupied
                    ? () {
                        Navigator.pushNamed(
                          context,
                          '/poulailler/migration',
                          arguments: poulailler,
                        );
                      }
                    : null,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Migrer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Supprimer
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !isOccupied && poulailler.nbPouletsActuels == 0
                    ? () => _showDeleteConfirmation(context)
                    : null,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoriqueItem({
    required String nom,
    required String periode,
    required String mortalite,
    required String benefice,
  }) {
    final isPositif = benefice.startsWith('+');
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            borderRadius: AppBorders.radiusSmall,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom, style: AppTextStyles.subtitleMedium),
              Text(periode, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Mortalité: $mortalite',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              benefice,
              style: AppTextStyles.subtitleMedium.copyWith(
                color: isPositif ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.radiusLarge,
        ),
        title: const Text('Supprimer le poulailler ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le poulailler "${poulailler.nom}" ? Cette action est irréversible.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<PoulaillerProvider>();
              provider.deletePoulailler(poulailler.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Poulailler "${poulailler.nom}" supprimé.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.cardRadius,
                  ),
                ),
              );
            },
            child: Text(
              'Supprimer',
              style: AppTextStyles.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}