// lib/screens/cycles/cycle_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/cycle_provider.dart';
import '../../models/cycle.dart';
import '../../widgets/custom_search_field.dart';

class CycleListScreen extends StatefulWidget {
  const CycleListScreen({super.key});

  @override
  State<CycleListScreen> createState() => _CycleListScreenState();
}

class _CycleListScreenState extends State<CycleListScreen> {
  String _filter = 'Tous';
  String _searchQuery = '';

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
        backgroundColor: AppColors.surface,
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

    if (_searchQuery.isNotEmpty) {
      filteredCycles = filteredCycles.where((c) =>
          c.nom.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    final nbTotal = cycles.length;
    final nbActifs = cycles.where((c) => c.isActive && !c.isArchived).length;
    final nbClotures = cycles.where((c) => c.isArchived).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Cycles de production'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // STATS HEADER
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: Row(children: [
              _buildHeaderStat('$nbTotal', 'Total'),
              _buildHeaderStat('$nbActifs', 'Actifs'),
              _buildHeaderStat('$nbClotures', 'Clôturés'),
            ]),
          ),

          // Barre de recherche
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: CustomSearchField(
              hint: 'Rechercher un cycle...',
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filtres
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                  Icon(AppIcons.cycle, size: 60, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aucun cycle ${_filter.toLowerCase()}',
                    style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async {
                await context.read<CycleProvider>().refreshCycles();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
        onPressed: () => Navigator.pushNamed(context, '/cycle/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(AppIcons.add),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Expanded(
      child: Column(children: [
        Text(value, style: AppTextStyles.numberLarge.copyWith(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
      ]),
    );
  }

  Widget _buildCycleCard(Cycle cycle) {
    final progression = cycle.progression ?? 0;
    final isActif = cycle.isActive && !cycle.isArchived;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cycle/${cycle.id}', arguments: cycle.toJson()),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorders.cardRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.shadowCard,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ligne 1 : nom + badge statut
          Row(children: [
            Expanded(child: Text(cycle.nom, style: AppTextStyles.subtitleLarge.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isActif ? AppColors.success.withOpacity(0.08) : AppColors.textHint.withOpacity(0.08),
                borderRadius: AppBorders.buttonRadius,
              ),
              child: Text(isActif ? 'Actif' : 'Clôturé', style: AppTextStyles.labelSmall.copyWith(color: isActif ? AppColors.success : AppColors.textHint, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          // Ligne 2 : date + jours
          Text('Début: ${_formatDate(cycle.dateDebut)} • ${cycle.joursEcoules ?? 0} jours', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          // Barre de progression
          Row(children: [
            Expanded(
              child: Stack(
                children: [
                  Container(height: 6, decoration: BoxDecoration(color: AppColors.grey200, borderRadius: AppBorders.buttonRadius)),
                  FractionallySizedBox(
                    widthFactor: progression / 100,
                    child: Container(height: 6, decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppBorders.buttonRadius)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('${progression.toInt()}%', style: AppTextStyles.numberSmall.copyWith(color: AppColors.primary)),
          ]),
        ]),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}