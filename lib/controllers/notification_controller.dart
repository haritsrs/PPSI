import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';

class NotificationController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  List<NotificationModel> get filteredNotifications {
    if (_selectedFilter == 'Belum Dibaca') {
      return _notifications.where((notification) => !notification.isRead).toList();
    }
    return _notifications;
  }

  int get unreadCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  List<String> get filters => ['Semua', 'Belum Dibaca'];

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notificationsSubscription?.cancel();
      _notificationsSubscription = _databaseService.getNotificationsStream().listen(
        (notificationsData) {
          _notifications = notificationsData.map((data) {
            return NotificationModel.fromFirebase(data);
          }).toList();
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          notifyListeners();
          throw error;
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsRead(NotificationModel notification) async {
    try {
      await _databaseService.markNotificationAsRead(notification.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _databaseService.markAllNotificationsAsRead();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotification(NotificationModel notification) async {
    try {
      await _databaseService.deleteNotification(notification.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _databaseService.deleteAllNotifications();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}

