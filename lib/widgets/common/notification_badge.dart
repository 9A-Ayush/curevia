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
  final double? fontSize;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider);

    return notificationCount.when(
      data: (count) {
        if (count == 0 && !showZero) {
          return child;
        }

        return Badge(
          isLabelVisible: count > 0 || showZero,
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize ?? 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: badgeColor ?? AppColors.error,
          child: child,
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// Widget that displays a notification icon with badge
class NotificationIconWithBadge extends ConsumerWidget {
  final IconData icon;
  final IconData? activeIcon;
  final Color? iconColor;
  final double? iconSize;
  final VoidCallback? onTap;
  final bool showZero;
  final Color? badgeColor;

  const NotificationIconWithBadge({
    super.key,
    required this.icon,
    this.activeIcon,
    this.iconColor,
    this.iconSize,
    this.onTap,
    this.showZero = false,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider);

    return notificationCount.when(
      data: (count) {
        final iconWidget = Icon(
          icon,
          color: iconColor,
          size: iconSize,
        );

        final badgedIcon = count > 0 || showZero
            ? Badge(
                isLabelVisible: count > 0 || showZero,
                label: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: badgeColor ?? AppColors.error,
                child: iconWidget,
              )
            : iconWidget;

        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: badgedIcon,
            ),
          );
        }

        return badgedIcon;
      },
      loading: () => Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
      error: (_, __) => Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}

/// Floating action button with notification badge
class NotificationFAB extends ConsumerWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const NotificationFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.notifications,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider);

    return notificationCount.when(
      data: (count) {
        return Badge(
          isLabelVisible: count > 0,
          label: Text(
            count > 99 ? '99+' : count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.error,
          child: FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            tooltip: tooltip ?? 'Notifications',
            child: Icon(icon),
          ),
        );
      },
      loading: () => FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        tooltip: tooltip ?? 'Notifications',
        child: Icon(icon),
      ),
      error: (_, __) => FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        tooltip: tooltip ?? 'Notifications',
        child: Icon(icon),
      ),
    );
  }
}