import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';
import 'role_based_notification_service.dart';
import 'notification_manager.dart';
import 'fcm_service.dart';

/// Service for testing notifications during development
/// Provides methods to test all notification types and scenarios
class NotificationTestingService {
  static final NotificationTestingService _instance = NotificationTestingService._internal();
  factory NotificationTestingService() => _instance;
  NotificationTestingService._internal();

  static NotificationTestingService get instance => _instance;

  /// Test all patient notification types
  Future<void> testAllPatientNotifications() async {
    debugPrint('🧪 Testing all patient notifications...');
    
    final service = RoleBasedNotificationService.instance;
    final testToken = FCMService.instance.fcmToken ?? 'test_patient_token';
    
    try {
      // 1. Appointment Booking Confirmation
      await service.sendAppointmentBookingConfirmation(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        doctorName: 'Dr. Sarah Wilson',
        appointmentId: 'apt_001',
        appointmentTime: DateTime.now().add(const Duration(days: 2)),
        appointmentType: 'General Consultation',
      );
      await _delay();

      // 2. Appointment Reminder
      await service.sendAppointmentReminderToPatient(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        doctorName: 'Dr. Sarah Wilson',
        appointmentId: 'apt_001',
        appointmentTime: DateTime.now().add(const Duration(minutes: 30)),
        appointmentType: 'General Consultation',
        minutesBefore: 30,
      );
      await _delay();

      // 3. Payment Success
      await service.sendPaymentSuccessToPatient(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        paymentId: 'pay_001',
        orderId: 'order_001',
        amount: 750.0,
        currency: 'INR',
        paymentMethod: 'UPI',
        doctorName: 'Dr. Sarah Wilson',
      );
      await _delay();

      // 4. Health Tips Reminder
      await service.sendHealthTipsReminder(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        healthTip: 'Take a 10-minute walk after meals to improve digestion and blood sugar control.',
        category: 'Diabetes Management',
      );
      await _delay();

      // 5. Doctor Rescheduled Appointment
      await service.sendDoctorRescheduledAppointment(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        doctorName: 'Dr. Sarah Wilson',
        appointmentId: 'apt_001',
        oldAppointmentTime: DateTime.now().add(const Duration(days: 2)),
        newAppointmentTime: DateTime.now().add(const Duration(days: 3)),
        reason: 'Emergency surgery scheduled',
      );
      await _delay();

      // 6. Engagement Notifications
      await service.sendEngagementNotification(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        message: 'How are you feeling today? Remember, your health journey matters!',
        engagementType: 'checkin',
      );
      await _delay();

      await service.sendEngagementNotification(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        message: 'Happy Birthday! 🎉 Wishing you a year filled with good health and happiness!',
        engagementType: 'wish',
      );
      await _delay();

      await service.sendEngagementNotification(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        message: 'You\'re doing great! Keep up the healthy habits and stay motivated! 💪',
        engagementType: 'motivation',
      );
      await _delay();

      // 7. Fitness Goal Achieved
      await service.sendFitnessGoalAchieved(
        patientId: 'test_patient_001',
        patientFCMToken: testToken,
        goalName: 'Daily Steps Goal',
        achievement: 'You walked 12,000 steps today!',
        streakDays: 14,
      );

      debugPrint('✅ All patient notifications tested successfully');
    } catch (e) {
      debugPrint('❌ Error testing patient notifications: $e');
    }
  }

  /// Test all doctor notification types
  Future<void> testAllDoctorNotifications() async {
    debugPrint('🧪 Testing all doctor notifications...');
    
    final service = RoleBasedNotificationService.instance;
    final testToken = FCMService.instance.fcmToken ?? 'test_doctor_token';
    
    try {
      // 1. New Appointment Booking
      await service.sendAppointmentBookingToDoctor(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        patientName: 'John Smith',
        appointmentId: 'apt_002',
        appointmentTime: DateTime.now().add(const Duration(hours: 4)),
        appointmentType: 'Follow-up Consultation',
      );
      await _delay();

      // 2. Appointment Reminder for Doctor
      await service.sendAppointmentReminderToDoctor(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        patientName: 'John Smith',
        appointmentId: 'apt_002',
        appointmentTime: DateTime.now().add(const Duration(minutes: 15)),
        appointmentType: 'Follow-up Consultation',
        minutesBefore: 15,
      );
      await _delay();

      // 3. Payment Received
      await service.sendPaymentReceivedToDoctor(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        patientName: 'John Smith',
        paymentId: 'pay_002',
        amount: 1200.0,
        currency: 'INR',
        appointmentId: 'apt_002',
      );
      await _delay();

      // 4. Appointment Rescheduled by Patient
      await service.sendAppointmentRescheduledOrCancelledToDoctor(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        patientName: 'John Smith',
        appointmentId: 'apt_002',
        action: 'rescheduled',
        originalTime: DateTime.now().add(const Duration(hours: 4)),
        newTime: DateTime.now().add(const Duration(days: 1)),
        reason: 'Patient requested different time',
      );
      await _delay();

      // 5. Appointment Cancelled by Patient
      await service.sendAppointmentRescheduledOrCancelledToDoctor(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        patientName: 'Jane Doe',
        appointmentId: 'apt_003',
        action: 'cancelled',
        originalTime: DateTime.now().add(const Duration(hours: 6)),
        reason: 'Personal emergency',
      );
      await _delay();

      // 6. Verification Status Updates
      await service.sendVerificationStatusUpdate(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        status: 'pending',
      );
      await _delay();

      await service.sendVerificationStatusUpdate(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        status: 'approved',
      );
      await _delay();

      await service.sendVerificationStatusUpdate(
        doctorId: 'test_doctor_001',
        doctorFCMToken: testToken,
        status: 'rejected',
        rejectionReason: 'Medical license document is not clear. Please upload a higher quality image.',
      );

      debugPrint('✅ All doctor notifications tested successfully');
    } catch (e) {
      debugPrint('❌ Error testing doctor notifications: $e');
    }
  }

  /// Test all admin notification types
  Future<void> testAllAdminNotifications() async {
    debugPrint('🧪 Testing all admin notifications...');
    
    final service = RoleBasedNotificationService.instance;
    final testToken = FCMService.instance.fcmToken ?? 'test_admin_token';
    
    try {
      // 1. Doctor Verification Request
      await service.sendDoctorVerificationRequestToAdmin(
        adminFCMTokens: [testToken],
        doctorId: 'test_doctor_002',
        doctorName: 'Dr. Michael Johnson',
        email: 'dr.johnson@example.com',
        specialization: 'Cardiology',
        phoneNumber: '+91-9876543210',
      );
      await _delay();

      // 2. Another verification request with different specialization
      await service.sendDoctorVerificationRequestToAdmin(
        adminFCMTokens: [testToken],
        doctorId: 'test_doctor_003',
        doctorName: 'Dr. Emily Chen',
        email: 'dr.chen@example.com',
        specialization: 'Dermatology',
        phoneNumber: '+91-9876543211',
      );

      debugPrint('✅ All admin notifications tested successfully');
    } catch (e) {
      debugPrint('❌ Error testing admin notifications: $e');
    }
  }

  /// Test notification sounds
  Future<void> testNotificationSounds() async {
    debugPrint('🔊 Testing notification sounds...');
    
    try {
      // Test different notification types with their respective sounds
      final notificationTypes = [
        NotificationType.appointmentBookingConfirmation,
        NotificationType.paymentSuccess,
        NotificationType.doctorVerificationRequest,
        NotificationType.healthTipsReminder,
        NotificationType.fitnessGoalAchieved,
      ];

      for (final type in notificationTypes) {
        await NotificationManager.instance.sendTestNotification(
          title: 'Sound Test: ${type.channelName}',
          body: 'Testing sound for ${type.toString()}',
          type: type,
          data: {'soundTest': true},
        );
        
        debugPrint('🔊 Tested sound for: ${type.toString()}');
        await _delay(2000); // 2 second delay between sound tests
      }

      debugPrint('✅ All notification sounds tested');
    } catch (e) {
      debugPrint('❌ Error testing notification sounds: $e');
    }
  }

  /// Test notification priorities and channels
  Future<void> testNotificationPriorities() async {
    debugPrint('📊 Testing notification priorities...');
    
    try {
      // High priority notifications
      final highPriorityTypes = [
        NotificationType.appointmentReminder,
        NotificationType.doctorVerificationRequest,
        NotificationType.appointmentBookingConfirmation,
      ];

      for (final type in highPriorityTypes) {
        await NotificationManager.instance.sendTestNotification(
          title: 'HIGH PRIORITY: ${type.channelName}',
          body: 'This is a high priority notification test',
          type: type,
          data: {'priorityTest': 'high'},
        );
        await _delay();
      }

      // Medium/Low priority notifications
      final lowPriorityTypes = [
        NotificationType.healthTipsReminder,
        NotificationType.engagementNotification,
        NotificationType.general,
      ];

      for (final type in lowPriorityTypes) {
        await NotificationManager.instance.sendTestNotification(
          title: 'NORMAL PRIORITY: ${type.channelName}',
          body: 'This is a normal priority notification test',
          type: type,
          data: {'priorityTest': 'normal'},
        );
        await _delay();
      }

      debugPrint('✅ All notification priorities tested');
    } catch (e) {
      debugPrint('❌ Error testing notification priorities: $e');
    }
  }

  /// Test bulk notifications
  Future<void> testBulkNotifications() async {
    debugPrint('📢 Testing bulk notifications...');
    
    try {
      final testTokens = [
        FCMService.instance.fcmToken ?? 'test_token_1',
        'test_token_2',
        'test_token_3',
      ];

      final bulkNotification = NotificationModel(
        id: 'bulk_test_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Bulk Notification Test 📢',
        body: 'This is a test of the bulk notification system. All users should receive this message.',
        type: NotificationType.general,
        data: {
          'bulkTest': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      await RoleBasedNotificationService.instance.sendBulkNotifications(
        fcmTokens: testTokens,
        notification: bulkNotification,
      );

      debugPrint('✅ Bulk notification test completed');
    } catch (e) {
      debugPrint('❌ Error testing bulk notifications: $e');
    }
  }

  /// Test notification scheduling
  Future<void> testNotificationScheduling() async {
    debugPrint('⏰ Testing notification scheduling...');
    
    try {
      // Schedule a notification for 10 seconds from now
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
      
      final scheduledNotification = NotificationModel(
        id: 'scheduled_test_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Scheduled Notification Test ⏰',
        body: 'This notification was scheduled 10 seconds ago!',
        type: NotificationType.appointmentReminder,
        data: {
          'scheduledTest': true,
          'scheduledFor': scheduledTime.toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      await FCMService.instance.scheduleNotification(
        notification: scheduledNotification,
        scheduledTime: scheduledTime,
      );

      debugPrint('✅ Scheduled notification for: $scheduledTime');
    } catch (e) {
      debugPrint('❌ Error testing notification scheduling: $e');
    }
  }

  /// Test notification in different app states
  Future<void> testNotificationStates() async {
    debugPrint('📱 Testing notifications in different app states...');
    
    try {
      // Foreground notification
      await NotificationManager.instance.sendTestNotification(
        title: 'Foreground Test 📱',
        body: 'This notification should appear while the app is in foreground',
        type: NotificationType.general,
        data: {'stateTest': 'foreground'},
      );
      await _delay();

      // Background notification (simulated)
      await NotificationManager.instance.sendTestNotification(
        title: 'Background Test 🔄',
        body: 'This notification simulates background delivery',
        type: NotificationType.appointmentReminder,
        data: {'stateTest': 'background'},
      );

      debugPrint('✅ App state notification tests completed');
      debugPrint('ℹ️ To fully test background/terminated states, minimize the app or close it');
    } catch (e) {
      debugPrint('❌ Error testing notification states: $e');
    }
  }

  /// Run comprehensive notification test suite
  Future<void> runFullTestSuite() async {
    debugPrint('🚀 Starting comprehensive notification test suite...');
    
    try {
      await testNotificationSounds();
      await _delay(3000);
      
      await testNotificationPriorities();
      await _delay(3000);
      
      await testAllPatientNotifications();
      await _delay(5000);
      
      await testAllDoctorNotifications();
      await _delay(5000);
      
      await testAllAdminNotifications();
      await _delay(3000);
      
      await testBulkNotifications();
      await _delay(3000);
      
      await testNotificationScheduling();
      await _delay(3000);
      
      await testNotificationStates();
      
      debugPrint('🎉 Full notification test suite completed successfully!');
    } catch (e) {
      debugPrint('❌ Error running full test suite: $e');
    }
  }

  /// Test specific notification type
  Future<void> testSpecificNotification(NotificationType type) async {
    debugPrint('🎯 Testing specific notification: ${type.toString()}');
    
    try {
      String title;
      String body;
      Map<String, dynamic> data = {'specificTest': true};

      switch (type) {
        case NotificationType.appointmentBookingConfirmation:
          title = 'Test: Appointment Confirmed! 🎉';
          body = 'Your test appointment has been successfully booked.';
          break;
        case NotificationType.paymentSuccess:
          title = 'Test: Payment Successful! ✅';
          body = 'Your test payment of ₹500 has been processed.';
          break;
        case NotificationType.healthTipsReminder:
          title = 'Test: Daily Health Tip 💡';
          body = 'Remember to stay hydrated throughout the day!';
          break;
        case NotificationType.fitnessGoalAchieved:
          title = 'Test: Fitness Goal Achieved! 🎉';
          body = 'Congratulations! You completed your daily step goal.';
          break;
        default:
          title = 'Test: ${type.channelName}';
          body = 'This is a test notification for ${type.toString()}';
      }

      await NotificationManager.instance.sendTestNotification(
        title: title,
        body: body,
        type: type,
        data: data,
      );

      debugPrint('✅ Specific notification test completed for: ${type.toString()}');
    } catch (e) {
      debugPrint('❌ Error testing specific notification: $e');
    }
  }

  /// Helper method to add delay between notifications
  Future<void> _delay([int milliseconds = 1500]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Get test statistics
  Map<String, dynamic> getTestStatistics() {
    return {
      'totalNotificationTypes': NotificationType.values.length,
      'patientNotificationTypes': 7,
      'doctorNotificationTypes': 5,
      'adminNotificationTypes': 1,
      'sharedNotificationTypes': 2,
      'testingServiceReady': true,
      'fcmServiceReady': FCMService.instance.isInitialized,
      'notificationManagerReady': NotificationManager.instance.isInitialized,
    };
  }
}