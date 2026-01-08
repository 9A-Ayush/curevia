import 'package:flutter/material.dart';

/// App color scheme for Curevia
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32); // Green
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  // Secondary Colors
  static const Color secondary = Color(0xFF1976D2); // Blue
  static const Color secondaryLight = Color(0xFF63A4FF);
  static const Color secondaryDark = Color(0xFF004BA0);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B35); // Orange
  static const Color accentLight = Color(0xFFFF9B6B);
  static const Color accentDark = Color(0xFFC73E00);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Specialty Colors
  static const Color cardiology = Color(0xFFE91E63);
  static const Color dermatology = Color(0xFF9C27B0);
  static const Color pediatrics = Color(0xFF3F51B5);
  static const Color gynecology = Color(0xFF673AB7);
  static const Color orthopedics = Color(0xFF795548);
  static const Color neurology = Color(0xFF607D8B);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF9E9E9E);

  // Overlay Colors
  static const Color overlayLight = Color(0x33000000);
  static const Color overlayMedium = Color(0x66000000);
  static const Color overlayDark = Color(0x99000000);

  // Rating Colors
  static const Color ratingEmpty = Color(0xFFE0E0E0);
  static const Color ratingFilled = Color(0xFFFFD700);

  // Health Category Colors
  static const Color medicineCategory = Color(0xFF4CAF50);
  static const Color remedyCategory = Color(0xFF8BC34A);
  static const Color symptomCategory = Color(0xFFFF9800);
  static const Color emergencyCategory = Color(0xFFF44336);

  // Consultation Status Colors
  static const Color consultationPending = Color(0xFFFF9800);
  static const Color consultationActive = Color(0xFF4CAF50);
  static const Color consultationCompleted = Color(0xFF2196F3);
  static const Color consultationCancelled = Color(0xFFF44336);

  // Payment Status Colors
  static const Color paymentPending = Color(0xFFFF9800);
  static const Color paymentSuccess = Color(0xFF4CAF50);
  static const Color paymentFailed = Color(0xFFF44336);
  static const Color paymentRefunded = Color(0xFF9C27B0);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2E7D32),
    Color(0xFF1976D2),
    Color(0xFFFF6B35),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF607D8B),
    Color(0xFFE91E63),
  ];

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Disabled Colors
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color disabledBackground = Color(0xFFF5F5F5);

  // Transparent
  static const Color transparent = Colors.transparent;

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);

  // Dark Theme Primary Colors
  static const Color darkPrimary = Color(0xFF66BB6A);
  static const Color darkPrimaryLight = Color(0xFF98EE99);
  static const Color darkPrimaryDark = Color(0xFF338A3E);

  // Dark Theme Secondary Colors
  static const Color darkSecondary = Color(0xFF64B5F6);
  static const Color darkSecondaryLight = Color(0xFF9BE7FF);
  static const Color darkSecondaryDark = Color(0xFF2286C3);

  // Dark Theme Text Colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE0E0E0);
  static const Color darkTextHint = Color(0xFFB0B0B0);
  static const Color darkTextOnPrimary = Color(0xFF000000);

  // Dark Theme Status Colors
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkInfo = Color(0xFF42A5F5);

  // Dark Theme Border Colors
  static const Color darkBorderLight = Color(0xFF424242);
  static const Color darkBorderMedium = Color(0xFF616161);
  static const Color darkBorderDark = Color(0xFF757575);

  // Dark Theme Shadow Colors
  static const Color darkShadowLight = Color(0x33000000);
  static const Color darkShadowMedium = Color(0x66000000);
  static const Color darkShadowDark = Color(0x99000000);

  // Dark Theme Gradients
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [darkPrimary, darkPrimaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSecondaryGradient = LinearGradient(
    colors: [darkSecondary, darkSecondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Theme Shimmer Colors
  static const Color darkShimmerBase = Color(0xFF2C2C2C);
  static const Color darkShimmerHighlight = Color(0xFF424242);

  // Dark Theme Disabled Colors
  static const Color darkDisabled = Color(0xFF616161);
  static const Color darkDisabledBackground = Color(0xFF2C2C2C);
}
