// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_shadows.dart';
import '../providers/poulailler_provider.dart';
import '../models/poulailler.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final List<OnboardingPoulailler> _poulaillers = [];
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs Étape 1
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Contrôleurs Étape 2
  final _longueurController = TextEditingController();
  final _largeurController = TextEditingController();
  final _hauteurController = TextEditingController();
  double _surface = 0;
  double _capacite = 0;

  // Contrôleurs Étape 3
  double _nbMangeoires = 2;
  double _nbAbreuvoirs = 3;
  final _localisationController = TextEditingController();

  bool _isLastStep = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _longueurController.dispose();
    _largeurController.dispose();
    _hauteurController.dispose();
    _localisationController.dispose();
    super.dispose();
  }

  void _updateCalculs() {
    final l = double.tryParse(_longueurController.text) ?? 0;
    final w = double.tryParse(_largeurController.text) ?? 0;
    setState(() {
      _surface = l * w;
      _capacite = _surface * 8; // 8 sujets/m² recommandé
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _isLastStep = _currentStep == 2;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isLastStep = _currentStep == 2;
      });
    }
  }

  void _savePoulailler() {
    if (!_formKey.currentState!.validate()) return;

    final poulailler = OnboardingPoulailler(
      nom: _nomController.text.trim(),
      description: _descriptionController.text.trim(),
      longueur: double.parse(_longueurController.text),
      largeur: double.parse(_largeurController.text),
      hauteur: double.tryParse(_hauteurController.text) ?? 0,
      localisation: _localisationController.text.trim(),
      nbMangeoires: _nbMangeoires.toInt(),
      nbAbreuvoirs: _nbAbreuvoirs.toInt(),
      surface: _surface,
      capacite: _capacite,
    );

    setState(() {
      _poulaillers.add(poulailler);
      _resetForm();
    });

    // Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Poulailler "${poulailler.nom}" ajouté !',
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
  }

  void _resetForm() {
    _nomController.clear();
    _descriptionController.clear();
    _longueurController.clear();
    _largeurController.clear();
    _hauteurController.clear();
    _localisationController.clear();
    setState(() {
      _surface = 0;
      _capacite = 0;
      _nbMangeoires = 2;
      _nbAbreuvoirs = 3;
      _currentStep = 0;
      _isLastStep = false;
    });
  }

  Future<void> _finishOnboarding() async {
    if (_poulaillers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins un poulailler pour continuer.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simuler l'enregistrement
    await Future.delayed(const Duration(seconds: 1));

    // Enregistrer dans le provider
    final provider = context.read<PoulaillerProvider>();
    for (final p in _poulaillers) {
      provider.addPoulailler(
        Poulailler(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nom: p.nom,
          longueur: p.longueur,
          largeur: p.largeur,
          hauteur: p.hauteur > 0 ? p.hauteur : null,
          localisation: p.localisation,
          nombreMangeoires: p.nbMangeoires,
          nombreAbreuvoirs: p.nbAbreuvoirs,
          surface: p.surface,
          statut: 'LIBRE',
          nbPouletsActuels: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    setState(() => _isSubmitting = false);

    // Rediriger vers le Dashboard
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: _prevStep,
              )
            : null,
        title: Text(
          'Configuration de l\'exploitation',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ============================================================
          // INDICATEUR D'ÉTAPES (Stepper horizontal)
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                return Row(
                  children: [
                    // Bille
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.success
                            : isActive
                                ? AppColors.primary
                                : AppColors.grey300,
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.grey300,
                          width: isActive ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCompleted || isActive
                                ? Colors.white
                                : AppColors.textHint,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Ligne de connexion (sauf après la dernière)
                    if (index < 2)
                      Container(
                        width: 40,
                        height: 2,
                        color: index < _currentStep
                            ? AppColors.success
                            : AppColors.grey300,
                      ),
                  ],
                );
              }),
            ),
          ),

          // ============================================================
          // ZONE DE FORMULAIRE DYNAMIQUE
          // ============================================================
          Expanded(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    // ==========================================================
                    // ÉTAPE 1 : IDENTITÉ
                    // ==========================================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Text('🏷️', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Identité du poulailler',
                              style: AppTextStyles.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Donnez un nom à votre bâtiment',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        CustomTextField(
                          controller: _nomController,
                          label: 'Nom du poulailler *',
                          hint: 'Ex: Poulailler Nord, Bâtiment A...',
                          prefixIcon: Icons.house_outlined,
                          validator: (value) =>
                              value!.isEmpty ? 'Ce champ est requis' : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description (optionnelle)',
                          hint: 'Ex: Bâtiment principal, proche du champ...',
                          prefixIcon: Icons.description_outlined,
                        ),
                      ],
                    ),

                    // ==========================================================
                    // ÉTAPE 2 : DIMENSIONS
                    // ==========================================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Text('📐', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Dimensions du bâtiment',
                              style: AppTextStyles.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Saisissez les dimensions en mètres',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _longueurController,
                                label: 'Longueur (m)',
                                hint: '0.0',
                                prefixIcon: Icons.straighten,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _updateCalculs(),
                                validator: (value) {
                                  if (value!.isEmpty) return 'Requis';
                                  if (double.tryParse(value) == null) {
                                    return 'Nombre valide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: CustomTextField(
                                controller: _largeurController,
                                label: 'Largeur (m)',
                                hint: '0.0',
                                prefixIcon: Icons.straighten,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _updateCalculs(),
                                validator: (value) {
                                  if (value!.isEmpty) return 'Requis';
                                  if (double.tryParse(value) == null) {
                                    return 'Nombre valide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: CustomTextField(
                                controller: _hauteurController,
                                label: 'Hauteur (m)',
                                hint: '0.0',
                                prefixIcon: Icons.height,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null &&
                                      value.isNotEmpty &&
                                      double.tryParse(value) == null) {
                                    return 'Nombre valide';
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
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Surface',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_surface.toStringAsFixed(1)} m²',
                                    style: AppTextStyles.numberMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Capacité maximale conseillée',
                                    style: AppTextStyles.bodyMedium.copyWith(
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
                      ],
                    ),

                    // ==========================================================
                    // ÉTAPE 3 : ÉQUIPEMENTS
                    // ==========================================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Text('⚙️', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Équipements & Localisation',
                              style: AppTextStyles.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Configurez les équipements du bâtiment',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Mangeoires
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Mangeoires : ${_nbMangeoires.toInt()}',
                                  style: AppTextStyles.subtitleMedium,
                                ),
                              ],
                            ),
                            Slider(
                              value: _nbMangeoires,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: _nbMangeoires.toInt().toString(),
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.grey300,
                              onChanged: (value) {
                                setState(() => _nbMangeoires = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Abreuvoirs
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Abreuvoirs : ${_nbAbreuvoirs.toInt()}',
                                  style: AppTextStyles.subtitleMedium,
                                ),
                              ],
                            ),
                            Slider(
                              value: _nbAbreuvoirs,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: _nbAbreuvoirs.toInt().toString(),
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.grey300,
                              onChanged: (value) {
                                setState(() => _nbAbreuvoirs = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Localisation
                        CustomTextField(
                          controller: _localisationController,
                          label: 'Localisation',
                          hint: 'Ex: Derrière la maison, Champ Nord...',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // FOOTER ACTIONS
          // ============================================================
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Bouton "Ajouter un autre bâtiment" (sauf si dernière étape)
                if (_currentStep == 2)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _poulaillers.isEmpty ? null : _savePoulailler,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.buttonRadius,
                        ),
                      ),
                      child: Text(
                        _poulaillers.isEmpty ? 'Ajouter' : '+ Ajouter',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: AppSpacing.md),

                // Bouton "Suivant" / "Terminer"
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    label: _isLastStep
                        ? _poulaillers.isEmpty
                            ? 'Ajouter un poulailler'
                            : 'Terminer (${_poulaillers.length})'
                        : 'Suivant',
                    isLoading: _isSubmitting,
                    onPressed: _isLastStep
                        ? _poulaillers.isEmpty
                            ? _savePoulailler
                            : _finishOnboarding
                        : _nextStep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODÈLE LOCAL POUR L'ONBOARDING
// ============================================================
class OnboardingPoulailler {
  final String nom;
  final String description;
  final double longueur;
  final double largeur;
  final double hauteur;
  final String localisation;
  final int nbMangeoires;
  final int nbAbreuvoirs;
  final double surface;
  final double capacite;

  OnboardingPoulailler({
    required this.nom,
    required this.description,
    required this.longueur,
    required this.largeur,
    required this.hauteur,
    required this.localisation,
    required this.nbMangeoires,
    required this.nbAbreuvoirs,
    required this.surface,
    required this.capacite,
  });
}