import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'biometric_service.dart';

/// Service to handle automatic biometric authentication when app comes to foreground
class AppLifecycleBiometricService {
  static bool _isAuthenticated = false;
  static bool _isAuthenticating = false;
  static DateTime? _lastBackgroundTime;
  static DateTime? _lastLoginTime;
  static const int _authTimeoutMinutes =
      5; // Require auth after 5 minutes in background
  static const int _loginGracePeriodSeconds =
      10; // Don't require auth for 10 seconds after login

  /// Check if user is currently authenticated
  static bool get isAuthenticated => _isAuthenticated;

  /// Set authentication status
  static void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    if (authenticated) {
      _lastLoginTime = DateTime.now();
    }
  }

  /// Handle app lifecycle changes
  static Future<void> handleAppLifecycleChange(
    AppLifecycleState state,
    BuildContext? context,
  ) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background
        _lastBackgroundTime = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        // App is coming to foreground
        await _handleAppResumed(context);
        break;

      case AppLifecycleState.detached:
        // App is being terminated
        _isAuthenticated = false;
        break;

      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }

  /// Handle app resumed from background
  static Future<void> _handleAppResumed(BuildContext? context) async {
    // Don't authenticate if already authenticating or if user is not logged in
    if (_isAuthenticating || context == null) return;

    // Check if biometric authentication is enabled
    final isBiometricEnabled = await BiometricService.isBiometricEnabled();
    if (!isBiometricEnabled) return;

    // Don't require authentication if user just logged in (grace period)
    if (_lastLoginTime != null) {
      final timeSinceLogin = DateTime.now().difference(_lastLoginTime!);
      if (timeSinceLogin.inSeconds < _loginGracePeriodSeconds) {
        return; // Still in grace period after login
      }
    }

    // Check if enough time has passed to require authentication
    if (_lastBackgroundTime != null && _isAuthenticated) {
      final timeDifference = DateTime.now().difference(_lastBackgroundTime!);
      if (timeDifference.inMinutes < _authTimeoutMinutes) {
        return; // No need to authenticate yet
      }
    }

    // If user is not authenticated, always require biometric authentication
    if (!_isAuthenticated) {
      // Show biometric authentication
      if (context.mounted) {
        await _showBiometricAuthentication(context);
      }
      return;
    }

    // If we reach here, user has been away for too long, require authentication
    final isBiometricAvailable = await BiometricService.isAvailable();
    if (!isBiometricAvailable) return;

    // Show biometric authentication
    if (context.mounted) {
      await _showBiometricAuthentication(context);
    }
  }

  /// Show biometric authentication overlay
  static Future<void> _showBiometricAuthentication(BuildContext context) async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;
    _isAuthenticated = false;

    try {
      // Show biometric authentication overlay
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const BiometricAuthenticationOverlay(),
      );

      if (result == true) {
        _isAuthenticated = true;
      } else {
        // If authentication failed, exit the app
        SystemNavigator.pop();
      }
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      // On error, exit the app for security
      SystemNavigator.pop();
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Force biometric authentication (for manual triggers)
  static Future<bool> forceBiometricAuthentication(BuildContext context) async {
    if (_isAuthenticating) return false;

    final isBiometricEnabled = await BiometricService.isBiometricEnabled();
    if (!isBiometricEnabled) return false;

    final isBiometricAvailable = await BiometricService.isAvailable();
    if (!isBiometricAvailable) return false;

    _isAuthenticating = true;
    _isAuthenticated = false;

    try {
      if (context.mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const BiometricAuthenticationOverlay(),
        );

        if (result == true) {
          _isAuthenticated = true;
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error during forced biometric authentication: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Reset authentication state (call when user logs out)
  static void reset() {
    _isAuthenticated = false;
    _isAuthenticating = false;
    _lastBackgroundTime = null;
    _lastLoginTime = null;
  }
}

/// Biometric authentication overlay widget
class BiometricAuthenticationOverlay extends StatefulWidget {
  const BiometricAuthenticationOverlay({super.key});

  @override
  State<BiometricAuthenticationOverlay> createState() =>
      _BiometricAuthenticationOverlayState();
}

class _BiometricAuthenticationOverlayState
    extends State<BiometricAuthenticationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAuthenticating = false;
  String _statusMessage = 'Authenticate to continue';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAuthentication();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _startAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      // Get available biometric names for display
      final biometricNames =
          await BiometricService.getAvailableBiometricNames();
      final authMethod = biometricNames.isNotEmpty
          ? biometricNames.first
          : 'biometric authentication';

      setState(() {
        _statusMessage = 'Use $authMethod to unlock';
      });

      final authenticated = await BiometricService.authenticate(
        reason: 'Authenticate to access Curevia',
      );

      if (authenticated) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = 'Authentication failed';
          });
        }
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Authentication error';
        });
      }
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App Name
                      Text(
                        'Curevia',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16),

                      // Biometric Icon
                      Icon(
                        Icons.fingerprint,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),

                      const SizedBox(height: 16),

                      // Status Message
                      Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Loading Indicator
                      if (_isAuthenticating)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
