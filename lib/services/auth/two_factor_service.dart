import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';

/// Service for handling two-factor authentication
class TwoFactorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _twoFactorEnabledKey = 'two_factor_enabled';
  static const String _twoFactorSecretKey = 'two_factor_secret';
  static const String _backupCodesKey = 'backup_codes';

  /// Generate a random secret for TOTP
  static String _generateSecret() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final Random random = Random.secure();
    return List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generate backup codes
  static List<String> _generateBackupCodes() {
    final Random random = Random.secure();
    return List.generate(10, (index) {
      return random.nextInt(100000000).toString().padLeft(8, '0');
    });
  }

  /// Setup two-factor authentication
  static Future<Map<String, dynamic>> setupTwoFactor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Generate secret and backup codes
      final String secret = _generateSecret();
      final List<String> backupCodes = _generateBackupCodes();

      // Create QR code data
      final String appName = 'Curevia';
      final String userEmail = user.email ?? 'user@curevia.com';
      final String qrData =
          'otpauth://totp/$appName:$userEmail?secret=$secret&issuer=$appName';

      return {'secret': secret, 'qrData': qrData, 'backupCodes': backupCodes};
    } catch (e) {
      print('Error setting up two-factor: $e');
      throw Exception('Failed to setup two-factor authentication');
    }
  }

  /// Enable two-factor authentication
  static Future<void> enableTwoFactor(
    String secret,
    List<String> backupCodes,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Save to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
            'twoFactorEnabled': true,
            'twoFactorSecret': secret,
            'backupCodes': backupCodes,
            'twoFactorEnabledAt': Timestamp.now(),
          });

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_twoFactorEnabledKey, true);
      await prefs.setString(_twoFactorSecretKey, secret);
      await prefs.setStringList(_backupCodesKey, backupCodes);
    } catch (e) {
      print('Error enabling two-factor: $e');
      throw Exception('Failed to enable two-factor authentication');
    }
  }

  /// Disable two-factor authentication
  static Future<void> disableTwoFactor() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Remove from Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
            'twoFactorEnabled': false,
            'twoFactorSecret': FieldValue.delete(),
            'backupCodes': FieldValue.delete(),
            'twoFactorDisabledAt': Timestamp.now(),
          });

      // Remove from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_twoFactorEnabledKey, false);
      await prefs.remove(_twoFactorSecretKey);
      await prefs.remove(_backupCodesKey);
    } catch (e) {
      print('Error disabling two-factor: $e');
      throw Exception('Failed to disable two-factor authentication');
    }
  }

  /// Check if two-factor authentication is enabled
  static Future<bool> isTwoFactorEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check Firestore first
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return data['twoFactorEnabled'] ?? false;
        }
      } catch (e) {
        print('Firestore error, checking local storage: $e');
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_twoFactorEnabledKey) ?? false;
    } catch (e) {
      print('Error checking two-factor status: $e');
      return false;
    }
  }

  /// Verify TOTP code during setup (with provided secret)
  static Future<bool> verifyTOTPWithSecret(String code, String secret) async {
    try {
      // Clean the input code (remove spaces, ensure it's 6 digits)
      final cleanCode = code.replaceAll(RegExp(r'\s+'), '').trim();
      if (cleanCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanCode)) {
        print('Invalid code format: $cleanCode');
        return false;
      }

      // Generate current TOTP with more time windows for better compatibility
      final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<String> validCodes = [];

      // Check multiple time windows (current, ±1, ±2 intervals)
      for (int i = -2; i <= 2; i++) {
        final timeWindow = currentTime + (i * 30);
        final generatedCode = OTP.generateTOTPCodeString(
          secret,
          timeWindow,
          length: 6,
          interval: 30,
          algorithm: Algorithm.SHA1,
        );
        validCodes.add(generatedCode);
      }

      print(
        'Testing setup code: $cleanCode against valid codes: ${validCodes.join(', ')}',
      );

      final isValid = validCodes.contains(cleanCode);
      print('Setup code verification result: $isValid');

      return isValid;
    } catch (e) {
      print('Error verifying setup TOTP: $e');
      return false;
    }
  }

  /// Verify TOTP code
  static Future<bool> verifyTOTP(String code) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      String? secret;

      // Try to get secret from Firestore first
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          secret = data['twoFactorSecret'];
        }
      } catch (e) {
        print('Firestore error, checking local storage: $e');
      }

      // Fallback to local storage
      if (secret == null) {
        final prefs = await SharedPreferences.getInstance();
        secret = prefs.getString(_twoFactorSecretKey);
      }

      if (secret == null) {
        throw Exception('Two-factor secret not found');
      }

      // Clean the input code (remove spaces, ensure it's 6 digits)
      final cleanCode = code.replaceAll(RegExp(r'\s+'), '').trim();
      if (cleanCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanCode)) {
        print('Invalid code format: $cleanCode');
        return false;
      }

      // Generate current TOTP with more time windows for better compatibility
      final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final List<String> validCodes = [];

      // Check multiple time windows (current, ±1, ±2 intervals)
      for (int i = -2; i <= 2; i++) {
        final timeWindow = currentTime + (i * 30);
        final generatedCode = OTP.generateTOTPCodeString(
          secret,
          timeWindow,
          length: 6,
          interval: 30,
          algorithm: Algorithm.SHA1,
        );
        validCodes.add(generatedCode);
      }

      print(
        'Testing code: $cleanCode against valid codes: ${validCodes.join(', ')}',
      );

      final isValid = validCodes.contains(cleanCode);
      print('Code verification result: $isValid');

      return isValid;
    } catch (e) {
      print('Error verifying TOTP: $e');
      return false;
    }
  }

  /// Verify backup code
  static Future<bool> verifyBackupCode(String code) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      List<String>? backupCodes;

      // Try to get backup codes from Firestore first
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          backupCodes = List<String>.from(data['backupCodes'] ?? []);
        }
      } catch (e) {
        print('Firestore error, checking local storage: $e');
      }

      // Fallback to local storage
      if (backupCodes == null || backupCodes.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        backupCodes = prefs.getStringList(_backupCodesKey) ?? [];
      }

      if (backupCodes.isEmpty) {
        throw Exception('No backup codes found');
      }

      // Check if code exists and remove it (one-time use)
      if (backupCodes.contains(code)) {
        backupCodes.remove(code);

        // Update Firestore
        try {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .update({'backupCodes': backupCodes});
        } catch (e) {
          print('Error updating Firestore backup codes: $e');
        }

        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_backupCodesKey, backupCodes);

        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying backup code: $e');
      return false;
    }
  }

  /// Get remaining backup codes count
  static Future<int> getBackupCodesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      List<String>? backupCodes;

      // Try Firestore first
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          backupCodes = List<String>.from(data['backupCodes'] ?? []);
        }
      } catch (e) {
        print('Firestore error, checking local storage: $e');
      }

      // Fallback to local storage
      if (backupCodes == null) {
        final prefs = await SharedPreferences.getInstance();
        backupCodes = prefs.getStringList(_backupCodesKey) ?? [];
      }

      return backupCodes.length;
    } catch (e) {
      print('Error getting backup codes count: $e');
      return 0;
    }
  }

  /// Generate new backup codes
  static Future<List<String>> regenerateBackupCodes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final List<String> newBackupCodes = _generateBackupCodes();

      // Update Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
            'backupCodes': newBackupCodes,
            'backupCodesRegeneratedAt': Timestamp.now(),
          });

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_backupCodesKey, newBackupCodes);

      return newBackupCodes;
    } catch (e) {
      print('Error regenerating backup codes: $e');
      throw Exception('Failed to regenerate backup codes');
    }
  }
}
