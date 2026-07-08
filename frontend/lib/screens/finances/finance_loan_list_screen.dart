// lib/screens/finances/finance_loan_list_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';

class FinanceLoanListScreen extends StatefulWidget {
  const FinanceLoanListScreen({super.key});

  @override
  State<FinanceLoanListScreen> createState() => _FinanceLoanListScreenState();
}

class _FinanceLoanListScreenState extends State<FinanceLoanListScreen> {
  String _filter = 'Tous';

  // Données simulées
  final List<Map<String, dynamic>> _prets = [
    {
      'id': '1',
      'preteur': 'Crédit Agricole',
      'type': 'Banque',
      'montant_total': 500000,
      'montant_restant': 250000,
      'taux': 5.5,
      'prochaine_echeance': '2026-07-20',
      'statut': 'ACTIF',
    },
    {
      'id': '2',
      'preteur': 'Tontine Mme Koffi',
      'type': 'Tontine',
      'montant_total': 200000,
      'montant_restant': 50000,
      'taux': 0,
      'prochaine_echeance': '2026-07-05',
      'statut': 'EN RETARD',
    },
    {
      'id': '3',
      'preteur': 'Frère Jean',
      'type': 'Famille',
      'montant_total': 150000,
      'montant_restant': 0,
      'taux': 0,
      'prochaine_echeance': '2026-06-30',
      'statut': 'REMBOURSÉ',
    },
    {
      'id': '4',
      'preteur': 'Microfinance ALAF',
      'type': 'Microfinance',
      'montant_total': 300000,
      'montant_restant': 120000,
      'taux': 8.0,
      'prochaine_echeance': '2026-08-10',
      'statut': 'ACTIF',
    },
  ];

  List<Map<String, dynamic>> get _filteredPrets {
    var list = _prets;
    if (_filter == 'Actifs') {
      list = list.where((p) => p['statut'] == 'ACTIF').toList();
    } else if (_filter == 'Remboursés') {
      list = list.where((p) => p['statut'] == 'REMBOURSÉ').toList();
    }

    // Trier: les "EN RETARD" en premier
    list.sort((a, b) {
      if (a['statut'] == 'EN RETARD' && b['statut'] != 'EN RETARD') return -1;
      if (b['statut'] == 'EN RETARD' && a['statut'] != 'EN RETARD') return 1;
      return 0;
    });

    return list;
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'ACTIF':
        return AppColors.success;
      case 'EN RETARD':
        return AppColors.error;
      case 'REMBOURSÉ':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  Color _getStatutBgColor(String statut) {
    switch (statut) {
      case 'ACTIF':
        return const Color(0xFFD1FAE5);
      case 'EN RETARD':
        return const Color(0xFFFEE2E2);
      case 'REMBOURSÉ':
        return const Color(0xFFF1F5F9);
      default:
        return AppColors.grey200;
    }
  }

  Color _getStatutTextColor(String statut) {
    switch (statut) {
      case 'ACTIF':
        return const Color(0xFF065F46);
      case 'EN RETARD':
        return const Color(0xFF991B1B);
      case 'REMBOURSÉ':
        return const Color(0xFF475569);
      default:
        return AppColors.textSecondary;
    }
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
          'Historique des prêts',
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
          // FILTRES (15%)
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: ['Tous', 'Actifs', 'Remboursés'].map((filter) {
                final isSelected = _filter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: AppBorders.buttonRadius,
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ============================================================
          // LISTE (85%)
          // ============================================================
          Expanded(
            child: _filteredPrets.isEmpty
                ? Center(
                    child: Text(
                      'Aucun prêt ${_filter == 'Tous' ? '' : _filter.toLowerCase()}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _filteredPrets.length,
                    separatorBuilder: (_, __) => Divider(
                      color: const Color(0xFFE2E8F0),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final pret = _filteredPrets[index];
                      final statut = pret['statut'];
                      final color = _getStatutColor(statut);
                      final bgColor = _getStatutBgColor(statut);
                      final textColor = _getStatutTextColor(statut);

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
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pret['preteur'],
                                      style: AppTextStyles.subtitleLarge,
                                    ),
                                    Text(
                                      pret['type'],
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
                                    '${pret['montant_total']} FCFA',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: AppBorders.buttonRadius,
                                    ),
                                    child: Text(
                                      statut,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
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
    );
  }
}