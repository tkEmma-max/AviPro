// lib/screens/cycles/cycle_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../providers/cycle_provider.dart';
import '../../models/cycle.dart';

class CycleListScreen extends StatefulWidget {
  const CycleListScreen({super.key});

  @override
  State<CycleListScreen> createState() => _CycleListScreenState();
}

class _CycleListScreenState extends State<CycleListScreen> {
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CycleProvider>().refreshCycles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CycleProvider>();
    final cycles = provider.cycles;

    if (provider.isLoading && cycles.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Cycles de production'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filtrage
    List<Cycle> filteredCycles;
    if (_filter == 'Actifs') {
      filteredCycles = cycles.where((c) => c.isActive && !c.isArchived).toList();
    } else if (_filter == 'Clôturés') {
      filteredCycles = cycles.where((c) => c.isArchived).toList();
    } else {
      filteredCycles = cycles;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cycles de production'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CycleProvider>().refreshCycles();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
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
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: AppBorders.buttonRadius,
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Liste
          Expanded(
            child: filteredCycles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline_outlined, size: 60, color: AppColors.textHint),
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
                : RefreshIndicator(
              onRefresh: () async {
                await context.read<CycleProvider>().refreshCycles();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                itemCount: filteredCycles.length,
                itemBuilder: (context, index) {
                  final cycle = filteredCycles[index];
                  return _buildCycleCard(cycle);
                },
              ),
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

  Widget _buildCycleCard(Cycle cycle) {
    final typeColor = _getTypeColor(cycle.type);
    final progression = cycle.progression ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/cycle/${cycle.id}',
          arguments: cycle.toJson(),
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
                          Text(cycle.nom, style: AppTextStyles.subtitleLarge),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: AppBorders.buttonRadius,
                            ),
                            child: Text(
                              _getTypeLabel(cycle.type),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Début: ${_formatDate(cycle.dateDebut)} • ${cycle.joursEcoules ?? 0} jours',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: cycle.isActive && !cycle.isArchived
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    cycle.isActive && !cycle.isArchived ? 'Actif' : 'Clôturé',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: cycle.isActive && !cycle.isArchived ? AppColors.success : AppColors.textHint,
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
                      Text('Progression', style: AppTextStyles.bodySmall),
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
                                color: progression > 80 ? AppColors.error : progression > 50 ? AppColors.warning : AppColors.success,
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
                    color: progression > 80 ? AppColors.error : progression > 50 ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'CHAIR': return AppColors.primary;
      case 'PONDEUSE': return AppColors.warning;
      case 'LOCAL': return AppColors.success;
      default: return AppColors.textHint;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'CHAIR': return 'Chair';
      case 'PONDEUSE': return 'Pondeuse';
      case 'LOCAL': return 'Local';
      default: return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}