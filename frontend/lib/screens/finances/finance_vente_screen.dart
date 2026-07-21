// lib/screens/finances/finance_vente_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../providers/cycle_provider.dart';
import '../../services/api_service.dart';

class FinanceVenteScreen extends StatefulWidget {
  const FinanceVenteScreen({super.key});

  @override
  State<FinanceVenteScreen> createState() => _FinanceVenteScreenState();
}

class _FinanceVenteScreenState extends State<FinanceVenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _quantiteController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _clientController = TextEditingController();

  String? _selectedCycleId;
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  double _montantTotal = 0;
  bool _isLoading = false;

  double _coutProductionUnitaire = 0;
  bool _isVenteAPerte = false;
  bool _donneesCycleChargees = false;

  final Map<String, String> _types = {
    'POULETS': 'Poulets',
    'OEUFS': 'Œufs',
    'POUSSINS': 'Poussins',
    'POULE_REFORME': 'Poules de réforme',
    'FIANTES': 'Fientes',
    'AUTRE': 'Autre',
  };

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

  @override
  void dispose() {
    _quantiteController.dispose();
    _prixUnitaireController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  void _updateMontantTotal() {
    final qte = int.tryParse(_quantiteController.text) ?? 0;
    final prix = double.tryParse(_prixUnitaireController.text) ?? 0;
    setState(() {
      _montantTotal = qte * prix;
      _checkVenteAPerte();
    });
  }

  void _checkVenteAPerte() {
    final prix = double.tryParse(_prixUnitaireController.text) ?? 0;
    _isVenteAPerte = _donneesCycleChargees && _coutProductionUnitaire > 0 && prix < _coutProductionUnitaire;
  }

  Future<void> _loadCoutProduction(String cycleId) async {
    try {
      final response = await _apiService.get('cycles/$cycleId/');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _coutProductionUnitaire = double.tryParse(data['cout_production_unitaire']?.toString() ?? '0') ?? 0;
          _donneesCycleChargees = true;
          _checkVenteAPerte();
        });
      }
    } catch (e) {
      print('❌ Erreur chargement cout: $e');
    }
  }

  double _getPrixRecommande(double pourcentageBenefice) {
    if (_coutProductionUnitaire <= 0) return 0;
    return _coutProductionUnitaire * (1 + pourcentageBenefice / 100);
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCycleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un cycle'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un type'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'cycle': _selectedCycleId,
        'type': _selectedType,
        'quantite': int.parse(_quantiteController.text),
        'prix_unitaire': _prixUnitaireController.text,
        'montant_total': _montantTotal.toStringAsFixed(0),
        'date': _selectedDate.toIso8601String().split('T')[0],
        if (_clientController.text.isNotEmpty) 'client_nom': _clientController.text,
      };

      print('📤 [VENTE] POST data: $data');
      final response = await _apiService.post('ventes/', data: data);
      print('📥 [VENTE] Reponse: ${response.statusCode}');

      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente enregistree !'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [VENTE] Exception: $e');
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
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Nouvelle vente', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
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
                    hint: Text('Selectionnez un cycle', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: cyclesActifs.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.nom, style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedCycleId = v);
                      if (v != null) _loadCoutProduction(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Type
              Text('Type de vente *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    hint: Text('Selectionnez un type', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: _types.entries.map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value, style: AppTextStyles.bodyMedium))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quantite & Prix
              Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Quantite *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(controller: _quantiteController, keyboardType: TextInputType.number, onChanged: (_) => _updateMontantTotal(), decoration: _inputDecoration('0'), validator: (v) => v!.isEmpty || int.tryParse(v) == null ? 'Requis' : null),
                    ]),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Prix unitaire *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(controller: _prixUnitaireController, keyboardType: TextInputType.number, onChanged: (_) => _updateMontantTotal(), decoration: _inputDecoration('0'), validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Requis' : null),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Montant total
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.3))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Montant total', style: AppTextStyles.bodyMedium),
                  Text('${_montantTotal.toInt()} FCFA', style: AppTextStyles.numberMedium.copyWith(color: AppColors.success)),
                ]),
              ),

              // Alerte vente a perte
              if (_isVenteAPerte)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.warning_amber_outlined, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text('VENTE A PERTE', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.error)),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Cout de production: ${_coutProductionUnitaire.toInt()} FCFA/unite. Vous vendez en dessous du prix de revient.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ),

              // Suggestions de prix
              if (_donneesCycleChargees && _coutProductionUnitaire > 0)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Prix suggeres', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.primary)),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      _buildPrixSuggere('Equilibre (0%)', _getPrixRecommande(0)),
                      _buildPrixSuggere('Benefice +10%', _getPrixRecommande(10)),
                      _buildPrixSuggere('Benefice +20%', _getPrixRecommande(20)),
                    ],
                  ),
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
                  child: Row(children: [
                    Icon(Icons.calendar_today, color: AppColors.textHint), const SizedBox(width: AppSpacing.md),
                    Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: AppTextStyles.bodyMedium),
                    const Spacer(), Icon(Icons.arrow_drop_down, color: AppColors.textHint),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Client
              Text('Client (optionnel)', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(controller: _clientController, decoration: _inputDecoration('Nom du client')),
              const SizedBox(height: AppSpacing.xxl),

              // Bouton
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppBorders.buttonRadius)),
                  child: Text(_isLoading ? 'ENREGISTREMENT...' : 'ENREGISTRER LA VENTE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrixSuggere(String label, double prix) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          GestureDetector(
            onTap: () {
              _prixUnitaireController.text = prix.toStringAsFixed(0);
              _updateMontantTotal();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppBorders.buttonRadius,
              ),
              child: Text('${prix.toStringAsFixed(0)} FCFA', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
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