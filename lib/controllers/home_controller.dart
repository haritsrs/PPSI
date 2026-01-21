import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class HomeController extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  User? _currentUser;
  List<String> _bannerImages = [];
  StreamSubscription<User?>? _authSubscription;

  User? get currentUser => _currentUser;
  List<String> get bannerImages => _bannerImages;
  DatabaseService get databaseService => _databaseService;

  Future<void> initialize() async {
    await _loadUserData();
    _loadBanners();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = AuthService.authStateChanges.listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    await AuthService.reloadUser();
    _currentUser = AuthService.currentUser;
    notifyListeners();
  }

  void _loadBanners() {
    _bannerImages = [
      'assets/banners/banner1.png',
      'assets/banners/banner2.png',
      'assets/banners/banner3.png',
    ];
    notifyListeners();
  }

  Future<void> reloadUser() async {
    await _loadUserData();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}


