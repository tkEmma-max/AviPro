// lib/screens/cycles/prevision_screen.dart
// ✅ MIS À JOUR — Support des paramètres optionnels typePouletId et nbSujets
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/prevision_provider.dart';

class PrevisionScreen extends StatefulWidget {
  /// ID du TypePoulet pré-sélectionné (optionnel, depuis la fiche cycle)
  final String? typePouletId;

  /// Nombre de sujets pré-rempli (optionnel, depuis la fiche cycle)
  final int? nbSujets;

  const PrevisionScreen({super.key, this.typePouletId, this.nbSujets});

  @override
  State<PrevisionScreen> createState() => _PrevisionScreenState();
}

class _PrevisionScreenState extends State<PrevisionScreen> {
  String? _selectedTypePouletId;
  final _nbSujetsController = TextEditingController();
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec les paramètres optionnels
    _selectedTypePouletId = widget.typePouletId;
    _nbSujetsController.text = (widget.nbSujets ?? 500).toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PrevisionProvider>();
      provider.loadTypesPoulet().then((_) {
        // Vérifier que le type pré-rempli existe bien dans la liste
        if (_selectedTypePouletId != null &&
            !provider.typesPoulet.any((t) => t.id == _selectedTypePouletId)) {
          _selectedTypePouletId = null;
          if (mounted) setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _nbSujetsController.dispose();
    super.dispose();
  }

  String _formatMoney(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
  }

  String _getFiabiliteLabel(String fiabilite) {
    switch (fiabilite) {
      case 'ELEVEE':
        return 'Élevée';
      case 'BONNE':
        return 'Bonne';
      case 'MOYENNE':
        return 'Moyenne';
      case 'FAIBLE':
        return 'Faible';
      case 'INDISPONIBLE':
        return 'Indisponible';
      default:
        return fiabilite;
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

  String _getMethodeLabel(String methode) {
    switch (methode) {
      case 'REGLE_DE_3':
        return 'Règle de 3';
      case 'MOYENNE_SIMPLE':
        return 'Moyenne simple';
      case 'MOYENNE_PONDEREE':
        return 'Moyenne pondérée';
      case 'RAPPORTS_SEULS':
        return 'Basée sur les rapports';
      case 'AUCUNE':
        return 'Aucune donnée';
      default:
        return methode;
    }
  }

  void _lancerPrevision() {
    if (_selectedTypePouletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de poulet'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final nbSujets = int.tryParse(_nbSujetsController.text);
    if (nbSujets == null || nbSujets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nombre de sujets valide'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _hasSearched = true);
    context.read<PrevisionProvider>().getPrevisions(
      typePouletId: _selectedTypePouletId!,
      nbSujets: nbSujets,
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
          'Prévisions',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Consumer<PrevisionProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // FORMULAIRE
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
                        'Paramètres de prévision',
                        style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Dropdown type de poulet
                      Text(
                        'Type d\'élevage',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      provider.isLoadingTypes
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _selectedTypePouletId,
                              decoration: InputDecoration(
                                hintText: 'Sélectionner un type',
                                border: OutlineInputBorder(
                                  borderRadius: AppBorders.radiusMedium,
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items: provider.typesPoulet.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type.id,
                                  child: Text(
                                    '${type.nom} (${type.dureeEstimeeJours} jours)',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedTypePouletId = value);
                              },
                            ),
                      const SizedBox(height: AppSpacing.md),

                      // Nombre de sujets
                      Text(
                        'Nombre de sujets',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _nbSujetsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ex: 500',
                          suffixText: 'sujets',
                          border: OutlineInputBorder(
                            borderRadius: AppBorders.radiusMedium,
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Bouton
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _lancerPrevision,
                          icon: const Icon(AppIcons.chart, size: 20),
                          label: Text(
                            provider.isLoading ? 'Calcul en cours...' : 'Lancer la prévision',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorders.buttonRadius,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // RÉSULTATS
                if (provider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (provider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: AppBorders.cardRadius,
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.urgent, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (provider.prevision != null) ...[
                  // Message de fiabilité
                  if (provider.prevision!.message != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: AppBorders.cardRadius,
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(AppIcons.info, color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              provider.prevision!.message!,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),

                  // CARTE : SYNTHÈSE
                  _buildSyntheseCard(provider.prevision!),
                  const SizedBox(height: AppSpacing.md),

                  // CARTE : DÉPENSES
                  _buildDepensesCard(provider.prevision!),
                  const SizedBox(height: AppSpacing.md),

                  // CARTE : VENTES
                  _buildVentesCard(provider.prevision!),
                  const SizedBox(height: AppSpacing.md),

                  // CARTE : CONSOMMATIONS
                  if (provider.prevision!.consommations != null)
                    _buildConsommationsCard(provider.prevision!),

                  // CARTE : INDICATEURS TECHNIQUES
                  _buildIndicateursCard(provider.prevision!),
                ],

                if (!_hasSearched &&
                    provider.prevision == null &&
                    provider.errorMessage == null &&
                    !provider.isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        children: [
                          Icon(AppIcons.chart,
                              size: 80, color: AppColors.textHint.withOpacity(0.5)),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Sélectionnez un type d\'élevage et\nun nombre de sujets, puis lancez la prévision',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
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

  Widget _buildSyntheseCard(prevision) {
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
              const Icon(AppIcons.succes, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Synthèse',
                  style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Type d\'élevage', prevision.typePoulet),
          _buildInfoRow('Nombre de sujets', '${prevision.nbSujets}'),
          _buildInfoRow('Durée estimée', '${prevision.dureeEstimeeJours} jours'),
          const Divider(height: AppSpacing.lg),
          _buildInfoRow(
            'Coût de production unitaire',
            '${_formatMoney(prevision.coutProductionUnitaire ?? 0)} FCFA',
            valueColor: AppColors.warning,
            valueBold: true,
          ),
          _buildInfoRow(
            'Bénéfice prévisionnel',
            '${(prevision.beneficePrevisionnel ?? 0) >= 0 ? "+" : ""}${_formatMoney(prevision.beneficePrevisionnel ?? 0)} FCFA',
            valueColor:
                (prevision.beneficePrevisionnel ?? 0) >= 0 ? AppColors.success : AppColors.error,
            valueBold: true,
          ),
          if (prevision.mortaliteEstimee != null)
            _buildInfoRow(
              'Mortalité estimée',
              '${prevision.mortaliteEstimee!.toStringAsFixed(1)}%',
              valueColor: AppColors.warning,
            ),
        ],
      ),
    );
  }

  Widget _buildDepensesCard(prevision) {
    if (prevision.depenses == null) {
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
            Row(children: [
              const Icon(AppIcons.depense, size: 20, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Text('Dépenses prévisionnelles',
                  style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pas assez de données historiques pour estimer les dépenses.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

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
          Row(children: [
            const Icon(AppIcons.depense, size: 20, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text('Dépenses prévisionnelles',
                style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            'Total dépenses',
            '${_formatMoney(prevision.depenses!.total ?? 0)} FCFA',
            valueColor: AppColors.error,
            valueBold: true,
          ),
          if (prevision.depenses!.parCategorie.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            ...prevision.depenses!.parCategorie.map((cat) => _buildInfoRow(
                  cat.categorie,
                  '${_formatMoney(cat.montantEstime)} FCFA',
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildVentesCard(prevision) {
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
          Row(children: [
            const Icon(AppIcons.vente, size: 20, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Text('Ventes prévisionnelles',
                style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: AppSpacing.md),
          if (prevision.ventes == null || prevision.ventes!.parType.isEmpty)
            Text(
              'Pas assez de données historiques pour estimer les ventes.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            )
          else ...[
            _buildInfoRow(
              'Total ventes',
              '${_formatMoney(prevision.ventes!.total ?? 0)} FCFA',
              valueColor: AppColors.success,
              valueBold: true,
            ),
            const Divider(height: AppSpacing.md),
            ...prevision.ventes!.parType.map((cat) => _buildInfoRow(
                  cat.categorie,
                  '${_formatMoney(cat.montantEstime)} FCFA',
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildConsommationsCard(prevision) {
    final conso = prevision.consommations!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
          Row(children: [
            const Icon(AppIcons.mangeoire, size: 20, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Text('Consommations estimées',
                style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
              'Aliment/sujet/jour', '${conso.alimentParSujetParJour.toStringAsFixed(3)} kg'),
          _buildInfoRow('Eau/sujet/jour', '${conso.eauParSujetParJour.toStringAsFixed(3)} L'),
          _buildInfoRow('Ratio eau/aliment', conso.ratioEauAliment.toStringAsFixed(1)),
          const Divider(height: AppSpacing.md),
          _buildInfoRow(
            'Aliment total estimé',
            '${conso.alimentTotalEstime.toStringAsFixed(1)} kg',
            valueBold: true,
          ),
          _buildInfoRow(
            'Eau totale estimée',
            '${conso.eauTotalEstimee.toStringAsFixed(1)} L',
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicateursCard(prevision) {
    final fiabiliteColor = _getFiabiliteColor(prevision.fiabilite);
    final fiabiliteLabel = _getFiabiliteLabel(prevision.fiabilite);
    final methodeLabel = _getMethodeLabel(prevision.methode);

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
          Row(children: [
            const Icon(AppIcons.performance, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Indicateurs techniques',
                style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Cycles de référence', '${prevision.nbCyclesHistorique}'),
          _buildInfoRow('Rapports utilisés', '${prevision.nbRapportsUtilises}'),
          _buildInfoRow('Méthode de calcul', methodeLabel),
          _buildInfoRow(
            'Fiabilité',
            fiabiliteLabel,
            valueColor: fiabiliteColor,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child:
                Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style:
                  (valueBold ? AppTextStyles.subtitleMedium : AppTextStyles.bodyMedium).copyWith(
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