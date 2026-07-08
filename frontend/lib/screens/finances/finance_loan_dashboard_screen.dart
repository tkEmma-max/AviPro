// lib/screens/finances/finance_loan_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class FinanceLoanDashboardScreen extends StatefulWidget {
  const FinanceLoanDashboardScreen({super.key});

  @override
  State<FinanceLoanDashboardScreen> createState() =>
      _FinanceLoanDashboardScreenState();
}

class _FinanceLoanDashboardScreenState
    extends State<FinanceLoanDashboardScreen> {
  // Données simulées
  final List<Map<String, dynamic>> _prets = [
    {
      'id': '1',
      'preteur': 'Crédit Agricole',
      'montant_total': 500000,
      'montant_restant': 250000,
      'taux': 5.5,
      'prochaine_echeance': '2026-07-20',
      'en_retard': false,
      'type': 'Banque',
    },
    {
      'id': '2',
      'preteur': 'Tontine Mme Koffi',
      'montant_total': 200000,
      'montant_restant': 50000,
      'taux': 0,
      'prochaine_echeance': '2026-07-05',
      'en_retard': true,
      'type': 'Tontine',
    },
    {
      'id': '3',
      'preteur': 'Frère Jean',
      'montant_total': 150000,
      'montant_restant': 150000,
      'taux': 0,
      'prochaine_echeance': '2026-07-28',
      'en_retard': false,
      'type': 'Famille',
    },
  ];

  double get _totalEmprunte {
    return _prets.fold(0, (sum, p) => sum + p['montant_total']);
  }

  double get _totalRestant {
    return _prets.fold(0, (sum, p) => sum + p['montant_restant']);
  }

  double get _totalRembourse {
    return _totalEmprunte - _totalRestant;
  }

  int get _nbPretsEnRetard {
    return _prets.where((p) => p['en_retard'] == true).length;
  }

  List<Map<String, dynamic>> get _pretsActifs {
    return _prets.where((p) => p['montant_restant'] > 0).toList();
  }

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
          'Financements',
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
          // HEADER - Carte de synthèse (28%)
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorders.cardRadius,
              border: Border(
                left: BorderSide(
                  color: AppColors.primary,
                  width: 4,
                ),
              ),
              boxShadow: AppShadows.shadowCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restant dû',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_totalRestant.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.numberLarge.copyWith(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Alerte en retard
                    if (_nbPretsEnRetard > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: AppBorders.buttonRadius,
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '$_nbPretsEnRetard en retard',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Ligne des sous-indicateurs
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total emprunté',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_totalEmprunte.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
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
                            'Total remboursé',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_totalRembourse.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
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
                            'Prêts actifs',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_pretsActifs.length}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Barre de progression (ratio remboursé)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression des remboursements',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${(_totalRembourse / _totalEmprunte * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _totalEmprunte > 0
                          ? _totalRembourse / _totalEmprunte
                          : 0,
                      backgroundColor: AppColors.grey200,
                      color: AppColors.success,
                      minHeight: 6,
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ============================================================
          // BODY - Liste des prêts actifs (57%)
          // ============================================================
          Expanded(
            child: _pretsActifs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card_outlined,
                          size: 60,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Aucun financement actif',
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Besoin de capital pour votre exploitation ?\nEnregistrez un prêt pour commencer.',
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
                    itemCount: _pretsActifs.length,
                    itemBuilder: (context, index) {
                      final pret = _pretsActifs[index];
                      final estEnRetard = pret['en_retard'] ?? false;

                      return GestureDetector(
                        onTap: () {
                          // TODO: Page 28 - Fiche détaillée
                          Navigator.pushNamed(
                            context,
                            '/finance/pret/${pret['id']}',
                            arguments: pret,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppBorders.cardRadius,
                            border: Border.all(
                              color: estEnRetard
                                  ? AppColors.error
                                  : AppColors.border,
                              width: estEnRetard ? 1.5 : 1,
                            ),
                            boxShadow: AppShadows.shadowCard,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: estEnRetard
                                      ? AppColors.error
                                      : AppColors.success,
                                  borderRadius: AppBorders.radiusSmall,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          pret['preteur'],
                                          style: AppTextStyles.subtitleLarge,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: estEnRetard
                                                ? AppColors.error
                                                    .withOpacity(0.1)
                                                : AppColors.success
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                AppBorders.buttonRadius,
                                          ),
                                          child: Text(
                                            estEnRetard ? 'En retard' : 'Actif',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                              color: estEnRetard
                                                  ? AppColors.error
                                                  : AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${pret['type']} • Prochaine échéance: ${pret['prochaine_echeance']}',
                                      style: AppTextStyles.bodySmall.copyWith(
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
                                    '${pret['montant_restant']} FCFA',
                                    style: AppTextStyles.numberMedium.copyWith(
                                      color: estEnRetard
                                          ? AppColors.error
                                          : AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'Restant dû',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
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
      // ============================================================
      // FOOTER (15%)
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/finance/pret/create');
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text(
              'NOUVEAU PRÊT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppBorders.buttonRadius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}