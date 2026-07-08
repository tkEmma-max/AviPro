// lib/screens/cycles/cycle_create_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CycleCreateScreen extends StatefulWidget {
  const CycleCreateScreen({super.key});

  @override
  State<CycleCreateScreen> createState() => _CycleCreateScreenState();
}

class _CycleCreateScreenState extends State<CycleCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _nomController = TextEditingController();
  final _nbSujetsController = TextEditingController();
  final _coutAchatController = TextEditingController();

  // Sélecteurs
  String? _selectedPoulaillerId;
  String _selectedType = 'CHAIR';
  DateTime _selectedDate = DateTime.now();

  // Calculs dynamiques
  double _densite = 0;
  bool _isDensiteOk = false;

  final List<String> _types = ['CHAIR', 'PONDEUSE', 'LOCAL'];

  @override
  void dispose() {
    _nomController.dispose();
    _nbSujetsController.dispose();
    _coutAchatController.dispose();
    super.dispose();
  }

  void _updateDensite() {
    final nb = int.tryParse(_nbSujetsController.text) ?? 0;
    final poulailler = _getSelectedPoulailler();
    if (poulailler != null && nb > 0 && poulailler.surface != null) {
      setState(() {
        _densite = nb / poulailler.surface!;
        _isDensiteOk = _densite <= 10; // Seuil pour poulet de chair
      });
    } else {
      setState(() {
        _densite = 0;
        _isDensiteOk = false;
      });
    }
  }

  Poulailler? _getSelectedPoulailler() {
    final provider = context.read<PoulaillerProvider>();
    try {
      return provider.poulaillers.firstWhere(
        (p) => p.id == _selectedPoulaillerId,
      );
    } catch (e) {
      return null;
    }
  }

  void _createCycle() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPoulaillerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un poulailler'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_isDensiteOk) return;

    // TODO: Sauvegarder le cycle
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final poulaillerProvider = context.watch<PoulaillerProvider>();
    final poulaillersLibres = poulaillerProvider.poulaillers
        .where((p) => p.statut == 'LIBRE')
        .toList();

    final selectedPoulailler = _getSelectedPoulailler();
    final capaciteMax = selectedPoulailler?.surface != null
        ? (selectedPoulailler!.surface! * 8).toInt()
        : 0;

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
          'Lancer un cycle',
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // SÉLECTION DU POULAILLER
              // ============================================================
              Text(
                'Infrastructure',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPoulaillerId,
                    hint: Text(
                      'Sélectionnez un poulailler libre',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: poulaillersLibres.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              p.nom,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const Spacer(),
                            Text(
                              '${p.surface?.toStringAsFixed(1) ?? 0} m²',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPoulaillerId = value;
                        _updateDensite();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // CARACTÉRISTIQUES DU LOT
              // ============================================================
              Text(
                'Caractéristiques du lot',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _nomController,
                label: 'Nom de la bande *',
                hint: 'Ex: Lot Chair Juil-07',
                prefixIcon: Icons.label_outline,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Type d'élevage
              Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          borderRadius: AppBorders.buttonRadius,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Nombre de sujets
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _nbSujetsController,
                      label: 'Nombre de sujets *',
                      hint: '0',
                      prefixIcon: Icons.pets,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateDensite(),
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        final v = int.tryParse(value);
                        if (v == null || v <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      controller: _coutAchatController,
                      label: "Coût d'achat",
                      hint: '0 FCFA',
                      prefixIcon: Icons.money_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              // ============================================================
              // ALERTE DE DENSITÉ
              // ============================================================
              if (_selectedPoulaillerId != null &&
                  _nbSujetsController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _isDensiteOk
                        ? AppColors.success.withOpacity(0.08)
                        : AppColors.error.withOpacity(0.08),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(
                      color: _isDensiteOk
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDensiteOk
                            ? Icons.check_circle
                            : Icons.warning_amber_outlined,
                        color: _isDensiteOk ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDensiteOk
                                  ? '🟢 Densité conforme (${_densite.toStringAsFixed(1)} sujets/m²)'
                                  : '🔴 Surcharge : Capacité maximale de ${capaciteMax} sujets (${_densite.toStringAsFixed(1)} sujets/m²)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _isDensiteOk
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!_isDensiteOk)
                              Text(
                                'La capacité maximale de ce bâtiment est de $capaciteMax sujets.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // DATE DE MISE EN PLACE
              // ============================================================
              Text(
                'Date de mise en place',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppBorders.inputRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: AppColors.textHint, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ============================================================
              // BOUTON VALIDER
              // ============================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _createCycle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                  child: Text(
                    'VALIDER ET LANCER LE CYCLE',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}