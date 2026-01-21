import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/news_service.dart';

class BeritaController extends ChangeNotifier {
  Timer? _timer;
  Map<String, dynamic>? _newsItem;
  String? _userDisplayName;

  // Getters
  Map<String, dynamic>? get newsItem => _newsItem;
  String? get userDisplayName => _userDisplayName;

  Future<void> initialize() async {
    // Load news data
    _newsItem = NewsService.getDefaultNews();
    
    // Get user display name
    _userDisplayName = AuthService.getUserDisplayName(AuthService.currentUser);
    
    // Start timer to refresh time display every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Update news item to refresh time display
      _newsItem = NewsService.getDefaultNews();
      notifyListeners();
    });
    
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}


