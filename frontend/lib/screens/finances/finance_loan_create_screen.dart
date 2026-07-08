// lib/screens/finances/finance_loan_create_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';

class FinanceLoanCreateScreen extends StatefulWidget {
  const FinanceLoanCreateScreen({super.key});

  @override
  State<FinanceLoanCreateScreen> createState() =>
      _FinanceLoanCreateScreenState();
}

class _FinanceLoanCreateScreenState extends State<FinanceLoanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _preteurController = TextEditingController();
  final _montantController = TextEditingController();
  final _tauxController = TextEditingController();
  final _nbEcheancesController = TextEditingController();
  final _montantEcheanceController = TextEditingController();

  String? _selectedTypePreteur;
  DateTime _selectedDate = DateTime.now();
  String _selectedMode = 'Proposé';
  List<String> _selectedCycles = [];

  final List<String> _typesPreteur = [
    'Banque',
    'Microfinance',
    'Famille',
    'Tontine',
    'Autre'
  ];

  final List<String> _cyclesDisponibles = ['Lot Juillet', 'Bande Mars'];

  bool _showEcheances = false;

  @override
  void dispose() {
    _preteurController.dispose();
    _montantController.dispose();
    _tauxController.dispose();
    _nbEcheancesController.dispose();
    _montantEcheanceController.dispose();
    super.dispose();
  }

  void _updateEcheancesVisibility() {
    setState(() {
      _showEcheances = _selectedMode == 'Imposé';
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Sauvegarder le prêt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prêt enregistré avec succès !'),
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
          'Nouveau prêt',
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
              // PRÊTEUR
              // ============================================================
              _buildLabel('Nom du prêteur'),
              TextFormField(
                controller: _preteurController,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('Ex: Crédit Agricole'),
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // TYPE DE PRÊTEUR
              // ============================================================
              _buildLabel('Type de prêteur'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTypePreteur,
                    hint: Text(
                      'Sélectionnez un type',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _typesPreteur.map((t) {
                      return DropdownMenuItem<String>(
                        value: t,
                        child: Text(t, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedTypePreteur = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // MONTANT
              // ============================================================
              _buildLabel('Montant total emprunté (FCFA)'),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('0'),
                validator: (value) {
                  if (value!.isEmpty) return 'Requis';
                  if (double.tryParse(value) == null) return 'Nombre';
                  if (double.parse(value) <= 0) return '> 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // DATE DE DÉBLOCAGE
              // ============================================================
              _buildLabel('Date de déblocage'),
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
                    color: const Color(0xFFF8FAFC),
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
              // TAUX D'INTÉRÊT
              // ============================================================
              _buildLabel('Taux d\'intérêt (%)'),
              TextFormField(
                controller: _tauxController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium,
                decoration: _inputDecoration('0 (prêt à taux zéro)'),
                validator: (value) {
                  if (value!.isEmpty) return 'Requis';
                  if (double.tryParse(value) == null) return 'Nombre';
                  if (double.parse(value) < 0) return '>= 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // MODE DE REMBOURSEMENT
              // ============================================================
              _buildLabel('Mode de remboursement'),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: AppBorders.buttonRadius,
                ),
                child: Row(
                  children: ['Imposé', 'Proposé', 'Flexible'].map((mode) {
                    final isSelected = _selectedMode == mode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMode = mode;
                            _updateEcheancesVisibility();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: AppBorders.buttonRadius,
                          ),
                          child: Center(
                            child: Text(
                              mode,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
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
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _selectedMode == 'Imposé'
                    ? 'Saisie manuelle des échéances'
                    : _selectedMode == 'Proposé'
                        ? 'Calcul automatique de l\'échéancier'
                        : 'Remboursement libre (sans échéances)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // SOUS-FORMULAIRE : ÉCHÉANCES (si mode Imposé)
              // ============================================================
              if (_showEcheances) ...[
                _buildLabel('Nombre d\'échéances'),
                TextFormField(
                  controller: _nbEcheancesController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('Ex: 6'),
                  validator: (value) {
                    if (value!.isEmpty) return 'Requis';
                    if (int.tryParse(value) == null) return 'Nombre';
                    if (int.parse(value) <= 0) return '> 0';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildLabel('Montant par échéance (FCFA)'),
                TextFormField(
                  controller: _montantEcheanceController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('0'),
                  validator: (value) {
                    if (value!.isEmpty) return 'Requis';
                    if (double.tryParse(value) == null) return 'Nombre';
                    if (double.parse(value) <= 0) return '> 0';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ============================================================
              // CYCLES AFFECTÉS (optionnel)
              // ============================================================
              _buildLabel('Cycles affectés (optionnel)'),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: null,
                    hint: Text(
                      'Sélectionnez un ou plusieurs cycles',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _cyclesDisponibles.map((c) {
                      final isSelected = _selectedCycles.contains(c);
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(c, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          if (_selectedCycles.contains(value)) {
                            _selectedCycles.remove(value);
                          } else {
                            _selectedCycles.add(value);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_selectedCycles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Cycles affectés: ${_selectedCycles.join(', ')}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                    'ENREGISTRER LE PRÊT',
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
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
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