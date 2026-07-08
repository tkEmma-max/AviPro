// lib/screens/cycles/cycle_report_history_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class CycleReportHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> cycle;

  const CycleReportHistoryScreen({
    super.key,
    required this.cycle,
  });

  @override
  State<CycleReportHistoryScreen> createState() =>
      _CycleReportHistoryScreenState();
}

class _CycleReportHistoryScreenState
    extends State<CycleReportHistoryScreen> {
  // Données simulées
  final List<Map<String, dynamic>> _rapports = [
    {
      'id': '1',
      'periode': '08-14 Juillet 2026',
      'aliment': 45.5,
      'eau': 78.0,
      'maladie': null,
      'date': '2026-07-14',
    },
    {
      'id': '2',
      'periode': '01-07 Juillet 2026',
      'aliment': 42.0,
      'eau': 72.5,
      'maladie': 'Coccidiose suspectée',
      'date': '2026-07-07',
    },
    {
      'id': '3',
      'periode': '24-30 Juin 2026',
      'aliment': 38.0,
      'eau': 65.0,
      'maladie': null,
      'date': '2026-06-30',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historique des rapports',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ============================================================
          // HEADER : Résumé du cycle
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorders.cardRadius,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.shadowCard,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cycle['nom'] ?? 'Cycle',
                        style: AppTextStyles.subtitleLarge,
                      ),
                      Text(
                        '${_rapports.length} rapports soumis',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
                    color: _rapports.any((r) => r['maladie'] != null)
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    _rapports.any((r) => r['maladie'] != null)
                        ? '⚠️ Alertes'
                        : '✅ Sain',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _rapports.any((r) => r['maladie'] != null)
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          // LISTE DES RAPPORTS
          // ============================================================
          Expanded(
            child: _rapports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assessment_outlined,
                          size: 60,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Aucun rapport de suivi',
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Prenez l\'habitude de noter les indicateurs chaque jour.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _rapports.length,
                    itemBuilder: (context, index) {
                      final r = _rapports[index];
                      final hasMaladie = r['maladie'] != null;

                      return GestureDetector(
                        onTap: () {
                          // TODO: Ouvrir le détail du rapport
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppBorders.cardRadius,
                            border: Border(
                              left: BorderSide(
                                color: hasMaladie ? AppColors.error : AppColors.primary,
                                width: 4,
                              ),
                            ),
                            boxShadow: AppShadows.shadowCard,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          r['periode'],
                                          style: AppTextStyles.subtitleMedium,
                                        ),
                                        if (hasMaladie) ...[
                                          const SizedBox(width: AppSpacing.sm),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withOpacity(0.1),
                                              borderRadius: AppBorders.buttonRadius,
                                            ),
                                            child: Text(
                                              'Maladie',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Aliment: ${r['aliment']} kg • Eau: ${r['eau']} L',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textHint,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/cycle/report/form',
            arguments: widget.cycle,
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}