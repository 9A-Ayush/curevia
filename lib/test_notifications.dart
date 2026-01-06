import 'package:flutter/material.dart';
import 'services/notifications/notification_manager.dart';
import 'models/notification_model.dart';

/// Simple test screen for notifications
class TestNotificationsScreen extends StatelessWidget {
  const TestNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                await NotificationManager.instance.sendTestNotification(
                  title: 'Appointment Reminder Test',
                  body: 'This is a test appointment reminder notification',
                  type: NotificationType.appointmentReminder,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment notification sent!')),
                  );
                }
              },
              child: const Text('Test Appointment Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NotificationManager.instance.sendTestNotification(
                  title: 'Payment Success Test',
                  body: 'This is a test payment success notification',
                  type: NotificationType.paymentSuccess,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment notification sent!')),
                  );
                }
              },
              child: const Text('Test Payment Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NotificationManager.instance.sendTestNotification(
                  title: 'Doctor Verification Test',
                  body: 'This is a test doctor verification notification',
                  type: NotificationType.doctorVerificationRequest,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification notification sent!')),
                  );
                }
              },
              child: const Text('Test Verification Notification'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final count = await NotificationManager.instance.getUnreadNotificationCount();
                final stats = await NotificationManager.instance.getNotificationStats();
                
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Notification Stats'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unread Count: $count'),
                          const SizedBox(height: 8),
                          Text('Total: ${stats['total'] ?? 0}'),
                          Text('Read: ${stats['read'] ?? 0}'),
                          Text('FCM Token: ${NotificationManager.instance.fcmToken?.substring(0, 20) ?? 'None'}...'),
                          Text('Initialized: ${NotificationManager.instance.isInitialized}'),
                        ],
                      ),
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
              child: const Text('Show Stats'),
            ),
          ],
        ),
      ),
    );
  }
}