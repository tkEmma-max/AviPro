// lib/screens/stock/stock_history_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  // Données simulées
  final List<Map<String, dynamic>> _transactions = [
    {'type': 'Achat', 'nom': 'Aliment pondeuse', 'date': '2026-07-08', 'quantite': '+10', 'categorie': 'Aliments', 'impact': '+25 000 FCFA'},
    {'type': 'Utilisation', 'nom': 'Aliment démarrage', 'date': '2026-07-07', 'quantite': '-3', 'categorie': 'Aliments', 'impact': '-7 500 FCFA'},
    {'type': 'Achat', 'nom': 'Vaccin Gumboro', 'date': '2026-07-06', 'quantite': '+5', 'categorie': 'Santé', 'impact': '+15 000 FCFA'},
    {'type': 'Utilisation', 'nom': 'Aliment pondeuse', 'date': '2026-07-05', 'quantite': '-8', 'categorie': 'Aliments', 'impact': '-20 000 FCFA'},
    {'type': 'Achat', 'nom': 'Mangeoires', 'date': '2026-07-04', 'quantite': '+4', 'categorie': 'Matériel', 'impact': '+12 000 FCFA'},
    {'type': 'Utilisation', 'nom': 'Anticoccidien', 'date': '2026-07-03', 'quantite': '-2', 'categorie': 'Santé', 'impact': '-4 000 FCFA'},
  ];

  Color _getCategoryColor(String categorie) {
    switch (categorie) {
      case 'Aliments': return const Color(0xFFFEF3C7);
      case 'Santé': return const Color(0xFFEDE9FE);
      case 'Matériel': return const Color(0xFFD1FAE5);
      default: return AppColors.surfaceLight;
    }
  }

  IconData _getCategoryIcon(String categorie) {
    switch (categorie) {
      case 'Aliments': return Icons.restaurant;
      case 'Santé': return Icons.health_and_safety;
      case 'Matériel': return Icons.build;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDepenses = 83500;

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
          'Journal des flux',
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
          // BANDEAU DE SYNTHÈSE
          // ============================================================
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorders.cardRadius,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.shadowCard,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total des dépenses',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$totalDepenses FCFA',
                      style: AppTextStyles.numberMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
                      color: AppColors.surfaceLight,
                      borderRadius: AppBorders.buttonRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ============================================================
          // LISTE DES TRANSACTIONS
          // ============================================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final t = _transactions[index];
                final isPositive = t['type'] == 'Achat';
                final color = _getCategoryColor(t['categorie']);
                final icon = _getCategoryIcon(t['categorie']);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icône circulaire
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isPositive ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Texte central
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['nom'],
                              style: AppTextStyles.subtitleMedium,
                            ),
                            Text(
                              '${t['date']} • ${t['type']}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Valeur
                      Text(
                        t['quantite'],
                        style: AppTextStyles.numberMedium.copyWith(
                          color: isPositive ? AppColors.success : AppColors.error,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ============================================================
          // BOUTON EXPORTATION
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export CSV en cours de développement'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('EXPORTER EN CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}