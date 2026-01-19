import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';
import '../storage/notification_storage_service.dart';
import 'notification_manager.dart';

/// Service for managing role-based notification channels and filtering
class RoleBasedNotificationChannelService {
  static final RoleBasedNotificationChannelService _instance = 
      RoleBasedNotificationChannelService._internal();
  factory RoleBasedNotificationChannelService() => _instance;
  RoleBasedNotificationChannelService._internal();

  static RoleBasedNotificationChannelService get instance => _instance;

  /// Define notification channels for each role
  static const Map<String, List<NotificationType>> _roleChannels = {
    'patient': [
      // Appointment related
      NotificationType.appointmentBookingConfirmation,
      NotificationType.appointmentReminder,
      NotificationType.doctorRescheduledAppointment,
      
      // Payment related
      NotificationType.paymentSuccess,
      
      // Health and wellness
      NotificationType.healthTipsReminder,
      NotificationType.engagementNotification,
      NotificationType.fitnessGoalAchieved,
      
      // Medical sharing
      NotificationType.medicalReportShared,
      
      // General
      NotificationType.general,
    ],
    
    'doctor': [
      // Appointment related
      NotificationType.appointmentBooking,
      NotificationType.appointmentRescheduledOrCancelled,
      NotificationType.appointmentReminder,
      
      // Payment related
      NotificationType.paymentReceived,
      
      // Verification related
      NotificationType.verificationStatusUpdate,
      
      // Medical sharing
      NotificationType.medicalReportShared,
      
      // General
      NotificationType.general,
    ],
    
    'admin': [
      // Verification related
      NotificationType.doctorVerificationRequest,
      NotificationType.verificationStatusUpdate,
      
      // System monitoring (admin can see all appointment and payment notifications for oversight)
      NotificationType.appointmentBooking,
      NotificationType.appointmentBookingConfirmation,
      NotificationType.paymentSuccess,
      NotificationType.paymentReceived,
      
      // General
      NotificationType.general,
    ],
  };

  /// Get allowed notification types for a specific role
  List<NotificationType> getAllowedNotificationTypes(String userRole) {
    return _roleChannels[userRole.toLowerCase()] ?? [NotificationType.general];
  }

  /// Check if a notification type is allowed for a specific role
  bool isNotificationAllowedForRole(NotificationType type, String userRole) {
    final allowedTypes = getAllowedNotificationTypes(userRole);
    return allowedTypes.contains(type);
  }

  /// Filter notifications based on user role
  List<NotificationModel> filterNotificationsByRole(
    List<NotificationModel> notifications, 
    String userRole
  ) {
    final allowedTypes = getAllowedNotificationTypes(userRole);
    return notifications.where((notification) => 
      allowedTypes.contains(notification.type)
    ).toList();
  }

  /// Get role-specific notifications from storage
  Future<List<NotificationModel>> getRoleBasedNotifications(String userRole) async {
    try {
      final allNotifications = await NotificationStorageService.getAllNotifications();
      return filterNotificationsByRole(allNotifications, userRole);
    } catch (e) {
      debugPrint('Error getting role-based notifications: $e');
      return [];
    }
  }

  /// Get unread role-specific notifications
  Future<List<NotificationModel>> getUnreadRoleBasedNotifications(String userRole) async {
    try {
      final roleNotifications = await getRoleBasedNotifications(userRole);
      return roleNotifications.where((n) => !n.isRead).toList();
    } catch (e) {
      debugPrint('Error getting unread role-based notifications: $e');
      return [];
    }
  }

  /// Get unread notification count for a specific role
  Future<int> getUnreadNotificationCountForRole(String userRole) async {
    try {
      final unreadNotifications = await getUnreadRoleBasedNotifications(userRole);
      return unreadNotifications.length;
    } catch (e) {
      debugPrint('Error getting unread notification count for role: $e');
      return 0;
    }
  }

  /// Get notifications by category for a specific role
  Future<List<NotificationModel>> getNotificationsByCategory(
    String userRole, 
    String category
  ) async {
    try {
      final roleNotifications = await getRoleBasedNotifications(userRole);
      
      switch (category.toLowerCase()) {
        case 'appointments':
          return roleNotifications.where((n) => _isAppointmentNotification(n.type)).toList();
        
        case 'payments':
          return roleNotifications.where((n) => _isPaymentNotification(n.type)).toList();
        
        case 'verifications':
          return roleNotifications.where((n) => _isVerificationNotification(n.type)).toList();
        
        case 'health':
          return roleNotifications.where((n) => _isHealthNotification(n.type)).toList();
        
        case 'medical':
          return roleNotifications.where((n) => _isMedicalNotification(n.type)).toList();
        
        default:
          return roleNotifications;
      }
    } catch (e) {
      debugPrint('Error getting notifications by category: $e');
      return [];
    }
  }

  /// Send role-based notification
  Future<void> sendRoleBasedNotification({
    required NotificationType type,
    required String title,
    required String body,
    required String targetRole,
    Map<String, dynamic>? data,
    String? targetUserId,
  }) async {
    try {
      // Check if notification type is allowed for the target role
      if (!isNotificationAllowedForRole(type, targetRole)) {
        debugPrint('Notification type $type not allowed for role $targetRole');
        return;
      }

      // Create notification
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: {
          'targetRole': targetRole,
          'targetUserId': targetUserId,
          ...?data,
        },
        timestamp: DateTime.now(),
      );

      // Save notification locally
      await NotificationStorageService.saveNotification(notification);

      // Send via FCM if token is available
      // This would typically be handled by your backend
      debugPrint('Role-based notification sent: $title to $targetRole');
      
    } catch (e) {
      debugPrint('Error sending role-based notification: $e');
    }
  }

  /// Subscribe user to role-based notification channels
  Future<void> subscribeToRoleChannels({
    required String userId,
    required String userRole,
    List<String>? specializations,
  }) async {
    try {
      await NotificationManager.instance.subscribeToTopics(
        userType: userRole,
        userId: userId,
        specializations: specializations,
      );
      
      debugPrint('Subscribed user $userId to $userRole channels');
    } catch (e) {
      debugPrint('Error subscribing to role channels: $e');
    }
  }

  /// Unsubscribe user from role-based notification channels
  Future<void> unsubscribeFromRoleChannels({
    required String userId,
    required String userRole,
    List<String>? specializations,
  }) async {
    try {
      await NotificationManager.instance.unsubscribeFromAllTopics(
        userType: userRole,
        userId: userId,
        specializations: specializations,
      );
      
      debugPrint('Unsubscribed user $userId from $userRole channels');
    } catch (e) {
      debugPrint('Error unsubscribing from role channels: $e');
    }
  }

  /// Get notification channel statistics for a role
  Future<Map<String, int>> getRoleNotificationStats(String userRole) async {
    try {
      final roleNotifications = await getRoleBasedNotifications(userRole);
      final stats = <String, int>{};
      
      // Count by category
      stats['appointments'] = roleNotifications.where((n) => _isAppointmentNotification(n.type)).length;
      stats['payments'] = roleNotifications.where((n) => _isPaymentNotification(n.type)).length;
      stats['verifications'] = roleNotifications.where((n) => _isVerificationNotification(n.type)).length;
      stats['health'] = roleNotifications.where((n) => _isHealthNotification(n.type)).length;
      stats['medical'] = roleNotifications.where((n) => _isMedicalNotification(n.type)).length;
      stats['general'] = roleNotifications.where((n) => n.type == NotificationType.general).length;
      
      // Total counts
      stats['total'] = roleNotifications.length;
      stats['unread'] = roleNotifications.where((n) => !n.isRead).length;
      stats['read'] = roleNotifications.where((n) => n.isRead).length;
      
      return stats;
    } catch (e) {
      debugPrint('Error getting role notification stats: $e');
      return {};
    }
  }

  /// Helper methods to categorize notifications
  bool _isAppointmentNotification(NotificationType type) {
    return [
      NotificationType.appointmentBooking,
      NotificationType.appointmentBookingConfirmation,
      NotificationType.appointmentReminder,
      NotificationType.appointmentRescheduledOrCancelled,
      NotificationType.doctorRescheduledAppointment,
    ].contains(type);
  }

  bool _isPaymentNotification(NotificationType type) {
    return [
      NotificationType.paymentSuccess,
      NotificationType.paymentReceived,
    ].contains(type);
  }

  bool _isVerificationNotification(NotificationType type) {
    return [
      NotificationType.doctorVerificationRequest,
      NotificationType.verificationStatusUpdate,
    ].contains(type);
  }

  bool _isHealthNotification(NotificationType type) {
    return [
      NotificationType.healthTipsReminder,
      NotificationType.engagementNotification,
      NotificationType.fitnessGoalAchieved,
    ].contains(type);
  }

  bool _isMedicalNotification(NotificationType type) {
    return [
      NotificationType.medicalReportShared,
    ].contains(type);
  }

  /// Get role-specific notification preferences
  Map<String, dynamic> getRoleNotificationPreferences(String userRole) {
    final allowedTypes = getAllowedNotificationTypes(userRole);
    
    return {
      'role': userRole,
      'allowedTypes': allowedTypes.map((t) => t.toString()).toList(),
      'channels': {
        'appointments': allowedTypes.where(_isAppointmentNotification).map((t) => t.toString()).toList(),
        'payments': allowedTypes.where(_isPaymentNotification).map((t) => t.toString()).toList(),
        'verifications': allowedTypes.where(_isVerificationNotification).map((t) => t.toString()).toList(),
        'health': allowedTypes.where(_isHealthNotification).map((t) => t.toString()).toList(),
        'medical': allowedTypes.where(_isMedicalNotification).map((t) => t.toString()).toList(),
      },
      'fcmTopics': _getFCMTopicsForRole(userRole),
    };
  }

  /// Get FCM topics for a specific role
  List<String> _getFCMTopicsForRole(String userRole) {
    switch (userRole.toLowerCase()) {
      case 'patient':
        return [
          'all_users',
          'patients',
          'patient_appointments',
          'patient_payments',
          'patient_health_tips',
        ];
      
      case 'doctor':
        return [
          'all_users',
          'doctors',
          'doctor_appointments',
          'doctor_payments',
          'doctor_verifications',
        ];
      
      case 'admin':
        return [
          'all_users',
          'admins',
          'admin_verifications',
          'admin_system_alerts',
        ];
      
      default:
        return ['all_users'];
    }
  }

  /// Validate notification for role before sending
  bool validateNotificationForRole(NotificationType type, String userRole) {
    final isAllowed = isNotificationAllowedForRole(type, userRole);
    
    if (!isAllowed) {
      debugPrint('⚠️ Notification type $type is not allowed for role $userRole');
      debugPrint('Allowed types: ${getAllowedNotificationTypes(userRole)}');
    }
    
    return isAllowed;
  }

  /// Get notification channel info for debugging
  Map<String, dynamic> getChannelInfo() {
    return {
      'channels': _roleChannels,
      'totalRoles': _roleChannels.keys.length,
      'totalNotificationTypes': NotificationType.values.length,
    };
  }
}