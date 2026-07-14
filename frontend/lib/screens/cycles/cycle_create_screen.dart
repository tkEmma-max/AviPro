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

  String? _selectedPoulaillerId;
  String _selectedType = 'CHAIR';
  DateTime _selectedDate = DateTime.now();

  double _densite = 0;
  bool _isDensiteOk = false;
  int _capaciteMax = 0;
  bool _isLoading = false;

  final List<String> _types = ['CHAIR', 'PONDEUSE', 'LOCAL'];

  @override
  void initState() {
    super.initState();
    // Rafraîchir la liste des poulaillers pour avoir les statuts à jour
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoulaillerProvider>().refreshPoulaillers();
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _nbSujetsController.dispose();
    _prixUnitaireController.dispose();
    super.dispose();
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
      return provider.poulaillers.firstWhere(
            (p) => p.id == _selectedPoulaillerId,
      );
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
    print('🟢 [CREATE CYCLE] Début de la création');

    if (!_formKey.currentState!.validate()) {
      print('❌ [CREATE CYCLE] Formulaire invalide');
      return;
    }
    if (_selectedPoulaillerId == null) {
      print('❌ [CREATE CYCLE] Pas de poulailler sélectionné');
      return;
    }
    if (!_isDensiteOk) {
      print('❌ [CREATE CYCLE] Densité non conforme');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nbSujets = int.parse(_nbSujetsController.text);
      final prixUnitaire = double.parse(_prixUnitaireController.text);

      print('📊 [CREATE CYCLE] nbSujets=$nbSujets, prixUnitaire=$prixUnitaire, type=$_selectedType');

      // 1. Créer le cycle
      final cycle = Cycle(
        id: '',
        nom: _nomController.text.trim(),
        poulailler: _selectedPoulaillerId!,
        type: _selectedType,
        dateDebut: _selectedDate,
        dateFin: null,
        nombreSujetsInitiaux: nbSujets,
        nombreSujetsActuels: nbSujets,
        dureeEstimeeJours: _getDureeEstimee(),
        isActive: true,
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cycleData = cycle.toJson();
      print('📤 [CREATE CYCLE] POST /cycles/ data: $cycleData');

      final cycleResponse = await _apiService.post('cycles/', data: cycleData);
      print('📥 [CREATE CYCLE] Réponse POST /cycles/: status=${cycleResponse.statusCode}');

      if (cycleResponse.statusCode != 201) {
        throw Exception('Erreur création cycle: ${cycleResponse.statusCode}');
      }

      final cycleCreated = Cycle.fromJson(cycleResponse.data);
      final cycleId = cycleCreated.id;
      print('✅ [CREATE CYCLE] Cycle créé: id=$cycleId');

      // 2. Créer la dépense d'achat des poussins
      final montantTotal = nbSujets * prixUnitaire;
      final depenseData = {
        'cycle': cycleId,
        'categorie': 'POUSSIN',
        'montant': (montantTotal.toInt()),
        'date': _selectedDate.toIso8601String().split('T')[0],
        'description': 'Achat de $nbSujets poussins à $prixUnitaire FCFA/unité',
      };

      print('📤 [CREATE CYCLE] POST /depenses/ data: $depenseData');

      final depenseResponse = await _apiService.post('depenses/', data: depenseData);
      print('📥 [CREATE CYCLE] Réponse POST /depenses/: status=${depenseResponse.statusCode}');

      if (depenseResponse.statusCode != 201) {
        print('⚠️ [CREATE CYCLE] Échec dépense: ${depenseResponse.data}');
      } else {
        print('✅ [CREATE CYCLE] Dépense créée: $montantTotal FCFA');
      }

      // 3. Rafraîchir
      // 3. Rafraîchir avec délai pour laisser le backend calculer
      if (mounted) {
        // Petit délai pour que le backend ait le temps de traiter
        await Future.delayed(const Duration(milliseconds: 500));
        await context.read<CycleProvider>().refreshCycles();
        await context.read<PoulaillerProvider>().refreshPoulaillers();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cycle créé ! Dépense: ${montantTotal.toInt()} FCFA'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ [CREATE CYCLE] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.toString().substring(0, 100)}...'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print('🏁 [CREATE CYCLE] Fin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final poulaillerProvider = context.watch<PoulaillerProvider>();
    final poulaillersLibres = poulaillerProvider.poulaillers
        .where((p) => p.statut == 'LIBRE' && !p.isArchived)
        .toList();

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
          'Lancer un cycle',
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

              // Poulailler
              Text(
                'Infrastructure',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppBorders.inputRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPoulaillerId,
                    hint: Text(
                      'Sélectionnez un poulailler libre',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    items: poulaillersLibres.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              p.nom,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const Spacer(),
                            Text(
                              '${p.surface?.toStringAsFixed(1) ?? 0} m²',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPoulaillerId = value;
                        _updateDensite();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Nom
              Text(
                'Caractéristiques du lot',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _nomController,
                label: 'Nom de la bande *',
                hint: 'Ex: Lot Chair Juil-07',
                prefixIcon: Icons.label_outline,
                validator: (value) =>
                value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Type
              Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                          _updateDensite();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          borderRadius: AppBorders.buttonRadius,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
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
              const SizedBox(height: AppSpacing.lg),

              // Nombre de sujets + Prix unitaire
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _nbSujetsController,
                      label: 'Nombre de sujets *',
                      hint: '0',
                      prefixIcon: Icons.pets,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateDensite(),
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        final v = int.tryParse(value);
                        if (v == null || v <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      controller: _prixUnitaireController,
                      label: 'Prix unit. (FCFA) *',
                      hint: '500',
                      prefixIcon: Icons.money_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        final v = double.tryParse(value);
                        if (v == null || v <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // Aperçu coût total
              if (_nbSujetsController.text.isNotEmpty &&
                  _prixUnitaireController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Coût total poussins: ${(int.parse(_nbSujetsController.text) * double.parse(_prixUnitaireController.text)).toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Alerte densité
              if (_selectedPoulaillerId != null &&
                  _nbSujetsController.text.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _isDensiteOk
                        ? AppColors.success.withOpacity(0.08)
                        : AppColors.error.withOpacity(0.08),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(
                      color: _isDensiteOk
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDensiteOk
                            ? Icons.check_circle
                            : Icons.warning_amber_outlined,
                        color: _isDensiteOk ? AppColors.success : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _isDensiteOk
                              ? 'Densité conforme (${_densite.toStringAsFixed(1)} sujets/m²)'
                              : 'Surcharge : Capacité max $_capaciteMax sujets',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _isDensiteOk
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),

              // Date
              Text(
                'Date de mise en place',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
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
              const SizedBox(height: AppSpacing.xxxl),

              // Bouton
              CustomButton(
                label: _isLoading ? 'CRÉATION EN COURS...' : 'VALIDER ET LANCER LE CYCLE',
                onPressed: _isLoading ? null : _createCycle,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}