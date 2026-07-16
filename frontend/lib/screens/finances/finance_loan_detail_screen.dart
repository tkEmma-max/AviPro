// lib/screens/finances/finance_loan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/pret.dart';
import '../../providers/pret_provider.dart';

class FinanceLoanDetailScreen extends StatefulWidget {
  final Pret pret;

  const FinanceLoanDetailScreen({
    super.key,
    required this.pret,
  });

  @override
  State<FinanceLoanDetailScreen> createState() => _FinanceLoanDetailScreenState();
}

class _FinanceLoanDetailScreenState extends State<FinanceLoanDetailScreen> {
  final _montantController = TextEditingController();
  bool _showRemboursement = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  double get _progression {
    if (widget.pret.montantTotal <= 0) return 0;
    final rembourse = widget.pret.montantTotal - widget.pret.montantRestant;
    return (rembourse / widget.pret.montantTotal) * 100;
  }

  Future<void> _rembourser() async {
    final montant = double.tryParse(_montantController.text) ?? 0;
    if (montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Montant invalide'), backgroundColor: AppColors.warning));
      return;
    }
    if (montant > widget.pret.montantRestant) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Max: ${widget.pret.montantRestant.toInt()} FCFA'), backgroundColor: AppColors.warning));
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<PretProvider>();
    final success = await provider.addRemboursement(widget.pret.id, montant);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showRemboursement = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Remboursement enregistré !'), backgroundColor: AppColors.success));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pret;
    final rembourse = p.montantTotal - p.montantRestant;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary), onPressed: () => Navigator.pop(context)),
        title: const Text('Détails du prêt', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: AppSpacing.md),

          // HEADER
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: AppBorders.cardRadius, boxShadow: AppShadows.shadowMedium,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.preteur, style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('${p.typePreteur} • ${p.tauxInteret}% ${p.typeTaux}', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                ])),
                if (p.isRembourse)
                  Container(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: AppBorders.buttonRadius),
                      child: Text('REMBOURSÉ', style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: AppSpacing.lg),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Restant dû', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                  Text('${p.montantRestant.toInt()} FCFA', style: AppTextStyles.numberLarge.copyWith(fontSize: 22, color: Colors.white)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${_progression.toInt()}%', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('remboursé', style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
                ]),
              ]),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(value: _progression / 100, backgroundColor: Colors.white.withOpacity(0.2), color: Colors.white, minHeight: 6, borderRadius: AppBorders.buttonRadius),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // INFOS
          _buildSectionTitle('Informations'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.border), boxShadow: AppShadows.shadowCard),
            child: Column(children: [
              _buildInfoRow('Capital emprunté', '${p.montantTotal.toInt()} FCFA'),
              const Divider(),
              _buildInfoRow('Total remboursé', '${rembourse.toInt()} FCFA'),
              const Divider(),
              _buildInfoRow('Taux d\'intérêt', '${p.tauxInteret}% ${p.typeTaux == "MENSUEL" ? "mensuel" : "annuel"}'),
              const Divider(),
              _buildInfoRow('Date de déblocage', '${p.dateDeblocage.day}/${p.dateDeblocage.month}/${p.dateDeblocage.year}'),
              const Divider(),
              _buildInfoRow('Date limite', p.dateLimite != null ? '${p.dateLimite!.day}/${p.dateLimite!.month}/${p.dateLimite!.year}' : 'Non définie'),
              const Divider(),
              _buildInfoRow('Mode', p.modeRemboursement == 'IMPOSE' ? 'Échéances imposées' : 'Remboursement libre'),
              const Divider(),
              _buildInfoRow('Durée estimée', p.dureeTotaleMois != null ? '${p.dureeTotaleMois} mois' : 'Non définie'),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // REMBOURSEMENT
          if (!p.isRembourse) ...[
            _buildSectionTitle('Remboursement'),
            const SizedBox(height: AppSpacing.md),
            if (!_showRemboursement)
              SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showRemboursement = true),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('EFFECTUER UN REMBOURSEMENT'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppBorders.buttonRadius)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.cardRadius, border: Border.all(color: AppColors.success.withOpacity(0.3))),
                child: Column(children: [
                  Text('Montant à rembourser', style: AppTextStyles.subtitleMedium),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _montantController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Max: ${p.montantRestant.toInt()} FCFA',
                      border: OutlineInputBorder(borderRadius: AppBorders.inputRadius),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => setState(() { _showRemboursement = false; _montantController.clear(); }), child: const Text('Annuler'))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: ElevatedButton(onPressed: _isLoading ? null : _rembourser, style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white), child: Text(_isLoading ? '...' : 'Confirmer'))),
                  ]),
                ]),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.primary, width: 3))),
      child: Text(title, style: AppTextStyles.subtitleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.subtitleMedium),
      ]),
    );
  }
}