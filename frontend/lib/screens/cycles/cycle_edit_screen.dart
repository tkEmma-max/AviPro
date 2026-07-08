// lib/screens/cycles/cycle_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';

class CycleEditScreen extends StatefulWidget {
  final Map<String, dynamic> cycle;

  const CycleEditScreen({
    super.key,
    required this.cycle,
  });

  @override
  State<CycleEditScreen> createState() => _CycleEditScreenState();
}

class _CycleEditScreenState extends State<CycleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();

  String? _selectedPoulaillerId;
  DateTime _selectedDate = DateTime.now();
  int _effectifInitial = 0;
  bool _isActive = true;
  bool _isDateLocked = false;
  bool _isEffectifLocked = false;

  @override
  void initState() {
    super.initState();
    final cycle = widget.cycle;
    _nomController.text = cycle['nom'] ?? '';
    _selectedPoulaillerId = cycle['poulaillerId'];
    _selectedDate = DateTime.parse(cycle['dateDebut'] ?? DateTime.now().toIso8601String());
    _effectifInitial = cycle['nbSujets'] ?? 0;
    _isActive = cycle['actif'] ?? true;

    // Simuler des verrouillages
    _isDateLocked = cycle['hasRapports'] ?? false;
    _isEffectifLocked = cycle['hasRapports'] ?? false;
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  Poulailler? get _selectedPoulailler {
    final provider = context.read<PoulaillerProvider>();
    try {
      return provider.poulaillers.firstWhere((p) => p.id == _selectedPoulaillerId);
    } catch (e) {
      return null;
    }
  }

  bool _hasDensityConflict() {
    final poulailler = _selectedPoulailler;
    if (poulailler == null) return false;
    final surface = poulailler.surface ?? 0;
    if (surface <= 0) return false;
    final densite = _effectifInitial / surface;
    return densite > 10; // Seuil critique
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;
    if (_hasDensityConflict()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Densité critique : Ajustez l\'effectif ou changez de poulailler.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Sauvegarder les modifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modifications enregistrées avec succès !'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PoulaillerProvider>();
    final poulaillers = provider.poulaillers.where((p) => !p.isArchived).toList();

    final hasConflict = _hasDensityConflict();

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
          'Modifier le cycle',
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
              // NOM DU CYCLE
              // ============================================================
              _buildLabel('Nom du cycle'),
              TextFormField(
                controller: _nomController,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Ex: Lot Chair Juil-07'),
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // POULAILLER ASSIGNÉ
              // ============================================================
              _buildLabel('Poulailler assigné'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(
                    color: hasConflict ? AppColors.error : const Color(0xFFE2E8F0),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPoulaillerId,
                    hint: Text(
                      'Sélectionnez un poulailler',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: hasConflict ? AppColors.error : AppColors.primary,
                    ),
                    items: poulaillers.map((p) {
                      final isOccupied = p.statut == 'OCCUPÉ' && p.id != widget.cycle['poulaillerId'];
                      return DropdownMenuItem<String>(
                        value: p.id,
                        enabled: !isOccupied,
                        child: Row(
                          children: [
                            Icon(
                              isOccupied ? Icons.lock : Icons.house_outlined,
                              size: 16,
                              color: isOccupied ? AppColors.textHint : AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                p.nom,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isOccupied ? AppColors.textHint : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isOccupied)
                              Text(
                                'Occupé',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedPoulaillerId = value),
                  ),
                ),
              ),
              if (hasConflict)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '⚠️ Densité critique dans ce poulailler',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // DATE DE DÉBUT
              // ============================================================
              _buildLabel('Date de début'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: _isDateLocked ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _isDateLocked ? AppColors.textHint : AppColors.textHint,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _isDateLocked ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (!_isDateLocked)
                      Icon(Icons.edit, color: AppColors.textHint, size: 16),
                    if (_isDateLocked)
                      Icon(Icons.lock, color: AppColors.textHint, size: 16),
                  ],
                ),
              ),
              if (_isDateLocked)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Verrouillé après 48h d\'activité',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // EFFECTIF INITIAL
              // ============================================================
              _buildLabel('Effectif initial'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: _isEffectifLocked ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pets,
                      color: _isEffectifLocked ? AppColors.textHint : AppColors.textHint,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '$_effectifInitial sujets',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _isEffectifLocked ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (!_isEffectifLocked)
                      Icon(Icons.edit, color: AppColors.textHint, size: 16),
                    if (_isEffectifLocked)
                      Icon(Icons.lock, color: AppColors.textHint, size: 16),
                  ],
                ),
              ),
              if (_isEffectifLocked)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Verrouillé car des événements ont été enregistrés',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // STATUT DU CYCLE
              // ============================================================
              _buildLabel('Statut du cycle'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isActive = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _isActive ? AppColors.primary : Colors.transparent,
                            borderRadius: AppBorders.buttonRadius,
                          ),
                          child: Center(
                            child: Text(
                              'ACTIF',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _isActive ? Colors.white : AppColors.textSecondary,
                                fontWeight: _isActive ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isActive = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: !_isActive ? AppColors.error : Colors.transparent,
                            borderRadius: AppBorders.buttonRadius,
                          ),
                          child: Center(
                            child: Text(
                              'CLÔTURÉ',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: !_isActive ? Colors.white : AppColors.textSecondary,
                                fontWeight: !_isActive ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // BOUTONS
              // ============================================================
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.buttonRadius,
                        ),
                      ),
                      child: const Text('ANNULER'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: hasConflict ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.buttonRadius,
                        ),
                        disabledBackgroundColor: AppColors.textHint,
                      ),
                      child: const Text('SAUVEGARDER'),
                    ),
                  ),
                ],
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }
}