// lib/screens/cycles/cycle_report_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../providers/rapport_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/poulailler_provider.dart';
import '../../services/api_service.dart';
import '../../models/rapport.dart';
import '../../models/cycle.dart';
import '../../models/poulailler.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CycleReportFormScreen extends StatefulWidget {
  final Map<String, dynamic> cycleData;

  const CycleReportFormScreen({
    super.key,
    required this.cycleData,
  });

  @override
  State<CycleReportFormScreen> createState() => _CycleReportFormScreenState();
}

class _CycleReportFormScreenState extends State<CycleReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _alimentController = TextEditingController();
  final _eauController = TextEditingController();
  final _maladieController = TextEditingController();
  final _medicamentsController = TextEditingController();
  final _observationsController = TextEditingController();

  late Cycle _cycle;
  Poulailler? _poulailler;
  DateTime _periodeDebut = DateTime.now().subtract(const Duration(days: 7));
  DateTime _periodeFin = DateTime.now();
  int _nbSujetsMalades = 0;
  bool _isLoading = false;
  bool _isLoadingInit = true;

  @override
  void initState() {
    super.initState();
    _cycle = Cycle.fromJson(widget.cycleData);
    _loadInitData();
  }

  Future<void> _loadInitData() async {
    try {
      // Charger les détails du poulailler
      final poulaillerResponse = await _apiService.get('poulaillers/${_cycle.poulailler}/');
      if (poulaillerResponse.statusCode == 200) {
        _poulailler = Poulailler.fromJson(poulaillerResponse.data);
      }

      // Charger le dernier rapport pour pré-remplir la date de début
      final rapportsResponse = await _apiService.get('rapports/?cycle=${_cycle.id}&ordering=-periode_fin');
      if (rapportsResponse.statusCode == 200) {
        final data = rapportsResponse.data;
        if (data['results'] != null && data['results'].isNotEmpty) {
          final dernierRapport = data['results'][0];
          final dateFinDernierRapport = DateTime.parse(dernierRapport['periode_fin']);
          setState(() {
            _periodeDebut = dateFinDernierRapport.add(const Duration(days: 1));
            // Ne pas dépasser aujourd'hui
            if (_periodeDebut.isAfter(DateTime.now())) {
              _periodeDebut = DateTime.now();
            }
          });
        } else {
          // Pas de rapport précédent : utiliser la date de début du cycle
          setState(() {
            _periodeDebut = _cycle.dateDebut;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur chargement init: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInit = false);
    }
  }

  @override
  void dispose() {
    _alimentController.dispose();
    _eauController.dispose();
    _maladieController.dispose();
    _medicamentsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isDebut ? _periodeDebut : _periodeFin,
      firstDate: _cycle.dateDebut,
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (date != null) {
      setState(() {
        if (isDebut) { _periodeDebut = date; } else { _periodeFin = date; }
      });
    }
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final rapport = Rapport(
        id: '',
        cycle: _cycle.id,
        cycleNom: _cycle.nom,
        periodeDebut: _periodeDebut,
        periodeFin: _periodeFin,
        alimentConsomme: double.tryParse(_alimentController.text) ?? 0,
        eauConsommee: double.tryParse(_eauController.text) ?? 0,
        maladieObservee: _maladieController.text.isNotEmpty ? _maladieController.text : null,
        medicaments: _medicamentsController.text.isNotEmpty ? _medicamentsController.text : null,
        nbSujetsMalades: _nbSujetsMalades,
        observations: _observationsController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<RapportProvider>();
      await provider.addRapport(rapport);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport enregistre !'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
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
    if (_isLoadingInit) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)), title: const Text('Chargement...', style: TextStyle(color: AppColors.textPrimary))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final duree = _periodeFin.difference(_periodeDebut).inDays + 1;
    final nbSujets = _cycle.nombreSujetsActuels;
    final surface = _poulailler?.surface ?? 0;
    final densite = surface > 0 ? nbSujets / surface : 0.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Rapport de suivi', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
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

              // Info cycle
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cycle: ${_cycle.nom}', style: AppTextStyles.subtitleMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${nbSujets} sujets • ${surface.toStringAsFixed(1)} m² • ${densite.toStringAsFixed(1)} sujets/m²', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    Text('Dernier rapport: ${_periodeDebut.day}/${_periodeDebut.month}/${_periodeDebut.year}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Période
              Text('Periode du rapport', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: _buildDatePicker(label: 'Debut (modifiable)', date: _periodeDebut, onTap: () => _selectDate(context, true), icon: Icons.edit_calendar)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildDatePicker(label: 'Fin', date: _periodeFin, onTap: () => _selectDate(context, false), icon: Icons.calendar_today)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text('Duree: $duree jours', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xxl),

              // Consommations
              Text('Consommations', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(controller: _alimentController, label: 'Aliment consomme (kg) *', hint: '0.0', prefixIcon: Icons.restaurant, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Requis' : null),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(controller: _eauController, label: 'Eau consommee (litres) *', hint: '0.0', prefixIcon: Icons.water_drop, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Requis' : null),
              const SizedBox(height: AppSpacing.xxl),

              // Suivi sanitaire
              Text('Suivi sanitaire', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(controller: _maladieController, label: 'Maladie observee (optionnel)', hint: 'Ex: Coccidiose, Gumboro...', prefixIcon: Icons.health_and_safety),
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(controller: _medicamentsController, label: 'Medicaments administres (optionnel)', hint: 'Ex: Anticoccidiens 5g/L...', prefixIcon: Icons.medication),
              const SizedBox(height: AppSpacing.lg),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Nombre de sujets malades', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                Row(children: [
                  _buildCounterButton(Icons.remove, () { if (_nbSujetsMalades > 0) setState(() => _nbSujetsMalades--); }),
                  Container(width: 60, height: 44, alignment: Alignment.center, child: Text(_nbSujetsMalades.toString(), style: AppTextStyles.numberMedium.copyWith(color: AppColors.primary))),
                  _buildCounterButton(Icons.add, () => setState(() => _nbSujetsMalades++)),
                ]),
              ]),
              const SizedBox(height: AppSpacing.xxl),

              // Observations (OBLIGATOIRE)
              Text('Observations *', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _observationsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Decrivez le comportement, l\'etat general, les conditions...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  border: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Les observations sont obligatoires' : null,
              ),
              const SizedBox(height: AppSpacing.xxl),

              CustomButton(label: _isLoading ? 'ENREGISTREMENT...' : 'ENREGISTRER LE RAPPORT', onPressed: _isLoading ? null : _submitReport, isLoading: _isLoading),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime date, required VoidCallback onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [Icon(icon, size: 16, color: AppColors.primary), const SizedBox(width: AppSpacing.sm), Text('${date.day}/${date.month}/${date.year}', style: AppTextStyles.bodyMedium)]),
        ]),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, size: 18, color: AppColors.primary), padding: EdgeInsets.zero, onPressed: onPressed, constraints: const BoxConstraints()),
    );
  }
}