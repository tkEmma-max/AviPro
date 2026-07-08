// lib/screens/cycles/cycle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class CycleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cycle;

  const CycleDetailScreen({super.key, required this.cycle});

  @override
  State<CycleDetailScreen> createState() => _CycleDetailScreenState();
}

class _CycleDetailScreenState extends State<CycleDetailScreen> {
  int _effectifActuel = 0;
  int _pertes = 0;

  @override
  void initState() {
    super.initState();
    _effectifActuel = widget.cycle['nbSujets'] ?? 0;
  }

  void _declarerPerte() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.radiusLarge,
        ),
        title: const Text('Déclarer une perte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nombre de poulets morts aujourd\'hui',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNumberButton('-', () {
                  setState(() {
                    if (_pertes > 0) _pertes--;
                  });
                }),
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  child: Text(
                    _pertes.toString(),
                    style: AppTextStyles.numberLarge.copyWith(
                      fontSize: 28,
                      color: AppColors.error,
                    ),
                  ),
                ),
                _buildNumberButton('+', () {
                  setState(() {
                    if (_pertes < _effectifActuel) _pertes++;
                  });
                }),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Effectif restant: ${_effectifActuel - _pertes}',
              style: AppTextStyles.bodySmall,
            ),
          ],
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
              setState(() {
                _effectifActuel -= _pertes;
                _pertes = 0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Perte déclarée. Effectif: $_effectifActuel'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.cardRadius,
                  ),
                ),
              );
            },
            child: Text(
              'Confirmer',
              style: AppTextStyles.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String label, VoidCallback onPressed) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Text(
          label,
          style: AppTextStyles.numberLarge.copyWith(
            fontSize: 24,
            color: AppColors.primary,
          ),
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycle = widget.cycle;
    final isActif = cycle['actif'] ?? true;
    final progression = cycle['progression']?.toDouble() ?? 0;
    final dateDebut = cycle['dateDebut'] ?? '01/07/2026';
    final age = cycle['age'] ?? 0;
    final type = cycle['type'] ?? 'CHAIR';
    final typeLabel = type == 'CHAIR' ? 'Chair' : type == 'PONDEUSE' ? 'Pondeuse' : 'Local';
    final mortalite = cycle['mortalite'] ?? 5.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          cycle['nom'] ?? 'Cycle',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bar_chart, color: AppColors.primary),
                        title: const Text('Rapport de performance'),
                        onTap: () {
                          print('🟢 Clic sur Rapport de performance');
                          print('🟢 Cycle ID: ${widget.cycle['id']}');
                          print('🟢 Cycle data: ${widget.cycle}');
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/cycle/report/${widget.cycle['id']}',
                            arguments: widget.cycle,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        title: const Text('Modifier le cycle'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Page 18
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.assessment_outlined, color: AppColors.primary),
                        title: const Text('Prévisions'),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Page 19
                        },
                      ),

                      // Dans le menu (more_vert)
                      ListTile(
                        leading: const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                        title: const Text('Soumettre un rapport'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/cycle/report/form',
                            arguments: widget.cycle,
                          );
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        title: const Text('Modifier le cycle'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/cycle/edit',
                            arguments: widget.cycle,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // ============================================================
            // HEADER : Nom + Âge + Effectif
            // ============================================================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isActif
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    isActif ? 'ACTIF' : 'CLÔTURÉ',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActif ? AppColors.success : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    typeLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cycle['nom'] ?? 'Cycle',
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Jour $age • Début: $dateDebut',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_effectifActuel',
                      style: AppTextStyles.numberLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'sujets vivants',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${progression.toInt()}%',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: progression > 80
                            ? AppColors.error
                            : progression > 50
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progression / 100,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progression > 80
                        ? AppColors.error
                        : progression > 50
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                  minHeight: 8,
                  borderRadius: AppBorders.buttonRadius,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // GRILLE DE SAISIE RAPIDE
            // ============================================================
            Text(
              'Actions terrain',
              style: AppTextStyles.subtitleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.4,
              children: [
                // Perte
                _buildQuickAction(
                  label: 'Déclarer une perte',
                  icon: Icons.warning,
                  color: AppColors.error,
                  bgColor: AppColors.error.withOpacity(0.08),
                  onTap: _declarerPerte,
                ),
                // Charge
                _buildQuickAction(
                  label: 'Noter une charge',
                  icon: Icons.money_off_outlined,
                  color: AppColors.primary,
                  bgColor: AppColors.primary.withOpacity(0.08),
                  onTap: () {},
                ),
                // Vente
                _buildQuickAction(
                  label: 'Enregistrer une vente',
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                  bgColor: AppColors.success.withOpacity(0.08),
                  onTap: () {},
                ),
                // Observation
                _buildQuickAction(
                  label: 'Observation',
                  icon: Icons.note_alt_outlined,
                  color: AppColors.warning,
                  bgColor: AppColors.warning.withOpacity(0.08),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // SECTION STATISTIQUES
            // ============================================================
            Text(
              'Statistiques du cycle',
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
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.shadowCard,
              ),
              child: Column(
                children: [
                  _buildStatRow('Taux de mortalité', '${mortalite.toStringAsFixed(1)}%',
                      mortalite > 10 ? AppColors.error : AppColors.success),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow('Aliment consommé', '1 250 kg', AppColors.textPrimary),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow('Total charges', '245 000 FCFA', AppColors.error),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow('Total ventes', '420 000 FCFA', AppColors.success),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow('Bénéfice estimé', '+175 000 FCFA', AppColors.success,
                      bold: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // BOUTON CLÔTURER
            // ============================================================
            if (isActif)
              Center(
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.radiusLarge,
                        ),
                        title: const Text('Clôturer le cycle ?'),
                        content: const Text(
                          'Cette action est irréversible. Les calculs de rentabilité seront figés.',
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
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cycle clôturé avec succès'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'Clôturer',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Clôturer définitivement le cycle',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppBorders.cardRadius,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: bold
              ? AppTextStyles.numberMedium.copyWith(color: valueColor)
              : AppTextStyles.bodyMedium.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
        ),
      ],
    );
  }
}