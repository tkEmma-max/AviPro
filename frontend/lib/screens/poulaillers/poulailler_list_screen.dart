// lib/screens/poulaillers/poulailler_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';
import '../../widgets/custom_search_field.dart';

class PoulaillerListScreen extends StatefulWidget {
  const PoulaillerListScreen({super.key});

  @override
  State<PoulaillerListScreen> createState() => _PoulaillerListScreenState();
}

class _PoulaillerListScreenState extends State<PoulaillerListScreen> {
  String _searchQuery = '';
  String _filterType = 'Tous';

  final List<String> _filters = ['Tous', 'Libres', 'Occupés'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoulaillerProvider>().refreshIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PoulaillerProvider>();
    final poulaillers = provider.poulaillers;

    final filtered = poulaillers.where((p) {
      final matchSearch = p.nom.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchFilter = _filterType == 'Tous' ||
          (_filterType == 'Libres' && p.statut == 'LIBRE') ||
          (_filterType == 'Occupés' && p.statut == 'OCCUPÉ');
      return matchSearch && matchFilter;
    }).toList();

    final nbTotal = poulaillers.length;
    final nbLibres = poulaillers.where((p) => p.statut == 'LIBRE').length;
    final nbOccupes = poulaillers.where((p) => p.statut == 'OCCUPÉ').length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Mes Poulaillers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            onPressed: () => Navigator.pushNamed(context, '/poulailler/create'),
          ),
        ],
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$nbTotal poulaillers', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: Row(children: [const Icon(AppIcons.libre, size: 16, color: Colors.white70), const SizedBox(width: 4), Text('$nbLibres libres', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600))])),
                Expanded(child: Row(children: [const Icon(AppIcons.occupe, size: 16, color: Colors.white70), const SizedBox(width: 4), Text('$nbOccupes occupés', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600))])),
              ]),
            ]),
          ),

          // Barre de recherche + filtres
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CustomSearchField(
                  hint: 'Rechercher un poulailler...',
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _filterType == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _filterType = filter);
                        },
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        checkmarkColor: AppColors.primary,
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.buttonRadius,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.house, size: 60, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Aucun poulailler enregistré', style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Ajoutez votre premier poulailler', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/poulailler/create'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Ajouter un poulailler')),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async {
                await context.read<PoulaillerProvider>().refreshPoulaillers();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  return _buildPoulaillerCard(context, p);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoulaillerCard(BuildContext context, Poulailler poulailler) {
    final isOccuped = poulailler.statut == 'OCCUPÉ';
    final statutColor = isOccuped ? AppColors.warning : AppColors.success;
    final statutLabel = isOccuped ? 'Occupé' : 'Libre';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/poulailler/${poulailler.id}', arguments: poulailler);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorders.cardRadius,
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Nom + Statut
          Row(children: [
            Expanded(child: Text(poulailler.nom, style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: statutColor.withOpacity(0.08), borderRadius: AppBorders.buttonRadius),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statutColor, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(statutLabel, style: AppTextStyles.labelSmall.copyWith(color: statutColor, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // Infos
          Row(children: [
            const Icon(AppIcons.sujets, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${poulailler.nbPouletsActuels} poulets', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: AppSpacing.md),
            const Icon(AppIcons.densite, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${poulailler.densiteActuelle?.toStringAsFixed(1) ?? '0'} sujets/m²', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}