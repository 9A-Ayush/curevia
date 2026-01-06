import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import 'notification_manager.dart';
import 'notification_scheduler.dart';

/// Example class showing how to integrate notifications into your app
class NotificationIntegrationExample {
  
  /// Example: Send appointment reminder when appointment is booked
  static Future<void> onAppointmentBooked({
    required String appointmentId,
    required String doctorName,
    required String patientName,
    required DateTime appointmentTime,
    required String appointmentType,
    required String patientId,
    required String doctorId,
    required String patientFCMToken,
    required String doctorFCMToken,
  }) async {
    try {
      // Schedule local reminders for both patient and doctor
      await NotificationScheduler.instance.scheduleAppointmentReminders(
        appointmentId: appointmentId,
        doctorName: doctorName,
        patientName: patientName,
        appointmentTime: appointmentTime,
        appointmentType: appointmentType,
        isForDoctor: false,
        userId: patientId,
      );

      await NotificationScheduler.instance.scheduleAppointmentReminders(
        appointmentId: appointmentId,
        doctorName: doctorName,
        patientName: patientName,
        appointmentTime: appointmentTime,
        appointmentType: appointmentType,
        isForDoctor: true,
        userId: doctorId,
      );

      // Send immediate confirmation notification (optional)
      await NotificationManager.instance.sendAppointmentReminder(
        appointmentId: appointmentId,
        doctorName: doctorName,
        patientName: patientName,
        appointmentTime: appointmentTime,
        appointmentType: appointmentType,
        patientFCMToken: patientFCMToken,
        doctorFCMToken: doctorFCMToken,
      );

      debugPrint('Appointment notifications set up successfully');
    } catch (e) {
      debugPrint('Error setting up appointment notifications: $e');
    }
  }

  /// Example: Send payment success notification
  static Future<void> onPaymentSuccess({
    required String paymentId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String userFCMToken,
  }) async {
    try {
      await NotificationManager.instance.sendPaymentSuccessNotification(
        paymentId: paymentId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        userFCMToken: userFCMToken,
      );

      debugPrint('Payment success notification sent');
    } catch (e) {
      debugPrint('Error sending payment success notification: $e');
    }
  }

  /// Example: Send doctor verification request to admin
  static Future<void> onDoctorVerificationRequest({
    required String doctorId,
    required String doctorName,
    required String email,
    required String specialization,
    required List<String> adminFCMTokens,
  }) async {
    try {
      await NotificationManager.instance.sendDoctorVerificationRequest(
        doctorId: doctorId,
        doctorName: doctorName,
        email: email,
        specialization: specialization,
        adminFCMTokens: adminFCMTokens,
      );

      debugPrint('Doctor verification request notification sent to admins');
    } catch (e) {
      debugPrint('Error sending doctor verification request: $e');
    }
  }

  /// Example: Initialize notifications for a user after login
  static Future<void> initializeUserNotifications({
    required String userId,
    required String userType, // 'patient', 'doctor', 'admin'
    List<String>? specializations,
  }) async {
    try {
      // Subscribe to relevant topics
      await NotificationManager.instance.subscribeToTopics(
        userType: userType,
        userId: userId,
        specializations: specializations,
      );

      // Send FCM token to server
      await NotificationManager.instance.sendTokenToServer(
        userId: userId,
        userType: userType,
      );

      debugPrint('User notifications initialized for $userType: $userId');
    } catch (e) {
      debugPrint('Error initializing user notifications: $e');
    }
  }

  /// Example: Clean up notifications on logout
  static Future<void> cleanupUserNotifications({
    required String userId,
    required String userType,
    List<String>? specializations,
  }) async {
    try {
      // Unsubscribe from topics
      await NotificationManager.instance.unsubscribeFromAllTopics(
        userType: userType,
        userId: userId,
        specializations: specializations,
      );

      // Clear FCM token
      await NotificationManager.instance.clearToken();

      // Cancel all scheduled notifications
      await NotificationScheduler.instance.cancelAllReminders();

      debugPrint('User notifications cleaned up for $userType: $userId');
    } catch (e) {
      debugPrint('Error cleaning up user notifications: $e');
    }
  }

  /// Example: Schedule medication reminders
  static Future<void> scheduleMedicationReminders({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required List<TimeOfDay> reminderTimes,
    required int durationDays,
  }) async {
    try {
      final now = DateTime.now();
      final reminderDateTimes = <DateTime>[];

      // Generate reminder times for the duration
      for (int day = 0; day < durationDays; day++) {
        final date = now.add(Duration(days: day));
        for (final time in reminderTimes) {
          final reminderDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (reminderDateTime.isAfter(now)) {
            reminderDateTimes.add(reminderDateTime);
          }
        }
      }

      await NotificationScheduler.instance.scheduleMedicationReminder(
        medicationId: medicationId,
        medicationName: medicationName,
        reminderTimes: reminderDateTimes,
        dosage: dosage,
        instructions: 'Take as prescribed by your doctor',
      );

      debugPrint('Medication reminders scheduled for $medicationName');
    } catch (e) {
      debugPrint('Error scheduling medication reminders: $e');
    }
  }

  /// Example: Handle notification tap in your app
  static void handleNotificationTap(NotificationModel notification) {
    // This is automatically handled by NotificationHandler
    // But you can add custom logic here if needed
    debugPrint('Notification tapped: ${notification.title}');
    
    // Example: Track analytics
    // AnalyticsService.trackNotificationTap(notification);
    
    // Example: Update user engagement metrics
    // UserEngagementService.recordNotificationInteraction(notification);
  }

  /// Example: Test all notification types
  static Future<void> testAllNotifications() async {
    try {
      // Test appointment reminder
      await NotificationManager.instance.sendTestNotification(
        title: 'Appointment Reminder Test',
        body: 'This is a test appointment reminder notification',
        type: NotificationType.appointmentReminder,
      );

      await Future.delayed(const Duration(seconds: 2));

      // Test payment success
      await NotificationManager.instance.sendTestNotification(
        title: 'Payment Success Test',
        body: 'This is a test payment success notification',
        type: NotificationType.paymentSuccess,
      );

      await Future.delayed(const Duration(seconds: 2));

      // Test doctor verification
      await NotificationManager.instance.sendTestNotification(
        title: 'Doctor Verification Test',
        body: 'This is a test doctor verification notification',
        type: NotificationType.doctorVerificationRequest,
      );

      await Future.delayed(const Duration(seconds: 2));

      // Test general notification
      await NotificationManager.instance.sendTestNotification(
        title: 'General Notification Test',
        body: 'This is a test general notification',
        type: NotificationType.general,
      );

      debugPrint('All test notifications sent');
    } catch (e) {
      debugPrint('Error sending test notifications: $e');
    }
  }

  /// Example: Get notification statistics for admin dashboard
  static Future<Map<String, dynamic>> getNotificationAnalytics() async {
    try {
      final stats = await NotificationManager.instance.getNotificationStats();
      final unreadCount = await NotificationManager.instance.getUnreadNotificationCount();
      
      return {
        'stats': stats,
        'unreadCount': unreadCount,
        'fcmToken': NotificationManager.instance.fcmToken,
        'isInitialized': NotificationManager.instance.isInitialized,
      };
    } catch (e) {
      debugPrint('Error getting notification analytics: $e');
      return {};
    }
  }
}

/// Widget example showing how to use notifications in UI
class NotificationExampleWidget extends StatelessWidget {
  const NotificationExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Examples'),
        actions: [
          // Example: Notification icon with badge
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => NotificationIntegrationExample.testAllNotifications(),
              child: const Text('Test All Notifications'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final analytics = await NotificationIntegrationExample.getNotificationAnalytics();
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Notification Analytics'),
                      content: Text(analytics.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Show Analytics'),
            ),
          ],
        ),
      ),
    );
  }
}