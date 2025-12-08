import 'package:flutter/material.dart';

/// Global navigation service for deep linking and navigation from anywhere
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current context
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigate to a named route
  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  /// Navigate and replace current route
  static Future<dynamic>? navigateReplaceTo(String routeName,
      {Object? arguments}) {
    return navigatorKey.currentState
        ?.pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Navigate and remove all previous routes
  static Future<dynamic>? navigateAndRemoveUntil(String routeName,
      {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack({dynamic result}) {
    navigatorKey.currentState?.pop(result);
  }

  /// Navigate to screen with widget
  static Future<dynamic>? navigateToWidget(Widget widget) {
    return navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => widget),
    );
  }

  /// Navigate and replace with widget
  static Future<dynamic>? navigateReplaceToWidget(Widget widget) {
    return navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => widget),
    );
  }

  /// Show dialog
  static Future<T?> showDialogWidget<T>(Widget dialog) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return showDialog<T>(
      context: context,
      builder: (context) => dialog,
    );
  }

  /// Show bottom sheet
  static Future<T?> showBottomSheetWidget<T>(Widget sheet) {
    final context = currentContext;
    if (context == null) return Future.value(null);
    
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => sheet,
    );
  }

  /// Show snackbar
  static void showSnackBar(String message, {bool isError = false}) {
    final context = currentContext;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
