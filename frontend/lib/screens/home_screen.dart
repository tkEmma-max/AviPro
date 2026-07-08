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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.house_outlined),
            label: 'Poulaillers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            label: 'Cycles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_outlined),
            label: 'Finances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final poulaillerProvider = context.watch<PoulaillerProvider>();

    final List<double> gainsData = [0, 15000, 28000, 42000, 38000, 55000, 72000, 68000, 85000, 92000];
    final List<double> depensesData = [0, 8000, 12000, 25000, 22000, 35000, 40000, 48000, 52000, 60000];
    final List<String> jours = ['1', '5', '10', '15', '20', '25', '30'];

    final solde = 250000;
    final totalDepenses = 85000;
    final cyclesActifs = 2;
    final pretsRestants = 150000;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await Future.delayed(const Duration(seconds: 1));
          setState(() => _isLoading = false);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'JD',
                          style: TextStyle(
                            color: AppColors.primary,
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
                          Text(
                            'Bonjour, Jean',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
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
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          color: AppColors.textPrimary,
                          onPressed: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
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

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard(
                      title: 'Solde net',
                      value: '$solde FCFA',
                      icon: Icons.account_balance_wallet,
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                    ),
                    _buildStatCard(
                      title: 'Dépenses totales',
                      value: '$totalDepenses FCFA',
                      icon: Icons.trending_down,
                      backgroundColor: Colors.white,
                      textColor: AppColors.error,
                      borderColor: AppColors.border,
                      valueColor: AppColors.error,
                    ),
                    _buildStatCard(
                      title: 'Cycles Actifs',
                      value: '$cyclesActifs bandes',
                      icon: Icons.timeline,
                      backgroundColor: Colors.white,
                      textColor: AppColors.primary,
                      borderColor: AppColors.border,
                    ),
                    _buildStatCard(
                      title: 'Prêts en cours',
                      value: '$pretsRestants FCFA',
                      icon: Icons.credit_card,
                      backgroundColor: Colors.white,
                      textColor: AppColors.primary,
                      borderColor: AppColors.border,
                      valueColor: AppColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Graphique
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: AppShadows.shadowCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Flux de trésorerie (30j)',
                          style: AppTextStyles.subtitleLarge.copyWith(
                            color: AppColors.primary,
                          ),
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
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('0');
                                  if (value == 50000) return const Text('50k');
                                  if (value == 100000) return const Text('100k');
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
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < jours.length) {
                                    return Text(
                                      jours[index],
                                      style: AppTextStyles.labelSmall,
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
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.success.withOpacity(0.1),
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
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.error.withOpacity(0.1),
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
              const SizedBox(height: AppSpacing.lg),

              // Échéances
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Échéances prioritaires',
                      style: AppTextStyles.subtitleLarge.copyWith(
                        color: AppColors.primary,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppBorders.radiusLarge,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
        boxShadow: backgroundColor == Colors.white
            ? AppShadows.shadowCard
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: textColor.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorders.cardRadius,
        border: Border.all(
          color: isUrgent ? AppColors.error : AppColors.border,
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppBorders.radiusSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preteur,
                  style: AppTextStyles.subtitleMedium,
                ),
                Text(
                  'Échéance: $date',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$montant FCFA',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppBorders.buttonRadius,
                ),
                child: Text(
                  isUrgent ? 'Urgent' : 'À venir',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}