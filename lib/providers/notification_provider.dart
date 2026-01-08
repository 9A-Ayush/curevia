import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notifications/notification_manager.dart';

/// Notifier for managing notification count state
class NotificationCountNotifier extends StateNotifier<AsyncValue<int>> {
  NotificationCountNotifier() : super(const AsyncValue.loading()) {
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final count = await NotificationManager.instance.getUnreadNotificationCount();
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

/// Provider for notification count with real-time updates
final notificationCountProvider = StateNotifierProvider<NotificationCountNotifier, AsyncValue<int>>((ref) {
  return NotificationCountNotifier();
});

/// Legacy provider for backward compatibility
final notificationCountLegacyProvider = FutureProvider<int>((ref) async {
  return await NotificationManager.instance.getUnreadNotificationCount();
});

/// Provider for all notifications
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return await NotificationManager.instance.getAllNotifications();
});

/// Provider for unread notifications
final unreadNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return await NotificationManager.instance.getUnreadNotifications();
});

/// Provider for notification statistics
final notificationStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await NotificationManager.instance.getNotificationStats();
});

/// Provider for unread notifications count with userId parameter (for backward compatibility)
final unreadNotificationsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  // For now, we'll use the global count since our new system doesn't separate by userId in local storage
  return await NotificationManager.instance.getUnreadNotificationCount();
});

/// Provider for notifications with userId parameter (for backward compatibility)
final notificationsProviderWithUserId = FutureProvider.family<List<NotificationModel>, String>((ref, userId) async {
  // For now, we'll use the global notifications since our new system doesn't separate by userId in local storage
  return await NotificationManager.instance.getAllNotifications();
});

/// Notifier for managing notification state
class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationNotifier() : super(const AsyncValue.loading()) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationManager.instance.getAllNotifications();
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

/// Provider for notification notifier
final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier();
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