// lib/screens/rapports/rapport_create_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class RapportCreateScreen extends StatefulWidget {
  final String cycleId;

  const RapportCreateScreen({super.key, required this.cycleId});

  @override
  State<RapportCreateScreen> createState() => _RapportCreateScreenState();
}

class _RapportCreateScreenState extends State<RapportCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _alimentController = TextEditingController();
  final _eauController = TextEditingController();
  final _maladieController = TextEditingController();
  final _medicamentsController = TextEditingController();
  final _nbMaladesController = TextEditingController();
  final _observationsController = TextEditingController();

  DateTime _periodeDebut = DateTime.now();
  DateTime _periodeFin = DateTime.now();

  bool _isLoading = false;

  @override
  void dispose() {
    _alimentController.dispose();
    _eauController.dispose();
    _maladieController.dispose();
    _medicamentsController.dispose();
    _nbMaladesController.dispose();
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

  Future<void> _submitRapport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Sauvegarder le rapport
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport enregistré avec succès !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.cardRadius,
          ),
        ),
      );
      Navigator.pop(context);
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
              // PÉRIODE
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
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // CONSOMMATIONS
              // ============================================================
              Text(
                'Consommations',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _alimentController,
                      label: 'Aliment (kg)',
                      hint: '0.0',
                      prefixIcon: Icons.grass,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      controller: _eauController,
                      label: 'Eau (litres)',
                      hint: '0.0',
                      prefixIcon: Icons.water_drop,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // SUIVI SANITAIRE
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
                label: 'Maladie observée',
                hint: 'Ex: Coccidiose, Gumboro...',
                prefixIcon: Icons.health_and_safety,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                controller: _medicamentsController,
                label: 'Médicaments administrés',
                hint: 'Ex: Anticoccidiens, Vitamines...',
                prefixIcon: Icons.medication,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                controller: _nbMaladesController,
                label: 'Nombre de sujets malades',
                hint: '0',
                prefixIcon: Icons.pets,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // OBSERVATIONS
              // ============================================================
              Text(
                'Observations',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _observationsController,
                label: 'Observations générales',
                hint: 'Ex: Comportement, conditions...',
                prefixIcon: Icons.note_alt_outlined,
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ============================================================
              // BOUTON VALIDER
              // ============================================================
              CustomButton(
                label: 'ENREGISTRER LE RAPPORT',
                isLoading: _isLoading,
                onPressed: _submitRapport,
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppBorders.inputRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    color: AppColors.textHint, size: 16),
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
}