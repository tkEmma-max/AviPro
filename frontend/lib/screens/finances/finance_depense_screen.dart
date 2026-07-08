// lib/screens/finances/finance_depense_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';

class FinanceDepenseScreen extends StatefulWidget {
  const FinanceDepenseScreen({super.key});

  @override
  State<FinanceDepenseScreen> createState() => _FinanceDepenseScreenState();
}

class _FinanceDepenseScreenState extends State<FinanceDepenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategorie;
  String? _selectedCycle;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Alimentation',
    'Santé/Vaccins',
    'Infrastructure',
    "Main d'œuvre",
    'Transport',
    'Électricité',
    'Autre'
  ];

  final List<String> _cycles = ['Lot Juillet', 'Bande Mars', 'Général'];

  @override
  void dispose() {
    _montantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategorie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedCycle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un cycle'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Sauvegarder la dépense
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dépense enregistrée avec succès !'),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nouvelle dépense',
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // CATÉGORIE
              // ============================================================
              Text(
                'Type de charge',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategorie,
                    hint: Text(
                      'Sélectionnez une catégorie',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategorie = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // MONTANT
              // ============================================================
              Text(
                'Montant (FCFA)',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
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
                  if (double.tryParse(value) == null) {
                    return 'Veuillez saisir un montant numérique valide';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // CYCLE
              // ============================================================
              Text(
                'Assignation au cycle',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCycle,
                    hint: Text(
                      'Choisissez un cycle',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _cycles.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCycle = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // DATE
              // ============================================================
              Text(
                'Date',
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
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // NOTE (optionnelle)
              // ============================================================
              Text(
                'Note / Commentaire (optionnel)',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ajoutez une note...',
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                  child: const Text(
                    'ENREGISTRER LA DÉPENSE',
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