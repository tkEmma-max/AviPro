// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AviPro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synchronisation en cours...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Text(
              'Tableau de bord',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bienvenue sur AviPro',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Statistiques
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Poulaillers',
                    value: '12',
                    icon: Icons.house_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    title: 'Cycles actifs',
                    value: '3',
                    icon: Icons.timeline_outlined,
                    color: AppColors.statusBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Bénéfice',
                    value: '250 000 FCFA',
                    icon: Icons.trending_up,
                    color: AppColors.statusGreen,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    title: 'Prêts en cours',
                    value: '2',
                    icon: Icons.credit_card_outlined,
                    color: AppColors.statusRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Actions rapides
            Text(
              'Actions rapides',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                QuickActionCard(
                  label: 'Nouveau cycle',
                  icon: Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                QuickActionCard(
                  label: 'Ajouter dépense',
                  icon: Icons.money_off_outlined,
                  color: AppColors.statusRed,
                ),
                QuickActionCard(
                  label: 'Enregistrer vente',
                  icon: Icons.payments_outlined,
                  color: AppColors.statusBlue,
                ),
                QuickActionCard(
                  label: 'Rapport suivi',
                  icon: Icons.assessment_outlined,
                  color: AppColors.statusOrange,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.house_outlined), label: 'Poulaillers'),
          BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), label: 'Cycles'),
          BottomNavigationBarItem(icon: Icon(Icons.money_outlined), label: 'Finances'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}