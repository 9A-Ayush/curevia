import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/app_theme_simple.dart';
import 'constants/app_constants.dart';
import 'utils/env_config.dart';
import 'screens/auth/splash_screen.dart';
import 'services/weather/weather_service.dart';
import 'services/auth/app_lifecycle_biometric_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main entry point of the Curevia app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvConfig.init();

  // Validate environment configuration
  if (!EnvConfig.validateConfig()) {
    print('Warning: Some required environment variables are missing');
  }

  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize weather service with saved API key
  await _initializeWeatherService();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: CureviaApp()));
}

/// Root widget of the Curevia application
class CureviaApp extends ConsumerStatefulWidget {
  const CureviaApp({super.key});

  @override
  ConsumerState<CureviaApp> createState() => _CureviaAppState();
}

class _CureviaAppState extends ConsumerState<CureviaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes for biometric authentication
    AppLifecycleBiometricService.handleAppLifecycleChange(state, context);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Update theme when system brightness changes
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    ref.read(themeProvider.notifier).updateSystemBrightness(brightness);
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(currentThemeModeProvider);

    // Convert AppThemeMode to ThemeMode
    ThemeMode materialThemeMode;
    switch (themeMode) {
      case AppThemeMode.light:
        materialThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        materialThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        materialThemeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: materialThemeMode,
      home: const SplashScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Prevent text scaling
          ),
          child: child!,
        );
      },
    );
  }
}

/// Initialize weather service with saved API key
Future<void> _initializeWeatherService() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedApiKey = prefs.getString('weather_api_key');

    if (savedApiKey != null && savedApiKey.isNotEmpty) {
      WeatherService.setApiKey(savedApiKey);
      print('Weather service initialized with saved API key');
    } else {
      // Set the provided OpenWeatherMap API key as default
      const defaultApiKey = 'cf98d18b597e8316fd53a4df8186d435';
      WeatherService.setApiKey(defaultApiKey);
      await prefs.setString('weather_api_key', defaultApiKey);
      print('Weather service initialized with default API key');
    }
  } catch (e) {
    print('Error initializing weather service: $e');
  }
}
