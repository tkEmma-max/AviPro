// lib/screens/finances/finance_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class FinanceHubScreen extends StatefulWidget {
  const FinanceHubScreen({super.key});

  @override
  State<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends State<FinanceHubScreen> {
  String _selectedFilter = 'Toutes';
  DateTime _selectedDate = DateTime.now();

  // Données simulées
  final List<Map<String, dynamic>> _transactions = [
    {'type': 'vente', 'libelle': 'Vente de poulets', 'montant': 250000, 'date': '2026-07-08', 'cycle': 'Lot Juillet'},
    {'type': 'depense', 'libelle': 'Aliment pondeuse', 'montant': 85000, 'date': '2026-07-07', 'cycle': 'Bande Mars'},
    {'type': 'vente', 'libelle': "Vente d'œufs", 'montant': 120000, 'date': '2026-07-06', 'cycle': 'Bande Mars'},
    {'type': 'depense', 'libelle': 'Vaccins Gumboro', 'montant': 45000, 'date': '2026-07-05', 'cycle': 'Lot Juillet'},
    {'type': 'vente', 'libelle': 'Vente poulets locaux', 'montant': 180000, 'date': '2026-07-04', 'cycle': 'Poulets Fév'},
    {'type': 'depense', 'libelle': 'Électricité', 'montant': 32000, 'date': '2026-07-03', 'cycle': 'Général'},
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    var list = _transactions;
    if (_selectedFilter == 'Ventes') {
      list = list.where((t) => t['type'] == 'vente').toList();
    } else if (_selectedFilter == 'Dépenses') {
      list = list.where((t) => t['type'] == 'depense').toList();
    }
    return list;
  }

  double get _totalVentes {
    return _transactions
        .where((t) => t['type'] == 'vente')
        .fold(0, (sum, t) => sum + t['montant']);
  }

  double get _totalDepenses {
    return _transactions
        .where((t) => t['type'] == 'depense')
        .fold(0, (sum, t) => sum + t['montant']);
  }

  double get _soldeNet => _totalVentes - _totalDepenses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ============================================================
          // HEADER - Carte de Synthèse (25%)
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Finances',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          locale: const Locale('fr', 'FR'),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: AppBorders.buttonRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              DateFormat('MMM yyyy', 'fr_FR').format(_selectedDate),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Solde net
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_soldeNet.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (_soldeNet < 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: AppBorders.buttonRadius,
                        ),
                        child: Text(
                          'Débit',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Solde net du mois',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Ligne Ventes / Dépenses
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_totalVentes.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_totalDepenses.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
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
          // BODY - Liste des transactions (60%)
          // ============================================================
          Expanded(
            child: Column(
              children: [
                // Filtres
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: ['Toutes', 'Ventes', 'Dépenses'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
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

                // Liste des transactions
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 60,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Aucune transaction ce mois-ci',
                                style: AppTextStyles.headline4.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Enregistrez votre premier flux ci-dessous.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: _filteredTransactions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final t = _filteredTransactions[index];
                            final isVente = t['type'] == 'vente';
                            final color = isVente ? AppColors.success : AppColors.error;

                            return GestureDetector(
                              onTap: () {
                                // TODO: Ouvrir détail de la transaction
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppBorders.cardRadius,
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                  boxShadow: AppShadows.shadowCard,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: AppBorders.radiusSmall,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t['libelle'],
                                            style: AppTextStyles.subtitleMedium,
                                          ),
                                          Text(
                                            '${t['date']} • ${t['cycle']}',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isVente ? '+' : '-'} ${t['montant']} FCFA',
                                      style: AppTextStyles.numberMedium.copyWith(
                                        color: color,
                                        fontSize: 16,
                                      ),
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
          ),

          // ============================================================
          // FOOTER - Barre d'actions fixes (15%)
          // ============================================================
          Container(
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/finance/depense');
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Dépense'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorders.buttonRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/finance/vente');
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Vente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
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
        ],
      ),
    );
  }
}