// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../providers/poulailler_provider.dart';
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  bool _isLoading = false;
  Map<String, dynamic>? _user;  // <--- AJOUTER CETTE LIGNE

  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;  // <--- AJOUTER CETTE LIGNE

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.storageAccessToken);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      if (response.statusCode == 200) {
        _token = response.data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.storageAccessToken, _token!);
        await prefs.setString(AppConstants.storageRefreshToken, response.data['refresh']);

        await getUserProfile();

        // ✅ REVOIR ICI - Utiliser le provider existant
        // Ne pas créer une nouvelle instance

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // NOUVELLE MÉTHODE : RÉCUPÉRER LE PROFIL
  // ═══════════════════════════════════════════════
  Future<void> getUserProfile() async {
    try {
      final response = await _apiService.get('users/me/');
      if (response.statusCode == 200) {
        _user = response.data;
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
    }
  }

  Future<bool> register(String firstName, String lastName, String email, String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        firstName,
        lastName,
        email,
        phone,
        password,
      );
      if (response.statusCode == 201) {
        final loginSuccess = await login(email, password);
        _isLoading = false;
        notifyListeners();
        return loginSuccess;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;  // <--- AJOUTER CETTE LIGNE
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageAccessToken);
    await prefs.remove(AppConstants.storageRefreshToken);
    notifyListeners();
  }
}