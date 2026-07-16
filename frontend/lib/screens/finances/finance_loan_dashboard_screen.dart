// lib/screens/finances/finance_loan_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../providers/pret_provider.dart';
import 'finance_loan_create_screen.dart';
import 'finance_loan_detail_screen.dart';

class FinanceLoanDashboardScreen extends StatefulWidget {
  const FinanceLoanDashboardScreen({super.key});

  @override
  State<FinanceLoanDashboardScreen> createState() => _FinanceLoanDashboardScreenState();
}

class _FinanceLoanDashboardScreenState extends State<FinanceLoanDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PretProvider>().refreshPrets();
    });
  }

  void _ouvrirCreationPret() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceLoanCreateScreen()))
        .then((_) => context.read<PretProvider>().refreshPrets());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PretProvider>();
    final prets = provider.prets;
    final pretsActifs = prets.where((p) => !p.isRembourse).toList();
    final totalRestant = pretsActifs.fold<double>(0, (s, p) => s + p.montantRestant);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Mes prêts', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28), onPressed: _ouvrirCreationPret, tooltip: 'Nouveau prêt'),
        ],
      ),
      body: prets.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.credit_card_outlined, size: 80, color: AppColors.textHint),
        const SizedBox(height: AppSpacing.lg),
        Text('Aucun prêt enregistré', style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Text('Ajoutez votre premier prêt', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(onPressed: _ouvrirCreationPret, icon: const Icon(Icons.add), label: const Text('NOUVEAU PRÊT'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14))),
      ]))
          : Column(children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppBorders.cardRadius),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total restant dû', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
            Text('${totalRestant.toInt()} FCFA', style: AppTextStyles.numberLarge.copyWith(color: Colors.white, fontSize: 28)),
            Text('${pretsActifs.length} prêt(s) actif(s)', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: prets.length,
            itemBuilder: (context, index) {
              final p = prets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.isRembourse ? AppColors.success : AppColors.primary,
                    child: Icon(p.isRembourse ? Icons.check : Icons.pending, color: Colors.white),
                  ),
                  title: Text(p.preteur, style: AppTextStyles.subtitleMedium),
                  subtitle: Text('${p.montantRestant.toInt()} FCFA restants • ${p.typePreteur}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FinanceLoanDetailScreen(pret: p)),
                    ).then((_) => context.read<PretProvider>().refreshPrets());
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}