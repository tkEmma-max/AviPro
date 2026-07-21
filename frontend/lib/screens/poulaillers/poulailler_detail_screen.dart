// lib/screens/poulaillers/poulailler_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/poulailler.dart';
import '../../models/cycle.dart';
import '../../providers/poulailler_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../services/densite_service.dart';
import '../../services/equipement_service.dart';
import 'poulailler_edit_screen.dart';
import 'poulailler_migration_screen.dart';


class PoulaillerDetailScreen extends StatefulWidget {
  final Poulailler poulailler;

  const PoulaillerDetailScreen({
    super.key,
    required this.poulailler,
  });

  @override
  State<PoulaillerDetailScreen> createState() => _PoulaillerDetailScreenState();
}

class _PoulaillerDetailScreenState extends State<PoulaillerDetailScreen> {
  List<Cycle> _cyclesPoulailler = [];
  bool _isLoadingCycles = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCycles();
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les cycles quand on revient sur l'écran
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    setState(() => _isLoadingCycles = true);

    print('🔍 [DETAIL] Chargement cycles pour poulailler: ${widget.poulailler.id}');

    final cycleProvider = context.read<CycleProvider>();
    final cycles = await cycleProvider.fetchCyclesByPoulailler(widget.poulailler.id);

    print('🔍 [DETAIL] ${cycles.length} cycles reçus');

    if (mounted) {
      setState(() {
        _cyclesPoulailler = cycles;
        _isLoadingCycles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = widget.poulailler.statut == 'OCCUPÉ';
    final statutColor = isOccupied ? AppColors.warning : AppColors.success;
    final statutLabel = isOccupied ? 'OCCUPÉ' : 'LIBRE';
    final statutBg = isOccupied
        ? AppColors.warning.withOpacity(0.1)
        : AppColors.success.withOpacity(0.1);

    // Surface
    final surfaceValue = widget.poulailler.surface ?? 0;

    // Cycle actif et densité
    final cycleProvider = context.watch<CycleProvider>();
    final cycleActif = cycleProvider.getCycleActif(widget.poulailler.id);
    final String typeElevage = cycleActif?.type ?? 'CHAIR';
    final int ageJours = cycleActif?.joursEcoules ?? 0;

    // Densité intelligente (RG2, RG3)
    final double densiteRecommandee = DensiteService.getDensiteRecommandee(typeElevage, ageJours);
    final int capaciteMax = DensiteService.getCapaciteMax(surfaceValue, typeElevage, ageJours);
    final int niveauAlerte = DensiteService.getNiveauAlerte(surfaceValue, widget.poulailler.nbPouletsActuels, typeElevage, ageJours);
    final double densite = widget.poulailler.densiteActuelle ?? 0;

    // Équipements (F49) - Calcul dynamique (APRÈS les déclarations ci-dessus)
    int nbMangeoiresRecommandees;
    int nbAbreuvoirsRecommandes;

    if (isOccupied && cycleActif != null) {
      nbMangeoiresRecommandees = EquipementService.getMangeoiresRecommandees(
          widget.poulailler.nbPouletsActuels, typeElevage, ageJours);
      nbAbreuvoirsRecommandes = EquipementService.getAbreuvoirsRecommandes(
          widget.poulailler.nbPouletsActuels, typeElevage, ageJours);
    } else if (!isOccupied && surfaceValue > 0) {
      final recommandations = EquipementService.getRecommandationsPoulaillerVide(surfaceValue);
      nbMangeoiresRecommandees = recommandations['mangeoires']!;
      nbAbreuvoirsRecommandes = recommandations['abreuvoirs']!;
    } else {
      nbMangeoiresRecommandees = 0;
      nbAbreuvoirsRecommandes = 0;
    }

    final alerteMangeoires = widget.poulailler.nbPouletsActuels > 0 &&
        widget.poulailler.nombreMangeoires < nbMangeoiresRecommandees;
    final alerteAbreuvoirs = widget.poulailler.nbPouletsActuels > 0 &&
        widget.poulailler.nombreAbreuvoirs < nbAbreuvoirsRecommandes;
    final hasAlerteEquipement = alerteMangeoires || alerteAbreuvoirs;

    Color densiteColor;
    String densiteLabel;
    switch (niveauAlerte) {
      case 0:
        densiteColor = AppColors.success;
        densiteLabel = 'OK';
        break;
      case 1:
        densiteColor = AppColors.warning;
        densiteLabel = 'Élevée';
        break;
      case 2:
        densiteColor = AppColors.error;
        densiteLabel = 'Critique';
        break;
      default:
        densiteColor = AppColors.success;
        densiteLabel = 'OK';
    }

    final tauxOccupation = capaciteMax > 0
        ? (widget.poulailler.nbPouletsActuels / capaciteMax).clamp(0.0, 1.0)
        : 0.0;

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
          'Détails du poulailler',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // ============================================================
            // EN-TÊTE
            // ============================================================
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.poulailler.nom,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
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
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statutColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
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
                          if (isOccupied) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '• ${widget.poulailler.nbPouletsActuels} sujets',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ============================================================
            // BLOC RATIOS & ALERTES ÉQUIPEMENTS
            // ============================================================
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppBorders.cardRadius,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppShadows.shadowCard,
              ),
              child: Column(
                children: [
                  // Densité
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Densité actuelle',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${densite.toStringAsFixed(1)} sujets/m²',
                              style: AppTextStyles.numberMedium.copyWith(
                                color: densiteColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Recommandé: ${densiteRecommandee.toStringAsFixed(1)} sujets/m²'
                                  '${cycleActif != null ? " (${typeElevage.toLowerCase()}, ${cycleActif.joursEcoules}j)" : ""}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                                fontSize: 10,
                              ),
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
                  const SizedBox(height: AppSpacing.md),

                  // Jauge d'occupation
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Occupation (max: $capaciteMax sujets à ${cycleActif?.joursEcoules ?? 0} jours)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(tauxOccupation * 100).toInt()}%',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: tauxOccupation,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tauxOccupation > 0.8
                              ? AppColors.error
                              : tauxOccupation > 0.6
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                        minHeight: 8,
                        borderRadius: AppBorders.buttonRadius,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Équipements
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mangeoires',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${widget.poulailler.nombreMangeoires}',
                              style: AppTextStyles.numberSmall.copyWith(
                                color: alerteMangeoires
                                    ? AppColors.error
                                    : AppColors.textPrimary,
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
                              'Abreuvoirs',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${widget.poulailler.nombreAbreuvoirs}',
                              style: AppTextStyles.numberSmall.copyWith(
                                color: alerteAbreuvoirs
                                    ? AppColors.error
                                    : AppColors.textPrimary,
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
                              'Surface',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${widget.poulailler.surface?.toStringAsFixed(1) ?? "0"} m²',
                              style: AppTextStyles.numberSmall,
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
            // ALERTE ÉQUIPEMENT (F49)
            // ============================================================
            if (hasAlerteEquipement)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Matériel insuffisant :'
                            '${alerteMangeoires ? ' Ajoutez au moins ${nbMangeoiresRecommandees - widget.poulailler.nombreMangeoires} mangeoires.' : ''}'
                            '${alerteAbreuvoirs ? ' Ajoutez au moins ${nbAbreuvoirsRecommandes - widget.poulailler.nombreAbreuvoirs} abreuvoirs.' : ''}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),

            // ============================================================
            // HISTORIQUE DES CYCLES
            // ============================================================
            Text(
              'Historique des cycles',
              style: AppTextStyles.subtitleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_isLoadingCycles)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_cyclesPoulailler.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: AppShadows.shadowCard,
                ),
                child: Center(
                  child: Text(
                    'Aucun cycle enregistré pour ce poulailler.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: AppShadows.shadowCard,
                ),
                child: Column(
                  children: _cyclesPoulailler.asMap().entries.map((entry) {
                    final index = entry.key;
                    final cycle = entry.value;
                    final isLast = index == _cyclesPoulailler.length - 1;
                    return Column(
                      children: [
                        _buildCycleHistoriqueItem(cycle),
                        if (!isLast)
                          const Divider(height: AppSpacing.lg),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),

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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoulaillerEditScreen(
                        poulailler: widget.poulailler,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    final provider = context.read<PoulaillerProvider>();
                    await provider.refreshPoulaillers();
                    _loadCycles();
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isOccupied
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoulaillerMigrationScreen(source: widget.poulailler),
                    ),
                  );
                }
                    : null,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Migrer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !isOccupied && widget.poulailler.nbPouletsActuels == 0
                    ? () => _showDeleteConfirmation(context)
                    : null,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCycleHistoriqueItem(Cycle cycle) {
    final dateDebut = '${cycle.dateDebut.day}/${cycle.dateDebut.month}/${cycle.dateDebut.year}';
    final dateFin = cycle.dateFin != null
        ? '${cycle.dateFin!.day}/${cycle.dateFin!.month}/${cycle.dateFin!.year}'
        : 'En cours';
    final periode = '$dateDebut - $dateFin';
    final mortalite = cycle.tauxMortalite != null
        ? '${cycle.tauxMortalite!.toStringAsFixed(1)}%'
        : 'N/A';
    final benefice = cycle.benefice ?? 0;
    final isPositif = benefice >= 0;
    final beneficeStr = isPositif
        ? '+${benefice.toStringAsFixed(0)} FCFA'
        : '${benefice.toStringAsFixed(0)} FCFA';

    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: cycle.isActive
                ? AppColors.success.withOpacity(0.5)
                : AppColors.primary.withOpacity(0.3),
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
                  Flexible(
                    child: Text(
                      cycle.nom,
                      style: AppTextStyles.subtitleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (cycle.isActive) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: AppBorders.radiusSmall,
                      ),
                      child: Text(
                        'Actif',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                periode,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Mortalité: $mortalite',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              beneficeStr,
              style: AppTextStyles.subtitleMedium.copyWith(
                color: isPositif ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.radiusLarge,
        ),
        title: const Text('Supprimer le poulailler ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le poulailler "${widget.poulailler.nom}" ? Cette action est irréversible.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<PoulaillerProvider>();
              await provider.deletePoulailler(widget.poulailler.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Poulailler "${widget.poulailler.nom}" supprimé.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.cardRadius,
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Supprimer',
              style: AppTextStyles.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}