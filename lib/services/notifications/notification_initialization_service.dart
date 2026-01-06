import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/notification_model.dart';
import 'notification_manager.dart';
import 'role_based_notification_service.dart';
import 'fcm_service.dart';

/// Service to initialize the complete notification system
/// Handles setup, permissions, and role-based subscriptions
class NotificationInitializationService {
  static final NotificationInitializationService _instance = NotificationInitializationService._internal();
  factory NotificationInitializationService() => _instance;
  NotificationInitializationService._internal();

  static NotificationInitializationService get instance => _instance;

  bool _isInitialized = false;

  /// Initialize the complete notification system
  Future<bool> initializeNotificationSystem() async {
    if (_isInitialized) return true;

    try {
      debugPrint('🔔 Initializing Curevia Notification System...');

      // Step 1: Initialize core notification manager
      await NotificationManager.instance.initialize();
      debugPrint('✅ Core notification manager initialized');

      // Step 2: Verify FCM service is ready
      if (!FCMService.instance.isInitialized) {
        throw Exception('FCM Service failed to initialize');
      }
      debugPrint('✅ FCM service ready');

      // Step 3: Get FCM token
      final fcmToken = FCMService.instance.fcmToken;
      if (fcmToken == null) {
        debugPrint('⚠️ FCM token not available yet - will retry');
        return false;
      }
      debugPrint('✅ FCM token obtained: ${fcmToken.substring(0, 20)}...');

      _isInitialized = true;
      debugPrint('🎉 Notification system initialized successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing notification system: $e');
      return false;
    }
  }

  /// Setup user-specific notifications after login
  Future<void> setupUserNotifications({
    required UserModel user,
    List<String>? specializations,
    String? location,
  }) async {
    try {
      if (!_isInitialized) {
        final initialized = await initializeNotificationSystem();
        if (!initialized) {
          throw Exception('Failed to initialize notification system');
        }
      }

      debugPrint('🔔 Setting up notifications for user: ${user.fullName} (${user.role})');

      // Step 1: Subscribe to role-based topics
      await RoleBasedNotificationService.instance.subscribeUserToRoleTopics(
        userId: user.uid,
        userRole: user.role.toLowerCase(),
        specializations: specializations,
        location: location,
      );

      // Step 2: Send FCM token to server (for targeted notifications)
      await NotificationManager.instance.sendTokenToServer(
        userId: user.uid,
        userType: user.role.toLowerCase(),
      );

      // Step 3: Send welcome notification based on role
      await _sendWelcomeNotification(user);

      debugPrint('✅ User notifications setup complete for: ${user.fullName}');
    } catch (e) {
      debugPrint('❌ Error setting up user notifications: $e');
    }
  }

  /// Send role-specific welcome notification
  Future<void> _sendWelcomeNotification(UserModel user) async {
    try {
      String title;
      String body;
      
      switch (user.role.toLowerCase()) {
        case 'patient':
          title = 'Welcome to Curevia! 🏥';
          body = 'Hi ${user.fullName}! Your health journey starts here. Book appointments, track your health, and stay connected with top doctors.';
          break;
        case 'doctor':
          title = 'Welcome Dr. ${user.fullName}! 🩺';
          body = 'Ready to help patients? Complete your verification to start accepting appointments and providing care.';
          break;
        case 'admin':
          title = 'Admin Access Granted 🛡️';
          body = 'Welcome ${user.fullName}! You now have admin access to manage doctors, verify accounts, and oversee the platform.';
          break;
        default:
          title = 'Welcome to Curevia!';
          body = 'Hi ${user.fullName}! Thanks for joining our healthcare platform.';
      }

      await NotificationManager.instance.sendTestNotification(
        title: title,
        body: body,
        type: NotificationType.general,
        data: {
          'welcomeMessage': true,
          'userRole': user.role,
          'userId': user.uid,
        },
      );
    } catch (e) {
      debugPrint('Error sending welcome notification: $e');
    }
  }

  /// Cleanup notifications on logout
  Future<void> cleanupUserNotifications({
    required String userId,
    required String userRole,
    List<String>? specializations,
    String? location,
  }) async {
    try {
      debugPrint('🧹 Cleaning up notifications for user: $userId');

      // Step 1: Unsubscribe from all topics
      await RoleBasedNotificationService.instance.unsubscribeUserFromRoleTopics(
        userId: userId,
        userRole: userRole.toLowerCase(),
        specializations: specializations,
        location: location,
      );

      // Step 2: Clear FCM token
      await NotificationManager.instance.clearToken();

      // Step 3: Clear local notifications (optional)
      // await NotificationManager.instance.clearAllNotifications();

      debugPrint('✅ User notifications cleanup complete');
    } catch (e) {
      debugPrint('❌ Error cleaning up user notifications: $e');
    }
  }

  /// Check notification permissions and request if needed
  Future<bool> checkAndRequestPermissions() async {
    try {
      // The FCM service already handles permission requests during initialization
      // This method can be used to check current permission status
      
      final fcmToken = FCMService.instance.fcmToken;
      if (fcmToken != null) {
        debugPrint('✅ Notification permissions granted');
        return true;
      } else {
        debugPrint('⚠️ Notification permissions not granted or FCM not ready');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking notification permissions: $e');
      return false;
    }
  }

  /// Test notification system with sample notifications
  Future<void> testNotificationSystem({required String userRole}) async {
    try {
      debugPrint('🧪 Testing notification system for role: $userRole');

      switch (userRole.toLowerCase()) {
        case 'patient':
          await _testPatientNotifications();
          break;
        case 'doctor':
          await _testDoctorNotifications();
          break;
        case 'admin':
          await _testAdminNotifications();
          break;
      }

      debugPrint('✅ Notification system test completed');
    } catch (e) {
      debugPrint('❌ Error testing notification system: $e');
    }
  }

  /// Test patient notifications
  Future<void> _testPatientNotifications() async {
    final service = RoleBasedNotificationService.instance;
    final testToken = FCMService.instance.fcmToken ?? 'test_token';

    // Test appointment booking confirmation
    await service.sendAppointmentBookingConfirmation(
      patientId: 'test_patient',
      patientFCMToken: testToken,
      doctorName: 'Dr. Smith',
      appointmentId: 'test_appointment_123',
      appointmentTime: DateTime.now().add(const Duration(days: 1)),
      appointmentType: 'Consultation',
    );

    // Test health tip
    await service.sendHealthTipsReminder(
      patientId: 'test_patient',
      patientFCMToken: testToken,
      healthTip: 'Remember to drink at least 8 glasses of water daily for optimal health!',
      category: 'Hydration',
    );

    // Test fitness achievement
    await service.sendFitnessGoalAchieved(
      patientId: 'test_patient',
      patientFCMToken: testToken,
      goalName: 'Daily Steps',
      achievement: 'You walked 10,000 steps today!',
      streakDays: 7,
    );
  }

  /// Test doctor notifications
  Future<void> _testDoctorNotifications() async {
    final service = RoleBasedNotificationService.instance;
    final testToken = FCMService.instance.fcmToken ?? 'test_token';

    // Test appointment booking
    await service.sendAppointmentBookingToDoctor(
      doctorId: 'test_doctor',
      doctorFCMToken: testToken,
      patientName: 'John Doe',
      appointmentId: 'test_appointment_456',
      appointmentTime: DateTime.now().add(const Duration(hours: 2)),
      appointmentType: 'Follow-up',
    );

    // Test payment received
    await service.sendPaymentReceivedToDoctor(
      doctorId: 'test_doctor',
      doctorFCMToken: testToken,
      patientName: 'John Doe',
      paymentId: 'test_payment_789',
      amount: 500.0,
      currency: 'INR',
      appointmentId: 'test_appointment_456',
    );

    // Test verification status
    await service.sendVerificationStatusUpdate(
      doctorId: 'test_doctor',
      doctorFCMToken: testToken,
      status: 'approved',
    );
  }

  /// Test admin notifications
  Future<void> _testAdminNotifications() async {
    final service = RoleBasedNotificationService.instance;
    final testToken = FCMService.instance.fcmToken ?? 'test_token';

    // Test doctor verification request
    await service.sendDoctorVerificationRequestToAdmin(
      adminFCMTokens: [testToken],
      doctorId: 'test_doctor_new',
      doctorName: 'Dr. Johnson',
      email: 'dr.johnson@example.com',
      specialization: 'Cardiology',
      phoneNumber: '+1234567890',
    );
  }

  /// Get notification system status
  Map<String, dynamic> getSystemStatus() {
    return {
      'isInitialized': _isInitialized,
      'fcmInitialized': FCMService.instance.isInitialized,
      'fcmToken': FCMService.instance.fcmToken != null,
      'notificationManagerReady': NotificationManager.instance.isInitialized,
    };
  }

  /// Handle app lifecycle changes for notifications
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    await NotificationManager.instance.handleAppLifecycleChange(state);
    
    // Additional lifecycle handling for role-based notifications
    switch (state) {
      case AppLifecycleState.resumed:
        // Refresh notification permissions and token if needed
        if (_isInitialized) {
          final hasPermissions = await checkAndRequestPermissions();
          if (!hasPermissions) {
            debugPrint('⚠️ Notification permissions lost - may need to re-request');
          }
        }
        break;
      default:
        break;
    }
  }

  /// Force refresh FCM token
  Future<String?> refreshFCMToken() async {
    try {
      // Clear current token
      await NotificationManager.instance.clearToken();
      
      // Reinitialize FCM service to get new token
      await FCMService.instance.initialize();
      
      final newToken = FCMService.instance.fcmToken;
      debugPrint('🔄 FCM token refreshed: ${newToken?.substring(0, 20)}...');
      
      return newToken;
    } catch (e) {
      debugPrint('❌ Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Check if notification system is ready
  bool get isReady => _isInitialized && FCMService.instance.isInitialized;

  /// Get current FCM token
  String? get currentFCMToken => FCMService.instance.fcmToken;
}