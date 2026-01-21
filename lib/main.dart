import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'routes/auth_wrapper.dart';
import 'pages/onboarding_page.dart';
import 'routes/app_routes.dart';
import 'themes/app_theme.dart';
import 'services/settings_service.dart';

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
  // UI scale setting stored with 'settings_' prefix per SettingsService convention
  final uiScalePreset = prefs.getString('settings_${SettingsService.keyUIScale}') ?? 'normal';

  runApp(KiosDarmaApp(hasSeenOnboarding: hasSeenOnboarding, initialUIScale: uiScalePreset));
}

class KiosDarmaApp extends StatefulWidget {
  const KiosDarmaApp({super.key, required this.hasSeenOnboarding, required this.initialUIScale});

  final bool hasSeenOnboarding;
  final String initialUIScale;

  // Global key to allow UI scale updates from anywhere
  static final GlobalKey<_KiosDarmaAppState> appKey = GlobalKey<_KiosDarmaAppState>();
  
  static void updateUIScale(String preset) {
    appKey.currentState?.updateUIScale(preset);
  }

  @override
  State<KiosDarmaApp> createState() => _KiosDarmaAppState();
}

class _KiosDarmaAppState extends State<KiosDarmaApp> {
  late bool _hasSeenOnboarding;
  late String _uiScalePreset;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.hasSeenOnboarding;
    _uiScalePreset = widget.initialUIScale;
  }

  void _handleOnboardingFinished() {
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  void updateUIScale(String preset) {
    if (['small', 'normal', 'large', 'extra_large'].contains(preset)) {
      setState(() {
        _uiScalePreset = preset;
      });
    }
  }

  double get _scaleFactor {
    switch (_uiScalePreset) {
      case 'small': return 0.9;
      case 'large': return 1.15;
      case 'extra_large': return 1.3;
      default: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: KiosDarmaApp.appKey,
      title: 'KiosDarma',
      theme: AppTheme.theme,
      // Apply global UI scaling via MediaQuery
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Apply text scale only (not affecting layout/hitboxes)
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(_scaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Routing setup: AuthWrapper handles authentication state
      home: _hasSeenOnboarding
          ? const AuthWrapper()
          : OnboardingPage(
              onFinished: _handleOnboardingFinished,
            ),
      routes: AppRoutes.getRoutes(),
      debugShowCheckedModeBanner: false,
    );
  }
}

