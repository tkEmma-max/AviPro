// lib/screens/rapports/rapport_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../providers/rapport_provider.dart';
import '../../models/rapport.dart';
import 'rapport_detail_screen.dart';

class RapportListScreen extends StatefulWidget {
  const RapportListScreen({super.key});

  @override
  State<RapportListScreen> createState() => _RapportListScreenState();
}

class _RapportListScreenState extends State<RapportListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RapportProvider>().refreshRapports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RapportProvider>();
    final rapports = provider.rapports;

    if (provider.isLoading && rapports.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
          title: const Text('Rapports de suivi', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Rapports de suivi', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<RapportProvider>().refreshRapports()),
        ],
      ),
      body: rapports.isEmpty
          ? Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.assessment_outlined, size: 60, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.lg),
          Text('Aucun rapport de suivi', style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Ajoutez votre premier rapport', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
        ]),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: rapports.length,
        itemBuilder: (context, index) {
          final rapport = rapports[index];
          return _buildRapportCard(rapport);
        },
      ),
    );
  }

  Widget _buildRapportCard(Rapport rapport) {
    final hasMaladie = rapport.maladieObservee != null && rapport.maladieObservee!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => RapportDetailScreen(rapport: rapport)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: AppBorders.cardRadius,
          border: Border(left: BorderSide(color: hasMaladie ? AppColors.error : AppColors.success, width: 4)),
          boxShadow: AppShadows.shadowCard,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${rapport.periodeDebut.day}/${rapport.periodeDebut.month} - ${rapport.periodeFin.day}/${rapport.periodeFin.month}', style: AppTextStyles.subtitleLarge)),
            if (hasMaladie)
              Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: AppBorders.buttonRadius), child: Text('⚠️ Maladie', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Row(children: [
            Text('Aliment: ${rapport.alimentConsomme} kg', style: AppTextStyles.bodySmall),
            const SizedBox(width: AppSpacing.md),
            Text('Eau: ${rapport.eauConsommee} L', style: AppTextStyles.bodySmall),
          ]),
          if (rapport.cycleNom != null)
            Text('Cycle: ${rapport.cycleNom}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}