// lib/screens/cycles/cycle_report_form_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CycleReportFormScreen extends StatefulWidget {
  final Map<String, dynamic> cycle;

  const CycleReportFormScreen({
    super.key,
    required this.cycle,
  });

  @override
  State<CycleReportFormScreen> createState() => _CycleReportFormScreenState();
}

class _CycleReportFormScreenState extends State<CycleReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _alimentController = TextEditingController();
  final _eauController = TextEditingController();
  final _maladieController = TextEditingController();
  final _medicamentsController = TextEditingController();
  final _observationsController = TextEditingController();

  // Sélecteurs
  DateTime _periodeDebut = DateTime.now().subtract(const Duration(days: 7));
  DateTime _periodeFin = DateTime.now();
  int _nbSujetsMalades = 0;

  @override
  void dispose() {
    _alimentController.dispose();
    _eauController.dispose();
    _maladieController.dispose();
    _medicamentsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDebut ? _periodeDebut : _periodeFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (date != null) {
      setState(() {
        if (isDebut) {
          _periodeDebut = date;
        } else {
          _periodeFin = date;
        }
      });
    }
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Sauvegarder le rapport
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rapport de suivi enregistré avec succès !'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.cardRadius,
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final duree = _periodeFin.difference(_periodeDebut).inDays + 1;

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
          'Rapport de suivi',
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
              // EN-TÊTE : Cycle concerné
              // ============================================================
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Cycle: ${widget.cycle['nom']}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: AppBorders.buttonRadius,
                      ),
                      child: Text(
                        'Jour ${widget.cycle['age'] ?? 0}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // SECTION : PÉRIODE
              // ============================================================
              Text(
                'Période du rapport',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Début',
                      date: _periodeDebut,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Fin',
                      date: _periodeFin,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Durée: $duree jours',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // SECTION : CONSOMMATIONS
              // ============================================================
              Text(
                'Consommations',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _alimentController,
                label: 'Aliment consommé (kg)',
                hint: '0.0',
                prefixIcon: Icons.restaurant,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Requis';
                  if (double.tryParse(value) == null) return 'Nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                controller: _eauController,
                label: 'Eau consommée (litres)',
                hint: '0.0',
                prefixIcon: Icons.water_drop,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Requis';
                  if (double.tryParse(value) == null) return 'Nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // SECTION : SUIVI SANITAIRE (F45)
              // ============================================================
              Text(
                'Suivi sanitaire',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _maladieController,
                label: 'Maladie observée (optionnel)',
                hint: 'Ex: Coccidiose, Gumboro...',
                prefixIcon: Icons.health_and_safety,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                controller: _medicamentsController,
                label: 'Médicaments administrés (optionnel)',
                hint: 'Ex: Anticoccidiens 5g/L...',
                prefixIcon: Icons.medication,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Nombre de sujets malades
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nombre de sujets malades',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _buildCounterButton(Icons.remove, () {
                        setState(() {
                          if (_nbSujetsMalades > 0) _nbSujetsMalades--;
                        });
                      }),
                      Container(
                        width: 60,
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          _nbSujetsMalades.toString(),
                          style: AppTextStyles.numberMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      _buildCounterButton(Icons.add, () {
                        setState(() {
                          _nbSujetsMalades++;
                        });
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // SECTION : OBSERVATIONS
              // ============================================================
              Text(
                'Observations',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _observationsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Comportement, conditions, remarques...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorders.inputRadius,
                    borderSide: const BorderSide(color: AppColors.border),
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
              // BOUTON ENREGISTRER
              // ============================================================
              CustomButton(
                label: 'ENREGISTRER LE RAPPORT',
                onPressed: _submitReport,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppBorders.inputRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.primary),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        constraints: const BoxConstraints(),
      ),
    );
  }
}