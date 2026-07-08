// lib/screens/cycles/cycle_list_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class CycleListScreen extends StatefulWidget {
  const CycleListScreen({super.key});

  @override
  State<CycleListScreen> createState() => _CycleListScreenState();
}

class _CycleListScreenState extends State<CycleListScreen> {
  String _filter = 'Actifs';

  // Données simulées avec id
  final List<Map<String, dynamic>> _cycles = [
    {
      'id': '1',
      'nom': 'Lot Poussins Juillet',
      'type': 'CHAIR',
      'date': '01/07/2026',
      'age': 21,
      'duree': 45,
      'progression': 46,
      'actif': true,
      'nbSujets': 50,
      'mortalite': 5.0,
    },
    {
      'id': '2',
      'nom': 'Bande Pondeuses Mars',
      'type': 'PONDEUSE',
      'date': '15/03/2026',
      'age': 112,
      'duree': 490,
      'progression': 22,
      'actif': true,
      'nbSujets': 30,
      'mortalite': 8.0,
    },
    {
      'id': '3',
      'nom': 'Poulets Locaux Février',
      'type': 'LOCAL',
      'date': '01/02/2026',
      'age': 155,
      'duree': 210,
      'progression': 73,
      'actif': false,
      'nbSujets': 20,
      'mortalite': 12.0,
    },
    {
      'id': '4',
      'nom': 'Poulet Chair Mai',
      'type': 'CHAIR',
      'date': '15/05/2026',
      'age': 7,
      'duree': 45,
      'progression': 15,
      'actif': true,
      'nbSujets': 60,
      'mortalite': 3.0,
    },
  ];

  List<Map<String, dynamic>> get _filteredCycles {
    if (_filter == 'Tous') return _cycles;
    if (_filter == 'Actifs') {
      return _cycles.where((c) => c['actif'] == true).toList();
    }
    return _cycles.where((c) => c['actif'] == false).toList();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'CHAIR':
        return AppColors.primary;
      case 'PONDEUSE':
        return AppColors.warning;
      case 'LOCAL':
        return AppColors.success;
      default:
        return AppColors.textHint;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'CHAIR':
        return 'Chair';
      case 'PONDEUSE':
        return 'Pondeuse';
      case 'LOCAL':
        return 'Local';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Cycles de production'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () {
              // TODO: Comparer cycles
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ============================================================
          // FILTRES
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: ['Actifs', 'Clôturés', 'Tous'].map((filter) {
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
          // LISTE DES CYCLES
          // ============================================================
          Expanded(
            child: _filteredCycles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline_outlined,
                          size: 60,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Aucun cycle ${_filter.toLowerCase()}',
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _filteredCycles.length,
                    itemBuilder: (context, index) {
                      final cycle = _filteredCycles[index];
                      return _buildCycleCard(cycle);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cycle/create');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCycleCard(Map<String, dynamic> cycle) {
    final typeColor = _getTypeColor(cycle['type']);
    final progression = cycle['progression'].toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/cycle/${cycle['id']}',
          arguments: cycle,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorders.cardRadius,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor,
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
                            cycle['nom'],
                            style: AppTextStyles.subtitleLarge,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: AppBorders.buttonRadius,
                            ),
                            child: Text(
                              _getTypeLabel(cycle['type']),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Début: ${cycle['date']} • ${cycle['age']} jours',
                        style: AppTextStyles.bodySmall,
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
                    color: cycle['actif']
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    cycle['actif'] ? 'Actif' : 'Clôturé',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: cycle['actif'] ? AppColors.success : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Barre de progression
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progression',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.grey200,
                              borderRadius: AppBorders.buttonRadius,
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progression / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: progression > 80
                                    ? AppColors.error
                                    : progression > 50
                                        ? AppColors.warning
                                        : AppColors.success,
                                borderRadius: AppBorders.buttonRadius,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${progression.toInt()}%',
                  style: AppTextStyles.numberSmall.copyWith(
                    color: progression > 80
                        ? AppColors.error
                        : progression > 50
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}