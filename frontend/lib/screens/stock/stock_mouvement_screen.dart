// lib/screens/stock/stock_mouvement_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class StockMouvementScreen extends StatefulWidget {
  const StockMouvementScreen({super.key});

  @override
  State<StockMouvementScreen> createState() => _StockMouvementScreenState();
}

class _StockMouvementScreenState extends State<StockMouvementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();
  final _dateController = TextEditingController();

  String _mode = 'ENTRÉE';
  String? _selectedProduit;
  String? _selectedCycle;
  DateTime _selectedDate = DateTime.now();

  final List<String> _produits = ['Aliment pondeuse', 'Aliment démarrage', 'Vaccin Gumboro', 'Mangeoires', 'Abreuvoirs'];
  final List<String> _cycles = ['Lot Poussins Juillet', 'Bande Pondeuses Mars', 'Poulet Chair Mai'];

  @override
  void dispose() {
    _quantiteController.dispose();
    _prixController.dispose();
    _dateController.dispose();
    super.dispose();
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
          'Mouvement de stock',
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
              // SÉLECTEUR DE MODE (ENTRÉE / SORTIE)
              // ============================================================
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: AppBorders.buttonRadius,
                ),
                child: Row(
                  children: ['ENTRÉE', 'SORTIE'].map((mode) {
                    final isSelected = _mode == mode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = mode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? mode == 'ENTRÉE'
                                    ? AppColors.success
                                    : AppColors.primary
                                : Colors.transparent,
                            borderRadius: AppBorders.buttonRadius,
                          ),
                          child: Center(
                            child: Text(
                              mode == 'ENTRÉE' ? '📥 ENTRÉE (Achat)' : '📤 SORTIE (Utilisation)',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // CHAMPS DU FORMULAIRE
              // ============================================================

              // Produit
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProduit,
                    hint: Text(
                      'Sélectionnez un produit',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _produits.map((p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(p, style: AppTextStyles.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedProduit = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quantité
              CustomTextField(
                controller: _quantiteController,
                label: 'Quantité',
                hint: '0.0',
                prefixIcon: Icons.numbers,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Requis';
                  if (double.tryParse(value) == null) return 'Nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Si mode SORTIE → Sélection du cycle
              if (_mode == 'SORTIE')
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: AppBorders.inputRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCycle,
                          hint: Text(
                            'Cycle de production',
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
                  ],
                ),

              // Si mode ENTRÉE → Prix et Date
              if (_mode == 'ENTRÉE')
                Column(
                  children: [
                    CustomTextField(
                      controller: _prixController,
                      label: "Prix d'achat (FCFA)",
                      hint: '0',
                      prefixIcon: Icons.money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        if (double.tryParse(value) == null) return 'Nombre valide';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppBorders.inputRadius,
                          border: Border.all(color: AppColors.border),
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
                  ],
                ),

              // ============================================================
              // BOUTON VALIDER
              // ============================================================
              CustomButton(
                label: 'VALIDER LE MOUVEMENT',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mouvement enregistré avec succès !'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}