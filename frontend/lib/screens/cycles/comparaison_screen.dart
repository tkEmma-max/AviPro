// lib/screens/cycles/comparaison_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/comparaison_provider.dart';

class ComparaisonScreen extends StatefulWidget {
  final String cycleId;
  final String cycleNom;

  const ComparaisonScreen({
    super.key,
    required this.cycleId,
    required this.cycleNom,
  });

  @override
  State<ComparaisonScreen> createState() => _ComparaisonScreenState();
}

class _ComparaisonScreenState extends State<ComparaisonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComparaisonProvider>().getComparaison(widget.cycleId);
    });
  }

  String _formatMoney(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  String _getFiabiliteLabel(String fiabilite) {
    switch (fiabilite) {
      case 'ELEVEE': return 'Élevée';
      case 'BONNE': return 'Bonne';
      case 'MOYENNE': return 'Moyenne';
      case 'FAIBLE': return 'Faible';
      case 'INDISPONIBLE': return 'Indisponible';
      default: return fiabilite;
    }
  }

  Color _getFiabiliteColor(String fiabilite) {
    switch (fiabilite) {
      case 'ELEVEE':
      case 'BONNE':
        return AppColors.success;
      case 'MOYENNE':
        return AppColors.warning;
      case 'FAIBLE':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  Widget _buildEcartBadge(double absolu, double pourcentage) {
    final positif = absolu >= 0;
    final color = positif ? AppColors.error : AppColors.success;
    final icon = positif ? AppIcons.tendanceHaut : AppIcons.tendanceBas;
    final signe = positif ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '$signe${pourcentage.toStringAsFixed(1)}%',
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prévisions vs Réalisations',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Consumer<ComparaisonProvider>(
        builder: (context, provider, _) {
          // CHARGEMENT
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERREUR
          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.urgent, size: 60, color: AppColors.error.withOpacity(0.6)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () => provider.refreshComparaison(widget.cycleId),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          // DONNÉES
          final comparaison = provider.comparaison;
          if (comparaison == null) {
            return Center(
              child: Text(
                'Aucune donnée disponible.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              ),
            );
          }

          final previsions = comparaison.previsions;
          final reel = comparaison.reel;
          final ecarts = comparaison.ecarts;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // EN-TÊTE : Nom du cycle + infos
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comparaison.cycleNom,
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          _buildInfoChip(
                            comparaison.typePoulet ?? 'Type inconnu',
                            AppIcons.poulet,
                            AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildInfoChip(
                            '${comparaison.nbSujets} sujets',
                            AppIcons.users,
                            AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildInfoChip(
                            'Terminé',
                            AppIcons.succes,
                            AppColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // MESSAGE D'ANALYSE
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.06),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(AppIcons.info, color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          comparaison.analyse,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // TABLEAU COMPARATIF
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.shadowCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparaison détaillée',
                        style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // En-tête du tableau
                      _buildTableHeader(),
                      const Divider(height: AppSpacing.md),

                      // DÉPENSES
                      _buildTableRow(
                        label: 'Dépenses',
                        icone: AppIcons.depense,
                        iconeColor: AppColors.error,
                        prevision: '${_formatMoney(previsions.depensesTotales)} FCFA',
                        reel: '${_formatMoney(reel.depensesTotales)} FCFA',
                        ecart: ecarts.depenses,
                        inverseCouleur: true,
                      ),
                      const Divider(height: AppSpacing.sm),

                      // VENTES
                      _buildTableRow(
                        label: 'Ventes',
                        icone: AppIcons.vente,
                        iconeColor: AppColors.success,
                        prevision: '${_formatMoney(previsions.ventesTotales)} FCFA',
                        reel: '${_formatMoney(reel.ventesTotales)} FCFA',
                        ecart: ecarts.ventes,
                      ),
                      const Divider(height: AppSpacing.sm),

                      // BÉNÉFICE
                      _buildTableRow(
                        label: 'Bénéfice',
                        icone: AppIcons.chart,
                        iconeColor: AppColors.primary,
                        prevision: '${_formatMoney(previsions.benefice)} FCFA',
                        reel: '${_formatMoney(reel.benefice)} FCFA',
                        ecart: ecarts.benefice,
                        bold: true,
                      ),
                      const Divider(height: AppSpacing.sm),

                      // COÛT DE PRODUCTION
                      _buildTableRow(
                        label: 'Coût unitaire',
                        icone: AppIcons.mangeoire,
                        iconeColor: AppColors.warning,
                        prevision: '${_formatMoney(previsions.coutProductionUnitaire ?? 0)} FCFA',
                        reel: '${_formatMoney(reel.coutProductionUnitaire)} FCFA',
                        ecart: ecarts.coutProduction,
                        inverseCouleur: true,
                      ),
                      const Divider(height: AppSpacing.sm),

                      // MORTALITÉ
                      _buildTableRow(
                        label: 'Mortalité',
                        icone: AppIcons.urgent,
                        iconeColor: AppColors.error,
                        prevision: '${(previsions.mortaliteEstimee ?? 0).toStringAsFixed(1)}%',
                        reel: '${reel.mortaliteReelle.toStringAsFixed(1)}%',
                        ecart: ecarts.mortalite,
                        inverseCouleur: true,
                        pourcentageRow: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // CARTE FIABILITÉ
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.shadowCard,
                  ),
                  child: Row(
                    children: [
                      const Icon(AppIcons.performance, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Fiabilité des prévisions : ',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getFiabiliteColor(previsions.fiabilite).withOpacity(0.1),
                          borderRadius: AppBorders.buttonRadius,
                        ),
                        child: Text(
                          _getFiabiliteLabel(previsions.fiabilite),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _getFiabiliteColor(previsions.fiabilite),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppBorders.buttonRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const SizedBox(width: 28),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(flex: 3, child: Text('')),
          Expanded(
            flex: 2,
            child: Text(
              'Prévu',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(
              'Réel',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            flex: 2,
            child: Text(
              'Écart',
              style: AppTextStyles.labelSmallDefault,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String label,
    required IconData icone,
    required Color iconeColor,
    required String prevision,
    required String reel,
    required EcartDetail ecart,
    bool bold = false,
    bool inverseCouleur = false,
    bool pourcentageRow = false,
  }) {
    final textStyle = bold
        ? AppTextStyles.subtitleMedium.copyWith(fontWeight: FontWeight.w600)
        : AppTextStyles.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icone, size: 18, color: iconeColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(label, style: textStyle.copyWith(color: AppColors.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              prevision,
              style: textStyle.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(
              reel,
              style: textStyle.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _buildEcartBadge(ecart.absolu, ecart.pourcentage),
          ),
        ],
      ),
    );
  }
}