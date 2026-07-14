// lib/screens/cycles/cycle_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../models/cycle.dart';
import '../../models/poulailler.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/poulailler_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';

class CycleEditScreen extends StatefulWidget {
  final Map<String, dynamic> cycleData;

  const CycleEditScreen({
    super.key,
    required this.cycleData,
  });

  @override
  State<CycleEditScreen> createState() => _CycleEditScreenState();
}

class _CycleEditScreenState extends State<CycleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late Cycle _cycle;
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _effectifController = TextEditingController();
  String? _selectedPoulaillerId;
  String _selectedType = 'CHAIR';
  DateTime _selectedDate = DateTime.now();

  final List<String> _types = ['CHAIR', 'PONDEUSE', 'LOCAL'];

  bool get _isFullyEditable {
    final difference = DateTime.now().difference(_cycle.createdAt);
    return difference.inHours < 48;
  }

  @override
  void initState() {
    super.initState();
    _cycle = Cycle.fromJson(widget.cycleData);
    _loadLatestCycle();
  }

  Future<void> _loadLatestCycle() async {
    try {
      print('🔍 [EDIT] Chargement depuis API: ${_cycle.id}');
      final response = await _apiService.get('cycles/${_cycle.id}/');
      if (response.statusCode == 200 && mounted) {
        final freshCycle = Cycle.fromJson(response.data);
        print('✅ [EDIT] Cycle frais chargé: ${freshCycle.nom}');
        setState(() {
          _cycle = freshCycle;
          _nomController.text = _cycle.nom;
          _effectifController.text = _cycle.nombreSujetsInitiaux.toString();
          _selectedPoulaillerId = _cycle.poulailler;
          _selectedType = _cycle.type;
          _selectedDate = _cycle.dateDebut;
        });
      } else {
        print('❌ [EDIT] Cycle introuvable: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ce cycle n\'existe plus'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('❌ [EDIT] Erreur chargement: $e');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _effectifController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nbSujets = int.tryParse(_effectifController.text) ?? _cycle.nombreSujetsInitiaux;

      final data = <String, dynamic>{
        'nom': _nomController.text.trim(),
        'poulailler': _selectedPoulaillerId ?? _cycle.poulailler,
        'type': _selectedType,
        'date_debut': _selectedDate.toIso8601String().split('T')[0],
        'nombre_sujets_initiaux': nbSujets,
        'nombre_sujets_actuels': nbSujets,
        'duree_estimee_jours': _cycle.dureeEstimeeJours,
        'is_active': _cycle.isActive,
        'is_archived': _cycle.isArchived,
      };

      print('📤 [EDIT] PUT data: $data');

      final provider = context.read<CycleProvider>();
      final success = await provider.updateCycle(_cycle.id, data);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cycle modifié avec succès'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la modification'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [EDIT] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poulaillerProvider = context.watch<PoulaillerProvider>();
    if (poulaillerProvider.poulaillers.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Liste sans doublons
    List<Poulailler> poulaillersDisponibles;
    if (_isFullyEditable) {
      poulaillersDisponibles = poulaillerProvider.poulaillers
          .where((p) => p.statut == 'LIBRE' || p.id == _selectedPoulaillerId)
          .toList();
    } else {
      poulaillersDisponibles = poulaillerProvider.poulaillers
          .where((p) => p.id == _selectedPoulaillerId)
          .toList();
    }
    final seen = <String>{};
    poulaillersDisponibles = poulaillersDisponibles.where((p) => seen.add(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isFullyEditable ? 'Modifier le cycle' : 'Modifier le nom',
          style: const TextStyle(
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
              const SizedBox(height: AppSpacing.md),

              if (!_isFullyEditable)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Cycle créé depuis plus de 48h. Seul le nom peut être modifié.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

              Text('Nom du cycle', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _nomController,
                label: 'Nom de la bande *',
                prefixIcon: Icons.label_outline,
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Poulailler', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _isFullyEditable ? AppColors.surfaceLight : AppColors.grey200,
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPoulaillerId,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: _isFullyEditable ? AppColors.primary : AppColors.textHint),
                    onChanged: _isFullyEditable ? (value) => setState(() => _selectedPoulaillerId = value) : null,
                    items: poulaillersDisponibles.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.nom, style: AppTextStyles.bodyMedium.copyWith(
                          color: _isFullyEditable ? AppColors.textPrimary : AppColors.textHint,
                        )),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Type d\'élevage', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: _isFullyEditable ? () => setState(() => _selectedType = type) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                          borderRadius: AppBorders.buttonRadius,
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        child: Center(
                          child: Text(type, style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_isFullyEditable)
                CustomTextField(
                  controller: _effectifController,
                  label: 'Nombre de sujets *',
                  prefixIcon: Icons.pets,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Requis';
                    final v = int.tryParse(value);
                    if (v == null || v <= 0) return '> 0';
                    return null;
                  },
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Effectif initial', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.grey200, borderRadius: AppBorders.inputRadius),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, size: 16, color: AppColors.textHint),
                          const SizedBox(width: AppSpacing.sm),
                          Text('${_cycle.nombreSujetsInitiaux} sujets (verrouillé)',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),

              Text('Date de début', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _isFullyEditable ? AppColors.surfaceLight : AppColors.grey200,
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _isFullyEditable ? AppColors.primary : AppColors.textHint),
                    const SizedBox(width: AppSpacing.md),
                    Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _isFullyEditable ? AppColors.textPrimary : AppColors.textHint,
                        )),
                    if (_isFullyEditable) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _selectedDate = date);
                        },
                        child: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, minimumSize: const Size(0, 48)),
                      child: const Text('ANNULER'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(0, 48)),
                      child: Text(_isLoading ? 'ENREGISTREMENT...' : 'ENREGISTRER'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}