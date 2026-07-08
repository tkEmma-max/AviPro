// lib/screens/finances/finance_loan_detail_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';

class FinanceLoanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pret;

  const FinanceLoanDetailScreen({
    super.key,
    required this.pret,
  });

  @override
  State<FinanceLoanDetailScreen> createState() =>
      _FinanceLoanDetailScreenState();
}

class _FinanceLoanDetailScreenState extends State<FinanceLoanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Données simulées
  final List<Map<String, dynamic>> _echeances = [
    {'date': '2026-07-20', 'montant': 85000, 'statut': 'Payée'},
    {'date': '2026-07-05', 'montant': 85000, 'statut': 'En retard'},
    {'date': '2026-06-20', 'montant': 85000, 'statut': 'Payée'},
  ];

  final List<Map<String, dynamic>> _historique = [
    {'date': '2026-06-22', 'montant': 85000, 'source': 'Vente poulets'},
    {'date': '2026-06-10', 'montant': 50000, 'source': 'Manuel'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalRembourse {
    return _historique.fold(0, (sum, h) => sum + h['montant']);
  }

  double get _montantTotal => widget.pret['montant_total'] ?? 0;
  double get _montantRestant => widget.pret['montant_restant'] ?? 0;
  double get _progression => _montantTotal > 0
      ? (_totalRembourse / _montantTotal) * 100
      : 0;

  bool get _estRembourse => _montantRestant <= 0;

  @override
  Widget build(BuildContext context) {
    final pret = widget.pret;
    final isFlexible = pret['mode'] == 'Flexible';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails du prêt',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ============================================================
          // HEADER - Fiche d'identité & Jauge (30%)
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppBorders.cardRadius,
              boxShadow: AppShadows.shadowMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pret['preteur'] ?? 'Prêteur',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pret['type'] ?? 'N/A'} • ${pret['taux'] ?? 0}% • ${pret['date_deblocage'] ?? 'N/A'}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_estRembourse)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: AppBorders.buttonRadius,
                        ),
                        child: Text(
                          'REMBOURSÉ',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restant dû',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '${_montantRestant.toStringAsFixed(0)} FCFA',
                            style: AppTextStyles.numberLarge.copyWith(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_progression.toStringAsFixed(0)}%',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'remboursé',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: _progression / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: Colors.white,
                  minHeight: 6,
                  borderRadius: AppBorders.buttonRadius,
                ),
              ],
            ),
          ),

          // ============================================================
          // BODY - TabBar (55%)
          // ============================================================
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Échéancier'),
                    Tab(text: 'Historique'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet 1 : Échéancier
                      isFlexible
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: AppColors.textHint,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'Prêt Flexible',
                                      style: AppTextStyles.headline4.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Ce financement ne dispose d\'aucun échéancier imposé. Vous remboursez librement selon votre trésorerie.',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              itemCount: _echeances.length,
                              itemBuilder: (context, index) {
                                final e = _echeances[index];
                                return _buildEcheanceCard(e);
                              },
                            ),

                      // Onglet 2 : Historique
                      _historique.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Aucun remboursement enregistré',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              itemCount: _historique.length,
                              itemBuilder: (context, index) {
                                final h = _historique[index];
                                return _buildHistoriqueCard(h);
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // ============================================================
      // FOOTER (15%)
      // ============================================================
      bottomNavigationBar: _estRembourse
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/finance/echeance/create',
                          arguments: widget.pret,
                        );
                      },
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('+ Échéance'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/finance/remboursement/create',
                          arguments: widget.pret,
                        );
                      },
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Remboursement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEcheanceCard(Map<String, dynamic> echeance) {
    final statut = echeance['statut'];
    Color bgColor;
    Color textColor;

    switch (statut) {
      case 'Payée':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'En retard':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      default:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorders.cardRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.shadowCard,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Échéance: ${echeance['date']}',
                  style: AppTextStyles.subtitleMedium,
                ),
                Text(
                  '${echeance['montant']} FCFA',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppBorders.buttonRadius,
            ),
            child: Text(
              statut,
              style: AppTextStyles.labelSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueCard(Map<String, dynamic> historique) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorders.cardRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: AppBorders.radiusSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${historique['montant']} FCFA',
                  style: AppTextStyles.subtitleMedium,
                ),
                Text(
                  '${historique['date']} • ${historique['source']}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}