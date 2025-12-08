import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class ResponsiveUtils {
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  /// Check if device is tablet (600 <= width < 1024)
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 1024;
  }

  /// Check if device is desktop (width >= 1024)
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1024;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.all(
      getResponsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final width = screenWidth(context);
    if (width < 360) {
      return baseFontSize * 0.9; // Small phones
    } else if (width >= 600) {
      return baseFontSize * 1.1; // Tablets and larger
    }
    return baseFontSize; // Normal phones
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(
    BuildContext context,
    double baseIconSize,
  ) {
    return getResponsiveValue(
      context: context,
      mobile: baseIconSize,
      tablet: baseIconSize * 1.2,
      desktop: baseIconSize * 1.4,
    );
  }

  /// Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isDesktop(context)) {
      return width * 0.3; // 30% on desktop
    } else if (isTablet(context)) {
      return width * 0.45; // 45% on tablet
    }
    return width * 0.9; // 90% on mobile
  }

  /// Get responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
  }

  /// Get max content width for large screens
  static double getMaxContentWidth(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1200.0,
    );
  }

  /// Center content on large screens
  static Widget centerContent({
    required BuildContext context,
    required Widget child,
  }) {
    final maxWidth = getMaxContentWidth(context);
    if (maxWidth == double.infinity) {
      return child;
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
