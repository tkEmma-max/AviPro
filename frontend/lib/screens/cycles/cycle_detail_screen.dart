// lib/screens/cycles/cycle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/cycle.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/cycle_provider.dart';

class CycleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cycleData;

  const CycleDetailScreen({super.key, required this.cycleData});

  @override
  State<CycleDetailScreen> createState() => _CycleDetailScreenState();
}

class _CycleDetailScreenState extends State<CycleDetailScreen> {
  late Cycle _cycle;
  int _pertes = 0;

  @override
  void initState() {
    super.initState();
    _cycle = Cycle.fromJson(widget.cycleData);
    _refreshCycle();
  }

  // Vérifie si le cycle peut être supprimé (moins de 48h)
  bool _canDeleteCycle() {
    final difference = DateTime.now().difference(_cycle.createdAt);
    return difference.inHours < 48;
  }

  // Affiche la confirmation de suppression
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.radiusLarge,
        ),
        title: const Text('Supprimer le cycle ?'),
        content: Text(
          'Le cycle "${_cycle.nom}" et toutes ses données (dépenses, ventes) seront définitivement supprimés.',
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
              Navigator.pop(context);
              final cycleProvider = context.read<CycleProvider>();
              final success = await cycleProvider.deleteCycle(_cycle.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cycle "${_cycle.nom}" supprimé'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context); // Retour à la liste
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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

  Future<void> _refreshCycle() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('cycles/${_cycle.id}/');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _cycle = Cycle.fromJson(response.data);
        });
      }
    } catch (e) {
      print('❌ Erreur rafraîchissement cycle: $e');
    }
  }

  void _declarerPerte() {
    int pertesTemp = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.radiusLarge,
          ),
          title: const Text('Déclarer une perte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nombre de poulets morts',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNumberButton('-', () {
                    setDialogState(() {
                      if (pertesTemp > 0) pertesTemp--;
                    });
                  }),
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      pertesTemp.toString(),
                      style: AppTextStyles.numberLarge.copyWith(
                        fontSize: 28,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  _buildNumberButton('+', () {
                    setDialogState(() {
                      if (pertesTemp < _cycle.nombreSujetsActuels) pertesTemp++;
                    });
                  }),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Effectif restant: ${_cycle.nombreSujetsActuels - pertesTemp}',
                style: AppTextStyles.bodySmall,
              ),
            ],
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
              onPressed: () {
                setState(() {
                  _cycle = Cycle(
                    id: _cycle.id,
                    nom: _cycle.nom,
                    poulailler: _cycle.poulailler,
                    poulaillerNom: _cycle.poulaillerNom,
                    type: _cycle.type,
                    dateDebut: _cycle.dateDebut,
                    dateFin: _cycle.dateFin,
                    nombreSujetsInitiaux: _cycle.nombreSujetsInitiaux,
                    nombreSujetsActuels: _cycle.nombreSujetsActuels - pertesTemp,
                    dureeEstimeeJours: _cycle.dureeEstimeeJours,
                    isActive: _cycle.isActive,
                    isArchived: _cycle.isArchived,
                    joursEcoules: _cycle.joursEcoules,
                    progression: _cycle.progression,
                    mortalites: (_cycle.mortalites ?? 0) + pertesTemp,
                    tauxMortalite: _cycle.nombreSujetsInitiaux > 0
                        ? ((_cycle.mortalites ?? 0) + pertesTemp) / _cycle.nombreSujetsInitiaux * 100
                        : 0,
                    totalDepenses: _cycle.totalDepenses,
                    totalVentes: _cycle.totalVentes,
                    benefice: _cycle.benefice,
                    estRentable: _cycle.estRentable,
                    coutProductionUnitaire: _cycle.coutProductionUnitaire,
                    prixVenteMoyen: _cycle.prixVenteMoyen,
                    createdAt: _cycle.createdAt,
                    updatedAt: _cycle.updatedAt,
                  );
                  _pertes = 0;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Confirmer',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String label, VoidCallback onPressed) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Text(
          label,
          style: AppTextStyles.numberLarge.copyWith(
            fontSize: 24,
            color: AppColors.primary,
          ),
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
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

  @override
  Widget build(BuildContext context) {
    final isActif = _cycle.isActive && !_cycle.isArchived;
    final progression = _cycle.progression ?? 0;
    final age = _cycle.joursEcoules ?? 0;
    final typeLabel = _getTypeLabel(_cycle.type);
    final typeColor = _getTypeColor(_cycle.type);
    final mortalite = _cycle.tauxMortalite ?? 0;
    final totalDepenses = _cycle.totalDepenses ?? 0;
    final totalVentes = _cycle.totalVentes ?? 0;
    final benefice = _cycle.benefice ?? 0;
    final dateDebut = DateFormat('dd/MM/yyyy').format(_cycle.dateDebut);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _cycle.nom,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bar_chart, color: AppColors.primary),
                        title: const Text('Rapport de performance'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/cycle/report/${_cycle.id}',
                            arguments: widget.cycleData,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                        title: const Text('Soumettre un rapport de suivi'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/cycle/report/form',
                            arguments: widget.cycleData,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        title: const Text('Modifier le cycle'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/cycle/edit',
                            arguments: widget.cycleData,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.assessment_outlined, color: AppColors.primary),
                        title: const Text('Voir les rapports'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/rapports');
                        },
                      ),
                      // Supprimer (seulement si cycle a moins de 48h)
                      if (_canDeleteCycle())
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: AppColors.error),
                          title: const Text('Supprimer le cycle',
                            style: TextStyle(color: AppColors.error),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation();
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // ============================================================
            // HEADER
            // ============================================================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isActif
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    isActif ? 'ACTIF' : 'CLÔTURÉ',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActif ? AppColors.success : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: AppBorders.buttonRadius,
                  ),
                  child: Text(
                    typeLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cycle.nom,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Jour $age • Début: $dateDebut',
                        style: AppTextStyles.bodyMedium.copyWith(
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
                      '${_cycle.nombreSujetsActuels}',
                      style: AppTextStyles.numberLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'sujets vivants',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${progression.toInt()}%',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: progression > 80
                            ? AppColors.error
                            : progression > 50
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progression / 100,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progression > 80
                        ? AppColors.error
                        : progression > 50
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  minHeight: 8,
                  borderRadius: AppBorders.buttonRadius,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // FRISE CHRONOLOGIQUE (F51)
            // ============================================================
            Text(
              'Frise chronologique',
              style: AppTextStyles.subtitleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFriseChronologique(),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // GRILLE DE SAISIE RAPIDE
            // ============================================================
            Text(
              'Actions terrain',
              style: AppTextStyles.subtitleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.4,
              children: [
                _buildQuickAction(
                  label: 'Déclarer une perte',
                  icon: Icons.warning,
                  color: AppColors.error,
                  bgColor: AppColors.error.withOpacity(0.08),
                  onTap: _declarerPerte,
                ),
                _buildQuickAction(
                  label: 'Noter une charge',
                  icon: Icons.money_off_outlined,
                  color: AppColors.primary,
                  bgColor: AppColors.primary.withOpacity(0.08),
                  onTap: () {
                    Navigator.pushNamed(context, '/finance/depense');
                  },
                ),
                _buildQuickAction(
                  label: 'Enregistrer une vente',
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                  bgColor: AppColors.success.withOpacity(0.08),
                  onTap: () {
                    Navigator.pushNamed(context, '/finance/vente');
                  },
                ),
                _buildQuickAction(
                  label: 'Observation',
                  icon: Icons.note_alt_outlined,
                  color: AppColors.warning,
                  bgColor: AppColors.warning.withOpacity(0.08),
                  onTap: () {
                    // TODO: Écran observation
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // SECTION STATISTIQUES
            // ============================================================
            Text(
              'Statistiques du cycle',
              style: AppTextStyles.subtitleLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppBorders.cardRadius,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.shadowCard,
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    'Taux de mortalité',
                    '${mortalite.toStringAsFixed(1)}%',
                    mortalite > 10 ? AppColors.error : AppColors.success,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow(
                    'Total charges',
                    '${totalDepenses.toStringAsFixed(0)} FCFA',
                    AppColors.error,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow(
                    'Total ventes',
                    '${totalVentes.toStringAsFixed(0)} FCFA',
                    AppColors.success,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow(
                    'Bénéfice estimé',
                    '${benefice >= 0 ? "+" : ""}${benefice.toStringAsFixed(0)} FCFA',
                    benefice >= 0 ? AppColors.success : AppColors.error,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // BOUTON CLÔTURER
            // ============================================================
            if (isActif)
              Center(
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.radiusLarge,
                        ),
                        title: const Text('Clôturer le cycle ?'),
                        content: const Text(
                          'Cette action est irréversible.',
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
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _cycle = Cycle(
                                  id: _cycle.id,
                                  nom: _cycle.nom,
                                  poulailler: _cycle.poulailler,
                                  poulaillerNom: _cycle.poulaillerNom,
                                  type: _cycle.type,
                                  dateDebut: _cycle.dateDebut,
                                  dateFin: DateTime.now(),
                                  nombreSujetsInitiaux: _cycle.nombreSujetsInitiaux,
                                  nombreSujetsActuels: _cycle.nombreSujetsActuels,
                                  dureeEstimeeJours: _cycle.dureeEstimeeJours,
                                  isActive: false,
                                  isArchived: true,
                                  joursEcoules: _cycle.joursEcoules,
                                  progression: 100,
                                  mortalites: _cycle.mortalites,
                                  tauxMortalite: _cycle.tauxMortalite,
                                  totalDepenses: _cycle.totalDepenses,
                                  totalVentes: _cycle.totalVentes,
                                  benefice: _cycle.benefice,
                                  estRentable: _cycle.estRentable,
                                  coutProductionUnitaire: _cycle.coutProductionUnitaire,
                                  prixVenteMoyen: _cycle.prixVenteMoyen,
                                  createdAt: _cycle.createdAt,
                                  updatedAt: DateTime.now(),
                                );
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cycle clôturé'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'Clôturer',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Clôturer définitivement le cycle',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FRISE CHRONOLOGIQUE (F51)
  // ============================================================
  Widget _buildFriseChronologique() {
    final etapes = _getEtapesFrise();
    final age = _cycle.joursEcoules ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorders.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.shadowCard,
      ),
      child: Column(
        children: [
          // Ligne du temps
          SizedBox(
            height: 60,
            child: Row(
              children: etapes.asMap().entries.map((entry) {
                final index = entry.key;
                final etape = entry.value;
                final isPast = age >= etape['age']!;
                final isCurrent = age < etape['age']! &&
                    (index == 0 || age >= etapes[index - 1]['age']!);

                return Expanded(
                  child: Column(
                    children: [
                      // Icône
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isPast
                              ? AppColors.primary
                              : isCurrent
                              ? AppColors.warning
                              : AppColors.grey200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          etape['icon'] as IconData,
                          size: 16,
                          color: isPast || isCurrent ? Colors.white : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Âge
                      Text(
                        etape['label'] as String,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isPast || isCurrent
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Barre de progression de la frise
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: _getFriseProgression(),
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
            borderRadius: AppBorders.buttonRadius,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getEtapesFrise() {
    switch (_cycle.type) {
      case 'CHAIR':
        return [
          {'age': 1, 'label': 'J1', 'icon': Icons.egg},
          {'age': 21, 'label': 'J21', 'icon': Icons.pets},
          {'age': 35, 'label': 'J35', 'icon': Icons.restaurant},
          {'age': 45, 'label': 'J45', 'icon': Icons.check_circle},
        ];
      case 'PONDEUSE':
        return [
          {'age': 1, 'label': 'Sem.1', 'icon': Icons.egg},
          {'age': 56, 'label': 'Sem.8', 'icon': Icons.pets},
          {'age': 126, 'label': 'Sem.18', 'icon': Icons.restaurant},
          {'age': 490, 'label': 'Sem.70', 'icon': Icons.check_circle},
        ];
      case 'LOCAL':
        return [
          {'age': 1, 'label': 'J1', 'icon': Icons.egg},
          {'age': 84, 'label': 'Sem.12', 'icon': Icons.pets},
          {'age': 168, 'label': 'Sem.24', 'icon': Icons.restaurant},
          {'age': _cycle.dureeEstimeeJours, 'label': 'Fin', 'icon': Icons.check_circle},
        ];
      default:
        return [
          {'age': 1, 'label': 'Début', 'icon': Icons.play_arrow},
          {'age': _cycle.dureeEstimeeJours, 'label': 'Fin', 'icon': Icons.flag},
        ];
    }
  }

  double _getFriseProgression() {
    final age = _cycle.joursEcoules ?? 0;
    if (_cycle.dureeEstimeeJours <= 0) return 0;
    return (age / _cycle.dureeEstimeeJours).clamp(0.0, 1.0);
  }

  // ============================================================
  // WIDGETS
  // ============================================================
  Widget _buildQuickAction({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppBorders.cardRadius,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: bold
              ? AppTextStyles.numberMedium.copyWith(color: valueColor)
              : AppTextStyles.bodyMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}