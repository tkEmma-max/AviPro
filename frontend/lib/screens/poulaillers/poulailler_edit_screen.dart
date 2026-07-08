// lib/screens/poulaillers/poulailler_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';
import '../../widgets/custom_text_field.dart';

class PoulaillerEditScreen extends StatefulWidget {
  final Poulailler poulailler;

  const PoulaillerEditScreen({
    super.key,
    required this.poulailler,
  });

  @override
  State<PoulaillerEditScreen> createState() => _PoulaillerEditScreenState();
}

class _PoulaillerEditScreenState extends State<PoulaillerEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _localisationController;
  late TextEditingController _longueurController;
  late TextEditingController _largeurController;

  int _nbMangeoires = 0;
  int _nbAbreuvoirs = 0;
  double _surface = 0;
  double _capacite = 0;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.poulailler.nom);
    _localisationController =
        TextEditingController(text: widget.poulailler.localisation ?? '');
    _longueurController =
        TextEditingController(text: widget.poulailler.longueur.toString());
    _largeurController =
        TextEditingController(text: widget.poulailler.largeur.toString());
    _nbMangeoires = widget.poulailler.nombreMangeoires;
    _nbAbreuvoirs = widget.poulailler.nombreAbreuvoirs;
    _updateCalculs();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _localisationController.dispose();
    _longueurController.dispose();
    _largeurController.dispose();
    super.dispose();
  }

  void _updateCalculs() {
    final l = double.tryParse(_longueurController.text) ?? 0;
    final w = double.tryParse(_largeurController.text) ?? 0;
    setState(() {
      _surface = l * w;
      _capacite = _surface * 8;
      _isBlocked = widget.poulailler.nbPouletsActuels > 0 &&
          _capacite < widget.poulailler.nbPouletsActuels;
    });
  }

  void _savePoulailler() {
    if (!_formKey.currentState!.validate()) return;
    if (_isBlocked) return;

    final updated = Poulailler(
      id: widget.poulailler.id,
      nom: _nomController.text.trim(),
      longueur: double.parse(_longueurController.text),
      largeur: double.parse(_largeurController.text),
      hauteur: widget.poulailler.hauteur,
      localisation: _localisationController.text.trim(),
      typeSol: widget.poulailler.typeSol,
      nombreMangeoires: _nbMangeoires,
      nombreAbreuvoirs: _nbAbreuvoirs,
      isArchived: widget.poulailler.isArchived,
      statut: widget.poulailler.statut,
      nbPouletsActuels: widget.poulailler.nbPouletsActuels,
      surface: _surface,
      densiteActuelle: widget.poulailler.densiteActuelle,
      createdAt: widget.poulailler.createdAt,
      updatedAt: DateTime.now(),
    );

    final provider = context.read<PoulaillerProvider>();
    provider.updatePoulailler(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Poulailler "${updated.nom}" modifié !'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.cardRadius,
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = widget.poulailler.statut == 'OCCUPÉ';

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
          'Modifier le poulailler',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Bandeau d'alerte si occupé
              if (isOccupied)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: AppBorders.cardRadius,
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Ce poulailler est occupé (${widget.poulailler.nbPouletsActuels} sujets). La réduction des dimensions est bloquée si elle réduit la capacité.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Informations générales',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              CustomTextField(
                controller: _nomController,
                label: 'Nom ou numéro du bâtiment *',
                prefixIcon: Icons.house_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                controller: _localisationController,
                label: 'Localisation',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Dimensions physiques',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _longueurController,
                      label: 'Longueur (m) *',
                      prefixIcon: Icons.straighten,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateCalculs(),
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        final v = double.tryParse(value);
                        if (v == null || v <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      controller: _largeurController,
                      label: 'Largeur (m) *',
                      prefixIcon: Icons.straighten,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateCalculs(),
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        final v = double.tryParse(value);
                        if (v == null || v <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Carte de calcul
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: _isBlocked
                      ? AppColors.error.withOpacity(0.08)
                      : const Color(0xFFEFF6FF),
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(
                    color: _isBlocked ? AppColors.error : AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Surface',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isBlocked ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_surface.toStringAsFixed(2)} m²',
                          style: AppTextStyles.numberMedium.copyWith(
                            color: _isBlocked ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Capacité max',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isBlocked ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_capacite.toInt()} sujets',
                          style: AppTextStyles.numberMedium.copyWith(
                            color: _isBlocked ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_isBlocked)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '❌ Action impossible : Les dimensions saisies réduisent la capacité en dessous du nombre de poulets actuellement présents (${widget.poulailler.nbPouletsActuels} sujets).',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Dotation en équipements',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _buildCounter(
                      label: 'Mangeoires',
                      value: _nbMangeoires,
                      icon: Icons.restaurant,
                      onIncrement: () => setState(() => _nbMangeoires++),
                      onDecrement: () => setState(() =>
                          _nbMangeoires = _nbMangeoires > 0 ? _nbMangeoires - 1 : 0),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildCounter(
                      label: 'Abreuvoirs',
                      value: _nbAbreuvoirs,
                      icon: Icons.water_drop,
                      onIncrement: () => setState(() => _nbAbreuvoirs++),
                      onDecrement: () => setState(() =>
                          _nbAbreuvoirs = _nbAbreuvoirs > 0 ? _nbAbreuvoirs - 1 : 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isBlocked ? null : _savePoulailler,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isBlocked ? AppColors.textHint : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                  child: Text(
                    'ENREGISTRER LES MODIFICATIONS',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter({
    required String label,
    required int value,
    required IconData icon,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _buildCounterButton(Icons.remove, onDecrement),
            Container(
              width: 48,
              height: 40,
              alignment: Alignment.center,
              child: Text(
                value.toString(),
                style: AppTextStyles.numberSmall.copyWith(
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
            _buildCounterButton(Icons.add, onIncrement),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.primary),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        constraints: const BoxConstraints(),
      ),
    );
  }
}