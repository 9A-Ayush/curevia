import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/firebase/notification_service.dart';

/// Provider for user notifications
final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return NotificationService.getNotificationsStream(userId);
});

/// Provider for unread notifications count
final unreadNotificationsCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return NotificationService.getUnreadCountStream(userId);
});

/// Notification actions provider
final notificationActionsProvider = Provider((ref) => NotificationActions(ref));

class NotificationActions {
  final Ref _ref;

  NotificationActions(this._ref);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await NotificationService.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    await NotificationService.markAllAsRead(userId);
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await NotificationService.deleteNotification(notificationId);
  }

  /// Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await NotificationService.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
    );
  }
}
