import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode { light, dark, system }

/// Theme state
class ThemeState {
  final AppThemeMode themeMode;
  final bool isDarkMode;

  const ThemeState({required this.themeMode, required this.isDarkMode});

  ThemeState copyWith({AppThemeMode? themeMode, bool? isDarkMode}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// Theme notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'app_theme_mode';

  ThemeNotifier()
    : super(
        const ThemeState(themeMode: AppThemeMode.system, isDarkMode: false),
      ) {
    _loadTheme();
  }

  /// Load saved theme from preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      AppThemeMode themeMode = AppThemeMode.system;
      if (savedTheme != null) {
        themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => AppThemeMode.system,
        );
      }

      // Determine if dark mode should be active
      bool isDarkMode = false;
      if (themeMode == AppThemeMode.dark) {
        isDarkMode = true;
      } else if (themeMode == AppThemeMode.system) {
        // Get system brightness
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        isDarkMode = brightness == Brightness.dark;
      }

      state = ThemeState(themeMode: themeMode, isDarkMode: isDarkMode);
    } catch (e) {
      // If loading fails, keep default theme
      debugPrint('Error loading theme: $e');
    }
  }

  /// Save theme to preferences
  Future<void> _saveTheme(AppThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeMode.name);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    bool isDarkMode = false;

    if (themeMode == AppThemeMode.dark) {
      isDarkMode = true;
    } else if (themeMode == AppThemeMode.system) {
      // Get system brightness
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
    }

    state = ThemeState(themeMode: themeMode, isDarkMode: isDarkMode);

    await _saveTheme(themeMode);
  }

  /// Update system brightness (called when system theme changes)
  void updateSystemBrightness(Brightness brightness) {
    if (state.themeMode == AppThemeMode.system) {
      state = state.copyWith(isDarkMode: brightness == Brightness.dark);
    }
  }

  /// Get theme mode display name
  String getThemeModeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  /// Get theme mode description
  String getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system settings';
    }
  }

  /// Get theme mode icon
  IconData getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Current theme mode provider
final currentThemeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

/// Is dark mode provider
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDarkMode;
});

/// Theme data provider for light theme
final lightThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50), // AppColors.primary
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
});

/// Theme data provider for dark theme
final darkThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF66BB6A), // Lighter green for dark mode
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
          primary: const Color(0xFF66BB6A),
          onPrimary: Colors.black,
          secondary: const Color(0xFF81C784),
          onSecondary: Colors.black,
        ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF66BB6A)),
      ),
      fillColor: const Color(0xFF2C2C2C),
      filled: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF66BB6A),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF66BB6A),
      unselectedItemColor: Color(0xFF757575),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1E1E1E)),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1E1E)),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF2C2C2C),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
});

/// Current theme data provider
final currentThemeProvider = Provider<ThemeData>((ref) {
  final isDarkMode = ref.watch(isDarkModeProvider);
  if (isDarkMode) {
    return ref.watch(darkThemeProvider);
  } else {
    return ref.watch(lightThemeProvider);
  }
});
