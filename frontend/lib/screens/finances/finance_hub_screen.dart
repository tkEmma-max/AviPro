// lib/screens/finances/finance_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../services/api_service.dart';
import 'finance_loan_dashboard_screen.dart';

class FinanceHubScreen extends StatefulWidget {
  const FinanceHubScreen({super.key});

  @override
  State<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends State<FinanceHubScreen> {
  final _apiService = ApiService();
  String _selectedFilter = 'Toutes';
  bool _isLoading = true;

  List<Map<String, dynamic>> _allTransactions = [];
  double _totalVentes = 0;
  double _totalDepenses = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      // Charger dépenses
      final depensesResponse = await _apiService.get('depenses/');
      final ventesResponse = await _apiService.get('ventes/');

      final List<Map<String, dynamic>> transactions = [];

      if (depensesResponse.statusCode == 200) {
        final data = depensesResponse.data;
        if (data['results'] != null) {
          for (var d in data['results']) {
            transactions.add({
              'type': 'depense',
              'libelle': d['categorie_label'] ?? d['categorie'] ?? 'Dépense',
              'montant': double.tryParse(d['montant']?.toString() ?? '0') ?? 0,
              'date': d['date'] ?? '',
              'cycle': d['cycle_nom'] ?? 'Sans cycle',
            });
          }
        }
      }

      if (ventesResponse.statusCode == 200) {
        final data = ventesResponse.data;
        if (data['results'] != null) {
          for (var v in data['results']) {
            transactions.add({
              'type': 'vente',
              'libelle': v['type_label'] ?? v['type'] ?? 'Vente',
              'montant': double.tryParse(v['montant_total']?.toString() ?? '0') ?? 0,
              'date': v['date'] ?? '',
              'cycle': v['cycle_nom'] ?? 'Sans cycle',
            });
          }
        }
      }

      // Trier par date (plus récent en premier)
      transactions.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      final ventes = transactions
          .where((t) => t['type'] == 'vente')
          .fold<double>(0, (sum, t) => sum + (t['montant'] as double));
      final depenses = transactions
          .where((t) => t['type'] == 'depense')
          .fold<double>(0, (sum, t) => sum + (t['montant'] as double));

      if (mounted) {
        setState(() {
          _allTransactions = transactions;
          _totalVentes = ventes;
          _totalDepenses = depenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [FINANCE] Erreur chargement: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'Ventes') {
      return _allTransactions.where((t) => t['type'] == 'vente').toList();
    } else if (_selectedFilter == 'Dépenses') {
      return _allTransactions.where((t) => t['type'] == 'depense').toList();
    }
    return _allTransactions;
  }

  double get _soldeNet => _totalVentes - _totalDepenses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Finances', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontSize: 22)),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'depense':
                  Navigator.pushNamed(context, '/finance/depense').then((_) => _loadTransactions());
                  break;
                case 'vente':
                  Navigator.pushNamed(context, '/finance/vente').then((_) => _loadTransactions());
                  break;
                case 'pret':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FinanceLoanDashboardScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'depense', child: ListTile(leading: Icon(Icons.remove_circle_outline, color: AppColors.error), title: Text('Nouvelle dépense'), dense: true)),
              const PopupMenuItem(value: 'vente', child: ListTile(leading: Icon(Icons.add_circle_outline, color: AppColors.success), title: Text('Nouvelle vente'), dense: true)),
              const PopupMenuItem(value: 'pret', child: ListTile(leading: Icon(Icons.credit_card_outlined, color: AppColors.primary), title: Text('Gestion des prêts'), dense: true)),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ============================================================
          // HEADER - Carte de Synthèse
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Solde net
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_soldeNet.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (_soldeNet < 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: AppBorders.buttonRadius),
                        child: Text('Débit', style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withOpacity(0.8))),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Solde net global', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: AppSpacing.md),

                // Ligne Ventes / Dépenses
                Row(
                  children: [
                    Expanded(
                      child: Row(children: [
                        const Icon(Icons.trending_up, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${_totalVentes.toStringAsFixed(0)} FCFA', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    Expanded(
                      child: Row(children: [
                        const Icon(Icons.trending_down, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('${_totalDepenses.toStringAsFixed(0)} FCFA', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ============================================================
          // FILTRES
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: ['Toutes', 'Ventes', 'Dépenses'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: AppBorders.buttonRadius,
                      ),
                      child: Center(
                        child: Text(filter, style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ============================================================
          // LISTE DES TRANSACTIONS
          // ============================================================
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.lg),
                Text('Aucune transaction', style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary)),
              ]),
            )
                : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _filteredTransactions.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final t = _filteredTransactions[index];
                  final isVente = t['type'] == 'vente';
                  final color = isVente ? AppColors.success : AppColors.error;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorders.cardRadius,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.shadowCard,
                    ),
                    child: Row(
                      children: [
                        Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: AppBorders.radiusSmall)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t['libelle'] as String, style: AppTextStyles.subtitleMedium),
                            Text('${t['date']} • ${t['cycle']}', style: AppTextStyles.bodySmall),
                          ]),
                        ),
                        Text(
                          '${isVente ? '+' : '-'} ${(t['montant'] as double).toStringAsFixed(0)} FCFA',
                          style: AppTextStyles.numberMedium.copyWith(color: color, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}