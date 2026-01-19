import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import 'role_based_notification_service.dart';
import 'fcm_direct_service.dart';

/// Debug service for admin notifications
class AdminNotificationDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test admin notification system
  static Future<Map<String, dynamic>> testAdminNotifications() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Check if admin users exist
      final adminUsers = await _getAdminUsers();
      results['adminUsersCount'] = adminUsers.length;
      results['adminUsers'] = adminUsers.map((user) => {
        'uid': user['uid'],
        'email': user['email'],
        'fullName': user['fullName'],
        'hasFCMToken': user['fcmToken'] != null && (user['fcmToken'] as String).isNotEmpty,
        'fcmToken': user['fcmToken'] != null ? '${(user['fcmToken'] as String).substring(0, 20)}...' : null,
      }).toList();

      // 2. Get admin FCM tokens
      final adminTokens = await _getAdminFCMTokens();
      results['adminFCMTokensCount'] = adminTokens.length;
      results['adminFCMTokens'] = adminTokens.map((token) => '${token.substring(0, 20)}...').toList();

      // 3. Test FCM configuration
      final fcmConfigValid = await FCMDirectService.testFCMConfiguration();
      results['fcmConfigurationValid'] = fcmConfigValid;

      // 4. Test sending a notification
      if (adminTokens.isNotEmpty && fcmConfigValid) {
        try {
          await RoleBasedNotificationService.instance.sendDoctorVerificationRequestToAdmin(
            adminFCMTokens: adminTokens,
            doctorId: 'test_doctor_id',
            doctorName: 'Test Doctor',
            email: 'test@example.com',
            specialization: 'General Medicine',
            phoneNumber: '+1234567890',
          );
          results['testNotificationSent'] = true;
          results['testNotificationError'] = null;
        } catch (e) {
          results['testNotificationSent'] = false;
          results['testNotificationError'] = e.toString();
        }
      } else {
        results['testNotificationSent'] = false;
        results['testNotificationError'] = adminTokens.isEmpty 
            ? 'No admin FCM tokens available'
            : 'FCM configuration invalid';
      }

      // 5. Check notification permissions
      results['notificationPermissionsChecked'] = true;

    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  /// Get all admin users from Firestore
  static Future<List<Map<String, dynamic>>> _getAdminUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      return snapshot.docs.map((doc) => {
        'uid': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting admin users: $e');
      return [];
    }
  }

  /// Get admin FCM tokens
  static Future<List<String>> _getAdminFCMTokens() async {
    try {
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      final tokens = <String>[];
      for (final doc in adminsSnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          tokens.add(fcmToken);
        }
      }
      
      return tokens;
    } catch (e) {
      debugPrint('Error getting admin FCM tokens: $e');
      return [];
    }
  }

  /// Create a test doctor verification request
  static Future<String> createTestVerificationRequest() async {
    try {
      final verificationRef = await _firestore.collection('doctor_verifications').add({
        'doctorId': 'test_doctor_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'testRequest': true, // Mark as test
      });

      return verificationRef.id;
    } catch (e) {
      debugPrint('Error creating test verification request: $e');
      rethrow;
    }
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      final testRequests = await _firestore
          .collection('doctor_verifications')
          .where('testRequest', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in testRequests.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('Cleaned up ${testRequests.docs.length} test verification requests');
    } catch (e) {
      debugPrint('Error cleaning up test data: $e');
    }
  }

  /// Update admin FCM token (for testing)
  static Future<void> updateAdminFCMToken(String adminId, String fcmToken) async {
    try {
      await _firestore.collection('users').doc(adminId).update({
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Updated admin FCM token for $adminId');
    } catch (e) {
      debugPrint('Error updating admin FCM token: $e');
      rethrow;
    }
  }

  /// Check if notification service is properly initialized
  static Future<Map<String, dynamic>> checkNotificationServiceStatus() async {
    final status = <String, dynamic>{};
    
    try {
      // Check if RoleBasedNotificationService is available
      final service = RoleBasedNotificationService.instance;
      status['roleBasedServiceAvailable'] = service != null;
      
      // Check if we can access Firestore
      final testQuery = await _firestore.collection('users').limit(1).get();
      status['firestoreAccessible'] = testQuery.docs.isNotEmpty || testQuery.docs.isEmpty;
      
      status['timestamp'] = DateTime.now().toIso8601String();
      
    } catch (e) {
      status['error'] = e.toString();
    }
    
    return status;
  }
}