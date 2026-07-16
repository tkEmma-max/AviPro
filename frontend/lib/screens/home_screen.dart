// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/poulailler_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/pret_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_shadows.dart';
import '../services/api_service.dart';
import 'poulaillers/poulailler_list_screen.dart';
import 'cycles/cycle_list_screen.dart';
import 'finances/finance_hub_screen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardContent(),
    const PoulaillerListScreen(),
    const CycleListScreen(),
    const FinanceHubScreen(),
    const ProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textHint,
            selectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.labelSmall,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.house_outlined), activeIcon: Icon(Icons.house_rounded), label: 'Poulaillers'),
              BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), activeIcon: Icon(Icons.timeline_rounded), label: 'Cycles'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Finances'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CONTENU DU DASHBOARD (chargement progressif)
// ============================================================
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final _apiService = ApiService();
  bool _isFirstLoad = true;

  double _totalVentes = 0;
  double _totalDepenses = 0;
  int _cyclesActifs = 0;
  double _pretsRestants = 0;
  List<Map<String, dynamic>> _dernieresTransactions = [];
  List<Map<String, dynamic>> _echeances = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Plus de setState(() => _isLoading = true) → pas de blocage
    try {
      final poulaillerProvider = context.read<PoulaillerProvider>();
      final cycleProvider = context.read<CycleProvider>();
      final pretProvider = context.read<PretProvider>();

      await Future.wait([
        poulaillerProvider.refreshPoulaillers(),
        cycleProvider.refreshCycles(),
        pretProvider.refreshPrets(),
      ]);

      final cycles = cycleProvider.cycles;
      final prets = pretProvider.prets;

      int actifs = 0;
      double pretsRest = 0;

      for (var c in cycles) {
        if (c.isActive && !c.isArchived) actifs++;
      }
      for (var p in prets) {
        pretsRest += p.montantRestant ?? 0;
      }

      final transactions = <Map<String, dynamic>>[];
      double totalVentes = 0;
      double totalDepenses = 0;

      final depResponse = await _apiService.get('depenses/?page_size=100');
      if (depResponse.statusCode == 200 && depResponse.data['results'] != null) {
        for (var d in depResponse.data['results']) {
          final montant = double.tryParse(d['montant']?.toString() ?? '0') ?? 0;
          totalDepenses += montant;
          transactions.add({'type': 'depense', 'label': d['categorie_label'] ?? 'Depense', 'montant': montant, 'date': d['date']?.toString() ?? ''});
        }
      }

      final venteResponse = await _apiService.get('ventes/?page_size=100');
      if (venteResponse.statusCode == 200 && venteResponse.data['results'] != null) {
        for (var v in venteResponse.data['results']) {
          final montant = double.tryParse(v['montant_total']?.toString() ?? '0') ?? 0;
          totalVentes += montant;
          transactions.add({'type': 'vente', 'label': v['type_label'] ?? 'Vente', 'montant': montant, 'date': v['date']?.toString() ?? ''});
        }
      }
      transactions.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      final echeances = <Map<String, dynamic>>[];
      if (prets.isNotEmpty) {
        for (var p in prets.where((p) => p.montantRestant != null && p.montantRestant! > 0)) {
          echeances.add({'preteur': p.preteur, 'montant': p.montantRestant, 'statut': 'normal'});
        }
      }

      if (mounted) {
        setState(() {
          _totalVentes = totalVentes;
          _totalDepenses = totalDepenses;
          _cyclesActifs = actifs;
          _pretsRestants = pretsRest;
          _dernieresTransactions = transactions.take(3).toList();
          _echeances = echeances.take(3).toList();
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      print('❌ Erreur dashboard: $e');
      if (mounted) setState(() => _isFirstLoad = false);
    }
  }

  Color _darken(Color color, [double amount = .15]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final solde = _totalVentes - _totalDepenses;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: AppSpacing.md),

            // HEADER
            Container(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, _darken(AppColors.primary, 0.12)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) => Text('Bonjour, ${auth.user?['first_name'] ?? 'Utilisateur'}', style: AppTextStyles.headlineSmall.copyWith(fontSize: 16, color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 14)),
                    ]),
                    const SizedBox(height: 2),
                    Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: IconButton(icon: const Icon(Icons.notifications_none_rounded), color: AppColors.textPrimary, onPressed: () => Navigator.pushNamed(context, '/notifications')),
                  ),
                ]),
              ]),
            ),

            // GRILLE STATS
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 1.55,
                children: [
                  _buildStatCard(title: 'Solde net', value: _isFirstLoad ? '...' : '${_formatMoney(solde.toInt())} FCFA', icon: Icons.account_balance_wallet_rounded, isPrimary: true),
                  _buildStatCard(title: 'Dépenses totales', value: _isFirstLoad ? '...' : '${_formatMoney(_totalDepenses.toInt())} FCFA', icon: Icons.trending_down_rounded, accentColor: AppColors.error),
                  _buildStatCard(title: 'Cycles actifs', value: _isFirstLoad ? '...' : '$_cyclesActifs bandes', icon: Icons.egg_rounded, accentColor: AppColors.primary),
                  _buildStatCard(title: 'Prêts en cours', value: _isFirstLoad ? '...' : '${_formatMoney(_pretsRestants.toInt())} FCFA', icon: Icons.credit_card_rounded, accentColor: AppColors.warning),
                ],
              ),
            ),

            // GRAPHIQUE
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border.withOpacity(0.6)), boxShadow: AppShadows.shadowCard),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.show_chart_rounded, size: 16, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Text('Flux de tresorerie', style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ]),
                  Row(children: [_buildLegend('Gains', AppColors.success), const SizedBox(width: AppSpacing.md), _buildLegend('Depenses', AppColors.error)]),
                ]),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(height: 160, child: _isFirstLoad ? const Center(child: CircularProgressIndicator()) : _buildGraphique()),
              ]),
            ),
            const SizedBox(height: AppSpacing.xl),

            // TRANSACTIONS
            _buildSectionHeader(title: 'Dernieres transactions', icon: Icons.receipt_long_rounded),
            const SizedBox(height: AppSpacing.md),
            if (_isFirstLoad)
              const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()))
            else if (_dernieresTransactions.isEmpty)
              Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border)), child: Center(child: Text('Aucune transaction', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))))
            else
              ..._dernieresTransactions.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildTransactionCard(label: t['label'] as String, montant: '${t['type'] == 'vente' ? '+' : '-'} ${_formatMoney((t['montant'] as double).toInt())} FCFA', date: t['date'] as String, isVente: t['type'] == 'vente', icon: t['type'] == 'vente' ? Icons.sell_rounded : Icons.restaurant_rounded),
              )),

            const SizedBox(height: AppSpacing.xxl),
          ]),
        ),
      ),
    );
  }

  Widget _buildGraphique() {
    final maxY = (_totalVentes > _totalDepenses ? _totalVentes : _totalDepenses) * 1.3;
    if (maxY == 0) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.show_chart, size: 40, color: AppColors.textHint),
        const SizedBox(height: AppSpacing.sm),
        Text('Ajoutez des transactions\npour voir le graphique', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
      ]));
    }
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border.withOpacity(0.4), strokeWidth: 1, dashArray: [4, 4])),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (value, meta) => Text('${(value/1000).toInt()}k', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 10)))),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, getTitlesWidget: (value, meta) => Text(value == 0 ? 'Debut' : 'Fin', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 10)))),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(spots: [const FlSpot(0, 0), FlSpot(1, _totalVentes)], isCurved: true, curveSmoothness: 0.3, color: AppColors.success, dotData: FlDotData(show: true), barWidth: 3, belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.success.withOpacity(0.2), AppColors.success.withOpacity(0.0)]))),
        LineChartBarData(spots: [const FlSpot(0, 0), FlSpot(1, _totalDepenses)], isCurved: true, curveSmoothness: 0.3, color: AppColors.error, dotData: FlDotData(show: true), barWidth: 3, belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.error.withOpacity(0.15), AppColors.error.withOpacity(0.0)]))),
      ],
      minX: 0, maxX: 1, minY: 0, maxY: maxY,
    ));
  }

  String _formatMoney(int value) => value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]} ');

  Widget _buildSectionHeader({required String title, required IconData icon}) => Row(children: [
    Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 8),
    Text(title, style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildStatCard({required String title, required String value, required IconData icon, bool isPrimary = false, Color accentColor = AppColors.textPrimary}) {
    if (isPrimary) {
      return Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, _darken(AppColors.primary, 0.14)]), borderRadius: AppBorders.radiusLarge, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 18)),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: AppTextStyles.numberMedium.copyWith(fontSize: 18, color: Colors.white), overflow: TextOverflow.ellipsis),
            Text(title, style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.85))),
          ]));
    }
    return Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.radiusLarge, border: Border.all(color: AppColors.border.withOpacity(0.6)), boxShadow: AppShadows.shadowCard),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: accentColor, size: 18)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.numberMedium.copyWith(fontSize: 18, color: accentColor), overflow: TextOverflow.ellipsis),
          Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]));
  }

  Widget _buildLegend(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600))]),
  );

  Widget _buildTransactionCard({required String label, required String montant, required String date, required bool isVente, required IconData icon}) {
    final color = isVente ? AppColors.success : AppColors.error;
    return Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md), decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border.withOpacity(0.6)), boxShadow: AppShadows.shadowCard),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTextStyles.subtitleMedium.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: Text(montant, style: AppTextStyles.numberMedium.copyWith(color: color, fontSize: 14))),
        ]));
  }
}