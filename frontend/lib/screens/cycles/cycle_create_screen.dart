// lib/screens/cycles/cycle_create_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../models/poulailler.dart';
import '../../models/cycle.dart';
import '../../providers/poulailler_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../services/densite_service.dart';
import '../../services/equipement_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CycleCreateScreen extends StatefulWidget {
  const CycleCreateScreen({super.key});

  @override
  State<CycleCreateScreen> createState() => _CycleCreateScreenState();
}

class _CycleCreateScreenState extends State<CycleCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _nomController = TextEditingController();
  final _nbSujetsController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _ageController = TextEditingController(text: '0');
  final _nbMangeoiresController = TextEditingController(text: '0');
  final _nbAbreuvoirsController = TextEditingController(text: '0');

  String? _selectedPoulaillerId;
  String _selectedType = 'CHAIR';

  double _densite = 0;
  bool _isDensiteOk = false;
  int _capaciteMax = 0;
  bool _isLoading = false;

  final List<String> _types = ['CHAIR', 'PONDEUSE', 'LOCAL'];

  @override
  void dispose() {
    _nomController.dispose();
    _nbSujetsController.dispose();
    _prixUnitaireController.dispose();
    _ageController.dispose();
    _nbMangeoiresController.dispose();
    _nbAbreuvoirsController.dispose();
    super.dispose();
  }

  String _getDateDebut() {
    final age = int.tryParse(_ageController.text) ?? 0;
    final date = DateTime.now().subtract(Duration(days: age));
    return '${date.day}/${date.month}/${date.year}';
  }

  int get _nbMangeoiresRecommandees {
    final nb = int.tryParse(_nbSujetsController.text) ?? 0;
    if (nb == 0) return 0;
    return EquipementService.getMangeoiresRecommandees(nb, _selectedType, int.tryParse(_ageController.text) ?? 0);
  }

  int get _nbAbreuvoirsRecommandes {
    final nb = int.tryParse(_nbSujetsController.text) ?? 0;
    if (nb == 0) return 0;
    return EquipementService.getAbreuvoirsRecommandes(nb, _selectedType, int.tryParse(_ageController.text) ?? 0);
  }

  void _updateDensite() {
    final nb = int.tryParse(_nbSujetsController.text) ?? 0;
    final poulailler = _getSelectedPoulailler();
    if (poulailler != null && nb > 0 && poulailler.surface != null && poulailler.surface! > 0) {
      final densiteMax = DensiteService.getDensiteRecommandee(_selectedType, 0);
      final capacite = (poulailler.surface! * densiteMax).floor();
      setState(() {
        _densite = nb / poulailler.surface!;
        _capaciteMax = capacite;
        _isDensiteOk = nb <= capacite;
      });
    } else {
      setState(() {
        _densite = 0;
        _capaciteMax = 0;
        _isDensiteOk = false;
      });
    }
  }

  Poulailler? _getSelectedPoulailler() {
    final provider = context.read<PoulaillerProvider>();
    try {
      return provider.poulaillers.firstWhere((p) => p.id == _selectedPoulaillerId);
    } catch (e) {
      return null;
    }
  }

  int _getDureeEstimee() {
    switch (_selectedType) {
      case 'CHAIR': return 45;
      case 'PONDEUSE': return 490;
      case 'LOCAL': return 180;
      default: return 90;
    }
  }

  void _createCycle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPoulaillerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un poulailler'), backgroundColor: AppColors.warning));
      return;
    }
    if (!_isDensiteOk) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Densité excessive ! Max: $_capaciteMax sujets'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nbSujets = int.parse(_nbSujetsController.text);
      final prixUnitaire = double.parse(_prixUnitaireController.text);
      final age = int.tryParse(_ageController.text) ?? 0;
      final dateDebut = DateTime.now().subtract(Duration(days: age));

      final cycle = Cycle(
        id: '',
        nom: _nomController.text.trim(),
        poulailler: _selectedPoulaillerId!,
        type: _selectedType,
        dateDebut: dateDebut,
        dateFin: null,
        nombreSujetsInitiaux: nbSujets,
        nombreSujetsActuels: nbSujets,
        dureeEstimeeJours: _getDureeEstimee(),
        isActive: true,
        isArchived: false,
        nbMangeoires: int.tryParse(_nbMangeoiresController.text) ?? 0,
        nbAbreuvoirs: int.tryParse(_nbAbreuvoirsController.text) ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cycleResponse = await _apiService.post('cycles/', data: cycle.toJson());
      if (cycleResponse.statusCode != 201) throw Exception('Erreur création cycle');

      final cycleCreated = Cycle.fromJson(cycleResponse.data);
      final cycleId = cycleCreated.id;

      final montantTotal = nbSujets * prixUnitaire;
      final depenseData = {
        'cycle': cycleId,
        'categorie': 'POUSSIN',
        'montant': montantTotal.toInt(),
        'date': dateDebut.toIso8601String().split('T')[0],
        'description': 'Achat de $nbSujets poussins à $prixUnitaire FCFA/unité',
      };

      await _apiService.post('depenses/', data: depenseData);

      if (mounted) {
        await context.read<CycleProvider>().refreshCycles();
        await context.read<PoulaillerProvider>().refreshPoulaillers();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cycle créé ! Dépense: ${montantTotal.toInt()} FCFA'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poulaillerProvider = context.watch<PoulaillerProvider>();
    final poulaillersLibres = poulaillerProvider.poulaillers.where((p) => p.statut == 'LIBRE' && !p.isArchived).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Lancer un cycle', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.lg),

          // Poulailler
          Text('Infrastructure', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(value: _selectedPoulaillerId, isExpanded: true,
                  hint: Text('Sélectionnez un poulailler libre', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  items: poulaillersLibres.map((p) => DropdownMenuItem(value: p.id, child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)), const SizedBox(width: AppSpacing.sm), Text(p.nom, style: AppTextStyles.bodyMedium), const Spacer(), Text('${p.surface?.toStringAsFixed(1) ?? 0} m²', style: AppTextStyles.bodySmall)]))).toList(),
                  onChanged: (value) { setState(() => _selectedPoulaillerId = value); _updateDensite(); }),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Nom
          Text('Caractéristiques du lot', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(controller: _nomController, label: 'Nom de la bande *', hint: 'Ex: Lot Chair Juil-07', prefixIcon: Icons.label_outline, validator: (v) => v!.isEmpty ? 'Requis' : null),
          const SizedBox(height: AppSpacing.lg),

          // Type
          Row(children: _types.map((type) {
            final isSelected = _selectedType == type;
            return Expanded(
                child: GestureDetector(
                  onTap: () { setState(() => _selectedType = type); _updateDensite(); },
                  child: Container(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), margin: const EdgeInsets.only(right: AppSpacing.sm), decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.surfaceLight, borderRadius: AppBorders.buttonRadius, border: Border.all(color: isSelected ? AppColors.primary : AppColors.border)),
                      child: Center(child: Text(type, style: AppTextStyles.labelMedium.copyWith(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)))),
                ));
          }).toList()),
          const SizedBox(height: AppSpacing.lg),

          // Nombre de sujets + Prix unitaire
          Row(children: [
            Expanded(flex: 2, child: CustomTextField(controller: _nbSujetsController, label: 'Nombre de sujets *', hint: '0', prefixIcon: Icons.pets, keyboardType: TextInputType.number, onChanged: (_) => _updateDensite(), validator: (v) { if (v!.isEmpty) return 'Requis'; final n = int.tryParse(v); if (n == null || n <= 0) return '> 0'; return null; })),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 1, child: CustomTextField(controller: _prixUnitaireController, label: 'Prix unit. (FCFA) *', hint: '500', prefixIcon: Icons.money_outlined, keyboardType: TextInputType.number, validator: (v) { if (v!.isEmpty) return 'Requis'; final n = double.tryParse(v); if (n == null || n <= 0) return '> 0'; return null; })),
          ]),

          // Aperçu coût total
          if (_nbSujetsController.text.isNotEmpty && _prixUnitaireController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Row(children: [const Icon(Icons.receipt_long, color: AppColors.primary, size: 18), const SizedBox(width: AppSpacing.sm), Text('Coût total poussins: ${(int.parse(_nbSujetsController.text) * double.parse(_prixUnitaireController.text)).toStringAsFixed(0)} FCFA', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))]),
            ),

          // Alerte densité
          if (_selectedPoulaillerId != null && _nbSujetsController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: _isDensiteOk ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.08), borderRadius: AppBorders.cardRadius, border: Border.all(color: _isDensiteOk ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3))),
              child: Row(children: [
                Icon(_isDensiteOk ? Icons.check_circle : Icons.warning_amber_outlined, color: _isDensiteOk ? AppColors.success : AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(_isDensiteOk ? 'Densité conforme (${_densite.toStringAsFixed(1)} sujets/m²)' : 'Surcharge : Capacité max $_capaciteMax sujets', style: AppTextStyles.bodyMedium.copyWith(color: _isDensiteOk ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600))),
              ]),
            ),
          const SizedBox(height: AppSpacing.xxl),

          // Âge des poussins
          Text('Âge des poussins', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(flex: 1, child: CustomTextField(controller: _ageController, label: 'Âge (jours)', hint: '0', prefixIcon: Icons.timer_outlined, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), validator: (v) { if (v!.isEmpty) return 'Requis'; final n = int.tryParse(v); if (n == null || n < 0) return '≥ 0'; return null; })),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Date de début calculée', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(_getDateDebut(), style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.primary)),
              ]),
            )),
          ]),
          const SizedBox(height: AppSpacing.xxl),

          // Matériel de nutrition
          Text('Matériel de nutrition', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: CustomTextField(controller: _nbMangeoiresController, label: 'Nb mangeoires', hint: '0', prefixIcon: Icons.restaurant, keyboardType: TextInputType.number, validator: (v) { if (v!.isEmpty) return 'Requis'; final n = int.tryParse(v); if (n == null || n < 0) return '≥ 0'; return null; })),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: CustomTextField(controller: _nbAbreuvoirsController, label: 'Nb abreuvoirs', hint: '0', prefixIcon: Icons.water_drop, keyboardType: TextInputType.number, validator: (v) { if (v!.isEmpty) return 'Requis'; final n = int.tryParse(v); if (n == null || n < 0) return '≥ 0'; return null; })),
          ]),
          if (_nbSujetsController.text.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.lightbulb_outline, color: AppColors.success, size: 18), const SizedBox(width: AppSpacing.sm), Text('Recommandations', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.success))]),
                const SizedBox(height: AppSpacing.sm),
                Text('Mangeoires recommandées: $_nbMangeoiresRecommandees', style: AppTextStyles.bodySmall),
                Text('Abreuvoirs recommandés: $_nbAbreuvoirsRecommandes', style: AppTextStyles.bodySmall),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),

          // Bouton
          CustomButton(label: _isLoading ? 'CRÉATION EN COURS...' : 'VALIDER ET LANCER LE CYCLE', onPressed: _isLoading ? null : _createCycle, isLoading: _isLoading),
          const SizedBox(height: AppSpacing.xxl),
        ])),
      ),
    );
  }
}