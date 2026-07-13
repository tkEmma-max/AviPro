// lib/screens/finances/pret_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../providers/pret_provider.dart';
import '../../models/pret.dart';

class PretListScreen extends StatefulWidget {
  const PretListScreen({super.key});

  @override
  State<PretListScreen> createState() => _PretListScreenState();
}

class _PretListScreenState extends State<PretListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PretProvider>().refreshPrets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PretProvider>();
    final prets = provider.prets;

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
          'Mes prêts',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PretProvider>().refreshPrets();
            },
          ),
        ],
      ),
      body: prets.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_outlined, size: 60, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucun prêt enregistré',
              style: AppTextStyles.headline4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ajoutez votre premier prêt',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: prets.length,
        itemBuilder: (context, index) {
          final pret = prets[index];
          return _buildPretCard(pret);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Page de création de prêt
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPretCard(Pret pret) {
    final isRembourse = pret.isRembourse;
    final color = isRembourse ? AppColors.success : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
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
            children: [
              Expanded(
                child: Text(
                  pret.preteur,
                  style: AppTextStyles.subtitleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppBorders.buttonRadius,
                ),
                child: Text(
                  isRembourse ? 'Remboursé' : 'En cours',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${pret.montantTotal.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                'Reste: ${pret.montantRestant.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: pret.montantRestant > 0 ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}