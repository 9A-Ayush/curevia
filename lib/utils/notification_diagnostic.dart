import 'package:flutter/foundation.dart';
import '../services/notifications/fcm_service.dart';
import '../services/notifications/notification_integration_service.dart';
import '../services/notifications/notification_initialization_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

/// Diagnostic utility to troubleshoot notification issues
class NotificationDiagnostic {
  static Future<Map<String, dynamic>> runFullDiagnostic({
    UserModel? currentUser,
  }) async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Check FCM Service Status
      results['fcm_service'] = await _checkFCMService();
      
      // 2. Check Notification Integration Service
      results['integration_service'] = await _checkIntegrationService();
      
      // 3. Check Notification Initialization Service
      results['initialization_service'] = await _checkInitializationService();
      
      // 4. Check User-specific setup
      if (currentUser != null) {
        results['user_setup'] = await _checkUserSetup(currentUser);
      }
      
      // 5. Test local notification
      results['local_notification_test'] = await _testLocalNotification();
      
      // 6. Check permissions
      results['permissions'] = await _checkPermissions();
      
      // 7. Generate recommendations
      results['recommendations'] = _generateRecommendations(results);
      
      return results;
    } catch (e) {
      results['error'] = 'Diagnostic failed: $e';
      return results;
    }
  }
  
  static Future<Map<String, dynamic>> _checkFCMService() async {
    try {
      final fcmService = FCMService.instance;
      
      return {
        'status': 'success',
        'is_initialized': fcmService.isInitialized,
        'has_token': fcmService.fcmToken != null,
        'token_preview': fcmService.fcmToken?.substring(0, 20) ?? 'null',
        'saved_token': await fcmService.getSavedFCMToken() != null,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _checkIntegrationService() async {
    try {
      final service = NotificationIntegrationService.instance;
      
      return {
        'status': 'success',
        'is_ready': service.isReady,
        'system_status': service.getSystemStatus(),
        'current_token': service.currentFCMToken?.substring(0, 20) ?? 'null',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _checkInitializationService() async {
    try {
      final service = NotificationInitializationService.instance;
      
      return {
        'status': 'success',
        'is_ready': service.isReady,
        'current_token': service.currentFCMToken?.substring(0, 20) ?? 'null',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _checkUserSetup(UserModel user) async {
    try {
      // Try to manually trigger welcome notification setup
      final service = NotificationIntegrationService.instance;
      
      // Check if service is ready
      if (!service.isReady) {
        return {
          'status': 'error',
          'error': 'Notification service not ready',
          'user_role': user.role,
          'user_id': user.uid,
        };
      }
      
      return {
        'status': 'success',
        'user_role': user.role,
        'user_id': user.uid,
        'user_name': user.fullName,
        'service_ready': service.isReady,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'user_role': user.role,
        'user_id': user.uid,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testLocalNotification() async {
    try {
      final fcmService = FCMService.instance;
      
      if (!fcmService.isInitialized) {
        return {
          'status': 'error',
          'error': 'FCM service not initialized',
        };
      }
      
      // Create a test notification
      final testNotification = NotificationModel(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: '🧪 Notification Test',
        body: 'This is a test notification to verify the system is working.',
        type: NotificationType.general,
        data: {'test': true},
        timestamp: DateTime.now(),
      );
      
      // Try to show it
      await fcmService.showLocalNotification(testNotification);
      
      return {
        'status': 'success',
        'message': 'Test notification sent successfully',
        'notification_id': testNotification.id,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _checkPermissions() async {
    try {
      final service = NotificationInitializationService.instance;
      final hasPermissions = await service.checkAndRequestPermissions();
      
      return {
        'status': 'success',
        'has_permissions': hasPermissions,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  static List<String> _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    // Check FCM service issues
    final fcmService = results['fcm_service'] as Map<String, dynamic>?;
    if (fcmService != null) {
      if (fcmService['status'] == 'error') {
        recommendations.add('❌ FCM Service has errors - restart the app');
      } else if (fcmService['is_initialized'] != true) {
        recommendations.add('⚠️ FCM Service not initialized - check Firebase configuration');
      } else if (fcmService['has_token'] != true) {
        recommendations.add('⚠️ No FCM token - check Google Play Services and internet connection');
      }
    }
    
    // Check integration service issues
    final integrationService = results['integration_service'] as Map<String, dynamic>?;
    if (integrationService != null && integrationService['is_ready'] != true) {
      recommendations.add('⚠️ Notification integration service not ready - try restarting');
    }
    
    // Check permissions
    final permissions = results['permissions'] as Map<String, dynamic>?;
    if (permissions != null && permissions['has_permissions'] != true) {
      recommendations.add('❌ Notification permissions not granted - check app settings');
    }
    
    // Check local notification test
    final localTest = results['local_notification_test'] as Map<String, dynamic>?;
    if (localTest != null && localTest['status'] == 'error') {
      recommendations.add('❌ Local notifications not working - check notification channels');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('✅ All systems appear to be working correctly');
      recommendations.add('💡 Try manually triggering a welcome notification');
    }
    
    return recommendations;
  }
  
  /// Manually trigger welcome notification for current user
  static Future<Map<String, dynamic>> triggerWelcomeNotification(UserModel user) async {
    try {
      debugPrint('🔔 Manually triggering welcome notification for: ${user.fullName} (${user.role})');
      
      // Initialize service if needed
      final service = NotificationIntegrationService.instance;
      if (!service.isReady) {
        await service.initialize();
      }
      
      // Create welcome notification based on role
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
      
      // Create notification
      final notification = NotificationModel(
        id: 'manual_welcome_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        type: NotificationType.general,
        data: {
          'welcomeMessage': true,
          'userRole': user.role,
          'userId': user.uid,
          'manual_trigger': true,
        },
        timestamp: DateTime.now(),
      );
      
      // Show local notification
      await FCMService.instance.showLocalNotification(notification);
      
      return {
        'status': 'success',
        'message': 'Welcome notification triggered successfully',
        'notification_id': notification.id,
        'title': title,
        'body': body,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  /// Test the complete notification flow
  static Future<Map<String, dynamic>> testCompleteFlow(UserModel user) async {
    try {
      final results = <String, dynamic>{};
      
      // Step 1: Initialize services
      results['step1_init'] = await _initializeServices();
      
      // Step 2: Setup user notifications
      results['step2_setup'] = await _setupUserNotifications(user);
      
      // Step 3: Trigger welcome notification
      results['step3_welcome'] = await triggerWelcomeNotification(user);
      
      // Step 4: Test local notification
      results['step4_test'] = await _testLocalNotification();
      
      return {
        'status': 'success',
        'results': results,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _initializeServices() async {
    try {
      final service = NotificationIntegrationService.instance;
      final initialized = await service.initialize();
      
      return {
        'status': initialized ? 'success' : 'failed',
        'initialized': initialized,
        'is_ready': service.isReady,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _setupUserNotifications(UserModel user) async {
    try {
      final service = NotificationIntegrationService.instance;
      
      await service.setupUserNotifications(
        user: user,
        specializations: user.role == 'doctor' ? ['General Medicine'] : null,
        location: null,
      );
      
      return {
        'status': 'success',
        'user_role': user.role,
        'user_id': user.uid,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}