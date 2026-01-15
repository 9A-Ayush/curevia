import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart';

/// Local storage service for notifications
class NotificationStorageService {
  static const String _notificationsKey = 'stored_notifications';
  static const int _maxStoredNotifications = 100;

  /// Save a notification to local storage
  static Future<void> saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getAllNotifications();
      
      // Add new notification at the beginning
      notifications.insert(0, notification);
      
      // Keep only the latest notifications (limit storage)
      if (notifications.length > _maxStoredNotifications) {
        notifications.removeRange(_maxStoredNotifications, notifications.length);
      }
      
      // Save to SharedPreferences
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Get all notifications from local storage
  static Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsKey);
      
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
      
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  /// Get notifications for a specific user role
  static Future<List<NotificationModel>> getNotificationsForRole(String userRole) async {
    try {
      final allNotifications = await getAllNotifications();
      
      // Define which notification types are for which roles
      final patientNotificationTypes = [
        NotificationType.appointmentBookingConfirmation,
        NotificationType.appointmentReminder,
        NotificationType.paymentSuccess,
        NotificationType.healthTipsReminder,
        NotificationType.doctorRescheduledAppointment,
        NotificationType.engagementNotification,
        NotificationType.fitnessGoalAchieved,
        NotificationType.medicalReportShared,
        NotificationType.general,
      ];
      
      final doctorNotificationTypes = [
        NotificationType.appointmentBooking,
        NotificationType.paymentReceived,
        NotificationType.appointmentRescheduledOrCancelled,
        NotificationType.verificationStatusUpdate,
        NotificationType.medicalReportShared,
        NotificationType.general,
      ];
      
      final adminNotificationTypes = [
        NotificationType.doctorVerificationRequest,
        NotificationType.general,
      ];
      
      // Filter based on role
      List<NotificationType> allowedTypes;
      switch (userRole.toLowerCase()) {
        case 'patient':
          allowedTypes = patientNotificationTypes;
          break;
        case 'doctor':
          allowedTypes = doctorNotificationTypes;
          break;
        case 'admin':
          allowedTypes = adminNotificationTypes;
          break;
        default:
          allowedTypes = [NotificationType.general];
      }
      
      return allNotifications.where((n) => allowedTypes.contains(n.type)).toList();
    } catch (e) {
      print('Error getting notifications for role: $e');
      return [];
    }
  }

  /// Get unread notifications for a specific user role
  static Future<List<NotificationModel>> getUnreadNotificationsForRole(String userRole) async {
    try {
      final roleNotifications = await getNotificationsForRole(userRole);
      return roleNotifications.where((n) => !n.isRead).toList();
    } catch (e) {
      print('Error getting unread notifications for role: $e');
      return [];
    }
  }

  /// Get unread notification count for a specific user role
  static Future<int> getUnreadNotificationCountForRole(String userRole) async {
    try {
      final unreadNotifications = await getUnreadNotificationsForRole(userRole);
      return unreadNotifications.length;
    } catch (e) {
      print('Error getting unread notification count for role: $e');
      return 0;
    }
  }

  /// Get notifications by type
  static Future<List<NotificationModel>> getNotificationsByType(NotificationType type) async {
    try {
      final allNotifications = await getAllNotifications();
      return allNotifications.where((n) => n.type == type).toList();
    } catch (e) {
      print('Error getting notifications by type: $e');
      return [];
    }
  }

  /// Get unread notifications
  static Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final allNotifications = await getAllNotifications();
      return allNotifications.where((n) => !n.isRead).toList();
    } catch (e) {
      print('Error getting unread notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      final unreadNotifications = await getUnreadNotifications();
      return unreadNotifications.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Get notification by ID
  static Future<NotificationModel?> getNotificationById(String id) async {
    try {
      final allNotifications = await getAllNotifications();
      return allNotifications.firstWhere(
        (n) => n.id == id,
        orElse: () => throw StateError('Notification not found'),
      );
    } catch (e) {
      print('Error getting notification by ID: $e');
      return null;
    }
  }

  /// Update a notification
  static Future<void> updateNotification(NotificationModel notification) async {
    try {
      final notifications = await getAllNotifications();
      final index = notifications.indexWhere((n) => n.id == notification.id);
      
      if (index != -1) {
        notifications[index] = notification;
        
        // Save updated list
        final prefs = await SharedPreferences.getInstance();
        final jsonList = notifications.map((n) => n.toJson()).toList();
        await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      }
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final notification = await getNotificationById(notificationId);
      if (notification != null && !notification.isRead) {
        final updatedNotification = notification.copyWith(isRead: true);
        await updateNotification(updatedNotification);
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final notifications = await getAllNotifications();
      final updatedNotifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
      
      // Save updated list
      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      
      // Save updated list
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  /// Get notifications for a specific date range
  static Future<List<NotificationModel>> getNotificationsInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final allNotifications = await getAllNotifications();
      return allNotifications.where((n) {
        return n.timestamp.isAfter(startDate) && n.timestamp.isBefore(endDate);
      }).toList();
    } catch (e) {
      print('Error getting notifications in date range: $e');
      return [];
    }
  }

  /// Get recent notifications (last 7 days)
  static Future<List<NotificationModel>> getRecentNotifications() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return getNotificationsInDateRange(
      startDate: sevenDaysAgo,
      endDate: DateTime.now(),
    );
  }

  /// Get notification statistics
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final allNotifications = await getAllNotifications();
      final stats = <String, int>{};
      
      // Count by type
      for (final type in NotificationType.values) {
        stats[type.toString()] = allNotifications.where((n) => n.type == type).length;
      }
      
      // Total counts
      stats['total'] = allNotifications.length;
      stats['unread'] = allNotifications.where((n) => !n.isRead).length;
      stats['read'] = allNotifications.where((n) => n.isRead).length;
      
      return stats;
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  /// Clean up old notifications (older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final allNotifications = await getAllNotifications();
      
      // Keep only notifications from the last 30 days
      final recentNotifications = allNotifications.where((n) {
        return n.timestamp.isAfter(thirtyDaysAgo);
      }).toList();
      
      // Save cleaned list
      final prefs = await SharedPreferences.getInstance();
      final jsonList = recentNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      
      print('Cleaned up ${allNotifications.length - recentNotifications.length} old notifications');
    } catch (e) {
      print('Error cleaning up old notifications: $e');
    }
  }

  /// Export notifications as JSON
  static Future<String> exportNotificationsAsJson() async {
    try {
      final notifications = await getAllNotifications();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      return jsonEncode(jsonList);
    } catch (e) {
      print('Error exporting notifications: $e');
      return '[]';
    }
  }

  /// Import notifications from JSON
  static Future<void> importNotificationsFromJson(String jsonString) async {
    try {
      final jsonList = jsonDecode(jsonString) as List;
      final notifications = jsonList.map((json) => NotificationModel.fromJson(json)).toList();
      
      // Save imported notifications
      final prefs = await SharedPreferences.getInstance();
      final exportJsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(exportJsonList));
      
    } catch (e) {
      print('Error importing notifications: $e');
    }
  }
}