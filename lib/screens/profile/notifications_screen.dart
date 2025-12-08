import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../services/firebase/notification_service.dart';

/// Notifications screen for viewing and managing user notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Use post frame callback to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    // Notifications are loaded via stream provider automatically
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).userModel;
    final notificationsAsync = user != null 
        ? ref.watch(notificationsProvider(user.uid))
        : const AsyncValue<List<NotificationModel>>.data([]);

    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(context),

            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ThemeUtils.getBackgroundColor(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: notificationsAsync.when(
                  data: (notifications) => _buildNotificationsList(notifications),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _buildErrorState(error.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final user = ref.watch(authProvider).userModel;
    final unreadCount = user != null 
        ? ref.watch(unreadNotificationsCountProvider(user.uid))
        : const AsyncValue.data(0);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                unreadCount.when(
                  data: (count) => count > 0 
                      ? Text(
                          '$count unread notifications',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Row(
            children: [
              unreadCount.when(
                data: (count) => count > 0
                    ? TextButton(
                        onPressed: () {
                          final user = ref.read(authProvider).userModel;
                          if (user != null) {
                            ref
                                .read(notificationActionsProvider)
                                .markAllAsRead(user.uid);
                          }
                        },
                        child: Text(
                          'Mark All Read',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // Debug button to create sample notifications
              IconButton(
                onPressed: () async {
                  final user = ref.read(authProvider).userModel;
                  if (user != null) {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    await NotificationService.createSampleNotifications(
                      user.uid,
                    );
                    // Notifications reload automatically via stream

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Sample notifications created!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                tooltip: 'Add Sample Notifications',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _loadNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see notifications about appointments, reminders, and updates here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? ThemeUtils.getSurfaceColor(context)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppColors.borderLight
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(
              notification.type,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  notification.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
                if (!notification.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleNotificationAction(value, notification),
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Text('Mark as read'),
              ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationActionsProvider).markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'reminder':
        return Icons.alarm;
      case 'medical':
        return Icons.medical_services;
      case 'payment':
        return Icons.payment;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'appointment':
        return AppColors.primary;
      case 'reminder':
        return AppColors.warning;
      case 'medical':
        return AppColors.success;
      case 'payment':
        return AppColors.info;
      case 'promotion':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  void _handleNotificationAction(
    String action,
    NotificationModel notification,
  ) {
    switch (action) {
      case 'mark_read':
        ref.read(notificationActionsProvider).markAsRead(notification.id);
        break;
      case 'delete':
        ref
            .read(notificationActionsProvider)
            .deleteNotification(notification.id);
        break;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle notification tap based on type and data
    switch (notification.type) {
      case 'appointment':
        // Navigate to appointments screen
        break;
      case 'medical':
        // Navigate to medical records
        break;
      case 'payment':
        // Navigate to payment history
        break;
      default:
        // Show notification details
        break;
    }
  }
}
