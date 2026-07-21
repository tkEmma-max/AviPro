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
import '../../models/cycle.dart';
import '../../services/api_service.dart';
import '../../services/equipement_service.dart';
import '../../providers/cycle_provider.dart';
import '../poulaillers/poulailler_migration_screen.dart';
import '../poulaillers/poulailler_detail_screen.dart';


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
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCycle());
  }

  bool _canDeleteCycle() {
    final difference = DateTime.now().difference(_cycle.createdAt);
    return difference.inHours < 48;
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

  void _modifierMateriel() {
    final nbMangeoiresController = TextEditingController(text: _cycle.nbMangeoires.toString());
    final nbAbreuvoirsController = TextEditingController(text: _cycle.nbAbreuvoirs.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge),
        title: const Text('Modifier le matériel'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nbMangeoiresController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nombre de mangeoires', border: OutlineInputBorder()),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: nbAbreuvoirsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nombre d\'abreuvoirs', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final nbM = int.tryParse(nbMangeoiresController.text) ?? _cycle.nbMangeoires;
                final nbA = int.tryParse(nbAbreuvoirsController.text) ?? _cycle.nbAbreuvoirs;
                print('📤 PATCH nb_mangeoires=$nbM, nb_abreuvoirs=$nbA');
                final response = await _apiService.patch('cycles/${_cycle.id}/', data: {
                  'nb_mangeoires': int.tryParse(nbMangeoiresController.text) ?? _cycle.nbMangeoires,
                  'nb_abreuvoirs': int.tryParse(nbAbreuvoirsController.text) ?? _cycle.nbAbreuvoirs,
                });
                print('📥 PATCH réponse: ${response.statusCode}');
                print('📥 Body: ${response.data}');
                if (response.statusCode == 200 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Matériel mis à jour'), backgroundColor: AppColors.success));
                  // Forcer le rechargement sans cache
                  _cachedCycleData = null;
                  _cachedCycleId = null;
                  _refreshCycle();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Enregistrer'),
          ),
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
        print('📥 GET cycle: nb_mangeoires=${data['nb_mangeoires']}, nb_abreuvoirs=${data['nb_abreuvoirs']}');
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

        // Sous-bandes
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

  Widget _buildNumberButton(String label, VoidCallback onPressed) {
    return Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle, border: Border.all(color: AppColors.border)), child: IconButton(icon: Text(label, style: AppTextStyles.numberLarge.copyWith(fontSize: 24, color: AppColors.primary)), onPressed: onPressed, padding: EdgeInsets.zero, constraints: const BoxConstraints()));
  }

  Color _getTypeColor(String type) {
    switch (type) { case 'CHAIR': return AppColors.primary; case 'PONDEUSE': return AppColors.warning; case 'LOCAL': return AppColors.success; default: return AppColors.textHint; }
  }

  String _getTypeLabel(String type) {
    switch (type) { case 'CHAIR': return 'Chair'; case 'PONDEUSE': return 'Pondeuse'; case 'LOCAL': return 'Local'; default: return type; }
  }

  String _formatMoney(int value) => value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ');

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isActif = _cycle.isActive && !_cycle.isArchived;
    final age = _cycle.joursEcoules ?? 0;
    final typeLabel = _getTypeLabel(_cycle.type);
    final typeColor = _getTypeColor(_cycle.type);
    final mortalite = _cycle.tauxMortalite ?? 0;
    final totalDepenses = _cycle.totalDepenses ?? 0;
    final totalVentes = _cycle.totalVentes ?? 0;
    final benefice = _cycle.benefice ?? 0;
    final coutUnitaire = _cycle.coutProductionUnitaire ?? 0;
    final dateDebut = DateFormat('dd/MM/yyyy').format(_cycle.dateDebut);

    // Alerte matériel
    final nbMangeoiresRecommandees = _cycle.nombreSujetsActuels > 0 ? EquipementService.getMangeoiresRecommandees(_cycle.nombreSujetsActuels, _cycle.type, age) : 0;
    final nbAbreuvoirsRecommandes = _cycle.nombreSujetsActuels > 0 ? EquipementService.getAbreuvoirsRecommandes(_cycle.nombreSujetsActuels, _cycle.type, age) : 0;
    final alerteMangeoires = _cycle.nbMangeoires < nbMangeoiresRecommandees;
    final alerteAbreuvoirs = _cycle.nbAbreuvoirs < nbAbreuvoirsRecommandes;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: Text(_cycle.nom, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: AppColors.textPrimary), onPressed: () {
            showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(leading: const Icon(Icons.bar_chart, color: AppColors.primary), title: const Text('Rapport de performance'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/cycle/report/${_cycle.id}', arguments: widget.cycleData); }),
              ListTile(leading: const Icon(Icons.note_alt_outlined, color: AppColors.primary), title: const Text('Soumettre un rapport'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/cycle/report/form', arguments: widget.cycleData); }),
              ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.primary), title: const Text('Modifier le cycle'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/cycle/edit', arguments: widget.cycleData); }),
              ListTile(leading: const Icon(Icons.assessment_outlined, color: AppColors.primary), title: const Text('Voir les rapports'), onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, '/rapports'); }),
              if (_canDeleteCycle()) ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.error), title: const Text('Supprimer le cycle', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(ctx); _showDeleteConfirmation(); }),
            ])));
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.md),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2, backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),

          // HEADER
          Row(children: [
            Container(padding: const EdgeInsets.all(AppSpacing.xs), decoration: BoxDecoration(color: isActif ? AppColors.success.withOpacity(0.1) : AppColors.textHint.withOpacity(0.1), borderRadius: AppBorders.buttonRadius), child: Text(isActif ? 'ACTIF' : 'CLÔTURÉ', style: AppTextStyles.labelSmall.copyWith(color: isActif ? AppColors.success : AppColors.textHint, fontWeight: FontWeight.w600))),
            const SizedBox(width: AppSpacing.sm),
            Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: AppBorders.buttonRadius), child: Text(typeLabel, style: AppTextStyles.labelSmall.copyWith(color: typeColor, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: AppSpacing.md),

          // NOM + ÂGE EN GROS
          Text(_cycle.nom, style: AppTextStyles.headlineLarge.copyWith(fontSize: 22, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text('($age jours)', style: AppTextStyles.headlineLarge.copyWith(fontSize: 22, color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text('📍 ${_cycle.poulaillerNom ?? "Poulailler"} • Début: $dateDebut', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),

          // SUJETS + COÛT
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_cycle.nombreSujetsActuels} sujets vivants', style: AppTextStyles.numberLarge.copyWith(fontSize: 20, color: AppColors.primary)),
            ])),
            Text('${coutUnitaire.toInt()} FCFA/sujet', style: AppTextStyles.numberLarge.copyWith(fontSize: 20, color: AppColors.warning)),
          ]),
          const SizedBox(height: AppSpacing.xxl),

          // FRISE
          Text('Frise chronologique', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          _buildFriseChronologique(),
          const SizedBox(height: AppSpacing.xxl),

          // RÉPARTITION DES SUJETS (SOUS-BANDES)
          Text('Répartition des sujets', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          if (_sousBandes.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune sous-bande', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._sousBandes.map((sb) => GestureDetector(
              onTap: () {
                // TODO: Ouvrir détail sous-bande (pop-up ou page)
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(sb['poulailler_nom'] ?? 'Poulailler'),
                    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${sb['nombre_sujets']} sujets', style: AppTextStyles.subtitleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Sous-bande active', style: AppTextStyles.bodySmall),
                    ]),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.house_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(sb['poulailler_nom'] ?? 'Poulailler', style: AppTextStyles.subtitleMedium)),
                  Text('${sb['nombre_sujets']} sujets', style: AppTextStyles.numberSmall.copyWith(color: AppColors.primary)),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
                ]),
              ),
            )),
          if (isActif) ...[
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () {
                // Trouver le poulailler source (première sous-bande active)
                final poulaillerId = _sousBandes.isNotEmpty ? _sousBandes.first['poulailler'] : null;
                if (poulaillerId != null) {
                  // Naviguer vers la migration
                  Navigator.pushNamed(context, '/poulailler/migration', arguments: poulaillerId);
                }
              },
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Gérer la répartition (migrer)'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            )),
          ],

          // MATÉRIEL DE NUTRITION
          Text('Matériel de nutrition', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: (alerteMangeoires || alerteAbreuvoirs) ? AppColors.warning.withOpacity(0.08) : AppColors.success.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: (alerteMangeoires || alerteAbreuvoirs) ? AppColors.warning : AppColors.success.withOpacity(0.2))),
            child: Column(children: [
              Row(children: [
                Icon(alerteMangeoires || alerteAbreuvoirs ? Icons.warning_amber_outlined : Icons.check_circle, color: alerteMangeoires || alerteAbreuvoirs ? AppColors.warning : AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(alerteMangeoires || alerteAbreuvoirs ? 'Matériel insuffisant' : 'Matériel suffisant', style: AppTextStyles.subtitleMedium.copyWith(color: alerteMangeoires || alerteAbreuvoirs ? AppColors.warning : AppColors.success)),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text('Mangeoires: ${_cycle.nbMangeoires} (recommandé: $nbMangeoiresRecommandees)', style: AppTextStyles.bodySmall),
              Text('Abreuvoirs: ${_cycle.nbAbreuvoirs} (recommandé: $nbAbreuvoirsRecommandes)', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () {
                  _modifierMateriel();
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Modifier le matériel'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
              )),
            ]),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ACTIONS TERRAIN
          Text('Actions terrain', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Column(children: [
            Row(children: [
              Expanded(child: _buildQuickAction(label: 'Déclarer une perte', icon: Icons.warning, color: AppColors.error, bgColor: AppColors.error.withOpacity(0.08), onTap: _declarerPerte)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildQuickAction(label: 'Noter une charge', icon: Icons.money_off_outlined, color: AppColors.primary, bgColor: AppColors.primary.withOpacity(0.08), onTap: () => Navigator.pushNamed(context, '/finance/depense', arguments: {'cycle_id': _cycle.id, 'cycle_nom': _cycle.nom}))),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _buildQuickAction(label: 'Enregistrer une vente', icon: Icons.payments_outlined, color: AppColors.success, bgColor: AppColors.success.withOpacity(0.08), onTap: () => Navigator.pushNamed(context, '/finance/vente', arguments: {'cycle_id': _cycle.id, 'cycle_nom': _cycle.nom}))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildQuickAction(label: 'Observation', icon: Icons.note_alt_outlined, color: AppColors.warning, bgColor: AppColors.warning.withOpacity(0.08), onTap: () => Navigator.pushNamed(context, '/cycle/report/form', arguments: widget.cycleData))),
            ]),
          ]),
          const SizedBox(height: AppSpacing.xxl),

          // STATS
          Text('Statistiques du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
              child: Column(children: [
                _buildStatRow('Taux de mortalité', '${mortalite.toStringAsFixed(1)}%', mortalite > 10 ? AppColors.error : AppColors.success),
                const Divider(height: AppSpacing.lg),
                _buildStatRow('Total charges', '${totalDepenses.toStringAsFixed(0)} FCFA', AppColors.error),
                const Divider(height: AppSpacing.lg),
                _buildStatRow('Total ventes', '${totalVentes.toStringAsFixed(0)} FCFA', AppColors.success),
                const Divider(height: AppSpacing.lg),
                _buildStatRow('Bénéfice estimé', '${benefice >= 0 ? "+" : ""}${benefice.toStringAsFixed(0)} FCFA', benefice >= 0 ? AppColors.success : AppColors.error, bold: true),
              ])),
          const SizedBox(height: AppSpacing.xl),

          // GRAPHIQUE
          Text('Flux du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border.withOpacity(0.6)), boxShadow: AppShadows.shadowCard),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.show_chart_rounded, size: 16, color: AppColors.primary)), const SizedBox(width: 8), Text('Évolution', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold))]),
                  Row(children: [_buildLegend('Gains', AppColors.success), const SizedBox(width: AppSpacing.md), _buildLegend('Dépenses', AppColors.error)]),
                ]),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(height: 160, child: _buildGraphique()),
              ])),
          const SizedBox(height: AppSpacing.xl),

          // VENTES
          Text('Ventes du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          if (_ventesCycle.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune vente', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._ventesCycle.take(5).map((v) => Container(margin: const EdgeInsets.only(bottom: AppSpacing.sm), padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.3))), child: Row(children: [Container(width: 4, height: 40, decoration: BoxDecoration(color: AppColors.success, borderRadius: AppBorders.radiusSmall)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v['type_label'] ?? v['type'] ?? 'Vente', style: AppTextStyles.subtitleMedium), Text(v['date']?.toString() ?? '', style: AppTextStyles.bodySmall)])), Text('+${_formatMoney(int.tryParse(v['montant_total']?.toString() ?? '0') ?? 0)} FCFA', style: AppTextStyles.numberSmall.copyWith(color: AppColors.success))]))),
          const SizedBox(height: AppSpacing.xl),

          // DÉPENSES
          Text('Dépenses du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          if (_depensesCycle.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune dépense', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._depensesCycle.take(5).map((d) => Container(margin: const EdgeInsets.only(bottom: AppSpacing.sm), padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.error.withOpacity(0.3))), child: Row(children: [Container(width: 4, height: 40, decoration: BoxDecoration(color: AppColors.error, borderRadius: AppBorders.radiusSmall)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['categorie_label'] ?? d['categorie'] ?? 'Dépense', style: AppTextStyles.subtitleMedium), Text(d['date']?.toString() ?? '', style: AppTextStyles.bodySmall)])), Text('-${_formatMoney(int.tryParse(d['montant']?.toString() ?? '0') ?? 0)} FCFA', style: AppTextStyles.numberSmall.copyWith(color: AppColors.error))]))),
          const SizedBox(height: AppSpacing.xxl),

          // CLÔTURER
          if (isActif)
            Center(child: TextButton(onPressed: () {
              showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge), title: const Text('Clôturer le cycle ?'), content: const Text('Cette action est irréversible.'), actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary))),
                TextButton(onPressed: () { Navigator.pop(ctx); _refreshCycle(); }, child: Text('Clôturer', style: AppTextStyles.button.copyWith(color: AppColors.error))),
              ]));
            }, child: Text('Clôturer définitivement le cycle', style: AppTextStyles.button.copyWith(color: AppColors.error)))),
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════
  Widget _buildGraphique() {
    final maxY = ((_cycle.totalVentes ?? 0) > (_cycle.totalDepenses ?? 0) ? (_cycle.totalVentes ?? 0) : (_cycle.totalDepenses ?? 0)) * 1.3;
    if (maxY == 0 || _spotsVentes.isEmpty) {
      return Center(child: Text('Ajoutez des transactions\npour voir le graphique', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)));
    }
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border.withOpacity(0.4), strokeWidth: 1, dashArray: [4, 4])),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (value, meta) => Text('${(value/1000).toInt()}k', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 10)))),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index >= 0 && index < _labelsJours.length) {
            if (_labelsJours.length > 7 && index % 2 != 0) return const Text('');
            return Text(_labelsJours[index], style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 9));
          }
          return const Text('');
        })),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(spots: _spotsVentes, isCurved: true, curveSmoothness: 0.3, color: AppColors.success, dotData: FlDotData(show: false), barWidth: 2.5, belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.success.withOpacity(0.2), AppColors.success.withOpacity(0.0)]))),
        LineChartBarData(spots: _spotsDepenses, isCurved: true, curveSmoothness: 0.3, color: AppColors.error, dotData: FlDotData(show: false), barWidth: 2.5, belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.error.withOpacity(0.15), AppColors.error.withOpacity(0.0)]))),
      ],
      minX: 0, maxX: (_spotsVentes.length - 1).toDouble().clamp(1, 30), minY: 0, maxY: maxY,
    ));
  }

  Widget _buildFriseChronologique() {
    final etapes = _getEtapesFrise();
    final age = _cycle.joursEcoules ?? 0;
    return Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard), child: Column(children: [
      SizedBox(height: 60, child: Row(children: etapes.asMap().entries.map((entry) {
        final index = entry.key; final etape = entry.value;
        final isPast = age >= etape['age']!;
        final isCurrent = age < etape['age']! && (index == 0 || age >= etapes[index - 1]['age']!);
        return Expanded(child: Column(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: isPast ? AppColors.primary : isCurrent ? AppColors.warning : AppColors.grey200, shape: BoxShape.circle), child: Icon(etape['icon'] as IconData, size: 16, color: isPast || isCurrent ? Colors.white : AppColors.textHint)),
          const SizedBox(height: 4),
          Text(etape['label'] as String, style: AppTextStyles.labelSmall.copyWith(color: isPast || isCurrent ? AppColors.textPrimary : AppColors.textHint, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, fontSize: 9), textAlign: TextAlign.center),
        ]));
      }).toList())),
      const SizedBox(height: AppSpacing.sm),
      LinearProgressIndicator(value: _getFriseProgression(), backgroundColor: AppColors.grey200, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary), minHeight: 6, borderRadius: AppBorders.buttonRadius),
    ]));
  }

  List<Map<String, dynamic>> _getEtapesFrise() {
    switch (_cycle.type) {
      case 'CHAIR': return [{'age': 1, 'label': 'J1', 'icon': Icons.egg}, {'age': 21, 'label': 'J21', 'icon': Icons.pets}, {'age': 35, 'label': 'J35', 'icon': Icons.restaurant}, {'age': 45, 'label': 'J45', 'icon': Icons.check_circle}];
      case 'PONDEUSE': return [{'age': 1, 'label': 'Sem.1', 'icon': Icons.egg}, {'age': 56, 'label': 'Sem.8', 'icon': Icons.pets}, {'age': 126, 'label': 'Sem.18', 'icon': Icons.restaurant}, {'age': 490, 'label': 'Sem.70', 'icon': Icons.check_circle}];
      case 'LOCAL': return [{'age': 1, 'label': 'J1', 'icon': Icons.egg}, {'age': 84, 'label': 'Sem.12', 'icon': Icons.pets}, {'age': 168, 'label': 'Sem.24', 'icon': Icons.restaurant}, {'age': _cycle.dureeEstimeeJours, 'label': 'Fin', 'icon': Icons.check_circle}];
      default: return [{'age': 1, 'label': 'Début', 'icon': Icons.play_arrow}, {'age': _cycle.dureeEstimeeJours, 'label': 'Fin', 'icon': Icons.flag}];
    }
  }

  double _getFriseProgression() {
    final age = _cycle.joursEcoules ?? 0;
    if (_cycle.dureeEstimeeJours <= 0) return 0;
    return (age / _cycle.dureeEstimeeJours).clamp(0.0, 1.0);
  }

  Widget _buildQuickAction({required String label, required IconData icon, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(color: bgColor, borderRadius: AppBorders.cardRadius, border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)), Text(value, style: bold ? AppTextStyles.numberMedium.copyWith(color: valueColor) : AppTextStyles.bodyMedium.copyWith(color: valueColor, fontWeight: FontWeight.w500))]);
  }

  Widget _buildLegend(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))]));
}