// lib/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_shadows.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;

  // Paramètres
  int _frequenceRappel = 7;
  bool _rappelActif = true;
  bool _notifEcheance = true;
  bool _notifDensite = true;
  bool _notifConsommation = true;
  bool _notifFinCycle = true;
  String _devise = 'FCFA';

  @override
  void initState() {
    super.initState();
    _loadParametres();
  }

  Future<void> _loadParametres() async {
    try {
      final response = await _apiService.get('users/parametres/');
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _frequenceRappel = data['frequence_rappel_rapport'] ?? 7;
          _rappelActif = data['rappel_rapport_actif'] ?? true;
          _notifEcheance = data['notif_echeance_pret'] ?? true;
          _notifDensite = data['notif_densite'] ?? true;
          _notifConsommation = data['notif_consommation'] ?? true;
          _notifFinCycle = data['notif_fin_cycle'] ?? true;
          _devise = data['devise'] ?? 'FCFA';
        });
      }
    } catch (e) {
      print('Erreur chargement paramètres: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveParametres() async {
    try {
      await _apiService.patch('users/parametres/', data: {
        'frequence_rappel_rapport': _frequenceRappel,
        'rappel_rapport_actif': _rappelActif,
        'notif_echeance_pret': _notifEcheance,
        'notif_densite': _notifDensite,
        'notif_consommation': _notifConsommation,
        'notif_fin_cycle': _notifFinCycle,
        'devise': _devise,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres enregistrés'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      print('Erreur sauvegarde paramètres: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Revenir au dashboard
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: const Text('Paramètres', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.md),

          // PROFIL
          _buildSectionTitle('Profil'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Row(children: [
              CircleAvatar(radius: 30, backgroundColor: AppColors.primary, child: Text((user?['first_name'] ?? '?')[0].toUpperCase() ?? '?', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?['full_name'] ?? 'Utilisateur', style: AppTextStyles.subtitleLarge),
                Text(user?['email'] ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ])),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // RAPPORTS
          _buildSectionTitle('Rapports de suivi'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Column(children: [
              SwitchListTile(
                title: Text('Rappels de rapports', style: AppTextStyles.subtitleMedium),
                subtitle: Text('Recevoir des rappels pour soumettre un rapport', style: AppTextStyles.bodySmall),
                value: _rappelActif, onChanged: (v) => setState(() { _rappelActif = v; _saveParametres(); }),
                activeColor: AppColors.primary, contentPadding: EdgeInsets.zero,
              ),
              if (_rappelActif) ...[
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Fréquence de rappel', style: AppTextStyles.bodyMedium),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary), onPressed: () { if (_frequenceRappel > 1) setState(() => _frequenceRappel--); _saveParametres(); }),
                    Text('$_frequenceRappel jours', style: AppTextStyles.subtitleMedium.copyWith(color: AppColors.primary)),
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () { if (_frequenceRappel < 30) setState(() => _frequenceRappel++); _saveParametres(); }),
                  ]),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // NOTIFICATIONS
          _buildSectionTitle('Notifications'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Column(children: [
              _buildNotifSwitch('Échéances de prêts', 'Alertes avant chaque échéance', _notifEcheance, (v) => setState(() { _notifEcheance = v; _saveParametres(); })),
              const Divider(),
              _buildNotifSwitch('Densité de poulets', 'Alerte en cas de surpopulation', _notifDensite, (v) => setState(() { _notifDensite = v; _saveParametres(); })),
              const Divider(),
              _buildNotifSwitch('Consommation anormale', 'Alerte si baisse/hausse de consommation', _notifConsommation, (v) => setState(() { _notifConsommation = v; _saveParametres(); })),
              const Divider(),
              _buildNotifSwitch('Fin de cycle', 'Alerte avant la fin estimée du cycle', _notifFinCycle, (v) => setState(() { _notifFinCycle = v; _saveParametres(); })),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // DÉCONNEXION
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                      TextButton(onPressed: () { Navigator.pop(ctx); context.read<AuthProvider>().logout(); Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); }, child: const Text('Déconnexion', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('DÉCONNEXION'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: AppBorders.buttonRadius)),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600));
  }

  Widget _buildNotifSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.subtitleMedium),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      value: value, onChanged: onChanged,
      activeColor: AppColors.primary, contentPadding: EdgeInsets.zero,
    );
  }
}