// lib/screens/cycles/comparaison_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/comparaison_provider.dart';
import '../../models/comparaison.dart';

class ComparaisonScreen extends StatefulWidget {
  final String cycleId;
  final String cycleNom;
  final String? typePoulet;
  final int nbSujets;
  final double totalDepenses;
  final double totalVentes;
  final double benefice;
  final double coutProductionUnitaire;
  final double tauxMortalite;

  const ComparaisonScreen({
    super.key,
    required this.cycleId,
    required this.cycleNom,
    this.typePoulet,
    required this.nbSujets,
    required this.totalDepenses,
    required this.totalVentes,
    required this.benefice,
    required this.coutProductionUnitaire,
    required this.tauxMortalite,
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
      case 'BONNE': return AppColors.success;
      case 'MOYENNE': return AppColors.warning;
      case 'FAIBLE': return AppColors.error;
      default: return AppColors.textHint;
    }
  }

  Widget _buildEcartBadge(double absolu, double pourcentage) {
    final positif = absolu >= 0;
    final color = positif ? AppColors.error : AppColors.success;
    final icon = positif ? AppIcons.vente : AppIcons.depense;
    final signe = positif ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text('$signe${pourcentage.toStringAsFixed(1)}%', style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: AppBorders.buttonRadius),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(AppIcons.arrowBack, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: Text('Prévisions vs Réalisations', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Consumer<ComparaisonProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: AppSpacing.md),

              // EN-TÊTE (données du cycle, toujours visibles)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.primary.withOpacity(0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.cycleNom, style: AppTextStyles.headlineLarge.copyWith(fontSize: 20, color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                    _buildInfoChip(widget.typePoulet ?? 'Type inconnu', AppIcons.poulet, AppColors.primary),
                    _buildInfoChip('${widget.nbSujets} sujets', AppIcons.sujets, AppColors.textSecondary),
                    _buildInfoChip('Terminé', AppIcons.succes, AppColors.success),
                  ]),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),

              // RÉSULTATS RÉELS (toujours visibles)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(AppIcons.chart, size: 20, color: AppColors.primary), const SizedBox(width: AppSpacing.sm), Text('Résultats réels', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary))]),
                  const SizedBox(height: AppSpacing.md),
                  _buildRealRow(AppIcons.depense, 'Dépenses totales', '${_formatMoney(widget.totalDepenses)} FCFA', AppColors.error),
                  const Divider(height: AppSpacing.md),
                  _buildRealRow(AppIcons.vente, 'Ventes totales', '${_formatMoney(widget.totalVentes)} FCFA', AppColors.success),
                  const Divider(height: AppSpacing.md),
                  _buildRealRow(AppIcons.succes, 'Bénéfice', '${widget.benefice >= 0 ? "+" : ""}${_formatMoney(widget.benefice)} FCFA', widget.benefice >= 0 ? AppColors.success : AppColors.error, bold: true),
                  const Divider(height: AppSpacing.md),
                  _buildRealRow(AppIcons.mangeoire, 'Coût unitaire', '${_formatMoney(widget.coutProductionUnitaire)} FCFA', AppColors.warning),
                  const Divider(height: AppSpacing.md),
                  _buildRealRow(AppIcons.urgent, 'Mortalité', '${widget.tauxMortalite.toStringAsFixed(1)}%', AppColors.error),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),

              // COMPARAISON (appel API)
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (provider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.warning.withOpacity(0.2))),
                  child: Row(children: [
                    const Icon(AppIcons.observation, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(provider.errorMessage!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary))),
                  ]),
                ),

              if (provider.comparaison != null) ...[
                // Message d'analyse
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.04), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.primary.withOpacity(0.1))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(AppIcons.observation, color: AppColors.primary, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(provider.comparaison!.analyse, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                  ]),
                ),

                // Tableau comparatif
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Comparaison prévisions', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    _buildTableHeader(),
                    const Divider(height: AppSpacing.md),
                    _buildCompareRow('Dépenses', AppIcons.depense, AppColors.error, '${_formatMoney(provider.comparaison!.previsions.depensesTotales)} FCFA', '${_formatMoney(provider.comparaison!.reel.depensesTotales)} FCFA', provider.comparaison!.ecarts.depenses),
                    const Divider(height: AppSpacing.sm),
                    _buildCompareRow('Ventes', AppIcons.vente, AppColors.success, '${_formatMoney(provider.comparaison!.previsions.ventesTotales)} FCFA', '${_formatMoney(provider.comparaison!.reel.ventesTotales)} FCFA', provider.comparaison!.ecarts.ventes),
                    const Divider(height: AppSpacing.sm),
                    _buildCompareRow('Bénéfice', AppIcons.succes, AppColors.primary, '${_formatMoney(provider.comparaison!.previsions.benefice)} FCFA', '${_formatMoney(provider.comparaison!.reel.benefice)} FCFA', provider.comparaison!.ecarts.benefice, bold: true),
                    const Divider(height: AppSpacing.sm),
                    _buildCompareRow('Coût unitaire', AppIcons.mangeoire, AppColors.warning, '${_formatMoney(provider.comparaison!.previsions.coutProductionUnitaire ?? 0)} FCFA', '${_formatMoney(provider.comparaison!.reel.coutProductionUnitaire)} FCFA', provider.comparaison!.ecarts.coutProduction),
                    const Divider(height: AppSpacing.sm),
                    _buildCompareRow('Mortalité', AppIcons.urgent, AppColors.error, '${(provider.comparaison!.previsions.mortaliteEstimee ?? 0).toStringAsFixed(1)}%', '${provider.comparaison!.reel.mortaliteReelle.toStringAsFixed(1)}%', provider.comparaison!.ecarts.mortalite),
                  ]),
                ),
                const SizedBox(height: AppSpacing.md),

                // Fiabilité
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
                  child: Row(children: [
                    const Icon(AppIcons.performance, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Fiabilité des prévisions : ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(color: _getFiabiliteColor(provider.comparaison!.previsions.fiabilite).withOpacity(0.1), borderRadius: AppBorders.buttonRadius),
                      child: Text(_getFiabiliteLabel(provider.comparaison!.previsions.fiabilite), style: AppTextStyles.labelSmall.copyWith(color: _getFiabiliteColor(provider.comparaison!.previsions.fiabilite), fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildRealRow(IconData icon, String label, String value, Color color, {bool bold = false}) {
    return Row(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
      Text(value, style: (bold ? AppTextStyles.subtitleMedium : AppTextStyles.bodyMedium).copyWith(color: color, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        const Expanded(flex: 3, child: Text('')),
        Expanded(flex: 2, child: Text('Prévu', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint), textAlign: TextAlign.right)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 2, child: Text('Réel', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint), textAlign: TextAlign.right)),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(flex: 2, child: Text('Écart', style: AppTextStyles.labelSmall, textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _buildCompareRow(String label, IconData icone, Color iconeColor, String prevision, String reel, EcartDetail ecart, {bool bold = false}) {
    final textStyle = bold ? AppTextStyles.subtitleMedium.copyWith(fontWeight: FontWeight.w600) : AppTextStyles.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        Icon(icone, size: 18, color: iconeColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 3, child: Text(label, style: textStyle.copyWith(color: AppColors.textPrimary))),
        Expanded(flex: 2, child: Text(prevision, style: textStyle.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.right)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 2, child: Text(reel, style: textStyle.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.right)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 2, child: _buildEcartBadge(ecart.absolu, ecart.pourcentage)),
      ]),
    );
  }
}