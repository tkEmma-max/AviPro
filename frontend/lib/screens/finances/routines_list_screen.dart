// lib/screens/finances/routines_list_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../services/api_service.dart';
import 'routine_create_screen.dart';

class RoutinesListScreen extends StatefulWidget {
  const RoutinesListScreen({super.key});

  @override
  State<RoutinesListScreen> createState() => _RoutinesListScreenState();
}

class _RoutinesListScreenState extends State<RoutinesListScreen> {
  final _apiService = ApiService();
  List<dynamic> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('depenses/routines/');
      if (response.statusCode == 200 && response.data['results'] != null) {
        setState(() => _routines = response.data['results']);
      }
    } catch (e) {
      print('❌ Erreur chargement routines: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteRoutine(String id) async {
    try {
      await _apiService.delete('depenses/routines/$id/');
      _loadRoutines();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routine supprimée'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showRoutineDetail(Map<String, dynamic> routine) {
    final nomController = TextEditingController(text: routine['nom'] ?? '');
    final ageController = TextEditingController(text: routine['age_jour']?.toString() ?? '0');
    final montantController = TextEditingController(
      text: routine['mode_calcul'] == 'PAR_SUJET'
          ? routine['montant_par_sujet']?.toString() ?? '0'
          : routine['mode_calcul'] == 'FIXE'
          ? routine['montant_fixe']?.toString() ?? '0'
          : routine['montant_par_tranche']?.toString() ?? '0',
    );
    final seuilController = TextEditingController(text: routine['seuil_tranche']?.toString() ?? '50');
    String modeCalcul = routine['mode_calcul'] ?? 'PAR_SUJET';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge),
          title: const Text('Détails de la routine'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Type de poulet : ${routine['type_poulet_nom'] ?? "N/A"}', style: AppTextStyles.bodyMedium),
              Text('Catégorie : ${routine['categorie_depense_nom'] ?? "N/A"}', style: AppTextStyles.bodyMedium),
              Text('Âge : J${routine['age_jour'] ?? 0}', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.md),

              Text('Mode de calcul :', style: AppTextStyles.subtitleMedium),
              Row(children: ['PAR_SUJET', 'PAR_TRANCHE', 'FIXE'].map((m) => Expanded(child: GestureDetector(
                  onTap: () => setDialogState(() => modeCalcul = m),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), margin: const EdgeInsets.only(right: AppSpacing.xs), decoration: BoxDecoration(color: modeCalcul == m ? AppColors.primary : AppColors.surfaceLight, borderRadius: AppBorders.buttonRadius, border: Border.all(color: modeCalcul == m ? AppColors.primary : AppColors.border)), child: Center(child: Text(m == 'PAR_SUJET' ? '/sujet' : m == 'PAR_TRANCHE' ? '/tranche' : 'Fixe', style: AppTextStyles.labelSmall.copyWith(color: modeCalcul == m ? Colors.white : AppColors.textSecondary))))),
              )).toList()),
              const SizedBox(height: AppSpacing.md),

              // Label dynamique selon le mode
              Text(modeCalcul == 'FIXE' ? 'Montant fixe (FCFA)' : modeCalcul == 'PAR_TRANCHE' ? 'Montant par tranche (FCFA)' : 'Montant par sujet (FCFA)', style: AppTextStyles.subtitleMedium),
              TextFormField(controller: montantController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),

              // Afficher le seuil seulement si mode TRANCHE
              if (modeCalcul == 'PAR_TRANCHE') ...[
                const SizedBox(height: AppSpacing.md),
                Text('Sujets par tranche', style: AppTextStyles.subtitleMedium),
                TextFormField(controller: seuilController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final data = {
                    'nom': routine['nom'],
                    'type_poulet': routine['type_poulet'],
                    'categorie_depense': routine['categorie_depense'],
                    'age_jour': int.tryParse(ageController.text) ?? 0,
                    'mode_calcul': modeCalcul,
                    'montant_par_sujet': modeCalcul == 'PAR_SUJET' ? int.tryParse(montantController.text) ?? 0 : 0,
                    'montant_par_tranche': modeCalcul == 'PAR_TRANCHE' ? int.tryParse(montantController.text) ?? 0 : 0,
                    'montant_fixe': modeCalcul == 'FIXE' ? int.tryParse(montantController.text) ?? 0 : 0,
                    'seuil_tranche': int.tryParse(seuilController.text) ?? 50,
                  };
                  await _apiService.patch('depenses/routines/${routine['id']}/', data: data);
                  _loadRoutines();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routine mise à jour'), backgroundColor: AppColors.success));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Dépenses de routine', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) =>  RoutineCreateScreen())).then((_) => _loadRoutines());
          }),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.repeat, size: 60, color: AppColors.textHint),
        const SizedBox(height: AppSpacing.lg),
        Text('Aucune routine configurée', style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Text('Ajoutez votre première routine', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
      ]))
          : ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _routines.length,
        itemBuilder: (context, index) {
          final r = _routines[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.repeat, color: AppColors.primary)),
              title: Text(r['nom'] ?? '', style: AppTextStyles.subtitleMedium),
              subtitle: Text('J${r['age_jour']} • ${r['type_poulet_nom'] ?? ""} • ${r['mode_calcul'] == 'PAR_SUJET' ? '${r['montant_par_sujet']} FCFA/sujet' : r['mode_calcul'] == 'FIXE' ? '${r['montant_fixe']} FCFA' : '${r['montant_par_tranche']} FCFA/${r['seuil_tranche']} sujets'}'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: () => _deleteRoutine(r['id'])),
              onTap: () {
                _showRoutineDetail(r);
              },
            ),
          );
        },
      ),
    );
  }
}