// lib/screens/finances/finance_echeance_create_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';

class FinanceEcheanceCreateScreen extends StatefulWidget {
  final Map<String, dynamic> pret;

  const FinanceEcheanceCreateScreen({
    super.key,
    required this.pret,
  });

  @override
  State<FinanceEcheanceCreateScreen> createState() =>
      _FinanceEcheanceCreateScreenState();
}

class _FinanceEcheanceCreateScreenState
    extends State<FinanceEcheanceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Sauvegarder l'échéance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Échéance ajoutée avec succès !'),
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
          'Ajouter une échéance',
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
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // DATE DE L'ÉCHÉANCE
              // ============================================================
              Text(
                'Date de l\'échéance',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime(2030),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: AppBorders.inputRadius,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.textHint),
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
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // MONTANT
              // ============================================================
              Text(
                'Montant à verser (FCFA)',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
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
                  if (value!.isEmpty) return 'Ce champ est requis';
                  if (double.tryParse(value) == null) return 'Nombre valide';
                  if (double.parse(value) <= 0) return '> 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // BOUTON VALIDER
              // ============================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                  child: const Text(
                    'AJOUTER L\'ÉCHÉANCE',
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
}