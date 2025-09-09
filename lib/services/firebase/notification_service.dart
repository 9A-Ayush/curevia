import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/notification_model.dart';

/// Service for managing user notifications
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user notifications
  static Future<List<NotificationModel>> getUserNotifications(
    String userId,
  ) async {
    try {
      // Try the optimized query first
      try {
        final querySnapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

        return querySnapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList();
      } catch (indexError) {
        // If composite index doesn't exist, fall back to simpler query
        print(
          'Composite index not available, using fallback query: $indexError',
        );

        final querySnapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .limit(50)
            .get();

        final notifications = querySnapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList();

        // Sort manually since we can't use orderBy without index
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return notifications;
      }
    } catch (e) {
      print('Error getting notifications: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      // Try the composite query first
      try {
        final querySnapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        return querySnapshot.docs.length;
      } catch (indexError) {
        // If composite index doesn't exist, fall back to getting all user notifications
        // and filtering manually
        print(
          'Composite index not available for unread count, using fallback: $indexError',
        );

        final querySnapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final unreadCount = querySnapshot.docs
            .where((doc) => doc.data()['isRead'] == false)
            .length;

        return unreadCount;
      }
    } catch (e) {
      print('Error getting unread notifications count: $e');
      // Return 0 instead of throwing to prevent app crashes
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({
            'isRead': true,
            'readAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      // Try the composite query first
      try {
        final querySnapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        for (final doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      } catch (indexError) {
        // If composite index doesn't exist, fall back to getting all user notifications
        // and filtering manually
        print(
          'Composite index not available for mark all read, using fallback: $indexError',
        );

        final querySnapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['isRead'] == false) {
            batch.update(doc.reference, {
              'isRead': true,
              'readAt': Timestamp.fromDate(DateTime.now()),
            });
          }
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      // Don't throw to prevent app crashes
    }
  }

  /// Create notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection(AppConstants.notificationsCollection).add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Get notifications stream for real-time updates
  static Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    // Use simpler query without orderBy to avoid index requirements
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();

          // Sort manually to avoid index requirements
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return notifications;
        });
  }

  /// Get unread count stream for real-time updates
  static Stream<int> getUnreadCountStream(String userId) {
    // Use simpler query and filter manually to avoid composite index
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['isRead'] == false)
              .length,
        );
  }

  /// Create sample notifications for testing (development only)
  static Future<void> createSampleNotifications(String userId) async {
    try {
      final sampleNotifications = [
        {
          'title': 'Appointment Reminder',
          'message':
              'You have an appointment with Dr. Smith tomorrow at 2:00 PM',
          'type': 'appointment',
          'data': {'appointmentId': 'apt_123'},
        },
        {
          'title': 'Lab Results Ready',
          'message': 'Your blood test results are now available',
          'type': 'medical',
          'data': {'reportId': 'lab_456'},
        },
        {
          'title': 'Medication Reminder',
          'message': 'Time to take your evening medication',
          'type': 'medication',
          'data': {'medicationId': 'med_789'},
        },
        {
          'title': 'Health Tip',
          'message': 'Remember to drink at least 8 glasses of water daily',
          'type': 'health_tip',
          'data': {},
        },
      ];

      for (final notification in sampleNotifications) {
        await createNotification(
          userId: userId,
          title: notification['title'] as String,
          message: notification['message'] as String,
          type: notification['type'] as String,
          data: notification['data'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      print('Error creating sample notifications: $e');
    }
  }
}
