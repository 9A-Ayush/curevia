import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notifications/notification_manager.dart';
import '../../services/notifications/notification_handler.dart';
import '../../services/notifications/role_based_notification_channel_service.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';

/// Admin-specific notifications screen
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  List<NotificationModel> _verificationNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final channelService = RoleBasedNotificationChannelService.instance;
      
      // Load all notifications for admin role
      final allNotifications = await channelService.getRoleBasedNotifications('admin');
      final unreadNotifications = await channelService.getUnreadRoleBasedNotifications('admin');
      
      // Filter verification-related notifications
      final verificationNotifications = await channelService.getNotificationsByCategory('admin', 'verifications');
      
      setState(() {
        _allNotifications = allNotifications;
        _unreadNotifications = unreadNotifications;
        _verificationNotifications = verificationNotifications;
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
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        title: Text(
          title,
          style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
        ),
        content: Text(
          content,
          style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeUtils.getErrorColor(context),
              foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
            ),
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
        title: Text(
          'Admin Notifications',
          style: TextStyle(
            color: ThemeUtils.getTextOnPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        elevation: 0,
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.mark_email_read,
                color: ThemeUtils.getTextOnPrimaryColor(context),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: ThemeUtils.getTextOnPrimaryColor(context),
            ),
            color: ThemeUtils.getSurfaceColor(context),
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _clearAllNotifications();
                  break;
                case 'test_notification':
                  _sendTestNotification();
                  break;
                case 'refresh':
                  _loadNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: ThemeUtils.getTextPrimaryColor(context)),
                    const SizedBox(width: 8),
                    Text('Refresh', style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: ThemeUtils.getTextPrimaryColor(context)),
                    const SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'test_notification',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: ThemeUtils.getTextPrimaryColor(context)),
                    const SizedBox(width: 8),
                    Text('Test Notification', style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context))),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ThemeUtils.getTextOnPrimaryColor(context),
          unselectedLabelColor: ThemeUtils.getTextOnPrimaryColor(context).withOpacity(0.7),
          indicatorColor: ThemeUtils.getTextOnPrimaryColor(context),
          tabs: [
            Tab(text: 'All (${_allNotifications.length})'),
            Tab(text: 'Unread (${_unreadNotifications.length})'),
            Tab(text: 'Verifications (${_verificationNotifications.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: ThemeUtils.getPrimaryColor(context),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_allNotifications),
                _buildNotificationsList(_unreadNotifications),
                _buildNotificationsList(_verificationNotifications),
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
      color: ThemeUtils.getPrimaryColor(context),
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
          : ThemeUtils.getSurfaceColor(context).withOpacity(0.9),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead 
              ? ThemeUtils.getBorderLightColor(context)
              : ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
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
                                  color: ThemeUtils.getTextPrimaryColor(context),
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: ThemeUtils.getPrimaryColor(context),
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
                    color: ThemeUtils.getSurfaceColor(context),
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
                        PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read, size: 16, color: ThemeUtils.getTextPrimaryColor(context)),
                              const SizedBox(width: 8),
                              Text('Mark as read', style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context))),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context))),
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
      case NotificationType.doctorVerificationRequest:
        iconData = Icons.verified_user;
        iconColor = AppColors.warning;
        break;
      case NotificationType.verificationStatusUpdate:
        iconData = Icons.verified;
        iconColor = AppColors.success;
        break;
      case NotificationType.appointmentBooking:
        iconData = Icons.event_note;
        iconColor = AppColors.primary;
        break;
      case NotificationType.paymentReceived:
        iconData = Icons.account_balance_wallet;
        iconColor = AppColors.success;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
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
      case NotificationType.doctorVerificationRequest:
        label = 'Verification Request';
        color = AppColors.warning;
        break;
      case NotificationType.verificationStatusUpdate:
        label = 'Verification Update';
        color = AppColors.success;
        break;
      case NotificationType.appointmentBooking:
        label = 'New Appointment';
        color = AppColors.primary;
        break;
      case NotificationType.paymentReceived:
        label = 'Payment';
        color = AppColors.success;
        break;
      default:
        label = 'General';
        color = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    await _markAsRead(notification);
    
    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.doctorVerificationRequest:
        // Navigate to doctor verification screen
        if (mounted) {
          Navigator.pushNamed(context, '/admin/doctor-verification');
        }
        break;
      case NotificationType.appointmentBooking:
        // Navigate to appointments management
        if (mounted) {
          Navigator.pushNamed(context, '/admin/appointments');
        }
        break;
      default:
        // Just mark as read for other types
        break;
    }
  }

  Future<void> _sendTestNotification() async {
    await RoleBasedNotificationChannelService.instance.sendRoleBasedNotification(
      type: NotificationType.general,
      title: 'Admin Test Notification',
      body: 'This is a test notification for admin panel',
      targetRole: 'admin',
    );
    
    await _loadNotifications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Test notification sent'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}