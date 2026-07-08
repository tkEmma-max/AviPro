// lib/screens/poulaillers/poulailler_migration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';

class PoulaillerMigrationScreen extends StatefulWidget {
  final Poulailler source;

  const PoulaillerMigrationScreen({
    super.key,
    required this.source,
  });

  @override
  State<PoulaillerMigrationScreen> createState() =>
      _PoulaillerMigrationScreenState();
}

class _PoulaillerMigrationScreenState
    extends State<PoulaillerMigrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nbSujetsController = TextEditingController();
  final _raisonController = TextEditingController();

  String? _selectedTargetId;
  int _agePoulets = 21; // Simulé
  int _effectifSource = 0;

  @override
  void initState() {
    super.initState();
    _effectifSource = widget.source.nbPouletsActuels;
  }

  @override
  void dispose() {
    _nbSujetsController.dispose();
    _raisonController.dispose();
    super.dispose();
  }

  Poulailler? get _selectedTarget {
    final provider = context.read<PoulaillerProvider>();
    try {
      return provider.poulaillers.firstWhere((p) => p.id == _selectedTargetId);
    } catch (e) {
      return null;
    }
  }

  bool _hasAgeConflict() {
    final target = _selectedTarget;
    if (target == null) return false;
    // Simuler un écart d'âge (pour la démo)
    return false;
  }

  void _submitMigration() {
    if (!_formKey.currentState!.validate()) return;

    final nb = int.parse(_nbSujetsController.text);
    final target = _selectedTarget;

    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un poulailler cible'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Exécuter la migration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Migration effectuée avec succès !'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PoulaillerProvider>();
    final poulaillers = provider.poulaillers
        .where((p) => p.id != widget.source.id && p.statut == 'LIBRE')
        .toList();

    final target = _selectedTarget;
    final nbSujets = int.tryParse(_nbSujetsController.text) ?? 0;
    final capacityConflict = target != null &&
        target.surface != null &&
        (target.nbPouletsActuels ?? 0) + nbSujets > (target.surface ?? 0) * 8;

    final ageConflict = _hasAgeConflict();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Migration de poulets',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // ============================================================
              // SOURCE (Lecture seule)
              // ============================================================
              _buildLabel('Poulailler source'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.source.nom,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$_effectifSource sujets',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // CIBLE
              // ============================================================
              _buildLabel('Poulailler cible *'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTargetId,
                    hint: Text(
                      'Sélectionnez un poulailler libre',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: poulaillers.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Row(
                          children: [
                            Icon(
                              Icons.house_outlined,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                p.nom,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            Text(
                              '${p.surface?.toStringAsFixed(1) ?? 0} m²',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedTargetId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // NOMBRE DE SUJETS
              // ============================================================
              _buildLabel('Nombre de sujets à migrer *'),
              TextFormField(
                controller: _nbSujetsController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Requis';
                  final nb = int.tryParse(value);
                  if (nb == null) return 'Nombre valide';
                  if (nb <= 0) return '> 0';
                  if (nb > _effectifSource) {
                    return 'Max: $_effectifSource sujets';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // ÂGE (Lecture seule)
              // ============================================================
              _buildLabel('Âge des poulets'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Âge actuel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_agePoulets jours',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // ALERTE ÉCART D'ÂGE
              // ============================================================
              if (ageConflict)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: const Color(0xFFB45309)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Attention : L\'écart d\'âge avec les sujets du bâtiment cible dépasse 7 jours. Risque sanitaire accru pour la bande.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // ============================================================
              // ALERTE CAPACITÉ
              // ============================================================
              if (capacityConflict)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Capacité maximale du poulailler cible dépassée !',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // RAISON (optionnelle)
              // ============================================================
              _buildLabel('Raison du transfert (optionnel)'),
              TextFormField(
                controller: _raisonController,
                maxLines: 2,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ex: Délestage pour réduire la densité...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // BOUTON VALIDER
              // ============================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: capacityConflict ? null : _submitMigration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                    disabledBackgroundColor: AppColors.textHint,
                  ),
                  child: const Text(
                    'VALIDER LA MIGRATION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}