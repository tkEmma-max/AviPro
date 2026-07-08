// lib/screens/finances/finance_remboursement_create_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';

class FinanceRemboursementCreateScreen extends StatefulWidget {
  final Map<String, dynamic> pret;

  const FinanceRemboursementCreateScreen({
    super.key,
    required this.pret,
  });

  @override
  State<FinanceRemboursementCreateScreen> createState() =>
      _FinanceRemboursementCreateScreenState();
}

class _FinanceRemboursementCreateScreenState
    extends State<FinanceRemboursementCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  double get _montantRestant => widget.pret['montant_restant'] ?? 0;

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final montant = double.parse(_montantController.text);
    if (montant > _montantRestant) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le montant ne peut pas dépasser le reste dû (${_montantRestant.toStringAsFixed(0)} FCFA)',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Sauvegarder le remboursement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remboursement enregistré avec succès !'),
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
          'Remboursement manuel',
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
              // RESTE DÛ (information)
              // ============================================================
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reste dû',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${_montantRestant.toStringAsFixed(0)} FCFA',
                      style: AppTextStyles.numberMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // MONTANT
              // ============================================================
              Text(
                'Montant remboursé (FCFA)',
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
                  suffixText: 'FCFA',
                  suffixStyle: AppTextStyles.bodyMedium.copyWith(
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
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // DATE
              // ============================================================
              Text(
                'Date du paiement',
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
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
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
              // DESCRIPTION (optionnelle)
              // ============================================================
              Text(
                'Description / Note (optionnel)',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ex: Remboursement partiel via fonds propres...',
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
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                  child: const Text(
                    'ENREGISTRER LE REMBOURSEMENT',
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