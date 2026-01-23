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
import 'utils/system_ui_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for date formatting
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Warning: Failed to initialize locale data: $e');
  }

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemUIManager.initialize();

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
    WidgetsBinding.instance.addObserver(SystemUILifecycleObserver());
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
    SystemUIManager.enforce();
    
    return MaterialApp(
      key: KiosDarmaApp.appKey,
      title: 'KiosDarma',
      theme: AppTheme.theme.copyWith(
        appBarTheme: AppTheme.theme.appBarTheme.copyWith(
          systemOverlayStyle: SystemUIManager.style,
        ),
      ),
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
