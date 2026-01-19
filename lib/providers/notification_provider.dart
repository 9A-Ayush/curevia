import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notifications/notification_manager.dart';
import '../services/notifications/role_based_notification_channel_service.dart';
import 'auth_provider.dart';

/// Notifier for managing notification count state with role-based filtering
class NotificationCountNotifier extends StateNotifier<AsyncValue<int>> {
  final Ref ref;
  
  NotificationCountNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      // Get current user role
      final userModel = ref.read(currentUserModelProvider);
      final userRole = userModel?.role ?? 'patient';
      
      // Get role-based unread count
      final count = await RoleBasedNotificationChannelService.instance
          .getUnreadNotificationCountForRole(userRole);
      state = AsyncValue.data(count);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh the notification count
  Future<void> refresh() async {
    await _loadCount();
  }

  /// Decrement count when a notification is marked as read
  void decrementCount() {
    state.whenData((count) {
      if (count > 0) {
        state = AsyncValue.data(count - 1);
      }
    });
  }

  /// Increment count when a new notification is received
  void incrementCount() {
    state.whenData((count) {
      state = AsyncValue.data(count + 1);
    });
  }

  /// Reset count to zero when all notifications are marked as read
  void resetCount() {
    state = const AsyncValue.data(0);
  }

  /// Set count to a specific value
  void setCount(int count) {
    state = AsyncValue.data(count);
  }
}

/// Provider for notification count with real-time updates and role-based filtering
final notificationCountProvider = StateNotifierProvider<NotificationCountNotifier, AsyncValue<int>>((ref) {
  return NotificationCountNotifier(ref);
});

/// Legacy provider for backward compatibility
final notificationCountLegacyProvider = FutureProvider<int>((ref) async {
  return await NotificationManager.instance.getUnreadNotificationCount();
});

/// Provider for all notifications with role-based filtering
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return await RoleBasedNotificationChannelService.instance
      .getRoleBasedNotifications(userRole);
});

/// Provider for unread notifications with role-based filtering
final unreadNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return await RoleBasedNotificationChannelService.instance
      .getUnreadRoleBasedNotifications(userRole);
});

/// Provider for notification statistics with role-based filtering
final notificationStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return await RoleBasedNotificationChannelService.instance
      .getRoleNotificationStats(userRole);
});

/// Provider for unread notifications count with userId parameter (role-based)
final unreadNotificationsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return await RoleBasedNotificationChannelService.instance
      .getUnreadNotificationCountForRole(userRole);
});

/// Provider for notifications with userId parameter (role-based)
final notificationsProviderWithUserId = FutureProvider.family<List<NotificationModel>, String>((ref, userId) async {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return await RoleBasedNotificationChannelService.instance
      .getRoleBasedNotifications(userRole);
});

/// Notifier for managing notification state with role-based filtering
class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref ref;
  
  NotificationNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final userModel = ref.read(currentUserModelProvider);
      final userRole = userModel?.role ?? 'patient';
      
      final notifications = await RoleBasedNotificationChannelService.instance
          .getRoleBasedNotifications(userRole);
      state = AsyncValue.data(notifications);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadNotifications();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await NotificationManager.instance.markAsRead(notificationId);
    await _loadNotifications();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await NotificationManager.instance.markAllAsRead();
    await _loadNotifications();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await NotificationManager.instance.deleteNotification(notificationId);
    await _loadNotifications();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    await NotificationManager.instance.clearAllNotifications();
    await _loadNotifications();
  }
}

/// Provider for notification notifier with role-based filtering
final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier(ref);
});

/// Provider for notification actions (for backward compatibility)
final notificationActionsProvider = Provider<NotificationNotifier>((ref) {
  return ref.read(notificationNotifierProvider.notifier);
});

/// Provider for FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  return NotificationManager.instance.fcmToken;
});

/// Provider for checking if notification system is initialized
final notificationInitializedProvider = Provider<bool>((ref) {
  return NotificationManager.instance.isInitialized;
});

/// Provider for notifications by category (role-based)
final notificationsByCategoryProvider = FutureProvider.family<List<NotificationModel>, String>((ref, category) async {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return await RoleBasedNotificationChannelService.instance
      .getNotificationsByCategory(userRole, category);
});

/// Provider for role-based notification preferences
final notificationPreferencesProvider = Provider<Map<String, dynamic>>((ref) {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return RoleBasedNotificationChannelService.instance
      .getRoleNotificationPreferences(userRole);
});

/// Provider for allowed notification types for current user role
final allowedNotificationTypesProvider = Provider<List<NotificationType>>((ref) {
  final userModel = ref.read(currentUserModelProvider);
  final userRole = userModel?.role ?? 'patient';
  
  return RoleBasedNotificationChannelService.instance
      .getAllowedNotificationTypes(userRole);
});