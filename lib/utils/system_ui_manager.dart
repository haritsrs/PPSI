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
    systemNavigationBarContrastEnforced: false,
  );
  
  static void initialize() {
    SystemChrome.setSystemUIOverlayStyle(_systemUIStyle);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
