// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  bool _isLoading = false;

  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.storageAccessToken);
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _token = 'demo_token_123456789';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.storageAccessToken, _token!);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ═══════════════════════════════════════════════
  // NOUVELLE MÉTHODE : REGISTER
  // ═══════════════════════════════════════════════
  Future<bool> register(String fullName, String email, String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Simulation d'inscription réussie
    _token = 'demo_token_123456789';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.storageAccessToken, _token!);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageAccessToken);
    await prefs.remove(AppConstants.storageRefreshToken);
    notifyListeners();
  }
}