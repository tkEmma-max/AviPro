// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/poulailler_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_shadows.dart';
import 'poulaillers/poulailler_list_screen.dart';
import 'cycles/cycle_list_screen.dart';
import 'finances/finance_hub_screen.dart';
import 'profile_settings_screen.dart';
import 'package:provider/provider.dart';

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
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textHint,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.house_outlined),
                activeIcon: Icon(Icons.house_rounded),
                label: 'Poulaillers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timeline_outlined),
                activeIcon: Icon(Icons.timeline_rounded),
                label: 'Cycles',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Finances',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CONTENU DU DASHBOARD
// ============================================================
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  bool _isLoading = false;

  final List<double> gainsData = [0, 15000, 28000, 42000, 38000, 55000, 72000, 68000, 85000, 92000];
  final List<double> depensesData = [0, 8000, 12000, 25000, 22000, 35000, 40000, 48000, 52000, 60000];
  final List<String> jours = ['1', '5', '10', '15', '20', '25', '30'];

  // Nuance plus foncée de la couleur primaire, utile pour les dégradés
  Color _darken(Color color, [double amount = .15]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final solde = 250000;
    final totalDepenses = 85000;
    final cyclesActifs = 2;
    final pretsRestants = 150000;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() => _isLoading = true);
          final provider = context.read<PoulaillerProvider>();
          await provider.refreshPoulaillers();  // <--- AJOUTER CETTE LIGNE
          setState(() => _isLoading = false);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // HEADER
              // ============================================================
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            _darken(AppColors.primary, 0.12),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'JD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final firstName = authProvider.user?['first_name'] ?? 'Utilisateur';
                                  return Text(
                                    'Bonjour, $firstName',
                                    style: AppTextStyles.headlineSmall.copyWith(
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              const Text('👋', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                                .format(DateTime.now()),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_rounded),
                            color: AppColors.textPrimary,
                            onPressed: () {
                              Navigator.pushNamed(context, '/notifications');
                            },
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ============================================================
              // GRILLE STATS
              // ============================================================
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.55,
                  children: [
                    _buildStatCard(
                      title: 'Solde net',
                      value: '${_formatMoney(solde)} FCFA',
                      icon: Icons.account_balance_wallet_rounded,
                      isPrimary: true,
                    ),
                    _buildStatCard(
                      title: 'Dépenses totales',
                      value: '${_formatMoney(totalDepenses)} FCFA',
                      icon: Icons.trending_down_rounded,
                      accentColor: AppColors.error,
                    ),
                    _buildStatCard(
                      title: 'Cycles actifs',
                      value: '$cyclesActifs bandes',
                      icon: Icons.egg_rounded,
                      accentColor: AppColors.primary,
                    ),
                    _buildStatCard(
                      title: 'Prêts en cours',
                      value: '${_formatMoney(pretsRestants)} FCFA',
                      icon: Icons.credit_card_rounded,
                      accentColor: AppColors.warning,
                    ),
                  ],
                ),
              ),

              // ============================================================
              // GRAPHIQUE
              // ============================================================
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(color: AppColors.border.withOpacity(0.6), width: 1),
                  boxShadow: AppShadows.shadowCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.show_chart_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Flux de trésorerie (30j)',
                              style: AppTextStyles.subtitleLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildLegend('Gains', AppColors.success),
                            const SizedBox(width: AppSpacing.md),
                            _buildLegend('Dépenses', AppColors.error),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 50000,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: AppColors.border.withOpacity(0.4),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  final style = TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textHint,
                                  );
                                  if (value == 0) return Text('0', style: style);
                                  if (value == 50000) return Text('50k', style: style);
                                  if (value == 100000) return Text('100k', style: style);
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 25,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < jours.length) {
                                    return Text(
                                      jours[index],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                gainsData.length,
                                    (index) => FlSpot(
                                  index.toDouble(),
                                  gainsData[index].toDouble(),
                                ),
                              ),
                              isCurved: true,
                              curveSmoothness: 0.3,
                              color: AppColors.success,
                              dotData: FlDotData(show: false),
                              barWidth: 2.5,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.success.withOpacity(0.18),
                                    AppColors.success.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                            LineChartBarData(
                              spots: List.generate(
                                depensesData.length,
                                    (index) => FlSpot(
                                  index.toDouble(),
                                  depensesData[index].toDouble(),
                                ),
                              ),
                              isCurved: true,
                              curveSmoothness: 0.3,
                              color: AppColors.error,
                              dotData: FlDotData(show: false),
                              barWidth: 2.5,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.error.withOpacity(0.14),
                                    AppColors.error.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          minX: 0,
                          maxX: gainsData.length.toDouble() - 1,
                          minY: 0,
                          maxY: 120000,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ============================================================
              // VENTES ET DÉPENSES RÉCENTES
              // ============================================================
              _buildSectionHeader(
                title: 'Dernières transactions',
                icon: Icons.receipt_long_rounded,
                onSeeAll: () {},
              ),
              const SizedBox(height: AppSpacing.md),

              _buildTransactionCard(
                label: 'Vente de poulets',
                montant: '+ 250 000 FCFA',
                date: 'Aujourd\'hui',
                isVente: true,
                icon: Icons.sell_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTransactionCard(
                label: 'Aliment pondeuse',
                montant: '- 85 000 FCFA',
                date: 'Hier',
                isVente: false,
                icon: Icons.restaurant_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildTransactionCard(
                label: "Vente d'œufs",
                montant: '+ 120 000 FCFA',
                date: 'Il y a 2 jours',
                isVente: true,
                icon: Icons.egg_alt_rounded,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ============================================================
              // ÉCHÉANCES PRIORITAIRES
              // ============================================================
              _buildSectionHeader(
                title: 'Échéances prioritaires',
                icon: Icons.event_note_rounded,
                onSeeAll: () {},
              ),
              const SizedBox(height: AppSpacing.md),

              _buildEcheanceCard(
                preteur: 'Crédit Agricole',
                date: '2026-07-10',
                montant: 45000,
                statut: 'urgent',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildEcheanceCard(
                preteur: 'Tontine Mme Koffi',
                date: '2026-07-18',
                montant: 25000,
                statut: 'normal',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildEcheanceCard(
                preteur: 'Frère Jean',
                date: '2026-07-25',
                montant: 12000,
                statut: 'normal',
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]} ',
    );
  }

  // ============================================================
  // EN-TÊTE DE SECTION (titre + icône + "Voir tout")
  // ============================================================
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.subtitleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Voir tout',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CARTE STATISTIQUE
  // ============================================================
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    bool isPrimary = false,
    Color accentColor = Colors.black,
  }) {
    if (isPrimary) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              _darken(AppColors.primary, 0.14),
            ],
          ),
          borderRadius: AppBorders.radiusLarge,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorders.radiusLarge,
        border: Border.all(
          color: AppColors.border.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: AppShadows.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LÉGENDE DU GRAPHIQUE
  // ============================================================
  Widget _buildLegend(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE TRANSACTION
  // ============================================================
  Widget _buildTransactionCard({
    required String label,
    required String montant,
    required String date,
    required bool isVente,
    required IconData icon,
  }) {
    final color = isVente ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorders.cardRadius,
        border: Border.all(
          color: AppColors.border.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: AppShadows.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.subtitleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              montant,
              style: AppTextStyles.numberMedium.copyWith(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTE ÉCHÉANCE (avec bande d'accent colorée)
  // ============================================================
  Widget _buildEcheanceCard({
    required String preteur,
    required String date,
    required int montant,
    required String statut,
  }) {
    final isUrgent = statut == 'urgent';
    final color = isUrgent ? AppColors.error : AppColors.warning;
    final bgColor = isUrgent
        ? AppColors.error.withOpacity(0.08)
        : AppColors.warning.withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorders.cardRadius,
        border: Border.all(
          color: isUrgent
              ? AppColors.error.withOpacity(0.3)
              : AppColors.border.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: AppShadows.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: AppBorders.cardRadius,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: AppBorders.buttonRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUrgent
                                  ? Icons.warning_rounded
                                  : Icons.schedule_rounded,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isUrgent ? 'Urgent' : 'À venir',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preteur,
                              style: AppTextStyles.subtitleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Échéance : $date',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_formatMoney(montant)} FCFA',
                        style: AppTextStyles.numberSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}