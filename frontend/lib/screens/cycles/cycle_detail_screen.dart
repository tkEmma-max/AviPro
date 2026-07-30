// lib/screens/cycles/cycle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../models/cycle.dart';
import '../../services/api_service.dart';
import '../../services/equipement_service.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/prevision_provider.dart';
import '../../providers/comparaison_provider.dart';
import '../../providers/vente_provider.dart';
import '../../providers/depense_provider.dart';
import 'prevision_screen.dart';
import 'comparaison_screen.dart';
import '../finances/vente_detail_screen.dart';
import '../finances/depense_detail_screen.dart';

class CycleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cycleData;

  const CycleDetailScreen({super.key, required this.cycleData});

  @override
  State<CycleDetailScreen> createState() => _CycleDetailScreenState();
}

class _CycleDetailScreenState extends State<CycleDetailScreen> {
  static Map<String, dynamic>? _cachedCycleData;
  static List<Map<String, dynamic>> _cachedVentesCycle = [];
  static List<Map<String, dynamic>> _cachedDepensesCycle = [];
  static List<FlSpot> _cachedSpotsVentes = [];
  static List<FlSpot> _cachedSpotsDepenses = [];
  static List<String> _cachedLabels = [];
  static List<Map<String, dynamic>> _cachedSousBandes = [];
  static String? _cachedCycleId;

  final _apiService = ApiService();
  late Cycle _cycle;
  bool _isRefreshing = false;

  List<FlSpot> _spotsVentes = [];
  List<FlSpot> _spotsDepenses = [];
  List<String> _labelsJours = [];
  List<Map<String, dynamic>> _ventesCycle = [];
  List<Map<String, dynamic>> _depensesCycle = [];
  List<Map<String, dynamic>> _sousBandes = [];

  @override
  void initState() {
    super.initState();
    _cycle = Cycle.fromJson(widget.cycleData);
    if (_cachedCycleId == _cycle.id && _cachedCycleData != null) {
      _cycle = Cycle.fromJson(_cachedCycleData!);
      _ventesCycle = _cachedVentesCycle;
      _depensesCycle = _cachedDepensesCycle;
      _spotsVentes = _cachedSpotsVentes;
      _spotsDepenses = _cachedSpotsDepenses;
      _labelsJours = _cachedLabels;
      _sousBandes = _cachedSousBandes;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCycle();
      _checkRoutines();
    });
  }

  bool _canDeleteCycle() {
    final difference = DateTime.now().difference(_cycle.createdAt);
    return difference.inHours < 48;
  }

  Future<void> _checkRoutines() async {
    try {
      final response = await _apiService.get('depenses/routines/a_appliquer/?cycle_id=${_cycle.id}');
      if (response.statusCode == 200 && response.data['nb_routines'] > 0 && mounted) {
        final routines = response.data['routines'] as List;
        _showRoutinesDialog(routines);
      }
    } catch (e) {
      print('❌ Erreur vérification routines: $e');
    }
  }

  void _showRoutinesDialog(List routines) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge),
        title: const Text('Dépenses de routine disponibles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${routines.length} routine(s) à appliquer pour ce cycle :', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ...routines.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(children: [
                Icon(r['est_obligatoire'] ? Icons.lock : Icons.check_circle_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['nom'] ?? '', style: AppTextStyles.subtitleMedium),
                  Text('${r['montant_calcule']} FCFA • ${r['categorie']}', style: AppTextStyles.bodySmall),
                ])),
              ]),
            )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ids = routines.map((r) => r['id'].toString()).toList();
              try {
                await _apiService.post('depenses/routines/appliquer/', data: {
                  'cycle_id': _cycle.id,
                  'routine_ids': ids,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routines appliquées !'), backgroundColor: AppColors.success));
                  _refreshCycle();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge),
        title: const Text('Supprimer le cycle ?'),
        content: Text('Le cycle "${_cycle.nom}" et toutes ses données seront définitivement supprimés.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary))),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            final provider = context.read<CycleProvider>();
            final success = await provider.deleteCycle(_cycle.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Cycle supprimé' : 'Erreur'), backgroundColor: success ? AppColors.success : AppColors.error));
              if (success) Navigator.pop(context);
            }
          }, child: Text('Supprimer', style: AppTextStyles.button.copyWith(color: AppColors.error))),
        ],
      ),
    );
  }

  Future<void> _refreshCycle() async {
    setState(() => _isRefreshing = true);
    try {
      final response = await _apiService.get('cycles/${_cycle.id}/');
      if (response.statusCode == 200 && mounted) {
        final data = response.data;
        final ventes = (data['ventes'] as List?) ?? [];
        final depenses = (data['depenses'] as List?) ?? [];

        Map<String, double> ventesParJour = {}, depensesParJour = {};
        for (var v in ventes) {
          final d = (v['date'] as String).substring(0, 10);
          ventesParJour[d] = (ventesParJour[d] ?? 0) + (double.tryParse(v['montant_total']?.toString() ?? '0') ?? 0);
        }
        for (var d in depenses) {
          final dd = (d['date'] as String).substring(0, 10);
          depensesParJour[dd] = (depensesParJour[dd] ?? 0) + (double.tryParse(d['montant']?.toString() ?? '0') ?? 0);
        }
        final tousLesJours = <String>{...ventesParJour.keys, ...depensesParJour.keys}.toList()..sort();
        double cv = 0, cd = 0;
        final sv = <FlSpot>[], sd = <FlSpot>[], labels = <String>[];
        for (int i = 0; i < tousLesJours.length; i++) {
          cv += ventesParJour[tousLesJours[i]] ?? 0; cd += depensesParJour[tousLesJours[i]] ?? 0;
          sv.add(FlSpot(i.toDouble(), cv)); sd.add(FlSpot(i.toDouble(), cd));
          labels.add(tousLesJours[i].substring(8, 10) + '/' + tousLesJours[i].substring(5, 7));
        }

        final sbResponse = await _apiService.get('cycles/${_cycle.id}/sous_bandes/');
        final sousBandes = (sbResponse.data as List?)?.cast<Map<String, dynamic>>() ?? [];

        setState(() {
          _cycle = Cycle.fromJson(data);
          _ventesCycle = ventes.cast<Map<String, dynamic>>();
          _depensesCycle = depenses.cast<Map<String, dynamic>>();
          _spotsVentes = sv; _spotsDepenses = sd; _labelsJours = labels;
          _sousBandes = sousBandes;
          _isRefreshing = false;
        });
        _cachedCycleData = data; _cachedCycleId = _cycle.id;
        _cachedVentesCycle = _ventesCycle; _cachedDepensesCycle = _depensesCycle;
        _cachedSpotsVentes = _spotsVentes; _cachedSpotsDepenses = _spotsDepenses;
        _cachedLabels = _labelsJours; _cachedSousBandes = _sousBandes;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _declarerPerte() async {
    int pertesTemp = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge),
        title: const Text('Déclarer une perte'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nombre de poulets morts', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildNumberButton('-', () { if (pertesTemp > 0) setD(() => pertesTemp--); }),
            Container(width: 60, height: 60, alignment: Alignment.center, child: Text('$pertesTemp', style: AppTextStyles.numberLarge.copyWith(fontSize: 28, color: AppColors.error))),
            _buildNumberButton('+', () { if (pertesTemp < _cycle.nombreSujetsActuels) setD(() => pertesTemp++); }),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text('Effectif restant: ${_cycle.nombreSujetsActuels - pertesTemp}', style: AppTextStyles.bodySmall),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary))),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            try {
              final response = await _apiService.post('cycles/${_cycle.id}/declarer_perte/', data: {'nombre': pertesTemp, 'raison': 'Mortalité déclarée'});
              if (response.statusCode == 200 && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perte déclarée'), backgroundColor: AppColors.success));
                _refreshCycle();
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
            }
          }, child: Text('Confirmer', style: AppTextStyles.button.copyWith(color: AppColors.error))),
        ],
      )),
    );
  }

  void _modifierMateriel() {
    final nbMangeoiresController = TextEditingController(text: _cycle.nbMangeoires.toString());
    final nbAbreuvoirsController = TextEditingController(text: _cycle.nbAbreuvoirs.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge),
        title: const Text('Modifier le matériel'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nbMangeoiresController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nombre de mangeoires', border: OutlineInputBorder())),
          const SizedBox(height: AppSpacing.md),
          TextField(controller: nbAbreuvoirsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nombre d\'abreuvoirs', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            try {
              final nbM = int.tryParse(nbMangeoiresController.text) ?? _cycle.nbMangeoires;
              final nbA = int.tryParse(nbAbreuvoirsController.text) ?? _cycle.nbAbreuvoirs;
              final response = await _apiService.patch('cycles/${_cycle.id}/', data: {'nb_mangeoires': nbM, 'nb_abreuvoirs': nbA});
              if (response.statusCode == 200 && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matériel mis à jour'), backgroundColor: AppColors.success));
                _cachedCycleData = null; _cachedCycleId = null;
                _refreshCycle();
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
            }
          }, child: const Text('Enregistrer')),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String label, VoidCallback onPressed) {
    return Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle, border: Border.all(color: AppColors.border)), child: IconButton(icon: Text(label, style: AppTextStyles.numberLarge.copyWith(fontSize: 24, color: AppColors.primary)), onPressed: onPressed, padding: EdgeInsets.zero, constraints: const BoxConstraints()));
  }

  String _formatMoney(int value) => value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ');

  @override
  Widget build(BuildContext context) {
    final isActif = _cycle.isActive && !_cycle.isArchived;
    final isArchived = _cycle.isArchived;
    final age = _cycle.joursEcoules ?? 0;
    final typeLabel = _cycle.type == 'CHAIR' ? 'Chair' : _cycle.type == 'PONDEUSE' ? 'Pondeuse' : _cycle.type == 'LOCAL' ? 'Local' : _cycle.type;
    final typeColor = _cycle.type == 'CHAIR' ? AppColors.primary : _cycle.type == 'PONDEUSE' ? AppColors.warning : _cycle.type == 'LOCAL' ? AppColors.success : AppColors.textHint;
    final mortalite = _cycle.tauxMortalite ?? 0;
    final totalDepenses = _cycle.totalDepenses ?? 0;
    final totalVentes = _cycle.totalVentes ?? 0;
    final benefice = _cycle.benefice ?? 0;
    final coutUnitaire = _cycle.coutProductionUnitaire ?? 0;
    final dateDebut = DateFormat('dd/MM/yyyy').format(_cycle.dateDebut);

    final nbMangeoiresRecommandees = _cycle.nombreSujetsActuels > 0 ? EquipementService.getMangeoiresRecommandees(_cycle.nombreSujetsActuels, _cycle.type, age) : 0;
    final nbAbreuvoirsRecommandes = _cycle.nombreSujetsActuels > 0 ? EquipementService.getAbreuvoirsRecommandes(_cycle.nombreSujetsActuels, _cycle.type, age) : 0;
    final alerteMangeoires = _cycle.nbMangeoires < nbMangeoiresRecommandees;
    final alerteAbreuvoirs = _cycle.nbAbreuvoirs < nbAbreuvoirsRecommandes;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(AppIcons.arrowBack, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: Text(_cycle.nom, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(AppIcons.menu, color: AppColors.textPrimary), onPressed: () {
            showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(AppIcons.chart, color: AppColors.primary),
                title: const Text('Prévisions'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => PrevisionProvider(), child: PrevisionScreen(typePouletId: _cycle.type_poulet, nbSujets: _cycle.nombreSujetsActuels))));
                },
              ),
              if (isArchived)
                ListTile(
                  leading: const Icon(AppIcons.performance, color: AppColors.primary),
                  title: const Text('Prévisions vs Réalisations'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => ComparaisonProvider(), child: ComparaisonScreen(cycleId: _cycle.id, cycleNom: _cycle.nom, typePoulet: _cycle.type_poulet, nbSujets: _cycle.nombreSujetsActuels, totalDepenses: _cycle.totalDepenses ?? 0, totalVentes: _cycle.totalVentes ?? 0, benefice: _cycle.benefice ?? 0, coutProductionUnitaire: _cycle.coutProductionUnitaire ?? 0, tauxMortalite: _cycle.tauxMortalite ?? 0))));
                  },
                ),
              ListTile(leading: const Icon(AppIcons.performance, color: AppColors.primary), title: const Text('Rapport de performance'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/cycle/report/${_cycle.id}', arguments: widget.cycleData); }),
              ListTile(leading: const Icon(AppIcons.rapport, color: AppColors.primary), title: const Text('Soumettre un rapport'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/cycle/report/form', arguments: widget.cycleData); }),
              ListTile(leading: const Icon(AppIcons.edit, color: AppColors.primary), title: const Text('Modifier le cycle'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/cycle/edit', arguments: widget.cycleData); }),
              ListTile(leading: const Icon(AppIcons.observation, color: AppColors.primary), title: const Text('Voir les rapports'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/rapports'); }),
              if (_canDeleteCycle()) ListTile(leading: const Icon(AppIcons.delete, color: AppColors.error), title: const Text('Supprimer le cycle', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(ctx); _showDeleteConfirmation(); }),
            ])));
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.md),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2, backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),

          // ═══════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppBorders.cardRadius,
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: (isActif ? AppColors.success : AppColors.textHint).withOpacity(0.08), borderRadius: AppBorders.buttonRadius), child: Text(isActif ? 'ACTIF' : 'CLÔTURÉ', style: AppTextStyles.labelSmall.copyWith(color: isActif ? AppColors.success : AppColors.textHint, fontWeight: FontWeight.w600))),
                const SizedBox(width: AppSpacing.sm),
                Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: AppBorders.buttonRadius), child: Text(typeLabel, style: AppTextStyles.labelSmall.copyWith(color: typeColor, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Expanded(child: Text(_cycle.nom, style: AppTextStyles.headlineLarge.copyWith(fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
                const SizedBox(width: AppSpacing.sm),
                Text('$age jours', style: AppTextStyles.headlineLarge.copyWith(fontSize: 20, color: AppColors.textPrimary, fontWeight: FontWeight.w300)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                const Icon(AppIcons.localisation, size: 16, color: AppColors.textPrimary),
                const SizedBox(width: 4),
                Text('${_cycle.poulaillerNom ?? "Poulailler"} • Début: $dateDebut', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: Text('${_cycle.nombreSujetsActuels} sujets vivants', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                Text('${coutUnitaire.toInt()} FCFA/sujet', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ═══════════════════════════════════════════
          // FRISE CHRONOLOGIQUE
          // ═══════════════════════════════════════════
          Text('Frise chronologique', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          _buildFriseChronologique(),
          const SizedBox(height: AppSpacing.xxl),

          // ═══════════════════════════════════════════
          // RÉPARTITION DES SUJETS
          // ═══════════════════════════════════════════
          Text('Répartition des sujets', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          if (_sousBandes.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune sous-bande', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._sousBandes.map((sb) => GestureDetector(
              onTap: () {
                showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(sb['poulailler_nom'] ?? 'Poulailler'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${sb['nombre_sujets']} sujets', style: AppTextStyles.subtitleLarge), const SizedBox(height: AppSpacing.sm), Text('Sous-bande active', style: AppTextStyles.bodySmall)]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))]));
              },
              child: Container(margin: const EdgeInsets.only(bottom: AppSpacing.sm), padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Row(children: [const Icon(AppIcons.house, color: AppColors.textPrimary, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(sb['poulailler_nom'] ?? 'Poulailler', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textPrimary))), Text('${sb['nombre_sujets']} sujets', style: AppTextStyles.numberSmall.copyWith(color: AppColors.textPrimary)), const SizedBox(width: AppSpacing.xs), const Icon(AppIcons.chevronRight, color: AppColors.textHint, size: 18)])),
            )),
          if (isActif) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gestion de la répartition disponible en V2'), backgroundColor: AppColors.primary));
              },
              icon: const Icon(AppIcons.migration, size: 16), label: const Text('Gérer la répartition (migrer)'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.textPrimary)),
            )),
          ],
          const SizedBox(height: AppSpacing.xxl),

          // ═══════════════════════════════════════════
          // MATÉRIEL DE NUTRITION
          // ═══════════════════════════════════════════
          Text('Matériel de nutrition', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: (alerteMangeoires || alerteAbreuvoirs) ? AppColors.warning.withOpacity(0.06) : AppColors.success.withOpacity(0.04), borderRadius: AppBorders.cardRadius),
            child: Column(children: [
              Row(children: [
                Icon(alerteMangeoires || alerteAbreuvoirs ? AppIcons.urgent : AppIcons.succes, color: alerteMangeoires || alerteAbreuvoirs ? AppColors.warning : AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(alerteMangeoires || alerteAbreuvoirs ? 'Matériel insuffisant' : 'Matériel suffisant', style: AppTextStyles.subtitleMedium.copyWith(color: alerteMangeoires || alerteAbreuvoirs ? AppColors.warning : AppColors.success, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text('Mangeoires: ${_cycle.nbMangeoires} (recommandé: $nbMangeoiresRecommandees)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              Text('Abreuvoirs: ${_cycle.nbAbreuvoirs} (recommandé: $nbAbreuvoirsRecommandes)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: _modifierMateriel,
                icon: const Icon(AppIcons.edit, size: 16, color: AppColors.textPrimary),
                label: const Text('Modifier le matériel', style: TextStyle(color: AppColors.textPrimary)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.textPrimary)),
              )),
            ]),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ═══════════════════════════════════════════
          // ACTIONS TERRAIN
          // ═══════════════════════════════════════════
          Text('Actions terrain', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Column(children: [
            Row(children: [
              Expanded(child: _buildQuickAction(label: 'Déclarer\nune perte', icon: AppIcons.urgent, color: AppColors.error, bgColor: AppColors.error.withOpacity(0.06), onTap: _declarerPerte)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildQuickAction(label: 'Noter\nune charge', icon: AppIcons.depenseAdd, color: AppColors.textPrimary, bgColor: AppColors.surfaceLight, onTap: () => Navigator.pushNamed(context, '/finance/depense', arguments: {'cycle_id': _cycle.id, 'cycle_nom': _cycle.nom}).then((_) => _refreshCycle()))),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _buildQuickAction(label: 'Vente', icon: AppIcons.venteAdd, color: AppColors.textPrimary, bgColor: AppColors.surfaceLight, onTap: () => Navigator.pushNamed(context, '/finance/vente', arguments: {'cycle_id': _cycle.id, 'cycle_nom': _cycle.nom}).then((_) => _refreshCycle()))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildQuickAction(label: 'Observation', icon: AppIcons.observation, color: AppColors.textPrimary, bgColor: AppColors.surfaceLight, onTap: () => Navigator.pushNamed(context, '/cycle/report/form', arguments: widget.cycleData).then((_) => _refreshCycle()))),
            ]),
          ]),
          const SizedBox(height: AppSpacing.xxl),

          // ═══════════════════════════════════════════
          // STATISTIQUES
          // ═══════════════════════════════════════════
          Text('Statistiques du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Column(children: [
              _buildStatRow('Taux de mortalité', '${mortalite.toStringAsFixed(1)}%', mortalite > 10 ? AppColors.error : AppColors.textPrimary),
              const SizedBox(height: AppSpacing.sm),
              _buildStatRow('Total charges', '${totalDepenses.toStringAsFixed(0)} FCFA', AppColors.textPrimary),
              const SizedBox(height: AppSpacing.sm),
              _buildStatRow('Total ventes', '${totalVentes.toStringAsFixed(0)} FCFA', AppColors.textPrimary),
              const SizedBox(height: AppSpacing.sm),
              _buildStatRow('Bénéfice estimé', '${benefice >= 0 ? "+" : ""}${benefice.toStringAsFixed(0)} FCFA', benefice >= 0 ? AppColors.success : AppColors.error, bold: true),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ═══════════════════════════════════════════
          // GRAPHIQUE
          // ═══════════════════════════════════════════
          Text('Flux du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border.withOpacity(0.6)), boxShadow: AppShadows.shadowCard), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Évolution', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              Row(children: [_buildLegend('Gains', AppColors.success), const SizedBox(width: AppSpacing.md), _buildLegend('Dépenses', AppColors.error)]),
            ]),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(height: 160, child: _buildGraphique()),
          ])),
          const SizedBox(height: AppSpacing.xl),

          // ═══════════════════════════════════════════
          // VENTES
          // ═══════════════════════════════════════════
          Text('Ventes du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          if (_ventesCycle.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune vente', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._ventesCycle.take(5).map((v) => GestureDetector(
              onTap: () {
                final id = v['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => VenteProvider(), child: VenteDetailScreen(venteId: id))));
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: AppBorders.radiusSmall), child: const Icon(AppIcons.vente, color: AppColors.success, size: 20)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v['type_label'] ?? v['type'] ?? 'Vente', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(v['date']?.toString() ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('+${_formatMoney(int.tryParse(v['montant_total']?.toString() ?? '0') ?? 0)} FCFA', style: AppTextStyles.numberSmall.copyWith(color: AppColors.success)),
                    if (v['pourcentage_benefice'] != null)
                      Text('${v['pourcentage_benefice']}%', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                  ]),
                ]),
              ),
            )),
          const SizedBox(height: AppSpacing.xl),

          // ═══════════════════════════════════════════
          // DÉPENSES
          // ═══════════════════════════════════════════
          Text('Dépenses du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          if (_depensesCycle.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune dépense', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._depensesCycle.take(5).map((d) => GestureDetector(
              onTap: () {
                final id = d['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => DepenseProvider(), child: DepenseDetailScreen(depenseId: id))));
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: AppBorders.radiusSmall), child: const Icon(AppIcons.depense, color: AppColors.error, size: 20)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['categorie_label'] ?? d['categorie'] ?? 'Dépense', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(d['date']?.toString() ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('-${_formatMoney(int.tryParse(d['montant']?.toString() ?? '0') ?? 0)} FCFA', style: AppTextStyles.numberSmall.copyWith(color: AppColors.error)),
                    if (d['impact_pourcentage'] != null)
                      Text('+${d['impact_pourcentage']}%', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                  ]),
                ]),
              ),
            )),
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // GRAPHIQUE
  // ═══════════════════════════════════════════
  Widget _buildGraphique() {
    final totalVentes = _spotsVentes.isNotEmpty ? _spotsVentes.last.y : 0;
    final totalDepenses = _spotsDepenses.isNotEmpty ? _spotsDepenses.last.y : 0;
    final maxY = (totalVentes > totalDepenses ? totalVentes : totalDepenses) * 1.3;

    if (maxY == 0) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(AppIcons.chart, size: 40, color: AppColors.textHint), const SizedBox(height: AppSpacing.sm), Text('Ajoutez des transactions\npour voir le graphique', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))]));
    }

    List<FlSpot> spotsV = _spotsVentes;
    List<FlSpot> spotsD = _spotsDepenses;
    if (spotsV.length == 1) spotsV = [spotsV.first, FlSpot(1, spotsV.first.y)];
    if (spotsD.length == 1) spotsD = [spotsD.first, FlSpot(1, spotsD.first.y)];
    final maxX = (spotsV.length > spotsD.length ? spotsV.length : spotsD.length).toDouble() - 1;

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border.withOpacity(0.4), strokeWidth: 0.5, dashArray: [4, 4])),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (value, meta) => Text('${(value/1000).toInt()}k', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)))),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(spots: spotsV, isCurved: true, curveSmoothness: 0.3, color: AppColors.success, dotData: FlDotData(show: false), barWidth: 1.5, belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.0)]))),
        LineChartBarData(spots: spotsD, isCurved: true, curveSmoothness: 0.3, color: AppColors.error, dotData: FlDotData(show: false), barWidth: 1.5, belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.error.withOpacity(0.08), AppColors.error.withOpacity(0.0)]))),
      ],
      minX: 0, maxX: maxX < 1 ? 1 : maxX, minY: 0, maxY: maxY,
    ));
  }

  // ═══════════════════════════════════════════
  // FRISE CHRONOLOGIQUE
  // ═══════════════════════════════════════════
  Widget _buildFriseChronologique() {
    final etapes = _getEtapesFrise(); final age = _cycle.joursEcoules ?? 0;
    return Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard), child: Column(children: [
      SizedBox(height: 60, child: Row(children: etapes.asMap().entries.map((entry) {
        final etape = entry.value; final isPast = age >= etape['age']!; final isCurrent = age < etape['age']! && (entry.key == 0 || age >= etapes[entry.key - 1]['age']!);
        final iconColor = isPast ? AppColors.textPrimary : isCurrent ? AppColors.warning : AppColors.textHint;
        return Expanded(child: Column(children: [
          Icon(etape['icon'] as IconData, size: 24, color: iconColor),
          const SizedBox(height: 4),
          Text(etape['label'] as String, style: AppTextStyles.labelSmall.copyWith(color: iconColor, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, fontSize: 9), textAlign: TextAlign.center)]));
      }).toList())),
      const SizedBox(height: AppSpacing.sm),
      LinearProgressIndicator(value: _getFriseProgression(), backgroundColor: AppColors.grey200, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary), minHeight: 4, borderRadius: AppBorders.buttonRadius),
    ]));
  }

  List<Map<String, dynamic>> _getEtapesFrise() {
    switch (_cycle.type) {
      case 'CHAIR': return [
        {'age': 1, 'label': 'J1', 'icon': AppIcons.oeuf},
        {'age': 21, 'label': 'J21', 'icon': AppIcons.poulet},
        {'age': 35, 'label': 'J35', 'icon': AppIcons.mangeoire},
        {'age': 45, 'label': 'J45', 'icon': AppIcons.succes}
      ];
      case 'PONDEUSE': return [
        {'age': 1, 'label': 'Sem.1', 'icon': AppIcons.oeuf},
        {'age': 56, 'label': 'Sem.8', 'icon': AppIcons.poulet},
        {'age': 126, 'label': 'Sem.18', 'icon': AppIcons.mangeoire},
        {'age': 490, 'label': 'Sem.70', 'icon': AppIcons.succes}
      ];
      case 'LOCAL': return [
        {'age': 1, 'label': 'J1', 'icon': AppIcons.oeuf},
        {'age': 84, 'label': 'Sem.12', 'icon': AppIcons.poulet},
        {'age': 168, 'label': 'Sem.24', 'icon': AppIcons.mangeoire},
        {'age': _cycle.dureeEstimeeJours, 'label': 'Fin', 'icon': AppIcons.succes}
      ];
      default: return [
        {'age': 1, 'label': 'Début', 'icon': AppIcons.debut},
        {'age': _cycle.dureeEstimeeJours, 'label': 'Fin', 'icon': AppIcons.fin}
      ];
    }
  }

  double _getFriseProgression() {
    final age = _cycle.joursEcoules ?? 0;
    if (_cycle.dureeEstimeeJours <= 0) return 0;
    return (age / _cycle.dureeEstimeeJours).clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════
  // QUICK ACTION
  // ═══════════════════════════════════════════
  Widget _buildQuickAction({required String label, required IconData icon, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(color: bgColor, borderRadius: AppBorders.cardRadius, border: Border.all(color: color.withOpacity(0.15))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 20), const SizedBox(width: AppSpacing.sm), Flexible(child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis))]),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // STAT ROW
  // ═══════════════════════════════════════════
  Widget _buildStatRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
      Text(value, style: AppTextStyles.bodyMedium.copyWith(color: valueColor, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }

  // ═══════════════════════════════════════════
  // LEGEND
  // ═══════════════════════════════════════════
  Widget _buildLegend(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600))]));
}