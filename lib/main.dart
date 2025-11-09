import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'pages/auth_wrapper.dart';
import 'views/home_view.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // must come before using XenditService
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay style to make navigation bar opaque and visible
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white, // Opaque white navbar
      systemNavigationBarIconBrightness: Brightness.dark, // Dark icons on white
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Set system UI mode to ensure navigation bar is always visible and opaque
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge, // Allows content to go edge-to-edge
  );

  runApp(const KiosDarmaApp());
}

class KiosDarmaApp extends StatelessWidget {
  const KiosDarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiosDarma',
      theme: AppTheme.theme,
      // Routing setup: AuthWrapper handles authentication state
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeView(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
