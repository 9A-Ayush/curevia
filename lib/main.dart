import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/app_theme_simple.dart';
import 'constants/app_constants.dart';
import 'utils/env_config.dart';
import 'screens/splash/splash_screen.dart';
import 'services/weather/weather_service.dart';
import 'services/auth/app_lifecycle_biometric_service.dart';
import 'services/navigation_service.dart';
import 'services/firebase/medicine_service.dart';
import 'services/firebase/home_remedies_service.dart';
import 'services/cloudinary_service.dart';
import 'services/notifications/notification_integration_service.dart';

import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main entry point of the Curevia app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize only essential services for fast startup
  await EnvConfig.init();
  
  // Initialize Firebase (essential for auth)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: CureviaApp()));
  
  // Initialize non-essential services after app starts
  _initializeBackgroundServices();
}

/// Initialize background services that don't block app startup
Future<void> _initializeBackgroundServices() async {
  // Validate environment configuration
  if (!EnvConfig.validateConfig()) {
    print('Warning: Some required environment variables are missing');
  }

  // Initialize Cloudinary service
  try {
    CloudinaryService.initialize();
    print('Cloudinary service initialized successfully');
  } catch (e) {
    print('Warning: Failed to initialize Cloudinary service: $e');
  }

  // Initialize app data (medicines and home remedies)
  await _initializeAppData();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize weather service with saved API key
  await _initializeWeatherService();

  // Initialize FCM and notification services
  try {
    await NotificationIntegrationService.instance.initialize();
    print('✅ Notification system initialized successfully');
  } catch (e) {
    print('❌ Warning: Failed to initialize notification system: $e');
  }
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
    
    // Handle app lifecycle changes for notifications
    NotificationIntegrationService.instance.handleAppLifecycleChange(state);
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
      navigatorKey: NavigationService.navigatorKey, // Use navigation service's navigator key
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

/// Initialize app data (medicines and home remedies)
Future<void> _initializeAppData() async {
  try {
    print('=== INITIALIZING APP DATA ===');
    
    // Check if medicine data exists
    final hasMedicineData = await MedicineService.hasMedicineData();
    print('Medicine data exists: $hasMedicineData');
    
    if (!hasMedicineData) {
      print('Seeding medicine data...');
      await MedicineService.seedMedicineData();
      print('Medicine data seeded successfully');
    }
    
    // Check if home remedies data exists
    final hasRemediesData = await HomeRemediesService.hasRemediesData();
    print('Remedies data exists: $hasRemediesData');
    
    if (!hasRemediesData) {
      print('Seeding home remedies data...');
      await HomeRemediesService.seedHomeRemediesData();
      print('Home remedies data seeded successfully');
    }
    
    print('=== APP DATA INITIALIZATION COMPLETED ===');
  } catch (e) {
    print('=== ERROR INITIALIZING APP DATA ===');
    print('Error details: $e');
    print('Stack trace: ${StackTrace.current}');
    
    // Try to force seed even if check fails
    try {
      print('Attempting force seed...');
      await MedicineService.seedMedicineData();
      await HomeRemediesService.seedHomeRemediesData();
      print('Force seed completed');
    } catch (forceError) {
      print('Force seed also failed: $forceError');
    }
  }
}


