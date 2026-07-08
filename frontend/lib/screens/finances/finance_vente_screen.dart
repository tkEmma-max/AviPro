// lib/screens/finances/finance_vente_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';

class FinanceVenteScreen extends StatefulWidget {
  const FinanceVenteScreen({super.key});

  @override
  State<FinanceVenteScreen> createState() => _FinanceVenteScreenState();
}

class _FinanceVenteScreenState extends State<FinanceVenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _clientController = TextEditingController();

  String? _selectedCycle;
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  double _montantTotal = 0;

  final List<String> _cycles = ['Lot Juillet', 'Bande Mars'];
  final List<String> _types = ['Œufs', 'Poulets', 'Poules réforme', 'Poussins', 'Fientes'];

  void _updateMontantTotal() {
    final qte = double.tryParse(_quantiteController.text) ?? 0;
    final prix = double.tryParse(_prixUnitaireController.text) ?? 0;
    setState(() {
      _montantTotal = qte * prix;
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

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
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de vente'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: Sauvegarder la vente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vente enregistrée avec succès !'),
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
  void dispose() {
    _quantiteController.dispose();
    _prixUnitaireController.dispose();
    _clientController.dispose();
    super.dispose();
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
          'Nouvelle vente',
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
              // CYCLE
              // ============================================================
              Text(
                'Cycle concerné',
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
                      'Sélectionnez un cycle',
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
              // TYPE
              // ============================================================
              Text(
                'Type de vente',
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
                    value: _selectedType,
                    hint: Text(
                      'Sélectionnez un type',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _types.map((t) {
                      return DropdownMenuItem<String>(
                        value: t,
                        child: Text(t, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // QUANTITÉ & PRIX (côte à côte)
              // ============================================================
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantité',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _quantiteController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateMontantTotal(),
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration('0'),
                          validator: (value) {
                            if (value!.isEmpty) return 'Requis';
                            if (double.tryParse(value) == null) return 'Nombre';
                            if (double.parse(value) <= 0) return '> 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prix unitaire (FCFA)',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _prixUnitaireController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateMontantTotal(),
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDecoration('0'),
                          validator: (value) {
                            if (value!.isEmpty) return 'Requis';
                            if (double.tryParse(value) == null) return 'Nombre';
                            if (double.parse(value) <= 0) return '> 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // MONTANT TOTAL (calculé)
              // ============================================================
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Montant total',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF047857),
                      ),
                    ),
                    Text(
                      '${_montantTotal.toStringAsFixed(0)} FCFA',
                      style: AppTextStyles.numberLarge.copyWith(
                        fontSize: 20,
                        color: const Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
              // CLIENT (optionnel)
              // ============================================================
              Text(
                'Nom du client (optionnel)',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _clientController,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Nom ou raison sociale'),
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
                    'ENREGISTRER LA VENTE',
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }
}