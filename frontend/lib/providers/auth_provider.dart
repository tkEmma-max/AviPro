// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';

enum AuthError {
  success,
  invalidCredentials,
  userNotFound,
  emailExists,
  weakPassword,
  passwordMismatch,
  networkError,
  serverError,
  unknown,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  bool _isLoading = false;
  Map<String, dynamic>? _user;

  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.storageAccessToken);
    notifyListeners();
  }

  Future<AuthError> login(String email, String password) async {
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
        _isLoading = false;
        notifyListeners();
        return AuthError.success;
      }
      _isLoading = false;
      notifyListeners();
      return AuthError.invalidCredentials;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AuthError.networkError;
      }
      if (e.response?.statusCode == 401) {
        return AuthError.invalidCredentials;
      }
      if (e.response?.statusCode == 404) {
        return AuthError.userNotFound;
      }
      return AuthError.serverError;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthError.unknown;
    }
  }

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

  Future<AuthError> register(String firstName, String lastName, String email, String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(firstName, lastName, email, phone, password);
      if (response.statusCode == 201) {
        final loginResult = await login(email, password);
        _isLoading = false;
        notifyListeners();
        return loginResult;
      }
      _isLoading = false;
      notifyListeners();
      return AuthError.serverError;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return AuthError.networkError;
      }
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map) {
          if (data.containsKey('email')) return AuthError.emailExists;
          if (data.containsKey('password')) return AuthError.weakPassword;
        }
      }
      return AuthError.serverError;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthError.unknown;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageAccessToken);
    await prefs.remove(AppConstants.storageRefreshToken);
    notifyListeners();
  }
}