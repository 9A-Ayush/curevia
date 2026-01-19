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
  bool _isInitializing = false;

  /// Initialize the complete notification system
  Future<bool> initializeNotificationSystem() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      // Wait for ongoing initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    _isInitializing = true;
    
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
        _isInitializing = false;
        return false;
      }
      debugPrint('✅ FCM token obtained: ${fcmToken.substring(0, 20)}...');

      _isInitialized = true;
      _isInitializing = false;
      debugPrint('🎉 Notification system initialized successfully!');
      return true;
    } catch (e) {
      _isInitializing = false;
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
      // Add a small delay to ensure FCM is fully ready
      await Future.delayed(Duration(milliseconds: 500));
      
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

      // Create and send welcome notification with retry logic
      final notification = NotificationModel(
        id: 'welcome_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        type: NotificationType.general,
        data: {
          'welcomeMessage': true,
          'userRole': user.role,
          'userId': user.uid,
        },
        timestamp: DateTime.now(),
      );

      // Try to show notification with retry
      bool notificationSent = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await FCMService.instance.showLocalNotification(notification);
          notificationSent = true;
          debugPrint('✅ Welcome notification sent successfully (attempt $attempt)');
          break;
        } catch (e) {
          debugPrint('❌ Welcome notification attempt $attempt failed: $e');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }
      
      if (!notificationSent) {
        debugPrint('⚠️ All welcome notification attempts failed, scheduling retry');
        // Schedule a retry after 10 seconds
        Future.delayed(Duration(seconds: 10), () async {
          try {
            await FCMService.instance.showLocalNotification(notification);
            debugPrint('✅ Delayed welcome notification sent successfully');
          } catch (e) {
            debugPrint('❌ Delayed welcome notification also failed: $e');
          }
        });
      }
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

      // Run all cleanup operations in parallel with timeout
      await Future.wait([
        // Step 1: Unsubscribe from all topics
        RoleBasedNotificationService.instance.unsubscribeUserFromRoleTopics(
          userId: userId,
          userRole: userRole.toLowerCase(),
          specializations: specializations,
          location: location,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => debugPrint('Topic unsubscribe timeout'),
        ).catchError((e) => debugPrint('Topic unsubscribe error: $e')),
        
        // Step 2: Clear FCM token
        NotificationManager.instance.clearToken()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => debugPrint('Token clear timeout'),
          )
          .catchError((e) => debugPrint('Token clear error: $e')),
      ]);

      debugPrint('✅ User notifications cleanup complete');
    } catch (e) {
      debugPrint('❌ Error cleaning up user notifications: $e');
      // Don't rethrow - cleanup errors shouldn't block logout
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