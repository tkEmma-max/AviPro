// lib/screens/finances/routine_create_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../services/api_service.dart';

class RoutineCreateScreen extends StatefulWidget {
  const RoutineCreateScreen({super.key});

  @override
  State<RoutineCreateScreen> createState() => _RoutineCreateScreenState();
}

class _RoutineCreateScreenState extends State<RoutineCreateScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _ageController = TextEditingController(text: '0');
  final _montantController = TextEditingController();
  final _seuilController = TextEditingController(text: '50');

  String? _selectedTypePoulet;
  String? _selectedCategorie;
  String _modeCalcul = 'PAR_SUJET';
  bool _isLoading = false;

  List<dynamic> _typesPoulet = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final typesResponse = await _apiService.get('cycles/types-poulet/');
      final catResponse = await _apiService.get('depenses/categories/');
      if (mounted) {
        setState(() {
          _typesPoulet = typesResponse.data['results'] ?? [];
          _categories = catResponse.data['results'] ?? [];
        });
      }
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypePoulet == null || _selectedCategorie == null) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'nom': _nomController.text.trim(),
        'type_poulet': _selectedTypePoulet,
        'categorie_depense': _selectedCategorie,
        'age_jour': int.tryParse(_ageController.text) ?? 0,
        'mode_calcul': _modeCalcul,
        'montant_par_sujet': _modeCalcul == 'PAR_SUJET' ? int.tryParse(_montantController.text) ?? 0 : 0,
        'montant_par_tranche': _modeCalcul == 'PAR_TRANCHE' ? int.tryParse(_montantController.text) ?? 0 : 0,
        'montant_fixe': _modeCalcul == 'FIXE' ? int.tryParse(_montantController.text) ?? 0 : 0,
        'seuil_tranche': _modeCalcul == 'PAR_TRANCHE' ? int.tryParse(_seuilController.text) ?? 50 : 50,
      };

      final response = await _apiService.post('depenses/routines/', data: data);
      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routine créée !'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Nouvelle routine', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.lg),

          Text('Nom *', style: AppTextStyles.subtitleMedium),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(controller: _nomController, decoration: _inputDecoration('Ex: Vaccins J0'), validator: (v) => v!.isEmpty ? 'Requis' : null),
          const SizedBox(height: AppSpacing.lg),

          Text('Type de poulet *', style: AppTextStyles.subtitleMedium),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            value: _selectedTypePoulet,
            items: _typesPoulet.map<DropdownMenuItem<String>>((t) => DropdownMenuItem<String>(value: t['id'], child: Text(t['nom'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedTypePoulet = v),
            decoration: _inputDecoration('Sélectionnez'),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Catégorie *', style: AppTextStyles.subtitleMedium),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            value: _selectedCategorie,
            items: _categories.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['nom'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedCategorie = v),
            decoration: _inputDecoration('Sélectionnez'),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Âge (jours) *', style: AppTextStyles.subtitleMedium),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(controller: _ageController, keyboardType: TextInputType.number, decoration: _inputDecoration('0')),
          const SizedBox(height: AppSpacing.lg),

          Text('Mode de calcul', style: AppTextStyles.subtitleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(children: ['PAR_SUJET', 'PAR_TRANCHE', 'FIXE'].map((m) => Expanded(child: GestureDetector(
              onTap: () => setState(() => _modeCalcul = m),
              child: Container(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), margin: const EdgeInsets.only(right: AppSpacing.sm), decoration: BoxDecoration(color: _modeCalcul == m ? AppColors.primary : AppColors.surfaceLight, borderRadius: AppBorders.buttonRadius, border: Border.all(color: _modeCalcul == m ? AppColors.primary : AppColors.border)), child: Center(child: Text(m == 'PAR_SUJET' ? '/sujet' : m == 'PAR_TRANCHE' ? '/tranche' : 'Fixe', style: AppTextStyles.labelSmall.copyWith(color: _modeCalcul == m ? Colors.white : AppColors.textSecondary))))),
          )).toList()),
          const SizedBox(height: AppSpacing.lg),

          Text(_modeCalcul == 'FIXE' ? 'Montant fixe (FCFA)' : _modeCalcul == 'PAR_TRANCHE' ? 'Montant par tranche (FCFA)' : 'Montant par sujet (FCFA)', style: AppTextStyles.subtitleMedium),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(controller: _montantController, keyboardType: TextInputType.number, decoration: _inputDecoration('0'), validator: (v) => v!.isEmpty ? 'Requis' : null),

          if (_modeCalcul == 'PAR_TRANCHE') ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Sujets par tranche', style: AppTextStyles.subtitleMedium),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(controller: _seuilController, keyboardType: TextInputType.number, decoration: _inputDecoration('50')),
          ],

          const SizedBox(height: AppSpacing.xxl),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppBorders.buttonRadius)), child: Text(_isLoading ? 'CRÉATION...' : 'CRÉER LA ROUTINE'))),
          const SizedBox(height: AppSpacing.lg),
        ])),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: AppBorders.inputRadius),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    );
  }
}