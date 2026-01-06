import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/notification_provider.dart';

/// Widget that displays a notification badge with unread count
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final bool showZero;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCountAsync = ref.watch(notificationCountProvider);

    return notificationCountAsync.when(
      data: (count) {
        if (count == 0 && !showZero) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: BoxConstraints(
                  minWidth: badgeSize ?? 20,
                  minHeight: badgeSize ?? 20,
                ),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.error,
                  borderRadius: BorderRadius.circular((badgeSize ?? 20) / 2),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// Simple notification dot indicator
class NotificationDot extends ConsumerWidget {
  final Widget child;
  final Color? dotColor;
  final double? dotSize;

  const NotificationDot({
    super.key,
    required this.child,
    this.dotColor,
    this.dotSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCountAsync = ref.watch(notificationCountProvider);

    return notificationCountAsync.when(
      data: (count) {
        if (count == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: dotSize ?? 12,
                height: dotSize ?? 12,
                decoration: BoxDecoration(
                  color: dotColor ?? AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// Notification icon button with badge
class NotificationIconButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? iconColor;
  final double? iconSize;
  final Color? badgeColor;
  final String? tooltip;

  const NotificationIconButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.notifications,
    this.iconColor,
    this.iconSize,
    this.badgeColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationBadge(
      badgeColor: badgeColor,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
        tooltip: tooltip ?? 'Notifications',
      ),
    );
  }
}

/// Notification list tile with unread indicator
class NotificationListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isRead;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final DateTime? timestamp;

  const NotificationListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isRead,
    this.onTap,
    this.leading,
    this.trailing,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          if (!isRead)
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              color: isRead ? Colors.grey[600] : Colors.grey[800],
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
      trailing: trailing,
      tileColor: isRead ? null : Colors.blue.withValues(alpha: 0.05),
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
}