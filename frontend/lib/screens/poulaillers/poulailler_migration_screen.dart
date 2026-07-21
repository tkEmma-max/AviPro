// lib/screens/poulaillers/poulailler_migration_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../services/api_service.dart';
import '../../models/cycle.dart';
class PoulaillerMigrationScreen extends StatefulWidget {
  final Poulailler source;

  const PoulaillerMigrationScreen({
    super.key,
    required this.source,
  });

  @override
  State<PoulaillerMigrationScreen> createState() => _PoulaillerMigrationScreenState();
}

class _PoulaillerMigrationScreenState extends State<PoulaillerMigrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _nbSujetsController = TextEditingController();
  final _raisonController = TextEditingController();

  String? _selectedTargetId;
  String? _cycleId;
  int _agePoulets = 0;
  int _effectifSource = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCycleActif();
  }

  Future<void> _loadCycleActif() async {
    try {
      final cycleProvider = context.read<CycleProvider>();
      await cycleProvider.refreshCycles();

      if (!mounted) return;

      // Chercher un cycle actif pour ce poulailler
      final cycles = cycleProvider.cycles;
      Cycle? cycleActif;

      try {
        cycleActif = cycles.firstWhere(
              (c) => c.poulailler == widget.source.id && c.isActive && !c.isArchived,
        );
      } catch (_) {
        cycleActif = null;
      }

      if (cycleActif != null && mounted) {
        setState(() {
          _cycleId = cycleActif!.id;
          _effectifSource = cycleActif!.nombreSujetsActuels;
          _agePoulets = cycleActif!.joursEcoules ?? 0;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Erreur chargement cycle: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nbSujetsController.dispose();
    _raisonController.dispose();
    super.dispose();
  }

  Future<void> _submitMigration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTargetId == null || _cycleId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _apiService.post('cycles/$_cycleId/migrer/', data: {
        'poulailler_cible': _selectedTargetId,
        'nombre_sujets': int.parse(_nbSujetsController.text),
        'raison': _raisonController.text.isNotEmpty ? _raisonController.text : 'Migration',
      });

      if (mounted) {
        if (response.statusCode == 200) {
          await context.read<PoulaillerProvider>().refreshPoulaillers();
          await context.read<CycleProvider>().refreshCycles();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Migration effectuée avec succès !'), backgroundColor: AppColors.success));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error, duration: const Duration(seconds: 4)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cycleId == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context))),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.info_outline, size: 60, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.lg),
          Text('Aucun cycle actif dans ce poulailler', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ])),
      );
    }

    final provider = context.watch<PoulaillerProvider>();
    final poulaillers = provider.poulaillers.where((p) => p.id != widget.source.id && p.statut == 'LIBRE').toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Migration de poulets', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.md),

          // SOURCE
          Text('Poulailler source', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(widget.source.nom, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                Text('$_effectifSource sujets • $_agePoulets jours', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ])),
          const SizedBox(height: AppSpacing.lg),

          // CIBLE
          Text('Poulailler cible *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(value: _selectedTargetId, isExpanded: true,
                  hint: Text('Sélectionnez un poulailler', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  items: poulaillers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nom, style: AppTextStyles.bodyMedium))).toList(),
                  onChanged: (value) => setState(() => _selectedTargetId = value)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // NOMBRE
          Text('Nombre de sujets à migrer *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _nbSujetsController, keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Max: $_effectifSource', border: OutlineInputBorder(borderRadius: AppBorders.inputRadius)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              final nb = int.tryParse(v);
              if (nb == null || nb <= 0) return '> 0';
              if (nb > _effectifSource) return 'Max: $_effectifSource';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // RAISON
          Text('Raison (optionnel)', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(controller: _raisonController, maxLines: 2, decoration: InputDecoration(hintText: 'Ex: Division après chauffage', border: OutlineInputBorder(borderRadius: AppBorders.inputRadius))),
          const SizedBox(height: AppSpacing.xxl),

          // BOUTON
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitMigration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppBorders.buttonRadius),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('VALIDER LA MIGRATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ])),
      ),
    );
  }
}