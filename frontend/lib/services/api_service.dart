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

    // Intercepteur JWT
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
          if (error.response?.statusCode == 401) {
            // TODO: Rafraîchir le token
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String endpoint) async => await _dio.get(endpoint);
  Future<Response> post(String endpoint, {dynamic data}) async => await _dio.post(endpoint, data: data);
  Future<Response> put(String endpoint, {dynamic data}) async => await _dio.put(endpoint, data: data);
  Future<Response> delete(String endpoint) async => await _dio.delete(endpoint);

  Future<Response> login(String email, String password) async {
    return await _dio.post(
      'auth/login/',
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> register(String firstName, String lastName, String email, String phone, String password) async {
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