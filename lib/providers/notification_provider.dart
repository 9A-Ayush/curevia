import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/firebase/notification_service.dart';

/// Notification state
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notification provider notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  /// Load notifications for user
  Future<void> loadNotifications(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final futures = await Future.wait([
        NotificationService.getUserNotifications(userId),
        NotificationService.getUnreadNotificationsCount(userId),
      ]);

      state = state.copyWith(
        isLoading: false,
        notifications: futures[0] as List<NotificationModel>,
        unreadCount: futures[1] as int,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId && !notification.isRead) {
          return notification.copyWith(isRead: true, readAt: DateTime.now());
        }
        return notification;
      }).toList();

      final newUnreadCount = updatedNotifications
          .where((notification) => !notification.isRead)
          .length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await NotificationService.markAllAsRead(userId);
      
      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (!notification.isRead) {
          return notification.copyWith(isRead: true, readAt: DateTime.now());
        }
        return notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      
      // Update local state
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final newUnreadCount = updatedNotifications
          .where((notification) => !notification.isRead)
          .length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final newUnreadCount = notification.isRead 
        ? state.unreadCount 
        : state.unreadCount + 1;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Notification provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// Recent notifications provider (last 10)
final recentNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notifications = ref.watch(notificationProvider).notifications;
  return notifications.take(10).toList();
});

/// Unread notifications provider
final unreadNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notifications = ref.watch(notificationProvider).notifications;
  return notifications.where((notification) => !notification.isRead).toList();
});
