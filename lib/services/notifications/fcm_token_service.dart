import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';

/// Service for managing FCM tokens in Firestore
class FCMTokenService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get FCM token for a user by their ID
  static Future<String?> getUserFCMToken(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user FCM token: $e');
      return null;
    }
  }

  /// Get FCM token for a doctor by their ID
  static Future<String?> getDoctorFCMToken(String doctorId) async {
    try {
      // First try to get from doctors collection
      final doctorDoc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();

      if (doctorDoc.exists) {
        final data = doctorDoc.data();
        final fcmToken = data?['fcmToken'] as String?;
        if (fcmToken != null) return fcmToken;
      }

      // Fallback to users collection
      return await getUserFCMToken(doctorId);
    } catch (e) {
      debugPrint('Error getting doctor FCM token: $e');
      return null;
    }
  }

  /// Get FCM tokens for all admins
  static Future<List<String>> getAdminFCMTokens() async {
    try {
      final adminQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'admin')
          .get();

      final tokens = <String>[];
      for (final doc in adminQuery.docs) {
        final data = doc.data();
        final fcmToken = data['fcmToken'] as String?;
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

  /// Update FCM token for a user
  static Future<void> updateUserFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated FCM token for user: $userId');
    } catch (e) {
      debugPrint('Error updating user FCM token: $e');
    }
  }

  /// Update FCM token for a doctor (sync to both collections)
  static Future<void> updateDoctorFCMToken(String doctorId, String fcmToken) async {
    try {
      final batch = _firestore.batch();

      // Update in users collection
      batch.update(
        _firestore.collection(AppConstants.usersCollection).doc(doctorId),
        {
          'fcmToken': fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update in doctors collection if it exists
      final doctorDoc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();

      if (doctorDoc.exists) {
        batch.update(
          _firestore.collection(AppConstants.doctorsCollection).doc(doctorId),
          {
            'fcmToken': fcmToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
      debugPrint('Updated FCM token for doctor: $doctorId');
    } catch (e) {
      debugPrint('Error updating doctor FCM token: $e');
    }
  }

  /// Remove FCM token for a user (on logout)
  static Future<void> removeUserFCMToken(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenRemovedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Removed FCM token for user: $userId');
    } catch (e) {
      debugPrint('Error removing user FCM token: $e');
    }
  }

  /// Get multiple user FCM tokens by IDs
  static Future<Map<String, String>> getMultipleUserFCMTokens(List<String> userIds) async {
    try {
      final tokens = <String, String>{};
      
      // Process in batches of 10 (Firestore limit)
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        
        final query = await _firestore
            .collection(AppConstants.usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in query.docs) {
          final data = doc.data();
          final fcmToken = data['fcmToken'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            tokens[doc.id] = fcmToken;
          }
        }
      }

      return tokens;
    } catch (e) {
      debugPrint('Error getting multiple user FCM tokens: $e');
      return {};
    }
  }

  /// Check if FCM token is valid (not expired)
  static Future<bool> isTokenValid(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final fcmToken = data?['fcmToken'] as String?;
        final updatedAt = data?['fcmTokenUpdatedAt'] as Timestamp?;
        
        if (fcmToken == null) return false;
        
        // Consider token valid if updated within last 30 days
        if (updatedAt != null) {
          final daysSinceUpdate = DateTime.now().difference(updatedAt.toDate()).inDays;
          return daysSinceUpdate <= 30;
        }
        
        return true; // Token exists but no timestamp
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking token validity: $e');
      return false;
    }
  }
}