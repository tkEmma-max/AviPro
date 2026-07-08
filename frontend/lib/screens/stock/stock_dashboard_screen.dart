// lib/screens/stock/stock_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class StockDashboardScreen extends StatefulWidget {
  const StockDashboardScreen({super.key});

  @override
  State<StockDashboardScreen> createState() => _StockDashboardScreenState();
}

class _StockDashboardScreenState extends State<StockDashboardScreen> {
  String _selectedFilter = 'Tout';
  final List<String> _filters = ['Tout', 'Aliments', 'Santé', 'Matériel'];

  // Données simulées
  final List<Map<String, dynamic>> _produits = [
    {'nom': 'Aliment pondeuse', 'categorie': 'Aliments', 'quantite': 14, 'seuil': 10, 'unite': 'sacs'},
    {'nom': 'Aliment démarrage', 'categorie': 'Aliments', 'quantite': 5, 'seuil': 10, 'unite': 'sacs'},
    {'nom': 'Vaccin Gumboro', 'categorie': 'Santé', 'quantite': 8, 'seuil': 5, 'unite': 'flacons'},
    {'nom': 'Mangeoires', 'categorie': 'Matériel', 'quantite': 12, 'seuil': 15, 'unite': 'unités'},
    {'nom': 'Abreuvoirs', 'categorie': 'Matériel', 'quantite': 18, 'seuil': 10, 'unite': 'unités'},
    {'nom': 'Anticoccidien', 'categorie': 'Santé', 'quantite': 3, 'seuil': 5, 'unite': 'sachets'},
  ];

  List<Map<String, dynamic>> get _filteredProduits {
    if (_selectedFilter == 'Tout') return _produits;
    return _produits.where((p) => p['categorie'] == _selectedFilter).toList();
  }

  bool _isStockBas(int quantite, int seuil) => quantite < seuil;

  @override
  Widget build(BuildContext context) {
    final hasAlerte = _produits.any((p) => _isStockBas(p['quantite'], p['seuil']));

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
          'Gestion des stocks',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ============================================================
          // ALERTE GLOBALE (si stock bas)
          // ============================================================
          if (hasAlerte)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: AppBorders.cardRadius,
                border: Border.all(color: const Color(0xFFD97706)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Certains produits ont atteint leur seuil de sécurité.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFFD97706),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // ============================================================
          // FILTRES HORIZONTAUX
          // ============================================================
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: AppColors.primary,
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ============================================================
          // LISTE DES PRODUITS
          // ============================================================
          Expanded(
            child: _filteredProduits.isEmpty
                ? Center(
                    child: Text(
                      'Aucun produit dans cette catégorie',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _filteredProduits.length,
                    itemBuilder: (context, index) {
                      final produit = _filteredProduits[index];
                      final quantite = produit['quantite'];
                      final seuil = produit['seuil'];
                      final estBas = _isStockBas(quantite, seuil);
                      final maxStock = (seuil * 1.5).toInt();

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppBorders.cardRadius,
                          border: Border.all(
                            color: estBas ? AppColors.error : AppColors.border,
                            width: estBas ? 1.5 : 1,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produit['nom'],
                                        style: AppTextStyles.subtitleLarge,
                                      ),
                                      Text(
                                        produit['categorie'],
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
                                      '${produit['quantite']} ${produit['unite']}',
                                      style: AppTextStyles.numberMedium.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: estBas
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ),
                                    ),
                                    if (estBas)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius:
                                              AppBorders.buttonRadius,
                                        ),
                                        child: Text(
                                          '⚠️ STOCK BAS',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: const Color(0xFFD97706),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Jauge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: quantite / maxStock,
                                  backgroundColor: AppColors.grey200,
                                  color: estBas ? AppColors.error : AppColors.primary,
                                  minHeight: 6,
                                  borderRadius: AppBorders.buttonRadius,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Seuil: $seuil ${produit['unite']}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ============================================================
          // BOUTON FIXE (Formulaire de mouvement)
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
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/stock/mouvement');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
                child: const Text(
                  'NOUVEAU MOUVEMENT DE STOCK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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