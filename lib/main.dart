import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'pages/auth_wrapper.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_view.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for date formatting (do this early)
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Warning: Failed to initialize locale data: $e');
  }

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

  // Set system UI mode - use manual mode to ensure navigation bar area is always reserved
  // This ensures the navigation bar area is always visible, even if buttons are hidden by gesture navigation
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top, // Show status bar
      SystemUiOverlay.bottom, // Show navigation bar area (buttons may be hidden by gesture navigation)
    ],
  );

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(KiosDarmaApp(hasSeenOnboarding: hasSeenOnboarding));
}

class KiosDarmaApp extends StatefulWidget {
  const KiosDarmaApp({super.key, required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;

  @override
  State<KiosDarmaApp> createState() => _KiosDarmaAppState();
}

class _KiosDarmaAppState extends State<KiosDarmaApp> {
  late bool _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.hasSeenOnboarding;
  }

  void _handleOnboardingFinished() {
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiosDarma',
      theme: AppTheme.theme,
      // Routing setup: AuthWrapper handles authentication state
      home: _hasSeenOnboarding
          ? const AuthWrapper()
          : OnboardingPage(
              onFinished: _handleOnboardingFinished,
            ),
      routes: {
        '/home': (context) => const HomeView(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
