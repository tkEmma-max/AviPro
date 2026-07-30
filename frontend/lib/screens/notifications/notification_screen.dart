// lib/screens/notifications/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  IconData _getIcone(String type) {
    switch (type) {
      case 'ECHEANCE_J7':
      case 'ECHEANCE_J3':
      case 'ECHEANCE_J1':
      case 'ECHEANCE_JOURJ':
      case 'ECHEANCE_RETARD':
        return AppIcons.echeance;
      case 'DENSITE':
        return AppIcons.densite;
      case 'CONSOMMATION':
        return AppIcons.mangeoire;
      case 'RAPPEL_RAPPORT':
        return AppIcons.rapport;
      case 'FIN_CYCLE':
        return AppIcons.fin;
      case 'PRET_FLEXIBLE':
        return AppIcons.pret;
      case 'SUGGESTION':
        return AppIcons.suggestion;
      default:
        return AppIcons.notification;
    }
  }

  Color _getCouleur(String type) {
    switch (type) {
      case 'ECHEANCE_JOURJ':
      case 'ECHEANCE_RETARD':
        return AppColors.error;
      case 'ECHEANCE_J7':
      case 'ECHEANCE_J3':
      case 'ECHEANCE_J1':
      case 'DENSITE':
      case 'CONSOMMATION':
        return AppColors.warning;
      case 'FIN_CYCLE':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.nbNonLues > 0) {
                return TextButton(
                  onPressed: () => provider.marquerToutesLues(),
                  child: Text(
                    'Tout lu',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.notification, size: 60, color: AppColors.textHint.withOpacity(0.5)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Aucune notification',
                    style: AppTextStyles.headline4.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Les alertes et rappels apparaîtront ici.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                final couleur = _getCouleur(notif.type);
                final icone = _getIcone(notif.type);
                final dateFormatted = DateFormat('dd/MM/yy • HH:mm', 'fr').format(notif.dateCreation);

                return GestureDetector(
                  onTap: () {
                    if (!notif.estLue) {
                      provider.marquerLue(notif.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: notif.estLue ? Colors.white : AppColors.primary.withOpacity(0.03),
                      borderRadius: AppBorders.cardRadius,
                      border: Border.all(
                        color: notif.estLue ? AppColors.border : couleur.withOpacity(0.3),
                      ),
                      boxShadow: AppShadows.shadowCard,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icône
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: couleur.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icone, size: 20, color: couleur),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Contenu
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.titre,
                                      style: AppTextStyles.subtitleMedium.copyWith(
                                        fontWeight: notif.estLue ? FontWeight.w400 : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!notif.estLue)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                notif.message,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                dateFormatted,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}