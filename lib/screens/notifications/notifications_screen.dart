import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notifications/notification_manager.dart';
import '../../services/notifications/notification_handler.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';

/// Notifications screen to display all notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final allNotifications = await NotificationManager.instance.getAllNotifications();
      final unreadNotifications = await NotificationManager.instance.getUnreadNotifications();
      
      setState(() {
        _allNotifications = allNotifications;
        _unreadNotifications = unreadNotifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationHandler.markAsRead(notification.id);
      await _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationHandler.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    await NotificationHandler.deleteNotification(notification.id);
    await _loadNotifications();
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Notifications',
      'Are you sure you want to clear all notifications? This action cannot be undone.',
    );
    
    if (confirmed) {
      await NotificationHandler.clearAllNotifications();
      await _loadNotifications();
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.mark_email_read,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _clearAllNotifications();
                  break;
                case 'test_notification':
                  _sendTestNotification();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_notification',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active),
                    SizedBox(width: 8),
                    Text('Test Notification'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'All (${_allNotifications.length})',
            ),
            Tab(
              text: 'Unread (${_unreadNotifications.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_allNotifications),
                _buildNotificationsList(_unreadNotifications),
              ],
            ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
            'No notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead 
          ? ThemeUtils.getSurfaceColor(context)
          : ThemeUtils.getSurfaceColor(context).withValues(alpha: 0.9),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildNotificationTypeChip(notification.type),
                            const Spacer(),
                            Text(
                              _formatTimestamp(notification.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_read':
                          _markAsRead(notification);
                          break;
                        case 'delete':
                          _deleteNotification(notification);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read, size: 16),
                              SizedBox(width: 8),
                              Text('Mark as read'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
        iconData = Icons.event_available;
        iconColor = AppColors.success;
        break;
      case NotificationType.appointmentReminder:
        iconData = Icons.event;
        iconColor = AppColors.primary;
        break;
      case NotificationType.paymentSuccess:
        iconData = Icons.payment;
        iconColor = AppColors.success;
        break;
      case NotificationType.healthTipsReminder:
        iconData = Icons.health_and_safety;
        iconColor = Colors.teal;
        break;
      case NotificationType.doctorRescheduledAppointment:
        iconData = Icons.event_busy;
        iconColor = AppColors.warning;
        break;
      case NotificationType.engagementNotification:
        iconData = Icons.favorite;
        iconColor = Colors.pink;
        break;
      case NotificationType.fitnessGoalAchieved:
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        iconData = Icons.event_note;
        iconColor = AppColors.primary;
        break;
      case NotificationType.paymentReceived:
        iconData = Icons.account_balance_wallet;
        iconColor = AppColors.success;
        break;
      case NotificationType.appointmentRescheduledOrCancelled:
        iconData = Icons.event_busy;
        iconColor = AppColors.warning;
        break;
      case NotificationType.verificationStatusUpdate:
        iconData = Icons.verified;
        iconColor = Colors.purple;
        break;
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        iconData = Icons.verified_user;
        iconColor = AppColors.warning;
        break;
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        iconData = Icons.share;
        iconColor = Colors.purple;
        break;
      case NotificationType.general:
        iconData = Icons.notifications;
        iconColor = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildNotificationTypeChip(NotificationType type) {
    String label;
    Color color;

    switch (type) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
        label = 'Booking Confirmed';
        color = AppColors.success;
        break;
      case NotificationType.appointmentReminder:
        label = 'Appointment';
        color = AppColors.primary;
        break;
      case NotificationType.paymentSuccess:
        label = 'Payment';
        color = AppColors.success;
        break;
      case NotificationType.healthTipsReminder:
        label = 'Health Tip';
        color = Colors.teal;
        break;
      case NotificationType.doctorRescheduledAppointment:
        label = 'Rescheduled';
        color = AppColors.warning;
        break;
      case NotificationType.engagementNotification:
        label = 'Health Check';
        color = Colors.pink;
        break;
      case NotificationType.fitnessGoalAchieved:
        label = 'Fitness Goal';
        color = Colors.amber;
        break;
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        label = 'New Booking';
        color = AppColors.primary;
        break;
      case NotificationType.paymentReceived:
        label = 'Payment Received';
        color = AppColors.success;
        break;
      case NotificationType.appointmentRescheduledOrCancelled:
        label = 'Appointment Update';
        color = AppColors.warning;
        break;
      case NotificationType.verificationStatusUpdate:
        label = 'Verification';
        color = Colors.purple;
        break;
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        label = 'Verification Request';
        color = AppColors.warning;
        break;
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        label = 'Medical Report';
        color = Colors.purple;
        break;
      case NotificationType.general:
        label = 'General';
        color = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<void> _sendTestNotification() async {
    await NotificationManager.instance.sendTestNotification(
      title: 'Test Notification',
      body: 'This is a test notification with sound',
      type: NotificationType.general,
    );
    
    await _loadNotifications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}