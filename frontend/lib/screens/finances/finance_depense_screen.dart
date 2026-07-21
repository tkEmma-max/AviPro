// lib/screens/finances/finance_depense_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../providers/cycle_provider.dart';
import '../../services/api_service.dart';

class FinanceDepenseScreen extends StatefulWidget {
  const FinanceDepenseScreen({super.key});

  @override
  State<FinanceDepenseScreen> createState() => _FinanceDepenseScreenState();
}

class _FinanceDepenseScreenState extends State<FinanceDepenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategorie;
  String? _selectedCycleId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Catégories alignées avec le backend
  final Map<String, String> _categories = {
    'ALIMENT': 'Aliment',
    'POUSSIN': 'Achat de poussins',
    'VACCIN': 'Vaccins et médicaments',
    'EAU': 'Eau',
    'ELECTRICITE': 'Électricité',
    'MAIN_OEUVRE': "Main-d'œuvre",
    'TRANSPORT': 'Transport',
    'ENTRETIEN': 'Entretien',
    'EQUIPEMENT': 'Équipement',
    'AUTRE': 'Autre',
  };

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args.containsKey('cycle_id')) {
        setState(() {
          _selectedCycleId = args['cycle_id'];
        });
      }
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategorie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une catégorie'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_selectedCycleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un cycle'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'cycle': _selectedCycleId,
        'categorie': _selectedCategorie,
        'montant': int.parse(_montantController.text),
        'date': _selectedDate.toIso8601String().split('T')[0],
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      };

      print('📤 [DEPENSE] POST data: $data');
      final response = await _apiService.post('depenses/', data: data);
      print('📥 [DEPENSE] Réponse: ${response.statusCode}');

      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dépense enregistrée !'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [DEPENSE] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycleProvider = context.watch<CycleProvider>();
    final cyclesActifs = cycleProvider.cycles.where((c) => c.isActive && !c.isArchived).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nouvelle dépense', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
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

              // Cycle
              Text('Cycle *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCycleId,
                    hint: Text('Sélectionnez un cycle actif', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: cyclesActifs.map((c) {
                      return DropdownMenuItem<String>(value: c.id, child: Text(c.nom, style: AppTextStyles.bodyMedium));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCycleId = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Catégorie
              Text('Catégorie *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategorie,
                    hint: Text('Sélectionnez une catégorie', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _categories.entries.map((e) {
                      return DropdownMenuItem<String>(value: e.key, child: Text(e.value, style: AppTextStyles.bodyMedium));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategorie = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Montant
              Text('Montant (FCFA) *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('0'),
                validator: (v) => v!.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0 ? 'Montant valide requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date
              Text('Date', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.textHint),
                      const SizedBox(width: AppSpacing.md),
                      Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              Text('Description (optionnel)', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: _inputDecoration('Note...')),
              const SizedBox(height: AppSpacing.xxl),

              // Bouton
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppBorders.buttonRadius)),
                  child: Text(_isLoading ? 'ENREGISTREMENT...' : 'ENREGISTRER LA DÉPENSE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
      hintText: hint, hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      filled: true, fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    );
  }
}