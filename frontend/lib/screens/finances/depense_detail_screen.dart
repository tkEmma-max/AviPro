// lib/screens/finances/depense_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/depense_provider.dart';

class DepenseDetailScreen extends StatefulWidget {
  final String depenseId;

  const DepenseDetailScreen({super.key, required this.depenseId});

  @override
  State<DepenseDetailScreen> createState() => _DepenseDetailScreenState();
}

class _DepenseDetailScreenState extends State<DepenseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepenseProvider>().getDepenseById(widget.depenseId);
    });
  }

  String _formatMoney(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
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
          'Détail de la dépense',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Consumer<DepenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final depense = provider.depenseDetail;
          if (depense == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(AppIcons.depense, size: 60, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Dépense introuvable',
                    style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => provider.refreshDepense(widget.depenseId),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final dateFormatted = DateFormat('dd MMMM yyyy', 'fr').format(depense.date);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // BADGE ROUTINE
                if (depense.estDepenseRoutine)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: AppBorders.buttonRadius,
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AppIcons.refresh, size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Dépense de routine',
                            style: AppTextStyles.subtitleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (depense.estDepenseRoutine) const SizedBox(height: AppSpacing.xl),

                // MONTANT
                Center(
                  child: Text(
                    '- ${_formatMoney(depense.montant)} FCFA',
                    style: AppTextStyles.numberLarge.copyWith(
                      fontSize: 32,
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    dateFormatted,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // CARTE : INFORMATIONS GÉNÉRALES
                _buildSectionCard(
                  title: 'Informations générales',
                  icon: AppIcons.observation,
                  children: [
                    _buildInfoRow('Catégorie', depense.categorieLabel ?? depense.categorie),
                    _buildInfoRow('Poulailler', depense.poulaillerNom ?? '-'),
                    _buildInfoRow('Cycle', depense.cycleNom ?? '-'),
                    if (depense.fournisseurNom != null)
                      _buildInfoRow('Fournisseur', depense.fournisseurNom!),
                    if (depense.description != null && depense.description!.isNotEmpty)
                      _buildInfoRow('Description', depense.description!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // CARTE : IMPACT SUR LE COÛT DE PRODUCTION
                if (depense.impactPourcentage != null ||
                    depense.prixRevientAvant != null ||
                    depense.prixRevientApres != null)
                  _buildSectionCard(
                    title: 'Impact sur le coût de production',
                    icon: AppIcons.chart,
                    iconColor: (depense.impactPourcentage ?? 0) > 10
                        ? AppColors.warning
                        : AppColors.primary,
                    children: [
                      if (depense.cumulDepensesAvant != null)
                        _buildInfoRow(
                          'Total dépenses avant',
                          '${_formatMoney(depense.cumulDepensesAvant!)} FCFA',
                        ),
                      if (depense.cumulDepensesApres != null)
                        _buildInfoRow(
                          'Total dépenses après',
                          '${_formatMoney(depense.cumulDepensesApres!)} FCFA',
                        ),
                      if (depense.prixRevientAvant != null && depense.prixRevientApres != null) ...[
                        const Divider(height: AppSpacing.md),
                        _buildInfoRow(
                          'Prix de revient avant',
                          '${_formatMoney(depense.prixRevientAvant!)} FCFA',
                        ),
                        _buildInfoRow(
                          'Prix de revient après',
                          '${_formatMoney(depense.prixRevientApres!)} FCFA',
                          valueColor: AppColors.warning,
                        ),
                      ],
                      if (depense.impactPourcentage != null) ...[
                        const Divider(height: AppSpacing.md),
                        _buildInfoRow(
                          'Augmentation du coût',
                          '+${depense.impactPourcentage!.toStringAsFixed(1)}%',
                          valueColor: depense.impactPourcentage! > 10
                              ? AppColors.error
                              : AppColors.warning,
                          valueBold: true,
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),

                // CARTE : DOCUMENTS
                if (depense.factureNumero != null || depense.facturePhoto != null)
                  _buildSectionCard(
                    title: 'Documents',
                    icon: AppIcons.rapport,
                    children: [
                      if (depense.factureNumero != null)
                        _buildInfoRow('N° Facture', depense.factureNumero!),
                      if (depense.facturePhoto != null)
                        _buildInfoRow('Photo facture', 'Disponible'),
                    ],
                  ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color iconColor = AppColors.primary,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        Color? valueColor,
        bool valueBold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: (valueBold ? AppTextStyles.subtitleMedium : AppTextStyles.bodyMedium).copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: valueBold ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}