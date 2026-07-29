// lib/screens/finances/vente_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/vente_provider.dart';

class VenteDetailScreen extends StatefulWidget {
  final String venteId;

  const VenteDetailScreen({super.key, required this.venteId});

  @override
  State<VenteDetailScreen> createState() => _VenteDetailScreenState();
}

class _VenteDetailScreenState extends State<VenteDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenteProvider>().getVenteById(widget.venteId);
    });
  }

  String _formatMoney(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'GAIN':
        return AppColors.success;
      case 'PERTE':
        return AppColors.error;
      case 'STABLE':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'GAIN':
        return 'Vente bénéficiaire';
      case 'PERTE':
        return 'Vente à perte';
      case 'STABLE':
        return 'Équilibre';
      default:
        return status ?? 'Inconnu';
    }
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
          'Détail de la vente',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Consumer<VenteProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final vente = provider.venteDetail;
          if (vente == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(AppIcons.vente, size: 60, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Vente introuvable',
                    style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => provider.refreshVente(widget.venteId),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final statusColor = _getStatusColor(vente.statusVente);
          final statusLabel = _getStatusLabel(vente.statusVente);
          final dateFormatted = DateFormat('dd MMMM yyyy', 'fr').format(vente.date);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // BADGE STATUT
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: AppBorders.buttonRadius,
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vente.statusVente == 'GAIN'
                              ? AppIcons.succes
                              : vente.statusVente == 'PERTE'
                                  ? AppIcons.urgent
                                  : AppIcons.info,
                          size: 18,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          statusLabel,
                          style: AppTextStyles.subtitleMedium.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // MONTANT
                Center(
                  child: Text(
                    '+ ${_formatMoney(vente.montantTotal)} FCFA',
                    style: AppTextStyles.numberLarge.copyWith(
                      fontSize: 32,
                      color: AppColors.success,
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
                  icon: AppIcons.info,
                  children: [
                    _buildInfoRow('Type de vente', vente.typeLabel ?? vente.type),
                    _buildInfoRow('Poulailler', vente.poulaillerNom ?? '-'),
                    _buildInfoRow('Cycle', vente.cycleNom ?? '-'),
                    _buildInfoRow('Vendeur', vente.vendeur ?? '-'),
                    if (vente.clientNom != null)
                      _buildInfoRow('Client', vente.clientNom!),
                    if (vente.description != null && vente.description!.isNotEmpty)
                      _buildInfoRow('Description', vente.description!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // CARTE : DÉTAIL DU CALCUL
                _buildSectionCard(
                  title: 'Détail du calcul',
                  icon: AppIcons.chart,
                  children: [
                    _buildInfoRow('Quantité', '${vente.quantite} sujets'),
                    _buildInfoRow('Prix unitaire', '${_formatMoney(vente.prixUnitaire)} FCFA'),
                    const Divider(height: AppSpacing.md),
                    _buildInfoRow(
                      'Montant total',
                      '${_formatMoney(vente.montantTotal)} FCFA',
                      valueBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // CARTE : RENTABILITÉ
                _buildSectionCard(
                  title: 'Rentabilité',
                  icon: vente.estRentable == true ? AppIcons.succes : AppIcons.urgent,
                  iconColor: vente.estRentable == true ? AppColors.success : AppColors.error,
                  children: [
                    if (vente.prixDeRevient != null)
                      _buildInfoRow(
                        'Prix de revient unitaire',
                        '${_formatMoney(vente.prixDeRevient!)} FCFA',
                      ),
                    if (vente.margeUnitaire != null)
                      _buildInfoRow(
                        'Marge unitaire',
                        '${vente.margeUnitaire! >= 0 ? "+" : ""}${_formatMoney(vente.margeUnitaire!)} FCFA',
                        valueColor: vente.margeUnitaire! >= 0 ? AppColors.success : AppColors.error,
                      ),
                    if (vente.pourcentageBenefice != null)
                      _buildInfoRow(
                        'Pourcentage bénéfice',
                        '${vente.pourcentageBenefice!.toStringAsFixed(1)}%',
                        valueColor: vente.pourcentageBenefice! >= 0 ? AppColors.success : AppColors.error,
                        valueBold: true,
                      ),
                    if (vente.cumulBeneficesCycle != null)
                      _buildInfoRow(
                        'Bénéfices cumulés du cycle',
                        '${_formatMoney(vente.cumulBeneficesCycle!)} FCFA',
                      ),
                    if (vente.potentielRestant != null)
                      _buildInfoRow(
                        'Potentiel restant',
                        '${_formatMoney(vente.potentielRestant!)} FCFA',
                        valueColor: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // CARTE : DOCUMENTS
                if (vente.factureNumero != null || vente.facturePhoto != null)
                  _buildSectionCard(
                    title: 'Documents',
                    icon: AppIcons.rapport,
                    children: [
                      if (vente.factureNumero != null)
                        _buildInfoRow('N° Facture', vente.factureNumero!),
                      if (vente.facturePhoto != null)
                        _buildInfoRow('Photo facture', 'Disponible'),
                    ],
                  ),

                // CARTE : RAPPEL REMBOURSEMENT
                if (vente.remboursementConfirme)
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: AppBorders.cardRadius,
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.pret, color: AppColors.primary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Remboursement de prêt confirmé',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
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