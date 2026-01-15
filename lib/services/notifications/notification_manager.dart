import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import 'fcm_service.dart';
import 'notification_handler.dart';
import 'notification_scheduler.dart';
import '../storage/notification_storage_service.dart';

/// Central notification manager that coordinates all notification services
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  static NotificationManager get instance => _instance;

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Initialize the notification system
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for ongoing initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;

    try {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialize FCM service
      await FCMService.instance.initialize();

      // Clean up old notifications
      await NotificationStorageService.cleanupOldNotifications();

      // Initialize badge count
      await NotificationHandler.initializeBadgeCount();

      _isInitialized = true;
      _isInitializing = false;
      debugPrint('Notification Manager initialized successfully');
    } catch (e) {
      _isInitializing = false;
      debugPrint('Error initializing Notification Manager: $e');
      rethrow;
    }
  }

  /// Check if the notification system is initialized
  bool get isInitialized => _isInitialized;

  /// Get FCM token
  String? get fcmToken => FCMService.instance.fcmToken;

  // APPOINTMENT NOTIFICATIONS

  /// Send appointment reminder notification
  Future<void> sendAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required String patientName,
    required DateTime appointmentTime,
    required String appointmentType,
    required String patientFCMToken,
    required String doctorFCMToken,
  }) async {
    try {
      // Create notifications for both patient and doctor
      final patientNotification = NotificationHandler.createAppointmentReminder(
        appointmentId: appointmentId,
        doctorName: doctorName,
        patientName: patientName,
        appointmentTime: appointmentTime,
        appointmentType: appointmentType,
        isForDoctor: false,
      );

      final doctorNotification = NotificationHandler.createAppointmentReminder(
        appointmentId: appointmentId,
        doctorName: doctorName,
        patientName: patientName,
        appointmentTime: appointmentTime,
        appointmentType: appointmentType,
        isForDoctor: true,
      );

      // TODO: Send FCM messages to patient and doctor tokens
      // This would typically involve calling your backend API
      await _sendFCMMessage(patientFCMToken, patientNotification);
      await _sendFCMMessage(doctorFCMToken, doctorNotification);

      debugPrint('Sent appointment reminder notifications');
    } catch (e) {
      debugPrint('Error sending appointment reminder: $e');
    }
  }

  /// Schedule appointment reminders
  Future<void> scheduleAppointmentReminders({
    required String appointmentId,
    required String doctorName,
    required String patientName,
    required DateTime appointmentTime,
    required String appointmentType,
    required String userId,
    required bool isForDoctor,
  }) async {
    await NotificationScheduler.instance.scheduleAppointmentReminders(
      appointmentId: appointmentId,
      doctorName: doctorName,
      patientName: patientName,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
      isForDoctor: isForDoctor,
      userId: userId,
    );
  }

  /// Cancel appointment reminders
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    await NotificationScheduler.instance.cancelAppointmentReminders(appointmentId);
  }

  // PAYMENT NOTIFICATIONS

  /// Send payment success notification
  Future<void> sendPaymentSuccessNotification({
    required String paymentId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String userFCMToken,
  }) async {
    try {
      final notification = NotificationHandler.createPaymentSuccess(
        paymentId: paymentId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
      );

      // Send FCM message
      await _sendFCMMessage(userFCMToken, notification);

      debugPrint('Sent payment success notification');
    } catch (e) {
      debugPrint('Error sending payment success notification: $e');
    }
  }

  // DOCTOR VERIFICATION NOTIFICATIONS

  /// Send doctor verification request notification to admin
  Future<void> sendDoctorVerificationRequest({
    required String doctorId,
    required String doctorName,
    required String email,
    required String specialization,
    required List<String> adminFCMTokens,
  }) async {
    try {
      final notification = NotificationHandler.createDoctorVerificationRequest(
        doctorId: doctorId,
        doctorName: doctorName,
        email: email,
        specialization: specialization,
      );

      // Send to all admin tokens
      for (final token in adminFCMTokens) {
        await _sendFCMMessage(token, notification);
      }

      debugPrint('Sent doctor verification request notification');
    } catch (e) {
      debugPrint('Error sending doctor verification request: $e');
    }
  }

  // TOPIC SUBSCRIPTIONS

  /// Subscribe user to relevant topics based on their role
  Future<void> subscribeToTopics({
    required String userType, // 'patient', 'doctor', 'admin'
    required String userId,
    List<String>? specializations,
  }) async {
    try {
      // Subscribe to general topics
      await FCMService.instance.subscribeToTopic('all_users');
      await FCMService.instance.subscribeToTopic(userType);

      // Subscribe to user-specific topic
      await FCMService.instance.subscribeToTopic('user_$userId');

      // Subscribe to role-specific topics
      switch (userType) {
        case 'patient':
          await FCMService.instance.subscribeToTopic('patients');
          break;
        case 'doctor':
          await FCMService.instance.subscribeToTopic('doctors');
          // Subscribe to specialization topics
          if (specializations != null) {
            for (final specialization in specializations) {
              await FCMService.instance.subscribeToTopic('doctors_$specialization');
            }
          }
          break;
        case 'admin':
          await FCMService.instance.subscribeToTopic('admins');
          await FCMService.instance.subscribeToTopic('doctor_verification_requests');
          break;
      }

      debugPrint('Subscribed to topics for $userType: $userId');
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }

  /// Unsubscribe from topics (for logout)
  Future<void> unsubscribeFromAllTopics({
    required String userType,
    required String userId,
    List<String>? specializations,
  }) async {
    try {
      // Unsubscribe from general topics
      await FCMService.instance.unsubscribeFromTopic('all_users');
      await FCMService.instance.unsubscribeFromTopic(userType);
      await FCMService.instance.unsubscribeFromTopic('user_$userId');

      // Unsubscribe from role-specific topics
      switch (userType) {
        case 'patient':
          await FCMService.instance.unsubscribeFromTopic('patients');
          break;
        case 'doctor':
          await FCMService.instance.unsubscribeFromTopic('doctors');
          if (specializations != null) {
            for (final specialization in specializations) {
              await FCMService.instance.unsubscribeFromTopic('doctors_$specialization');
            }
          }
          break;
        case 'admin':
          await FCMService.instance.unsubscribeFromTopic('admins');
          await FCMService.instance.unsubscribeFromTopic('doctor_verification_requests');
          break;
      }

      debugPrint('Unsubscribed from topics for $userType: $userId');
    } catch (e) {
      debugPrint('Error unsubscribing from topics: $e');
    }
  }

  // TOKEN MANAGEMENT

  /// Send FCM token to server
  Future<void> sendTokenToServer({
    required String userId,
    required String userType,
  }) async {
    await FCMService.instance.sendTokenToServer(userId, userType);
  }

  /// Clear FCM token (for logout)
  Future<void> clearToken() async {
    await FCMService.instance.clearToken();
  }

  // NOTIFICATION HISTORY

  /// Get all notifications
  Future<List<NotificationModel>> getAllNotifications({String? userRole}) async {
    if (userRole != null) {
      return await NotificationStorageService.getNotificationsForRole(userRole);
    }
    return await NotificationStorageService.getAllNotifications();
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications({String? userRole}) async {
    if (userRole != null) {
      return await NotificationStorageService.getUnreadNotificationsForRole(userRole);
    }
    return await NotificationStorageService.getUnreadNotifications();
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    return await NotificationStorageService.getUnreadNotificationCount();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await NotificationHandler.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await NotificationHandler.markAllAsRead();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await NotificationHandler.deleteNotification(notificationId);
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await NotificationHandler.clearAllNotifications();
  }

  // TEST METHODS

  /// Send test notification (for testing purposes)
  Future<void> sendTestNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: data ?? {},
        timestamp: DateTime.now(),
      );

      // Save the notification locally for testing
      await NotificationStorageService.saveNotification(notification);
      
      // Show in-app notification
      await NotificationHandler.handleNotificationReceived(notification);

      debugPrint('Test notification sent: $title');
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  // UTILITY METHODS

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    return await NotificationStorageService.getNotificationStats();
  }

  /// Send FCM message to specific token (public method for role-based service)
  Future<void> sendFCMMessage(String token, NotificationModel notification) async {
    await _sendFCMMessage(token, notification);
  }

  /// Private method to send FCM message (placeholder)
  Future<void> _sendFCMMessage(String token, NotificationModel notification) async {
    // TODO: Implement actual FCM message sending via your backend API
    // This is typically done through your server, not directly from the client
    
    debugPrint('Would send FCM message to token: ${token.substring(0, 20)}...');
    debugPrint('Notification: ${notification.title} - ${notification.body}');
    
    // For now, just save the notification locally for testing
    await NotificationStorageService.saveNotification(notification);
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        debugPrint('App resumed - checking for pending notifications');
        break;
      case AppLifecycleState.paused:
        // App went to background
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        debugPrint('App detached');
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        debugPrint('App inactive');
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        debugPrint('App hidden');
        break;
    }
  }

  /// Show local notification (private method)
  Future<void> _showLocalNotification(NotificationModel notification) async {
    // Delegate to FCM service
    // We'll create a public method in FCM service for this
    debugPrint('Showing local notification: ${notification.title}');
    
    // For now, just save the notification locally
    await NotificationStorageService.saveNotification(notification);
  }
}