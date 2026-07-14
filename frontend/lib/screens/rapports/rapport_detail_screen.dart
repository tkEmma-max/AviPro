// lib/screens/rapports/rapport_detail_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/rapport.dart';
import '../../services/api_service.dart';

class RapportDetailScreen extends StatefulWidget {
  final Rapport rapport;

  const RapportDetailScreen({
    super.key,
    required this.rapport,
  });

  @override
  State<RapportDetailScreen> createState() => _RapportDetailScreenState();
}

class _RapportDetailScreenState extends State<RapportDetailScreen> {
  final _apiService = ApiService();
  late Rapport _rapport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rapport = widget.rapport;
    _loadFullRapport();
  }

  Future<void> _loadFullRapport() async {
    try {
      final response = await _apiService.get('rapports/${_rapport.id}/');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _rapport = Rapport.fromJson(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement rapport: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final duree = _rapport.periodeFin.difference(_rapport.periodeDebut).inDays + 1;
    final alimentParJour = duree > 0 ? _rapport.alimentConsomme / duree : 0;
    final eauParJour = duree > 0 ? _rapport.eauConsommee / duree : 0;
    final ratioEauAliment = _rapport.alimentConsomme > 0 ? _rapport.eauConsommee / _rapport.alimentConsomme : 0;
    final densite = (_rapport.surface != null && _rapport.surface! > 0 && _rapport.nbSujetsActuels > 0)
        ? _rapport.nbSujetsActuels / _rapport.surface!
        : 0.0;
    final alimentOK = alimentParJour >= 0.08 && alimentParJour <= 0.15;
    final eauOK = ratioEauAliment >= 1.5 && ratioEauAliment <= 2.5;
    final hasAlerte = _rapport.maladieObservee != null || !alimentOK || !eauOK;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Detail du rapport', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.md),

          // EN-TETE
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [hasAlerte ? AppColors.error : AppColors.primary, hasAlerte ? AppColors.error.withOpacity(0.7) : AppColors.primary.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: AppBorders.cardRadius, boxShadow: AppShadows.shadowCard,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: AppBorders.buttonRadius), child: Text('${_rapport.periodeDebut.day}/${_rapport.periodeDebut.month} → ${_rapport.periodeFin.day}/${_rapport.periodeFin.month}/${_rapport.periodeFin.year}', style: AppTextStyles.labelSmall.copyWith(color: Colors.white))),
                const SizedBox(width: AppSpacing.sm),
                Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: AppBorders.buttonRadius), child: Text('$duree jours', style: AppTextStyles.labelSmall.copyWith(color: Colors.white))),
              ]),
              const SizedBox(height: AppSpacing.md),
              if (_rapport.cycleNom != null) Text(_rapport.cycleNom!, style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
              if (hasAlerte) ...[const SizedBox(height: AppSpacing.sm), Row(children: [const Icon(Icons.warning_amber, color: Colors.white, size: 16), const SizedBox(width: AppSpacing.xs), Text('Points d\'attention detectes', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.9)))])],
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // INFOS ELEVAGE
          _buildSectionTitle('Infos elevage'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Column(children: [
              _buildInfoRow(Icons.grid_view, 'Densite', '${densite.toStringAsFixed(1)} sujets/m²', AppColors.primary),
              const Divider(height: AppSpacing.lg),
              _buildInfoRow(Icons.pets, 'Sujets', '${_rapport.nbSujetsActuels}', AppColors.textPrimary),
              const Divider(height: AppSpacing.lg),
              _buildInfoRow(Icons.restaurant, 'Mangeoires', '${_rapport.nbMangeoires}', AppColors.warning),
              const Divider(height: AppSpacing.lg),
              _buildInfoRow(Icons.water_drop, 'Abreuvoirs', '${_rapport.nbAbreuvoirs}', AppColors.primary),
              const Divider(height: AppSpacing.lg),
              _buildInfoRow(Icons.square_foot, 'Surface', '${_rapport.surface?.toStringAsFixed(1) ?? "N/A"} m²', AppColors.textSecondary),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ALIMENTATION
          _buildSectionTitle('Alimentation'),
          const SizedBox(height: AppSpacing.md),
          _buildConsommationCard(icon: Icons.restaurant, label: 'Aliment consomme', valeur: '${_rapport.alimentConsomme.toStringAsFixed(1)} kg', detail: '${alimentParJour.toStringAsFixed(2)} kg/jour', couleur: AppColors.warning, pourcentage: (alimentParJour / 0.15).clamp(0.0, 1.0), status: alimentOK ? 'Normal' : 'Anormal', statusOK: alimentOK),
          const SizedBox(height: AppSpacing.md),

          // HYDRATATION
          _buildSectionTitle('Hydratation'),
          const SizedBox(height: AppSpacing.md),
          _buildConsommationCard(icon: Icons.water_drop, label: 'Eau consommee', valeur: '${_rapport.eauConsommee.toStringAsFixed(1)} litres', detail: '${eauParJour.toStringAsFixed(2)} litres/jour', couleur: AppColors.primary, pourcentage: (eauParJour / 0.3).clamp(0.0, 1.0), status: 'Ratio eau/aliment: ${ratioEauAliment.toStringAsFixed(2)}', statusOK: eauOK),
          const SizedBox(height: AppSpacing.lg),

          // RATIO
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Ratio eau/aliment', style: AppTextStyles.subtitleLarge),
                Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: eauOK ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1), borderRadius: AppBorders.buttonRadius), child: Text(eauOK ? 'Normal (1.5-2.5)' : 'Hors norme', style: AppTextStyles.labelSmall.copyWith(color: eauOK ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(ratioEauAliment.toStringAsFixed(2), style: AppTextStyles.numberLarge.copyWith(fontSize: 36)),
                const SizedBox(width: AppSpacing.sm),
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('L/kg', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // SUIVI SANITAIRE
          _buildSectionTitle('Suivi sanitaire'),
          const SizedBox(height: AppSpacing.md),
          if (_rapport.maladieObservee != null || _rapport.medicaments != null || _rapport.nbSujetsMalades > 0)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
              child: Column(children: [
                if (_rapport.maladieObservee != null) ...[_buildSanitaireRow(Icons.health_and_safety, 'Maladie observee', _rapport.maladieObservee!, AppColors.error), const Divider(height: AppSpacing.lg)],
                if (_rapport.medicaments != null) ...[_buildSanitaireRow(Icons.medication, 'Medicaments', _rapport.medicaments!, AppColors.warning), const Divider(height: AppSpacing.lg)],
                _buildSanitaireRow(Icons.pets, 'Sujets malades', '${_rapport.nbSujetsMalades}', _rapport.nbSujetsMalades > 0 ? AppColors.error : AppColors.success),
              ]),
            )
          else
            Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.05), borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.3))), child: Row(children: [const Icon(Icons.check_circle, color: AppColors.success, size: 24), const SizedBox(width: AppSpacing.md), Text('Aucun probleme sanitaire signale', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success))])),
          const SizedBox(height: AppSpacing.lg),

          // OBSERVATIONS
          if (_rapport.observations != null && _rapport.observations!.isNotEmpty) ...[
            _buildSectionTitle('Observations'),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
              child: Text(_rapport.observations!, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600));

  Widget _buildInfoRow(IconData icon, String label, String valeur, Color couleur) => Row(children: [Icon(icon, color: couleur, size: 20), const SizedBox(width: AppSpacing.md), Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))), Text(valeur, style: AppTextStyles.subtitleMedium.copyWith(color: couleur, fontWeight: FontWeight.w600))]);

  Widget _buildConsommationCard({required IconData icon, required String label, required String valeur, required String detail, required Color couleur, required double pourcentage, required String status, required bool statusOK}) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
    child: Column(children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: couleur.withOpacity(0.1), borderRadius: AppBorders.buttonRadius), child: Icon(icon, color: couleur, size: 24)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)), const SizedBox(height: 2), Text(valeur, style: AppTextStyles.numberMedium), Text(detail, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs), decoration: BoxDecoration(color: statusOK ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1), borderRadius: AppBorders.buttonRadius), child: Text(status, style: AppTextStyles.labelSmall.copyWith(color: statusOK ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: AppSpacing.md),
      LinearProgressIndicator(value: pourcentage, backgroundColor: AppColors.grey200, valueColor: AlwaysStoppedAnimation<Color>(couleur), minHeight: 6, borderRadius: AppBorders.buttonRadius),
    ]),
  );

  Widget _buildSanitaireRow(IconData icon, String label, String valeur, Color couleur) => Row(children: [Icon(icon, color: couleur, size: 20), const SizedBox(width: AppSpacing.md), Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))), Text(valeur, style: AppTextStyles.subtitleMedium.copyWith(color: couleur, fontWeight: FontWeight.w600))]);
}