// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';

    print('🔵 ApiService initialisé avec baseUrl: ${AppConstants.apiBaseUrl}');

    // Intercepteur JWT avec refresh auto
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.storageAccessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Si 401 → tenter de rafraîchir le token
          if (error.response?.statusCode == 401) {
            final success = await _refreshToken();
            if (success) {
              // Réessayer la requête avec le nouveau token
              final prefs = await SharedPreferences.getInstance();
              final newToken = prefs.getString(AppConstants.storageAccessToken);
              if (newToken != null) {
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                try {
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(error);
                }
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // REFRESH TOKEN SILENCIEUX
  // ═══════════════════════════════════════════
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.storageRefreshToken);

      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.apiBaseUrl}auth/auth/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        await prefs.setString(AppConstants.storageAccessToken, response.data['access']);
        print('🔄 Token rafraîchi avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Échec refresh token: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════
  // MÉTHODES HTTP
  // ═══════════════════════════════════════════
  Future<Response> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String endpoint, {Map<String, dynamic>? data}) async {
    return _dio.patch(endpoint, data: data);
  }

  Future<Response> login(String email, String password) async {
    return await _dio.post('auth/auth/login/', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String firstName, String lastName, String email, String phone, String password) async {
    return await _dio.post('auth/auth/register/', data: {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'telephone': phone,
      'password': password,
    });
  }
}