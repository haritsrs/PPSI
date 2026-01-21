import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LogoutController extends ChangeNotifier {
  bool _isLoggingOut = false;

  bool get isLoggingOut => _isLoggingOut;

  Future<void> logout() async {
    _isLoggingOut = true;
    notifyListeners();

    try {
      await AuthService.signOut();
      // AuthWrapper will automatically navigate to LoginPage
    } catch (e) {
      _isLoggingOut = false;
      notifyListeners();
      rethrow;
    }
  }
}


