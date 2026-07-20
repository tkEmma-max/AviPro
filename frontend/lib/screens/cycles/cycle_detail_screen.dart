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
import '../../providers/cycle_provider.dart';

class CycleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cycleData;

  const CycleDetailScreen({super.key, required this.cycleData});

  @override
  State<CycleDetailScreen> createState() => _CycleDetailScreenState();
}

class _CycleDetailScreenState extends State<CycleDetailScreen> {
  // Cache statique (gardé entre les navigations)
  static Map<String, dynamic>? _cachedCycleData;
  static List<Map<String, dynamic>> _cachedVentesCycle = [];
  static List<Map<String, dynamic>> _cachedDepensesCycle = [];
  static List<FlSpot> _cachedSpotsVentes = [];
  static List<FlSpot> _cachedSpotsDepenses = [];
  static List<String> _cachedLabels = [];
  static String? _cachedCycleId;
  final _apiService = ApiService();
  late Cycle _cycle;
  bool _isRefreshing = false;

  // Données du graphique
  List<FlSpot> _spotsVentes = [];
  List<FlSpot> _spotsDepenses = [];
  List<String> _labelsJours = [];

  // Ventes et dépenses du cycle
  List<Map<String, dynamic>> _ventesCycle = [];
  List<Map<String, dynamic>> _depensesCycle = [];

  @override
  void initState() {
    super.initState();
    _cycle = Cycle.fromJson(widget.cycleData);

    // Si on a des données en cache pour ce cycle, les afficher immédiatement
    if (_cachedCycleId == _cycle.id && _cachedCycleData != null) {
      _cycle = Cycle.fromJson(_cachedCycleData!);
      _ventesCycle = _cachedVentesCycle;
      _depensesCycle = _cachedDepensesCycle;
      _spotsVentes = _cachedSpotsVentes;
      _spotsDepenses = _cachedSpotsDepenses;
      _labelsJours = _cachedLabels;
    }

    // Rafraîchir en arrière-plan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCycle();
    });
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
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final cycleProvider = context.read<CycleProvider>();
              final success = await cycleProvider.deleteCycle(_cycle.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Cycle "${_cycle.nom}" supprimé' : 'Erreur'), backgroundColor: success ? AppColors.success : AppColors.error));
                if (success) Navigator.pop(context);
              }
            },
            child: Text('Supprimer', style: AppTextStyles.button.copyWith(color: AppColors.error)),
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

        // Extraire ventes et dépenses
        final ventes = (data['ventes'] as List?) ?? [];
        final depenses = (data['depenses'] as List?) ?? [];

        // Agréger pour le graphique
        Map<String, double> ventesParJour = {};
        Map<String, double> depensesParJour = {};

        for (var v in ventes) {
          final dateStr = (v['date'] as String).substring(0, 10);
          final montant = double.tryParse(v['montant_total']?.toString() ?? '0') ?? 0;
          ventesParJour[dateStr] = (ventesParJour[dateStr] ?? 0) + montant;
        }
        for (var d in depenses) {
          final dateStr = (d['date'] as String).substring(0, 10);
          final montant = double.tryParse(d['montant']?.toString() ?? '0') ?? 0;
          depensesParJour[dateStr] = (depensesParJour[dateStr] ?? 0) + montant;
        }

        final tousLesJours = <String>{...ventesParJour.keys, ...depensesParJour.keys}.toList()..sort();
        double cumulVentes = 0;
        double cumulDepenses = 0;
        final spotsVentes = <FlSpot>[];
        final spotsDepenses = <FlSpot>[];
        final labels = <String>[];

        for (int i = 0; i < tousLesJours.length; i++) {
          cumulVentes += ventesParJour[tousLesJours[i]] ?? 0;
          cumulDepenses += depensesParJour[tousLesJours[i]] ?? 0;
          spotsVentes.add(FlSpot(i.toDouble(), cumulVentes));
          spotsDepenses.add(FlSpot(i.toDouble(), cumulDepenses));
          final parts = tousLesJours[i].split('-');
          labels.add('${parts[2]}/${parts[1]}');
        }

        setState(() {
          _cycle = Cycle.fromJson(data);
          _ventesCycle = ventes.cast<Map<String, dynamic>>();
          _depensesCycle = depenses.cast<Map<String, dynamic>>();
          _spotsVentes = spotsVentes;
          _spotsDepenses = spotsDepenses;
          _labelsJours = labels;
          _isRefreshing = false;
        });
        // Mettre en cache
        _cachedCycleData = data;
        _cachedCycleId = _cycle.id;
        _cachedVentesCycle = _ventesCycle;
        _cachedDepensesCycle = _depensesCycle;
        _cachedSpotsVentes = _spotsVentes;
        _cachedSpotsDepenses = _spotsDepenses;
        _cachedLabels = _labelsJours;
      }
    } catch (e) {
      print('❌ Erreur rafraîchissement cycle: $e');
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _declarerPerte() async {
    int pertesTemp = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge),
          title: const Text('Déclarer une perte'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Nombre de poulets morts', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildNumberButton('-', () { if (pertesTemp > 0) setDialogState(() => pertesTemp--); }),
              Container(width: 60, height: 60, alignment: Alignment.center, child: Text(pertesTemp.toString(), style: AppTextStyles.numberLarge.copyWith(fontSize: 28, color: AppColors.error))),
              _buildNumberButton('+', () { if (pertesTemp < _cycle.nombreSujetsActuels) setDialogState(() => pertesTemp++); }),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text('Effectif restant: ${_cycle.nombreSujetsActuels - pertesTemp}', style: AppTextStyles.bodySmall),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary))),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final response = await _apiService.post('cycles/${_cycle.id}/declarer_perte/', data: {'nombre': pertesTemp, 'raison': 'Mortalité déclarée'});
                  if (response.statusCode == 200 && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perte déclarée'), backgroundColor: AppColors.success));
                    _refreshCycle();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
                }
              },
              child: Text('Confirmer', style: AppTextStyles.button.copyWith(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String label, VoidCallback onPressed) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: AppColors.surfaceLight, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
      child: IconButton(icon: Text(label, style: AppTextStyles.numberLarge.copyWith(fontSize: 24, color: AppColors.primary)), onPressed: onPressed, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) { case 'CHAIR': return AppColors.primary; case 'PONDEUSE': return AppColors.warning; case 'LOCAL': return AppColors.success; default: return AppColors.textHint; }
  }

  String _getTypeLabel(String type) {
    switch (type) { case 'CHAIR': return 'Chair'; case 'PONDEUSE': return 'Pondeuse'; case 'LOCAL': return 'Local'; default: return type; }
  }

  String _formatMoney(int value) => value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ');

  @override
  Widget build(BuildContext context) {
    final isActif = _cycle.isActive && !_cycle.isArchived;
    final progression = _cycle.progression ?? 0;
    final age = _cycle.joursEcoules ?? 0;
    final typeLabel = _getTypeLabel(_cycle.type);
    final typeColor = _getTypeColor(_cycle.type);
    final mortalite = _cycle.tauxMortalite ?? 0;
    final totalDepenses = _cycle.totalDepenses ?? 0;
    final totalVentes = _cycle.totalVentes ?? 0;
    final benefice = _cycle.benefice ?? 0;
    final coutUnitaire = _cycle.coutProductionUnitaire ?? 0;
    final dateDebut = DateFormat('dd/MM/yyyy').format(_cycle.dateDebut);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: Text(_cycle.nom, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                builder: (context) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(leading: const Icon(Icons.bar_chart, color: AppColors.primary), title: const Text('Rapport de performance'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/cycle/report/${_cycle.id}', arguments: widget.cycleData); }),
                    ListTile(leading: const Icon(Icons.note_alt_outlined, color: AppColors.primary), title: const Text('Soumettre un rapport de suivi'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/cycle/report/form', arguments: widget.cycleData); }),
                    ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.primary), title: const Text('Modifier le cycle'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/cycle/edit', arguments: widget.cycleData); }),
                    ListTile(leading: const Icon(Icons.assessment_outlined, color: AppColors.primary), title: const Text('Voir les rapports'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/rapports'); }),
                    if (_canDeleteCycle()) ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.error), title: const Text('Supprimer le cycle', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _showDeleteConfirmation(); }),
                  ]),
                ),
              );
            },
          ),
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

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_cycle.nom, style: AppTextStyles.headlineLarge.copyWith(fontSize: 22, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text('Jour $age • Début: $dateDebut', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${_cycle.nombreSujetsActuels}', style: AppTextStyles.numberLarge.copyWith(fontSize: 24, color: AppColors.primary)),
              Text('sujets vivants', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('${coutUnitaire.toInt()} FCFA/sujet', style: AppTextStyles.numberLarge.copyWith(fontSize: 24, color: AppColors.warning)),
              Text('coût production', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ]),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // PROGRESSION
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progression', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text('${progression.toInt()}%', style: AppTextStyles.labelMedium.copyWith(color: progression > 80 ? AppColors.error : progression > 50 ? AppColors.warning : AppColors.success)),
            ]),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progression / 100, backgroundColor: AppColors.grey200, valueColor: AlwaysStoppedAnimation<Color>(progression > 80 ? AppColors.error : progression > 50 ? AppColors.warning : AppColors.success), minHeight: 8, borderRadius: AppBorders.buttonRadius),
          ]),
          const SizedBox(height: AppSpacing.xxl),

          // FRISE
          Text('Frise chronologique', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          _buildFriseChronologique(),
          const SizedBox(height: AppSpacing.xxl),

          // ACTIONS TERRAIN
          Text('Actions terrain', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 1.4,
            children: [
              _buildQuickAction(label: 'Déclarer une perte', icon: Icons.warning, color: AppColors.error, bgColor: AppColors.error.withOpacity(0.08), onTap: _declarerPerte),
              _buildQuickAction(label: 'Noter une charge', icon: Icons.money_off_outlined, color: AppColors.primary, bgColor: AppColors.primary.withOpacity(0.08), onTap: () => Navigator.pushNamed(context, '/finance/depense')),
              _buildQuickAction(label: 'Enregistrer une vente', icon: Icons.payments_outlined, color: AppColors.success, bgColor: AppColors.success.withOpacity(0.08), onTap: () => Navigator.pushNamed(context, '/finance/vente')),
              _buildQuickAction(label: 'Observation', icon: Icons.note_alt_outlined, color: AppColors.warning, bgColor: AppColors.warning.withOpacity(0.08), onTap: () => Navigator.pushNamed(context, '/cycle/report/form', arguments: widget.cycleData)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // STATS
          Text('Statistiques du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Column(children: [
              _buildStatRow('Taux de mortalité', '${mortalite.toStringAsFixed(1)}%', mortalite > 10 ? AppColors.error : AppColors.success),
              const Divider(height: AppSpacing.lg),
              _buildStatRow('Total charges', '${totalDepenses.toStringAsFixed(0)} FCFA', AppColors.error),
              const Divider(height: AppSpacing.lg),
              _buildStatRow('Total ventes', '${totalVentes.toStringAsFixed(0)} FCFA', AppColors.success),
              const Divider(height: AppSpacing.lg),
              _buildStatRow('Bénéfice estimé', '${benefice >= 0 ? "+" : ""}${benefice.toStringAsFixed(0)} FCFA', benefice >= 0 ? AppColors.success : AppColors.error, bold: true),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // GRAPHIQUE DU CYCLE
          Text('Flux du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border.withOpacity(0.6)), boxShadow: AppShadows.shadowCard),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.show_chart_rounded, size: 16, color: AppColors.primary)), const SizedBox(width: 8), Text('Évolution', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold))]),
                Row(children: [_buildLegend('Gains', AppColors.success), const SizedBox(width: AppSpacing.md), _buildLegend('Dépenses', AppColors.error)]),
              ]),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: 160, child: _buildGraphique()),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // VENTES DU CYCLE
          Text('Ventes du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          if (_ventesCycle.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune vente', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._ventesCycle.take(5).map((v) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.3))),
              child: Row(children: [
                Container(width: 4, height: 40, decoration: BoxDecoration(color: AppColors.success, borderRadius: AppBorders.radiusSmall)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(v['type_label'] ?? v['type'] ?? 'Vente', style: AppTextStyles.subtitleMedium), Text(v['date']?.toString() ?? '', style: AppTextStyles.bodySmall)])),
                Text('+${_formatMoney(int.tryParse(v['montant_total']?.toString() ?? '0') ?? 0)} FCFA', style: AppTextStyles.numberSmall.copyWith(color: AppColors.success)),
              ]),
            )),
          const SizedBox(height: AppSpacing.xl),

          // DÉPENSES DU CYCLE
          Text('Dépenses du cycle', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          if (_depensesCycle.isEmpty)
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune dépense', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
          else
            ..._depensesCycle.take(5).map((d) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.error.withOpacity(0.3))),
              child: Row(children: [
                Container(width: 4, height: 40, decoration: BoxDecoration(color: AppColors.error, borderRadius: AppBorders.radiusSmall)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['categorie_label'] ?? d['categorie'] ?? 'Dépense', style: AppTextStyles.subtitleMedium), Text(d['date']?.toString() ?? '', style: AppTextStyles.bodySmall)])),
                Text('-${_formatMoney(int.tryParse(d['montant']?.toString() ?? '0') ?? 0)} FCFA', style: AppTextStyles.numberSmall.copyWith(color: AppColors.error)),
              ]),
            )),
          const SizedBox(height: AppSpacing.xxl),

          // CLÔTURER
          if (isActif)
            Center(child: TextButton(
              onPressed: () {
                showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: AppBorders.radiusLarge), title: const Text('Clôturer le cycle ?'), content: const Text('Cette action est irréversible.'), actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary))),
                  TextButton(onPressed: () { Navigator.pop(ctx); _refreshCycle(); }, child: Text('Clôturer', style: AppTextStyles.button.copyWith(color: AppColors.error))),
                ]));
              },
              child: Text('Clôturer définitivement le cycle', style: AppTextStyles.button.copyWith(color: AppColors.error)),
            )),
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
      child: Column(children: [
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
      ]),
    );
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
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: bgColor, borderRadius: AppBorders.cardRadius, border: Border.all(color: color.withOpacity(0.2))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: AppSpacing.xs), Text(label, style: AppTextStyles.labelMedium.copyWith(color: color, fontWeight: FontWeight.w500), textAlign: TextAlign.center)])));
  }

  Widget _buildStatRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)), Text(value, style: bold ? AppTextStyles.numberMedium.copyWith(color: valueColor) : AppTextStyles.bodyMedium.copyWith(color: valueColor, fontWeight: FontWeight.w500))]);
  }

  Widget _buildLegend(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))]));
}