// lib/screens/poulaillers/poulailler_create_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_borders.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/poulailler.dart';
import '../../providers/poulailler_provider.dart';
import '../../widgets/custom_text_field.dart';

class PoulaillerCreateScreen extends StatefulWidget {
  const PoulaillerCreateScreen({super.key});

  @override
  State<PoulaillerCreateScreen> createState() =>
      _PoulaillerCreateScreenState();
}

class _PoulaillerCreateScreenState extends State<PoulaillerCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _nomController = TextEditingController();
  final _localisationController = TextEditingController();
  final _longueurController = TextEditingController();
  final _largeurController = TextEditingController();

  // Équipements
  int _nbMangeoires = 2;
  int _nbAbreuvoirs = 3;

  // Calculs dynamiques
  double _surface = 0;
  double _capacite = 0;

  void _updateCalculs() {
    final l = double.tryParse(_longueurController.text) ?? 0;
    final w = double.tryParse(_largeurController.text) ?? 0;
    setState(() {
      _surface = l * w;
      _capacite = _surface * 8; // 8 sujets/m² recommandé
    });
  }

  void _savePoulailler() {
    if (!_formKey.currentState!.validate()) return;

    final poulailler = Poulailler(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nom: _nomController.text.trim(),
      longueur: double.parse(_longueurController.text),
      largeur: double.parse(_largeurController.text),
      localisation: _localisationController.text.trim(),
      nombreMangeoires: _nbMangeoires,
      nombreAbreuvoirs: _nbAbreuvoirs,
      surface: _surface,
      statut: 'LIBRE',
      nbPouletsActuels: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<PoulaillerProvider>();
    provider.addPoulailler(poulailler);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Poulailler "${poulailler.nom}" enregistré !',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.cardRadius,
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          'Nouveau poulailler',
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

              // ============================================================
              // SECTION A : INFORMATIONS GÉNÉRALES
              // ============================================================
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
                hint: 'Ex: Bâtiment C, Poulailler Nord...',
                prefixIcon: Icons.house_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              CustomTextField(
                controller: _localisationController,
                label: 'Localisation',
                hint: 'Ex: Site Ouest, Zone B...',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // SECTION B : DIMENSIONS PHYSIQUES
              // ============================================================
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
                      hint: '0.0',
                      prefixIcon: Icons.straighten,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateCalculs(),
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        final v = double.tryParse(value);
                        if (v == null || v <= 0) {
                          return '> 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      controller: _largeurController,
                      label: 'Largeur (m) *',
                      hint: '0.0',
                      prefixIcon: Icons.straighten,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateCalculs(),
                      validator: (value) {
                        if (value!.isEmpty) return 'Requis';
                        final v = double.tryParse(value);
                        if (v == null || v <= 0) {
                          return '> 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Carte de calcul dynamique
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: AppBorders.cardRadius,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
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
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_surface.toStringAsFixed(2)} m²',
                          style: AppTextStyles.numberMedium.copyWith(
                            color: AppColors.primary,
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
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_capacite.toInt()} sujets',
                          style: AppTextStyles.numberMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // SECTION C : ÉQUIPEMENTS
              // ============================================================
              Text(
                'Dotation en équipements',
                style: AppTextStyles.subtitleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  // Mangeoires
                  Expanded(
                    child: _buildCounter(
                      label: 'Mangeoires',
                      value: _nbMangeoires,
                      icon: Icons.restaurant,
                      onIncrement: () =>
                          setState(() => _nbMangeoires++),
                      onDecrement: () =>
                          setState(() => _nbMangeoires = _nbMangeoires > 0 ? _nbMangeoires - 1 : 0),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Abreuvoirs
                  Expanded(
                    child: _buildCounter(
                      label: 'Abreuvoirs',
                      value: _nbAbreuvoirs,
                      icon: Icons.water_drop,
                      onIncrement: () =>
                          setState(() => _nbAbreuvoirs++),
                      onDecrement: () =>
                          setState(() => _nbAbreuvoirs = _nbAbreuvoirs > 0 ? _nbAbreuvoirs - 1 : 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ============================================================
              // BOUTON ENREGISTRER
              // ============================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _savePoulailler,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.buttonRadius,
                    ),
                  ),
                  child: Text(
                    'ENREGISTRER LE BÂTIMENT',
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