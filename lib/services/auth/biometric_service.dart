import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling biometric authentication
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Request biometric permissions
  static Future<bool> requestPermissions() async {
    try {
      // For biometric authentication, we don't need explicit permissions
      // The local_auth package handles permissions internally
      // Just check if the device supports biometrics
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking biometric support: $e');
      return false;
    }
  }

  /// Check if biometric authentication is available on the device
  static Future<bool> isAvailable() async {
    try {
      // First check if device supports biometrics
      final bool isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) {
        print('Device does not support biometric authentication');
        return false;
      }

      // Check if we can check biometrics
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        print('Cannot check biometrics on this device');
        return false;
      }

      // Get available biometric types
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        print('No biometrics enrolled on this device');
        return false;
      }

      print(
        'Available biometrics: ${availableBiometrics.map((e) => e.name).join(', ')}',
      );
      return true;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if fingerprint is available
  static Future<bool> isFingerprintAvailable() async {
    try {
      final List<BiometricType> availableBiometrics =
          await getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      print('Error checking fingerprint availability: $e');
      return false;
    }
  }

  /// Authenticate using biometrics
  static Future<bool> authenticate({
    String reason = 'Please authenticate to access your account',
  }) async {
    try {
      final bool isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available');
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      if (e.code == 'NotAvailable') {
        throw Exception('Biometric authentication is not available');
      } else if (e.code == 'NotEnrolled') {
        throw Exception('No biometrics enrolled on this device');
      } else if (e.code == 'LockedOut') {
        throw Exception('Too many failed attempts. Please try again later');
      } else if (e.code == 'PermanentlyLockedOut') {
        throw Exception('Biometric authentication is permanently locked');
      } else {
        throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      print('Unexpected biometric error: $e');
      throw Exception('Authentication failed');
    }
  }

  /// Enable biometric authentication
  static Future<bool> enableBiometric() async {
    try {
      // First request permissions
      final bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Biometric permissions not granted');
      }

      // Check if biometric is available
      final bool isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        throw Exception(
          'Biometric authentication is not available on this device',
        );
      }

      // Test authentication
      final bool authenticated = await authenticate(
        reason: 'Authenticate to enable biometric login',
      );

      if (authenticated) {
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, true);
        return true;
      }

      return false;
    } catch (e) {
      print('Error enabling biometric: $e');
      rethrow;
    }
  }

  /// Disable biometric authentication
  static Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
    } catch (e) {
      print('Error disabling biometric: $e');
      throw Exception('Failed to disable biometric authentication');
    }
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }

  /// Get detailed diagnostic information about biometric authentication
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();
      final bool isFingerprintAvailable = availableBiometrics.contains(
        BiometricType.fingerprint,
      );
      final bool isEnabled = await isBiometricEnabled();

      return {
        'isDeviceSupported': isDeviceSupported,
        'canCheckBiometrics': canCheckBiometrics,
        'availableBiometrics': availableBiometrics.map((e) => e.name).toList(),
        'isFingerprintAvailable': isFingerprintAvailable,
        'isEnabled': isEnabled,
        'hasAnyBiometrics': availableBiometrics.isNotEmpty,
        'biometricCount': availableBiometrics.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isDeviceSupported': false,
        'canCheckBiometrics': false,
        'availableBiometrics': <String>[],
        'isFingerprintAvailable': false,
        'isEnabled': false,
        'hasAnyBiometrics': false,
        'biometricCount': 0,
      };
    }
  }

  /// Get biometric type name for display
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Biometric';
    }
  }

  /// Get available biometric names for display
  static Future<List<String>> getAvailableBiometricNames() async {
    try {
      final List<BiometricType> types = await getAvailableBiometrics();
      return types.map((type) => getBiometricTypeName(type)).toList();
    } catch (e) {
      print('Error getting biometric names: $e');
      return [];
    }
  }
}
