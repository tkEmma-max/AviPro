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

    // Intercepteur JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.storageAccessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Token ajouté à la requête: ${token.substring(0, 20)}...');
          } else {
            print('⚠️ Aucun token trouvé');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          print('❌ Erreur API: ${error.response?.statusCode} - ${error.message}');
          if (error.response?.statusCode == 401) {
            print('🔴 Token expiré, tentative de rafraîchissement...');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String endpoint) async {
    print('📡 GET $endpoint');
    try {
      final response = await _dio.get(endpoint);
      print('✅ GET $endpoint → ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET $endpoint → Erreur: $e');
      rethrow;
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    print('📡 POST $endpoint');
    print('📦 Data: $data');
    try {
      final response = await _dio.post(endpoint, data: data);
      print('✅ POST $endpoint → ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ POST $endpoint → Erreur: $e');
      rethrow;
    }
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    print('📡 PUT $endpoint');
    try {
      final response = await _dio.put(endpoint, data: data);
      print('✅ PUT $endpoint → ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ PUT $endpoint → Erreur: $e');
      rethrow;
    }
  }

  Future<Response> delete(String endpoint) async {
    print('📡 DELETE $endpoint');
    try {
      final response = await _dio.delete(endpoint);
      print('✅ DELETE $endpoint → ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ DELETE $endpoint → Erreur: $e');
      rethrow;
    }
  }

  Future<Response> login(String email, String password) async {
    print('🔐 Tentative de login: $email');
    return await _dio.post(
      'auth/auth/login/',
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> register(String firstName, String lastName, String email, String phone, String password) async {
    print('📝 Tentative d\'inscription: $email');
    return await _dio.post(
      'auth/register/',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'telephone': phone,
        'password': password,
      },
    );
  }
  String getErrorMessage(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'];
      }
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Erreur ${error.response!.statusCode}';
    }
    return 'Erreur réseau. Vérifiez votre connexion.';
  }
}