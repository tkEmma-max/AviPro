// lib/screens/poulaillers/poulailler_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
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
    print('🟢 [PoulaillerListScreen] build');
    final provider = context.watch<PoulaillerProvider>();
    final poulaillers = provider.poulaillers;
    print('📦 [PoulaillerListScreen] ${poulaillers.length} poulaillers dans le provider');

    // Filtrage
    final filtered = poulaillers.where((p) {
      final matchSearch = p.nom.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchFilter = _filterType == 'Tous' ||
          (_filterType == 'Libres' && p.statut == 'LIBRE') ||
          (_filterType == 'Occupés' && p.statut == 'OCCUPÉ');
      return matchSearch && matchFilter;
    }).toList();

    print('📊 [PoulaillerListScreen] ${filtered.length} poulaillers filtrés');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mes Poulaillers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 [PoulaillerListScreen] Bouton refresh cliqué');
              context.read<PoulaillerProvider>().refreshPoulaillers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              print('➕ [PoulaillerListScreen] Bouton add cliqué');
              Navigator.pushNamed(context, '/poulailler/create');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche + filtres
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomSearchField(
                        hint: 'Rechercher un poulailler...',
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
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

          // Liste des poulaillers
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.house_outlined,
                    size: 60,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _searchQuery.isEmpty && _filterType == 'Tous'
                        ? 'Aucun poulailler enregistré'
                        : 'Aucun résultat trouvé',
                    style: AppTextStyles.headline4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _searchQuery.isEmpty && _filterType == 'Tous'
                        ? 'Ajoutez votre premier poulailler'
                        : 'Essayez de modifier votre recherche',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  if (_searchQuery.isEmpty && _filterType == 'Tous')
                    const SizedBox(height: AppSpacing.xl),
                  if (_searchQuery.isEmpty && _filterType == 'Tous')
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/poulailler/create');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.buttonRadius,
                        ),
                      ),
                      child: const Text('Ajouter un poulailler'),
                    ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async {
                print('🔄 [PoulaillerListScreen] Pull-to-refresh');
                await context.read<PoulaillerProvider>().refreshPoulaillers();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
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
    final statutLabel = isOccuped ? 'OCCUPÉ' : 'LIBRE';
    final statutBg = isOccuped
        ? AppColors.warning.withOpacity(0.1)
        : AppColors.success.withOpacity(0.1);

    Color densiteColor;
    String densiteLabel;
    if (poulailler.densiteActuelle == null || poulailler.densiteActuelle! < 5) {
      densiteColor = AppColors.success;
      densiteLabel = 'OK';
    } else if (poulailler.densiteActuelle! < 10) {
      densiteColor = AppColors.warning;
      densiteLabel = 'Élevée';
    } else {
      densiteColor = AppColors.error;
      densiteLabel = 'Critique';
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/poulailler/${poulailler.id}',
          arguments: poulailler,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorders.cardRadius,
          boxShadow: AppShadows.shadowCard,
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : Nom + Statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    poulailler.nom,
                    style: AppTextStyles.headline4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statutBg,
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statutColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statutLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statutColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Ligne 2 : Effectif
            Row(
              children: [
                Icon(
                  Icons.pets,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  '${poulailler.nbPouletsActuels} poulets',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Ligne 3 : Densité
            Row(
              children: [
                Icon(
                  Icons.square_foot,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Densité: ${poulailler.densiteActuelle?.toStringAsFixed(1) ?? '0'} sujets/m²',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: densiteColor.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    densiteLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: densiteColor,
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
  }
}