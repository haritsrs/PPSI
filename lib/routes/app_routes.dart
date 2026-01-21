import 'package:flutter/material.dart';
import '../pages/home_page.dart';

class AppRoutes {
  static const String home = '/home';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomePage(),
    };
  }
}


