import 'package:flutter/material.dart';
import 'services/notifications/notification_manager.dart';
import 'models/notification_model.dart';

/// Test helper for notification icon functionality
class NotificationIconTestHelper {
  /// Test notification with custom icon
  static Future<void> testNotificationIcon() async {
    try {
      print('🔔 Testing notification with custom Curevia icon...');
      
      // Initialize notification manager if not already done
      if (!NotificationManager.instance.isInitialized) {
        await NotificationManager.instance.initialize();
      }
      
      // Send test notifications for different types
      await NotificationManager.instance.sendTestNotification(
        title: 'Appointment Reminder',
        body: 'You have an appointment with Dr. Smith in 30 minutes',
        type: NotificationType.appointmentReminder,
        data: {
          'appointmentId': 'test_123',
          'doctorName': 'Dr. Smith',
          'type': 'appointment',
        },
      );
      
      // Wait a bit before sending the next one
      await Future.delayed(const Duration(seconds: 2));
      
      await NotificationManager.instance.sendTestNotification(
        title: 'Payment Successful',
        body: 'Your payment of ₹500 has been processed successfully',
        type: NotificationType.paymentSuccess,
        data: {
          'paymentId': 'pay_test_456',
          'amount': '500',
          'type': 'payment',
        },
      );
      
      // Wait a bit before sending the next one
      await Future.delayed(const Duration(seconds: 2));
      
      await NotificationManager.instance.sendTestNotification(
        title: 'Medical Reports Shared',
        body: 'John Doe has shared medical reports with you',
        type: NotificationType.medicalReportShared,
        data: {
          'sharingId': 'share_test_789',
          'patientName': 'John Doe',
          'type': 'medical_sharing',
        },
      );
      
      print('✅ Test notifications sent successfully!');
      print('   Check your notification panel to see the custom Curevia icons');
      
    } catch (e) {
      print('❌ Error testing notification icon: $e');
    }
  }
  
  /// Test scheduled notification
  static Future<void> testScheduledNotification() async {
    try {
      print('⏰ Testing scheduled notification with custom icon...');
      
      // Schedule a notification for 10 seconds from now
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
      
      final notification = NotificationModel(
        id: 'scheduled_test_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Scheduled Notification Test',
        body: 'This notification was scheduled 10 seconds ago with custom Curevia icon',
        type: NotificationType.appointmentReminder,
        data: {
          'test': 'scheduled',
          'scheduledAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      );
      
      // Use FCM service directly for scheduling
      final fcmService = await import('services/notifications/fcm_service.dart');
      await fcmService.FCMService.instance.scheduleNotification(
        notification: notification,
        scheduledTime: scheduledTime,
      );
      
      print('✅ Scheduled notification set for: $scheduledTime');
      print('   You should receive it in 10 seconds with the custom icon');
      
    } catch (e) {
      print('❌ Error testing scheduled notification: $e');
    }
  }
}

/// Widget to test notification icons
class NotificationIconTestWidget extends StatelessWidget {
  const NotificationIconTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Icon Test'),
        backgroundColor: const Color(0xFF0175C2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_active,
              size: 64,
              color: Color(0xFF0175C2),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notification Icon Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test the custom Curevia notification icons',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Test immediate notifications
            ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sending test notifications...'),
                  ),
                );
                
                await NotificationIconTestHelper.testNotificationIcon();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notifications sent! Check your notification panel.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Test Notification Icons'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0175C2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test scheduled notification
            ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scheduling test notification...'),
                  ),
                );
                
                await NotificationIconTestHelper.testScheduledNotification();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scheduled notification set for 10 seconds!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.schedule),
              label: const Text('Test Scheduled Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Tap "Test Notification Icons" to send immediate notifications\n'
                    '2. Check your notification panel to see the custom Curevia icons\n'
                    '3. The small icon should be a medical cross with heart (no blue circle)\n'
                    '4. The notification will use your app\'s brand color for tinting',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}