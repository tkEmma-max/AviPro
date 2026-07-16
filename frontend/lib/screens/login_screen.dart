// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_borders.dart';
import '../core/theme/app_shadows.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(AuthError error) {
    switch (error) {
      case AuthError.success:
        return '';
      case AuthError.invalidCredentials:
        return 'Email ou mot de passe incorrect.';
      case AuthError.userNotFound:
        return 'Aucun compte trouvé avec cet email. Veuillez créer un compte.';
      case AuthError.networkError:
        return 'Pas de connexion internet. Vérifiez votre réseau.';
      case AuthError.serverError:
        return 'Le serveur est indisponible. Réessayez plus tard.';
      case AuthError.emailExists:
        return 'Cet email est déjà utilisé.';
      case AuthError.weakPassword:
        return 'Mot de passe trop faible.';
      case AuthError.passwordMismatch:
        return 'Mots de passe différents.';
      case AuthError.unknown:
        return 'Une erreur inconnue est survenue. Réessayez.';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == AuthError.success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _getErrorMessage(result),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: result == AuthError.networkError
              ? AppColors.warning
              : AppColors.error,
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
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: AppBorders.radiusXLarge, boxShadow: AppShadows.shadowMedium),
                          child: ClipRRect(
                            borderRadius: AppBorders.radiusXLarge,
                            child: Image.asset('assets/icons/avipro_icon.png', width: 80, height: 80, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('AVIPRO', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Gestion intégrée de votre élevage avicole', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.8))),
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
                          const SizedBox(height: AppSpacing.xxxl),
                          Text('Bienvenue', style: AppTextStyles.headlineLarge.copyWith(fontSize: 24, color: AppColors.primary)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Connectez-vous à votre compte', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildInputField(
                            controller: _emailController,
                            label: 'Adresse email',
                            hint: 'exemple@email.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value!.isEmpty) return 'Veuillez saisir votre email';
                              if (!value.contains('@') || !value.contains('.')) return 'Veuillez saisir un email valide';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            hint: 'Entrez votre mot de passe',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textHint, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) => value!.isEmpty ? 'Veuillez saisir votre mot de passe' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
                              child: Text('Mot de passe oublié ?', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          CustomButton(label: 'Se connecter', isLoading: _isLoading, onPressed: _login),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Nouveau sur AVIPRO ? ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Text('Créer un compte', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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