import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Utility class for theme-aware color selection
class ThemeUtils {
  /// Get primary color based on current theme
  static Color getPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkPrimary : AppColors.primary;
  }

  /// Get secondary color based on current theme
  static Color getSecondaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSecondary : AppColors.secondary;
  }

  /// Get surface color based on current theme
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSurface : AppColors.surface;
  }

  /// Get background color based on current theme
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBackground : AppColors.background;
  }

  /// Get surface variant color based on current theme
  static Color getSurfaceVariantColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
  }

  /// Get primary text color based on current theme
  static Color getTextPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  }

  /// Get secondary text color based on current theme
  static Color getTextSecondaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  }

  /// Get hint text color based on current theme
  static Color getTextHintColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkTextHint : AppColors.textHint;
  }

  /// Get text on primary color based on current theme
  static Color getTextOnPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkTextOnPrimary : AppColors.textOnPrimary;
  }

  /// Get border light color based on current theme
  static Color getBorderLightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorderLight : AppColors.borderLight;
  }

  /// Get border medium color based on current theme
  static Color getBorderMediumColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkBorderMedium : AppColors.borderMedium;
  }

  /// Get shadow light color based on current theme
  static Color getShadowLightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkShadowLight : AppColors.shadowLight;
  }

  /// Get disabled color based on current theme
  static Color getDisabledColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkDisabled : AppColors.disabled;
  }

  /// Get disabled background color based on current theme
  static Color getDisabledBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.darkDisabledBackground
        : AppColors.disabledBackground;
  }

  /// Get success color based on current theme
  static Color getSuccessColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSuccess : AppColors.success;
  }

  /// Get warning color based on current theme
  static Color getWarningColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkWarning : AppColors.warning;
  }

  /// Get error color based on current theme
  static Color getErrorColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkError : AppColors.error;
  }

  /// Get info color based on current theme
  static Color getInfoColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkInfo : AppColors.info;
  }

  /// Get shimmer base color based on current theme
  static Color getShimmerBaseColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase;
  }

  /// Get shimmer highlight color based on current theme
  static Color getShimmerHighlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight;
  }

  /// Get primary color with opacity based on current theme
  static Color getPrimaryColorWithOpacity(
    BuildContext context,
    double opacity,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkPrimary : AppColors.primary;
    return color.withValues(alpha: opacity);
  }

  /// Get surface color with opacity based on current theme
  static Color getSurfaceColorWithOpacity(
    BuildContext context,
    double opacity,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkSurface : AppColors.surface;
    return color.withValues(alpha: opacity);
  }

  /// Get secondary color with opacity based on current theme
  static Color getSecondaryColorWithOpacity(
    BuildContext context,
    double opacity,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkSecondary : AppColors.secondary;
    return color.withValues(alpha: opacity);
  }

  /// Check if current theme is dark
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get appropriate icon color for current theme
  static Color getIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  }

  /// Get card color based on current theme
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Get scaffold background color based on current theme
  static Color getScaffoldBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Get divider color based on current theme
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  /// Get app bar background color based on current theme
  static Color getAppBarBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkSurface : AppColors.primary;
  }

  /// Get app bar foreground color based on current theme
  static Color getAppBarForegroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkTextPrimary : Colors.white;
  }
}
