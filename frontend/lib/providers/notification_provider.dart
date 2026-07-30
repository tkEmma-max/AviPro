// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  DateTime? _lastFetch;
  static const _cacheDuration = Duration(seconds: 30);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get nbNonLues => _notifications.where((n) => !n.estLue).length;

  bool get _isCacheValid =>
      _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<void> loadNotifications() async {
    if (_isCacheValid && _notifications.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('notifications/');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['results'] != null) {
          _notifications = (data['results'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else if (data is List) {
          _notifications = data
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
        _lastFetch = DateTime.now();
      }
    } catch (e) {
      print('❌ [NotificationProvider] Erreur: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> marquerLue(String id) async {
    try {
      await _apiService.patch('notifications/$id/', data: {'est_lue': true});
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel.fromJson({
          ..._notifications[index].toJson(),
          'est_lue': true,
        });
        notifyListeners();
      }
    } catch (e) {
      print('❌ [NotificationProvider] Erreur marquerLue: $e');
    }
  }

  Future<void> marquerToutesLues() async {
    try {
      await _apiService.post('notifications/marquer_toutes_lues/');
      _notifications = _notifications.map((n) {
        return NotificationModel.fromJson({
          'id': n.id,
          'type': n.type,
          'type_label': n.typeLabel,
          'titre': n.titre,
          'message': n.message,
          'donnees': n.donnees,
          'est_lue': true,
          'date_creation': n.dateCreation.toIso8601String(),
        });
      }).toList();
      notifyListeners();
    } catch (e) {
      print('❌ [NotificationProvider] Erreur marquerToutesLues: $e');
    }
  }

  Future<void> refreshNotifications() async {
    _lastFetch = null;
    await loadNotifications();
  }
}