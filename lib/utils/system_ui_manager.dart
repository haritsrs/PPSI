import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIManager {
  SystemUIManager._();
  
  static const _systemUIStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.black,
    systemNavigationBarContrastEnforced: true,
  );
  
  static void initialize() {
    SystemChrome.setSystemUIOverlayStyle(_systemUIStyle);
    // Edge-to-edge layout but with navigation bar visible (not transparent)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }
  
  static void enforce() {
    SystemChrome.setSystemUIOverlayStyle(_systemUIStyle);
  }
  
  static SystemUiOverlayStyle get style => _systemUIStyle;
}

class SystemUILifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemUIManager.enforce();
    }
  }
}
