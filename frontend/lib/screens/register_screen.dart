// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_shadows.dart';
import '../widgets/custom_button.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(AuthError error) {
    switch (error) {
      case AuthError.success:
        return '';
      case AuthError.emailExists:
        return 'Cet email est déjà utilisé. Veuillez vous connecter.';
      case AuthError.weakPassword:
        return 'Mot de passe trop faible. Utilisez au moins 8 caractères avec lettres et chiffres.';
      case AuthError.passwordMismatch:
        return 'Les mots de passe ne correspondent pas.';
      case AuthError.networkError:
        return 'Pas de connexion internet. Vérifiez votre réseau.';
      case AuthError.serverError:
        return 'Le serveur est indisponible. Réessayez plus tard.';
      case AuthError.invalidCredentials:
        return 'Identifiants incorrects.';
      case AuthError.userNotFound:
        return 'Utilisateur introuvable.';
      case AuthError.unknown:
        return 'Une erreur inconnue est survenue. Réessayez.';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez accepter les conditions d\'utilisation.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppBorders.cardRadius),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.register(
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == AuthError.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Compte créé avec succès !', style: TextStyle(color: Colors.white))),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppBorders.cardRadius),
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(_getErrorMessage(result), style: const TextStyle(color: Colors.white))),
          ]),
          backgroundColor: result == AuthError.networkError ? AppColors.warning : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppBorders.cardRadius),
          margin: const EdgeInsets.all(AppSpacing.lg),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.30,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.radiusXLarge, boxShadow: AppShadows.shadowMedium),
                            child: ClipRRect(borderRadius: AppBorders.radiusXLarge, child: Image.asset('assets/icons/avipro_icon.png', width: 80, height: 80, fit: BoxFit.cover))),
                        const SizedBox(height: AppSpacing.md),
                        Text('CRÉER UN COMPTE', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Rejoignez AVIPRO pour digitaliser votre exploitation.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          Text('Inscription', style: AppTextStyles.headlineLarge.copyWith(fontSize: 24, color: AppColors.primary)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Créez votre compte en quelques secondes', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.xl),
                          _buildInputField(controller: _firstNameController, label: 'Prénom *', hint: 'Entrez votre prénom', prefixIcon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Ce champ est requis' : null),
                          const SizedBox(height: AppSpacing.xl),
                          _buildInputField(controller: _lastNameController, label: 'Nom (optionnel)', hint: 'Entrez votre nom', prefixIcon: Icons.person_outline),
                          const SizedBox(height: AppSpacing.xl),
                          _buildInputField(controller: _emailController, label: 'Adresse email *', hint: 'exemple@email.com', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) { if (v!.isEmpty) return 'Veuillez saisir votre email'; if (!v.contains('@') || !v.contains('.')) return 'Email valide requis'; return null; }),
                          const SizedBox(height: AppSpacing.xl),
                          _buildInputField(controller: _phoneController, label: 'Numéro de téléphone *', hint: '+237 6XX XX XX XX', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Ce champ est requis' : null),
                          const SizedBox(height: AppSpacing.xl),
                          _buildInputField(controller: _passwordController, label: 'Mot de passe *', hint: 'Minimum 8 caractères', prefixIcon: Icons.lock_outline, obscureText: _obscurePassword,
                              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textHint, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                              validator: (v) { if (v!.isEmpty) return 'Veuillez saisir un mot de passe'; if (v.length < 8) return 'Minimum 8 caractères'; return null; }),
                          const SizedBox(height: AppSpacing.xl),
                          _buildInputField(controller: _confirmPasswordController, label: 'Confirmer le mot de passe *', hint: 'Répétez votre mot de passe', prefixIcon: Icons.lock_outline, obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textHint, size: 20), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                              validator: (v) { if (v!.isEmpty) return 'Veuillez confirmer'; if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas'; return null; }),
                          const SizedBox(height: AppSpacing.md),
                          GestureDetector(
                            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                            child: Row(children: [
                              Checkbox(value: _acceptedTerms, onChanged: (v) => setState(() => _acceptedTerms = v ?? false), activeColor: AppColors.success, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              Expanded(child: Text('J\'accepte les Conditions d\'Utilisation', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                            ]),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          CustomButton(label: 'Créer mon compte', isLoading: _isLoading, onPressed: _register),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Vous avez déjà un compte ? ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    GestureDetector(onTap: () => Navigator.pop(context), child: Text('Se connecter', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller, required String label, required String hint,
    required IconData prefixIcon, Widget? suffixIcon, bool obscureText = false,
    TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppBorders.inputRadius, boxShadow: [BoxShadow(color: const Color(0xFFCBD5E1), blurRadius: 6, offset: const Offset(0, 2))]),
          child: TextFormField(
            controller: controller, obscureText: obscureText, validator: validator, keyboardType: keyboardType,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint, hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint, fontSize: 15),
              prefixIcon: Icon(prefixIcon, color: AppColors.textHint, size: 22), suffixIcon: suffixIcon,
              filled: true, fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 18),
              border: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: BorderSide.none),
              errorBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: AppBorders.inputRadius, borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }
}