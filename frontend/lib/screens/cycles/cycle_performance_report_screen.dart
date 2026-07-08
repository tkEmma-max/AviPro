// lib/screens/cycles/cycle_performance_report_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class CyclePerformanceReportScreen extends StatelessWidget {
  final Map<String, dynamic> cycle;

  const CyclePerformanceReportScreen({
    super.key,
    required this.cycle,
  });

  @override
  Widget build(BuildContext context) {
    print('🟢 BUILD DU RAPPORT DE PERFORMANCE');
    print('🟢 Cycle reçu: ${cycle}');
    final mortalite = (cycle['mortalite'] ?? 5.0).toDouble();
    Color mortaliteColor;
    String mortaliteLabel;
    String mortaliteEmoji;

    if (mortalite < 5) {
      mortaliteColor = AppColors.success;
      mortaliteLabel = 'Excellent';
      mortaliteEmoji = '🟢';
    } else if (mortalite < 10) {
      mortaliteColor = AppColors.warning;
      mortaliteLabel = 'Alerte';
      mortaliteEmoji = '🟡';
    } else {
      mortaliteColor = AppColors.error;
      mortaliteLabel = 'Critique';
      mortaliteEmoji = '🔴';
    }

    // Données financières simulées
    final chiffreAffaires = 420000;
    final coutPoussins = 85000;
    final coutAlimentation = 120000;
    final coutSoins = 45000;
    final beneficeNet = chiffreAffaires - coutPoussins - coutAlimentation - coutSoins;
    final isBeneficiaire = beneficeNet > 0;

    // Données de croissance (poids en grammes)
    final List<double> poidsTheorique = [0, 150, 350, 600, 900, 1200, 1600, 2000, 2400];
    final List<double> poidsReel = [0, 140, 330, 580, 850, 1150, 1500, 1900, 2300];
    final List<String> semaines = ['0', '1', '2', '3', '4', '5', '6', '7', '8'];

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
          'Rapport de performance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // ============================================================
            // HEADER : Taux de mortalité
            // ============================================================
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppBorders.cardRadius,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppShadows.shadowCard,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: mortaliteColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        mortaliteEmoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Taux de mortalité',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${mortalite.toStringAsFixed(1)}%',
                          style: AppTextStyles.numberLarge.copyWith(
                            fontSize: 28,
                            color: mortaliteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: mortaliteColor.withOpacity(0.1),
                      borderRadius: AppBorders.buttonRadius,
                      border: Border.all(
                        color: mortaliteColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      mortaliteLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: mortaliteColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ============================================================
            // BILAN COMPTABLE (Ticket de caisse)
            // ============================================================
            const Text(
              'Bilan comptable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppBorders.cardRadius,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppShadows.shadowCard,
              ),
              child: Column(
                children: [
                  _buildBilanRow('Chiffre d\'affaires', chiffreAffaires,
                      AppColors.success, true),
                  const Divider(height: AppSpacing.md),
                  _buildBilanRow('Coût initial (poussins)', coutPoussins,
                      AppColors.error, false),
                  _buildBilanRow('Coût alimentation', coutAlimentation,
                      AppColors.error, false),
                  _buildBilanRow('Coût soins (vaccins)', coutSoins,
                      AppColors.error, false),
                  const Divider(height: AppSpacing.md),
                  _buildBilanRow(
                    'Bénéfice net du cycle',
                    beneficeNet,
                    isBeneficiaire ? AppColors.success : AppColors.error,
                    isBeneficiaire,
                    true, // isBold
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ============================================================
            // GRAPHIQUE DE CROISSANCE
            // ============================================================
            const Text(
              'Croissance des sujets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
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
                      _buildGraphLegend('Poids théorique', AppColors.primary),
                      _buildGraphLegend('Poids réel', AppColors.success),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 500,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('0');
                                if (value == 500) return const Text('500g');
                                if (value == 1000) return const Text('1kg');
                                if (value == 1500) return const Text('1.5kg');
                                if (value == 2000) return const Text('2kg');
                                if (value == 2500) return const Text('2.5kg');
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
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < semaines.length) {
                                  return Text(
                                    semaines[index],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Courbe théorique
                          LineChartBarData(
                            spots: List.generate(
                              poidsTheorique.length,
                              (index) => FlSpot(
                                index.toDouble(),
                                poidsTheorique[index].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: AppColors.primary,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                            dashArray: [8, 4],
                          ),
                          // Courbe réelle
                          LineChartBarData(
                            spots: List.generate(
                              poidsReel.length,
                              (index) => FlSpot(
                                index.toDouble(),
                                poidsReel[index].toDouble(),
                              ),
                            ),
                            isCurved: true,
                            color: AppColors.success,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.success.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: poidsTheorique.length.toDouble() - 1,
                        minY: 0,
                        maxY: 2500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ============================================================
            // BOUTON EXPORTER
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Exporter en PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export PDF en cours de développement'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 20),
                label: const Text(
                  'EXPORTER LE RAPPORT PDF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.buttonRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppBorders.radiusSmall,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBilanRow(
    String label,
    int montant,
    Color color,
    bool isPositive, [
    bool isBold = false,
  ]) {
    final prefix = isPositive ? '+' : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTextStyles.subtitleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  )
                : AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
          ),
          Text(
            '$prefix ${montant.toString()} FCFA',
            style: isBold
                ? AppTextStyles.numberMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  )
                : AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ],
      ),
    );
  }
}