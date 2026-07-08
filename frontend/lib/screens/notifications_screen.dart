// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_borders.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'Toutes';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'Prêts',
      'message': 'Échéance du prêt Crédit Agricole dans 3 jours (45 000 FCFA)',
      'date': '2026-07-08T10:30:00',
      'lu': false,
      'critique': true,
      'route': '/finance/pret',
      'routeArgs': {'id': '1'},
    },
    {
      'id': '2',
      'type': 'Densité',
      'message': 'Poulailler Nord: densité critique (12 sujets/m²)',
      'date': '2026-07-07T14:20:00',
      'lu': false,
      'critique': true,
      'route': '/poulailler',
      'routeArgs': {'id': '1'},
    },
    {
      'id': '3',
      'type': 'Consommation',
      'message': "Baisse de 25% de l'eau consommée sur le cycle Lot Juillet",
      'date': '2026-07-07T09:15:00',
      'lu': true,
      'critique': false,
      'route': '/cycle',
      'routeArgs': {'id': '1'},
    },
    {
      'id': '4',
      'type': 'Prêts',
      'message': 'Tontine Mme Koffi: rappel de remboursement (50 000 FCFA)',
      'date': '2026-07-06T16:45:00',
      'lu': true,
      'critique': false,
      'route': '/finance/pret',
      'routeArgs': {'id': '2'},
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    var list = _notifications;
    if (_selectedFilter != 'Toutes') {
      list = list.where((n) => n['type'] == _selectedFilter).toList();
    }
    // Trier: critiques en premier
    list.sort((a, b) {
      if (a['critique'] && !b['critique']) return -1;
      if (b['critique'] && !a['critique']) return 1;
      return 0;
    });
    return list;
  }

  int get _nbNonLues {
    return _notifications.where((n) => n['lu'] == false).length;
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Prêts':
        return Icons.credit_card_outlined;
      case 'Densité':
        return Icons.square_foot;
      case 'Consommation':
        return Icons.water_drop;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Prêts':
        return AppColors.primary;
      case 'Densité':
        return AppColors.warning;
      case 'Consommation':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_nbNonLues > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n['lu'] = true;
                  }
                });
              },
              child: Text(
                'Tout marquer comme lu',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ============================================================
          // FILTRES
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Toutes', 'Prêts', 'Densité', 'Consommation'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ActionChip(
                    label: Text(filter),
                    onPressed: () => setState(() => _selectedFilter = filter),
                    backgroundColor: isSelected ? AppColors.primary : Colors.white,
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ============================================================
          // LISTE DES NOTIFICATIONS
          // ============================================================
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 60,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Vous êtes à jour !',
                          style: AppTextStyles.headline4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Aucune notification ou alerte pour le moment.',
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
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final n = _filteredNotifications[index];
                      return _buildNotificationCard(n);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isLu = notification['lu'] == true;
    final isCritique = notification['critique'] == true;
    final icon = _getTypeIcon(notification['type']);
    final color = _getTypeColor(notification['type']);

    return GestureDetector(
      onTap: () {
        // Marquer comme lu
        setState(() {
          notification['lu'] = true;
        });
        // TODO: Navigation contextuelle
        // if (notification['route'] != null) {
        //   Navigator.pushNamed(context, notification['route']);
        // }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isLu ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: AppBorders.cardRadius,
          border: Border(
            left: BorderSide(
              color: isCritique ? AppColors.error : color,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['message'],
                    style: isLu
                        ? AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          )
                        : AppTextStyles.subtitleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _getRelativeTime(notification['date']),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      if (!isLu) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCritique ? AppColors.error : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isCritique)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: AppBorders.buttonRadius,
                ),
                child: Text(
                  'URGENT',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRelativeTime(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else if (diff.inHours > 0) {
      return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
    } else if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}