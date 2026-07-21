// lib/screens/finances/finance_loan_create_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../models/pret.dart';
import '../../providers/pret_provider.dart';

class FinanceLoanCreateScreen extends StatefulWidget {
  const FinanceLoanCreateScreen({super.key});

  @override
  State<FinanceLoanCreateScreen> createState() => _FinanceLoanCreateScreenState();
}

class _FinanceLoanCreateScreenState extends State<FinanceLoanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _preteurController = TextEditingController();
  final _montantController = TextEditingController();
  final _tauxController = TextEditingController(text: '0');
  final _montantEcheanceController = TextEditingController();

  String? _selectedTypePreteur;
  DateTime _selectedDate = DateTime.now();
  DateTime? _dateLimite;
  String _typeTaux = 'MENSUEL';
  String _typeEcheance = 'MENSUEL';
  bool _echeancesImposees = false;
  bool _isLoading = false;

  final Map<String, String> _typesPreteur = {
    'BANQUE': 'Banque', 'MICROFINANCE': 'Microfinance',
    'FAMILLE': 'Famille', 'TONTINE': 'Tontine', 'AUTRE': 'Autre',
  };

  final Map<String, String> _typesEcheance = {
    'MENSUEL': 'Mensuelle',
    'HEBDOMADAIRE': 'Hebdomadaire',
    'JOURNALIER': 'Journalière (10, 15, 20 jours...)',
    'ANNUEL': 'Annuelle',
  };

  @override
  void dispose() {
    _preteurController.dispose(); _montantController.dispose();
    _tauxController.dispose(); _montantEcheanceController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  // CALCULS
  // ═══════════════════════════════════════════════
  double get _montantEmprunte => double.tryParse(_montantController.text) ?? 0;
  double get _taux => double.tryParse(_tauxController.text) ?? 0;
  double get _montantEcheance => double.tryParse(_montantEcheanceController.text) ?? 0;

  int get _nbMois {
    if (_dateLimite == null) return 0;
    final jours = _dateLimite!.difference(_selectedDate).inDays;
    return (jours / 30).ceil().clamp(1, 120);
  }

  int get _nbEcheances {
    if (_dateLimite == null) return 0;
    final jours = _dateLimite!.difference(_selectedDate).inDays;
    switch (_typeEcheance) {
      case 'JOURNALIER':
        return jours.clamp(1, 365);
      case 'HEBDOMADAIRE':
        return (jours / 7).ceil().clamp(1, 52);
      case 'MENSUEL':
        return (jours / 30).ceil().clamp(1, 120);
      case 'ANNUEL':
        return (jours / 365).ceil().clamp(1, 30);
      default:
        return (jours / 30).ceil().clamp(1, 120);
    }
  }

  double get _montantTotalARembourser {
    if (_montantEmprunte <= 0) return 0;
    if (_taux == 0) return _montantEmprunte;

    if (_typeTaux == 'MENSUEL') {
      return _montantEmprunte * (1 + (_taux / 100) * _nbMois);
    } else {
      // Taux annuel : minimum 1 an
      final annees = (_nbMois / 12).ceil().clamp(1, 30);
      return _montantEmprunte * (1 + (_taux / 100) * annees);
    }
  }

  double get _suggestionParEcheance {
    if (_nbEcheances <= 0) return 0;
    return _montantTotalARembourser / _nbEcheances;
  }

  int get _nbEcheancesCalcule {
    if (_montantEcheance <= 0 || _montantTotalARembourser <= 0) return 0;
    return (_montantTotalARembourser / _montantEcheance).ceil();
  }

  double get _derniereEcheanceAjustee {
    if (_nbEcheancesCalcule <= 1) return _montantTotalARembourser;
    return _montantTotalARembourser - (_montantEcheance * (_nbEcheancesCalcule - 1));
  }

  String _getLabelEcheance() {
    switch (_typeEcheance) {
      case 'JOURNALIER': return 'jours';
      case 'HEBDOMADAIRE': return 'semaines';
      case 'MENSUEL': return 'mois';
      case 'ANNUEL': return 'années';
      default: return 'mois';
    }
  }

  // ═══════════════════════════════════════════════
  // SOUMISSION
  // ═══════════════════════════════════════════════
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypePreteur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez un type de prêteur'), backgroundColor: AppColors.warning));
      return;
    }
    if (_dateLimite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez une date limite'), backgroundColor: AppColors.warning));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final pret = Pret(
        id: '', preteur: _preteurController.text.trim(), typePreteur: _selectedTypePreteur!,
        montantTotal: _montantTotalARembourser, dateDeblocage: _selectedDate,
        tauxInteret: _taux, typeTaux: _typeTaux,
        modeRemboursement: _echeancesImposees ? 'IMPOSE' : 'PROPOSE',
        dateLimite: _dateLimite, montantRestant: _montantTotalARembourser,
        dureeTotaleMois: _nbMois,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final provider = context.read<PretProvider>();
      final success = await provider.addPret(pret);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? 'Prêt enregistré !' : 'Erreur'), backgroundColor: success ? AppColors.success : AppColors.error));
        if (success) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Nouveau prêt', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.lg),

          // ═══════════════════════════════════════
          // SECTION 1 : IDENTITÉ DU PRÊT
          // ═══════════════════════════════════════
          _buildSectionTitle('Identité du prêt'),
          const SizedBox(height: AppSpacing.md),
          _buildLabel('Nom du prêteur *'),
          TextFormField(controller: _preteurController, decoration: _inputDecoration('Ex: Crédit Agricole'), validator: (v) => v!.isEmpty ? 'Requis' : null),
          const SizedBox(height: AppSpacing.lg),
          _buildLabel('Type de prêteur *'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(value: _selectedTypePreteur, isExpanded: true,
                  hint: Text('Sélectionnez', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  items: _typesPreteur.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() => _selectedTypePreteur = v)),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          // ═══════════════════════════════════════
          // SECTION 2 : MONTANT
          // ═══════════════════════════════════════
          _buildSectionTitle('Montant'),
          const SizedBox(height: AppSpacing.md),
          _buildLabel('Montant emprunté (FCFA) *'),
          TextFormField(controller: _montantController, keyboardType: TextInputType.number, decoration: _inputDecoration('Ex: 500000'), validator: (v) => v!.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0 ? 'Montant valide requis' : null),
          const SizedBox(height: AppSpacing.lg),
          _buildLabel('Taux d\'intérêt (%)'),
          Row(children: [
            Expanded(flex: 2, child: TextFormField(controller: _tauxController, keyboardType: TextInputType.number, decoration: _inputDecoration('0'))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(value: _typeTaux, isExpanded: true,
                      items: const [DropdownMenuItem(value: 'MENSUEL', child: Text('Mensuel')), DropdownMenuItem(value: 'ANNUEL', child: Text('Annuel'))],
                      onChanged: (v) => setState(() => _typeTaux = v ?? 'MENSUEL')),
                ),
              ),
            ),
          ]),

          const SizedBox(height: AppSpacing.xxl),
          // ═══════════════════════════════════════
          // SECTION 3 : DURÉE
          // ═══════════════════════════════════════
          _buildSectionTitle('Durée du prêt'),
          const SizedBox(height: AppSpacing.md),
          _buildLabel('Date de déblocage'),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
                child: Row(children: [Icon(Icons.calendar_today, color: AppColors.textHint), const SizedBox(width: AppSpacing.md), Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: AppTextStyles.bodyMedium)])),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLabel('Date limite de remboursement *'),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: _dateLimite ?? _selectedDate.add(const Duration(days: 90)), firstDate: _selectedDate, lastDate: DateTime(2030));
              if (date != null) setState(() => _dateLimite = date);
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: _dateLimite != null ? AppColors.surfaceLight : AppColors.warning.withOpacity(0.1), borderRadius: AppBorders.inputRadius, border: Border.all(color: _dateLimite != null ? AppColors.border : AppColors.warning)),
              child: Row(children: [
                Icon(Icons.event, color: _dateLimite != null ? AppColors.textHint : AppColors.warning),
                const SizedBox(width: AppSpacing.md),
                Text(_dateLimite != null ? '${_dateLimite!.day}/${_dateLimite!.month}/${_dateLimite!.year}' : 'Obligatoire', style: AppTextStyles.bodyMedium.copyWith(color: _dateLimite != null ? AppColors.textPrimary : AppColors.warning)),
                const Spacer(),
                if (_dateLimite != null) Text('$_nbMois mois', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              ]),
            ),
          ),

          // ═══════════════════════════════════════
          // MONTANT TOTAL CALCULÉ
          // ═══════════════════════════════════════
          if (_montantEmprunte > 0 && _dateLimite != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Text('💰', style: TextStyle(fontSize: 20)), const SizedBox(width: AppSpacing.sm), Text('Récapitulatif', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.primary))]),
                const Divider(),
                _buildRecapRow('Capital emprunté', '${_montantEmprunte.toInt()} FCFA'),
                if (_taux > 0) _buildRecapRow('Intérêts (${_taux.toInt()}% ${_typeTaux == 'MENSUEL' ? 'mensuel' : 'annuel'})', '${(_montantTotalARembourser - _montantEmprunte).toInt()} FCFA'),
                _buildRecapRow('Total à rembourser', '${_montantTotalARembourser.toInt()} FCFA', bold: true),
                _buildRecapRow('Durée', '$_nbMois mois'),
              ]),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          // ═══════════════════════════════════════
          // SECTION 4 : ÉCHÉANCES
          // ═══════════════════════════════════════
          if (_dateLimite != null && _montantEmprunte > 0) ...[
            _buildSectionTitle('Échéances'),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: Text('Échéances imposées', style: AppTextStyles.subtitleMedium),
              subtitle: Text('Le créancier exige un montant fixe par échéance', style: AppTextStyles.bodySmall),
              value: _echeancesImposees, onChanged: (v) => setState(() => _echeancesImposees = v),
              activeColor: AppColors.primary,
            ),

            if (_echeancesImposees) ...[
              const SizedBox(height: AppSpacing.md),
              _buildLabel('Périodicité des échéances'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(value: _typeEcheance, isExpanded: true,
                      items: _typesEcheance.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _typeEcheance = v ?? 'MENSUEL')),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildLabel('Montant par échéance (FCFA)'),
              TextFormField(
                controller: _montantEcheanceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Ex: 100000'),
                onChanged: (_) => setState(() {}),
              ),
              if (_montantEcheance > 0 && _montantTotalARembourser > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18), const SizedBox(width: AppSpacing.sm), Text('Échéancier calculé', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.success))]),
                    const SizedBox(height: AppSpacing.sm),
                    Text('$_nbEcheancesCalcule échéances de ${_montantEcheance.toInt()} FCFA', style: AppTextStyles.bodyMedium),
                    if (_derniereEcheanceAjustee != _montantEcheance)
                      Text('Dernière échéance ajustée : ${_derniereEcheanceAjustee.toInt()} FCFA', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning)),
                    Text('Total : ${(_montantEcheance * _nbEcheancesCalcule).toInt()} FCFA', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  ]),
                ),
              ],
            ] else ...[
              // Mode libre : suggestion
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.lightbulb_outline, color: AppColors.success, size: 18), const SizedBox(width: AppSpacing.sm), Text('Suggestion de remboursement', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.success))]),
                  const SizedBox(height: AppSpacing.sm),
                  Text('$_nbEcheances échéances de ${_suggestionParEcheance.toInt()} FCFA', style: AppTextStyles.bodyMedium),
                  Text('Remboursement libre, sans contrainte', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                ]),
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.xxl),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppBorders.buttonRadius)),
              child: Text(_isLoading ? 'ENREGISTREMENT...' : 'ENREGISTRER LE PRÊT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ])),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.primary, width: 3))),
      child: Text(title, style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary, fontSize: 13)),
    );
  }

  Widget _buildRecapRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        Text(value, style: bold ? AppTextStyles.subtitleMedium.copyWith(color: AppColors.primary) : AppTextStyles.bodyMedium),
      ]),
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