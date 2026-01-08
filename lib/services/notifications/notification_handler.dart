import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../storage/notification_storage_service.dart';

/// Global provider container for accessing providers outside of widget tree
final _providerContainer = ProviderContainer();

/// Cleanup method for the provider container (call this when app is disposed)
void disposeNotificationHandler() {
  _providerContainer.dispose();
}

/// Handles notification actions and navigation
class NotificationHandler {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize the notification badge count
  static Future<void> initializeBadgeCount() async {
    try {
      final unreadCount = await NotificationStorageService.getUnreadNotificationCount();
      _providerContainer.read(notificationCountProvider.notifier).setCount(unreadCount);
      debugPrint('Badge count initialized: $unreadCount');
    } catch (e) {
      debugPrint('Error initializing badge count: $e');
    }
  }

  /// Handle notification received (when app is in foreground)
  static Future<void> handleNotificationReceived(NotificationModel notification) async {
    try {
      // Save notification to local storage
      await NotificationStorageService.saveNotification(notification);
      
      // Increment badge count for new unread notification
      _providerContainer.read(notificationCountProvider.notifier).incrementCount();
      
      // Show in-app notification if needed
      _showInAppNotification(notification);
      
      debugPrint('Notification received and processed: ${notification.id}');
    } catch (e) {
      debugPrint('Error handling notification received: $e');
    }
  }

  /// Handle notification tap (when user taps on notification)
  static Future<void> handleNotificationTap(NotificationModel notification) async {
    try {
      // Mark notification as read if it wasn't already
      if (!notification.isRead) {
        final updatedNotification = notification.copyWith(isRead: true);
        await NotificationStorageService.updateNotification(updatedNotification);
        
        // Update badge count
        _providerContainer.read(notificationCountProvider.notifier).decrementCount();
      }
      
      // Navigate based on notification type
      await _navigateBasedOnNotificationType(notification);
      
      debugPrint('Notification tap handled: ${notification.id}');
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Navigate based on notification type
  static Future<void> _navigateBasedOnNotificationType(NotificationModel notification) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (notification.type) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
      case NotificationType.appointmentReminder:
        await _handleAppointmentReminderTap(context, notification);
        break;
      case NotificationType.paymentSuccess:
        await _handlePaymentSuccessTap(context, notification);
        break;
      case NotificationType.healthTipsReminder:
      case NotificationType.engagementNotification:
      case NotificationType.fitnessGoalAchieved:
        await _handleGeneralNotificationTap(context, notification);
        break;
      case NotificationType.doctorRescheduledAppointment:
        await _handleAppointmentReminderTap(context, notification);
        break;
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        await _handleAppointmentReminderTap(context, notification);
        break;
      case NotificationType.paymentReceived:
        await _handlePaymentSuccessTap(context, notification);
        break;
      case NotificationType.appointmentRescheduledOrCancelled:
        await _handleAppointmentReminderTap(context, notification);
        break;
      case NotificationType.verificationStatusUpdate:
        await _handleDoctorVerificationTap(context, notification);
        break;
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        await _handleDoctorVerificationTap(context, notification);
        break;
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        await _handleMedicalReportSharedTap(context, notification);
        break;
      case NotificationType.general:
        await _handleGeneralNotificationTap(context, notification);
        break;
    }
  }

  /// Handle appointment reminder notification tap
  static Future<void> _handleAppointmentReminderTap(
    BuildContext context, 
    NotificationModel notification,
  ) async {
    try {
      final appointmentData = AppointmentReminderData.fromJson(notification.data);
      
      // Navigate to appointment details
      context.push('/appointments/${appointmentData.appointmentId}');
    } catch (e) {
      debugPrint('Error handling appointment reminder tap: $e');
      // Fallback to appointments list
      context.push('/appointments');
    }
  }

  /// Handle payment success notification tap
  static Future<void> _handlePaymentSuccessTap(
    BuildContext context, 
    NotificationModel notification,
  ) async {
    try {
      final paymentData = PaymentSuccessData.fromJson(notification.data);
      
      // Navigate to payment details or receipt
      context.push('/payments/${paymentData.paymentId}');
    } catch (e) {
      debugPrint('Error handling payment success tap: $e');
      // Fallback to payment history
      context.push('/payments');
    }
  }

  /// Handle doctor verification request notification tap
  static Future<void> _handleDoctorVerificationTap(
    BuildContext context, 
    NotificationModel notification,
  ) async {
    try {
      final doctorData = DoctorVerificationData.fromJson(notification.data);
      
      // Navigate to admin panel for doctor verification
      context.push('/admin/doctor-verification/${doctorData.doctorId}');
    } catch (e) {
      debugPrint('Error handling doctor verification tap: $e');
      // Fallback to admin panel
      context.push('/admin/doctor-verification');
    }
  }

  /// Handle medical report shared notification tap
  static Future<void> _handleMedicalReportSharedTap(
    BuildContext context, 
    NotificationModel notification,
  ) async {
    try {
      final sharingId = notification.data['sharingId'] as String?;
      
      if (sharingId != null) {
        // Navigate to shared medical reports view
        context.push('/shared-reports/$sharingId');
      } else {
        // Fallback to medical reports list
        context.push('/medical-reports');
      }
    } catch (e) {
      debugPrint('Error handling medical report shared tap: $e');
      // Fallback to medical reports list
      context.push('/medical-reports');
    }
  }

  /// Handle general notification tap
  static Future<void> _handleGeneralNotificationTap(
    BuildContext context, 
    NotificationModel notification,
  ) async {
    if (notification.actionUrl != null) {
      // Navigate to specific URL if provided
      context.push(notification.actionUrl!);
    } else {
      // Navigate to notifications list
      context.push('/notifications');
    }
  }

  /// Show in-app notification (optional - for foreground notifications)
  static void _showInAppNotification(NotificationModel notification) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Show a snackbar or overlay notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.type),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => handleNotificationTap(notification),
        ),
      ),
    );
  }

  /// Get notification color based on type
  static Color _getNotificationColor(NotificationType type) {
    switch (type) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
      case NotificationType.appointmentReminder:
      case NotificationType.doctorRescheduledAppointment:
        return Colors.blue;
      case NotificationType.paymentSuccess:
        return Colors.green;
      case NotificationType.healthTipsReminder:
        return Colors.teal;
      case NotificationType.engagementNotification:
        return Colors.indigo;
      case NotificationType.fitnessGoalAchieved:
        return Colors.amber;
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        return Colors.blue;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.appointmentRescheduledOrCancelled:
        return Colors.orange;
      case NotificationType.verificationStatusUpdate:
        return Colors.purple;
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        return Colors.orange;
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  /// Update notification badge count
  static Future<void> _updateBadgeCount() async {
    try {
      final unreadCount = await NotificationStorageService.getUnreadNotificationCount();
      
      // Update the provider state
      _providerContainer.read(notificationCountProvider.notifier).setCount(unreadCount);
      
      // TODO: Update app badge count
      // This might require a plugin like flutter_app_badger
      debugPrint('Unread notification count updated: $unreadCount');
    } catch (e) {
      debugPrint('Error updating badge count: $e');
    }
  }

  /// Create appointment reminder notification
  static NotificationModel createAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required String patientName,
    required DateTime appointmentTime,
    required String appointmentType,
    required bool isForDoctor,
  }) {
    final data = AppointmentReminderData(
      appointmentId: appointmentId,
      doctorName: doctorName,
      patientName: patientName,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
    );

    final title = isForDoctor 
        ? 'Upcoming Appointment'
        : 'Appointment Reminder';
    
    final body = isForDoctor
        ? 'You have an appointment with $patientName in 30 minutes'
        : 'Your appointment with Dr. $doctorName is in 30 minutes';

    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: NotificationType.appointmentReminder,
      data: data.toJson(),
      timestamp: DateTime.now(),
    );
  }

  /// Create payment success notification
  static NotificationModel createPaymentSuccess({
    required String paymentId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
  }) {
    final data = PaymentSuccessData(
      paymentId: paymentId,
      orderId: orderId,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      paymentTime: DateTime.now(),
    );

    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Payment Successful',
      body: 'Your payment of $currency ${amount.toStringAsFixed(2)} has been processed successfully',
      type: NotificationType.paymentSuccess,
      data: data.toJson(),
      timestamp: DateTime.now(),
    );
  }

  /// Create doctor verification request notification
  static NotificationModel createDoctorVerificationRequest({
    required String doctorId,
    required String doctorName,
    required String email,
    required String specialization,
  }) {
    final data = DoctorVerificationData(
      doctorId: doctorId,
      doctorName: doctorName,
      email: email,
      specialization: specialization,
      requestTime: DateTime.now(),
    );

    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Doctor Verification Request',
      body: 'Dr. $doctorName ($specialization) has submitted a verification request',
      type: NotificationType.doctorVerificationRequest,
      data: data.toJson(),
      timestamp: DateTime.now(),
    );
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationStorageService.markAsRead(notificationId);
      
      // Update badge count
      _providerContainer.read(notificationCountProvider.notifier).decrementCount();
      
      debugPrint('Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      await NotificationStorageService.markAllAsRead();
      
      // Reset badge count to zero
      _providerContainer.read(notificationCountProvider.notifier).resetCount();
      
      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      // Check if notification was unread before deleting
      final notifications = await NotificationStorageService.getAllNotifications();
      final notification = notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => NotificationModel(
          id: '',
          title: '',
          body: '',
          type: NotificationType.general,
          data: {},
          timestamp: DateTime.now(),
          isRead: true,
        ),
      );
      
      await NotificationStorageService.deleteNotification(notificationId);
      
      // If the deleted notification was unread, decrement the count
      if (!notification.isRead && notification.id.isNotEmpty) {
        _providerContainer.read(notificationCountProvider.notifier).decrementCount();
      }
      
      debugPrint('Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await NotificationStorageService.clearAllNotifications();
      
      // Reset badge count to zero
      _providerContainer.read(notificationCountProvider.notifier).resetCount();
      
      debugPrint('All notifications cleared');
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }
}