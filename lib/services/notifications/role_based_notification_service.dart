import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import 'notification_manager.dart';
import 'fcm_service.dart';

/// Role-based notification service for sending targeted notifications
/// based on user roles (Patient, Doctor, Admin)
class RoleBasedNotificationService {
  static final RoleBasedNotificationService _instance = RoleBasedNotificationService._internal();
  factory RoleBasedNotificationService() => _instance;
  RoleBasedNotificationService._internal();

  static RoleBasedNotificationService get instance => _instance;

  // PATIENT NOTIFICATIONS

  /// Send appointment booking confirmation to patient
  Future<void> sendAppointmentBookingConfirmation({
    required String patientId,
    required String patientFCMToken,
    required String doctorName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'booking_conf_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Appointment Confirmed! 🎉',
        body: 'Your appointment with Dr. $doctorName has been successfully booked for ${_formatDateTime(appointmentTime)}',
        type: NotificationType.appointmentBookingConfirmation,
        data: {
          'appointmentId': appointmentId,
          'doctorName': doctorName,
          'appointmentTime': appointmentTime.toIso8601String(),
          'appointmentType': appointmentType,
          'patientId': patientId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent appointment booking confirmation to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending appointment booking confirmation: $e');
    }
  }

  /// Send appointment reminder to patient
  Future<void> sendAppointmentReminderToPatient({
    required String patientId,
    required String patientFCMToken,
    required String doctorName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
    required int minutesBefore,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'reminder_patient_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Appointment Reminder ⏰',
        body: 'Your appointment with Dr. $doctorName is in $minutesBefore minutes. Please be ready!',
        type: NotificationType.appointmentReminder,
        data: {
          'appointmentId': appointmentId,
          'doctorName': doctorName,
          'appointmentTime': appointmentTime.toIso8601String(),
          'appointmentType': appointmentType,
          'patientId': patientId,
          'minutesBefore': minutesBefore,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent appointment reminder to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending appointment reminder to patient: $e');
    }
  }

  /// Send payment successful notification to patient
  Future<void> sendPaymentSuccessToPatient({
    required String patientId,
    required String patientFCMToken,
    required String paymentId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String doctorName,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'payment_success_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Successful! ✅',
        body: 'Your payment of $currency ${amount.toStringAsFixed(2)} for Dr. $doctorName has been processed successfully',
        type: NotificationType.paymentSuccess,
        data: {
          'paymentId': paymentId,
          'orderId': orderId,
          'amount': amount,
          'currency': currency,
          'paymentMethod': paymentMethod,
          'doctorName': doctorName,
          'patientId': patientId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent payment success notification to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending payment success notification: $e');
    }
  }

  /// Send comprehensive appointment booking confirmation to patient
  /// Includes both appointment booking and payment confirmation
  Future<void> sendAppointmentBookingWithPaymentConfirmation({
    required String patientId,
    required String patientName,
    required String patientFCMToken,
    required String doctorName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
    required String paymentId,
    required double amount,
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'appointment_booking_payment_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Appointment Booked Successfully! 🎉',
        body: 'Hi $patientName! Your appointment is booked successfully with Dr. $doctorName and payment is done for the appointment with doctor.',
        type: NotificationType.appointmentBookingConfirmation,
        data: {
          'appointmentId': appointmentId,
          'patientId': patientId,
          'patientName': patientName,
          'doctorName': doctorName,
          'appointmentTime': appointmentTime.toIso8601String(),
          'appointmentType': appointmentType,
          'paymentId': paymentId,
          'amount': amount,
          'currency': currency,
          'paymentMethod': paymentMethod,
          'paymentStatus': 'completed',
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent appointment booking with payment confirmation to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending appointment booking with payment confirmation: $e');
    }
  }

  /// Send health tips reminder to patient
  Future<void> sendHealthTipsReminder({
    required String patientId,
    required String patientFCMToken,
    required String healthTip,
    required String category,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'health_tip_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Daily Health Tip 💡',
        body: healthTip,
        type: NotificationType.healthTipsReminder,
        data: {
          'category': category,
          'patientId': patientId,
          'tip': healthTip,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent health tip to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending health tip: $e');
    }
  }

  /// Send doctor rescheduled appointment notification to patient
  Future<void> sendDoctorRescheduledAppointment({
    required String patientId,
    required String patientFCMToken,
    required String doctorName,
    required String appointmentId,
    required DateTime oldAppointmentTime,
    required DateTime newAppointmentTime,
    required String reason,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'reschedule_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Appointment Rescheduled 📅',
        body: 'Dr. $doctorName has rescheduled your appointment from ${_formatDateTime(oldAppointmentTime)} to ${_formatDateTime(newAppointmentTime)}',
        type: NotificationType.doctorRescheduledAppointment,
        data: {
          'appointmentId': appointmentId,
          'doctorName': doctorName,
          'oldAppointmentTime': oldAppointmentTime.toIso8601String(),
          'newAppointmentTime': newAppointmentTime.toIso8601String(),
          'reason': reason,
          'patientId': patientId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent appointment reschedule notification to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending appointment reschedule notification: $e');
    }
  }

  /// Send engagement notification to patient
  Future<void> sendEngagementNotification({
    required String patientId,
    required String patientFCMToken,
    required String message,
    required String engagementType, // 'wish', 'checkin', 'motivation'
  }) async {
    try {
      String title;
      String emoji;
      
      switch (engagementType) {
        case 'wish':
          title = 'Special Wishes';
          emoji = '🌟';
          break;
        case 'checkin':
          title = 'Health Check-in';
          emoji = '💚';
          break;
        case 'motivation':
          title = 'Stay Motivated';
          emoji = '💪';
          break;
        default:
          title = 'Health Reminder';
          emoji = '🏥';
      }

      final notification = NotificationModel(
        id: 'engagement_${DateTime.now().millisecondsSinceEpoch}',
        title: '$title $emoji',
        body: message,
        type: NotificationType.engagementNotification,
        data: {
          'engagementType': engagementType,
          'patientId': patientId,
          'message': message,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent engagement notification to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending engagement notification: $e');
    }
  }

  /// Send fitness goal achieved notification to patient
  Future<void> sendFitnessGoalAchieved({
    required String patientId,
    required String patientFCMToken,
    required String goalName,
    required String achievement,
    required int streakDays,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'fitness_goal_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Fitness Goal Achieved! 🎉',
        body: 'Congratulations! You\'ve completed your $goalName goal. $achievement ${streakDays > 0 ? "($streakDays day streak!)" : ""}',
        type: NotificationType.fitnessGoalAchieved,
        data: {
          'goalName': goalName,
          'achievement': achievement,
          'streakDays': streakDays,
          'patientId': patientId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(patientFCMToken, notification);
      debugPrint('Sent fitness goal achievement to patient: $patientId');
    } catch (e) {
      debugPrint('Error sending fitness goal achievement: $e');
    }
  }

  // DOCTOR NOTIFICATIONS

  /// Send appointment booking notification to doctor
  Future<void> sendAppointmentBookingToDoctor({
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'booking_doctor_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Appointment Booked! 📅',
        body: '$patientName has booked a $appointmentType appointment for ${_formatDateTime(appointmentTime)}',
        type: NotificationType.appointmentBooking,
        data: {
          'appointmentId': appointmentId,
          'patientName': patientName,
          'appointmentTime': appointmentTime.toIso8601String(),
          'appointmentType': appointmentType,
          'doctorId': doctorId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(doctorFCMToken, notification);
      debugPrint('Sent appointment booking notification to doctor: $doctorId');
    } catch (e) {
      debugPrint('Error sending appointment booking to doctor: $e');
    }
  }

  /// Send appointment reminder to doctor
  Future<void> sendAppointmentReminderToDoctor({
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
    required int minutesBefore,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'reminder_doctor_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Upcoming Appointment ⏰',
        body: 'You have a $appointmentType appointment with $patientName in $minutesBefore minutes',
        type: NotificationType.appointmentBooking,
        data: {
          'appointmentId': appointmentId,
          'patientName': patientName,
          'appointmentTime': appointmentTime.toIso8601String(),
          'appointmentType': appointmentType,
          'doctorId': doctorId,
          'minutesBefore': minutesBefore,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(doctorFCMToken, notification);
      debugPrint('Sent appointment reminder to doctor: $doctorId');
    } catch (e) {
      debugPrint('Error sending appointment reminder to doctor: $e');
    }
  }

  /// Send payment received notification to doctor
  Future<void> sendPaymentReceivedToDoctor({
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String paymentId,
    required double amount,
    required String currency,
    required String appointmentId,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'payment_received_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payment Received! 💰',
        body: 'You received $currency ${amount.toStringAsFixed(2)} from $patientName for the appointment',
        type: NotificationType.paymentReceived,
        data: {
          'paymentId': paymentId,
          'patientName': patientName,
          'amount': amount,
          'currency': currency,
          'appointmentId': appointmentId,
          'doctorId': doctorId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(doctorFCMToken, notification);
      debugPrint('Sent payment received notification to doctor: $doctorId');
    } catch (e) {
      debugPrint('Error sending payment received notification: $e');
    }
  }

  /// Send appointment rescheduled or cancelled notification to doctor
  Future<void> sendAppointmentRescheduledOrCancelledToDoctor({
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String appointmentId,
    required String action, // 'rescheduled' or 'cancelled'
    required DateTime originalTime,
    DateTime? newTime,
    String? reason,
  }) async {
    try {
      String title;
      String body;
      
      if (action == 'cancelled') {
        title = 'Appointment Cancelled ❌';
        body = '$patientName has cancelled the appointment scheduled for ${_formatDateTime(originalTime)}';
      } else {
        title = 'Appointment Rescheduled 📅';
        body = '$patientName has rescheduled the appointment from ${_formatDateTime(originalTime)} to ${newTime != null ? _formatDateTime(newTime) : "TBD"}';
      }

      final notification = NotificationModel(
        id: 'appointment_change_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        type: NotificationType.appointmentRescheduledOrCancelled,
        data: {
          'appointmentId': appointmentId,
          'patientName': patientName,
          'action': action,
          'originalTime': originalTime.toIso8601String(),
          'newTime': newTime?.toIso8601String(),
          'reason': reason,
          'doctorId': doctorId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(doctorFCMToken, notification);
      debugPrint('Sent appointment $action notification to doctor: $doctorId');
    } catch (e) {
      debugPrint('Error sending appointment change notification to doctor: $e');
    }
  }

  /// Send verification status update to doctor
  Future<void> sendVerificationStatusUpdate({
    required String doctorId,
    required String doctorFCMToken,
    required String status, // 'approved', 'rejected', 'pending'
    String? rejectionReason,
  }) async {
    try {
      String title;
      String body;
      
      switch (status) {
        case 'approved':
          title = 'Verification Approved! ✅';
          body = 'Congratulations! Your doctor verification has been approved. You can now start accepting patients.';
          break;
        case 'rejected':
          title = 'Verification Update ❌';
          body = 'Your verification request needs attention. ${rejectionReason ?? "Please check your documents and resubmit."}';
          break;
        case 'pending':
          title = 'Verification In Progress ⏳';
          body = 'Your verification documents are being reviewed. We\'ll notify you once the review is complete.';
          break;
        default:
          title = 'Verification Update';
          body = 'There\'s an update on your verification status.';
      }

      final notification = NotificationModel(
        id: 'verification_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        type: NotificationType.verificationStatusUpdate,
        data: {
          'status': status,
          'rejectionReason': rejectionReason,
          'doctorId': doctorId,
        },
        timestamp: DateTime.now(),
      );

      await _sendNotificationToUser(doctorFCMToken, notification);
      debugPrint('Sent verification status update to doctor: $doctorId');
    } catch (e) {
      debugPrint('Error sending verification status update: $e');
    }
  }

  // ADMIN NOTIFICATIONS

  /// Send doctor verification request to admin
  Future<void> sendDoctorVerificationRequestToAdmin({
    required List<String> adminFCMTokens,
    required String doctorId,
    required String doctorName,
    required String email,
    required String specialization,
    required String phoneNumber,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'admin_verification_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Doctor Verification Request! 🩺',
        body: 'Dr. $doctorName ($specialization) has submitted verification documents for review',
        type: NotificationType.doctorVerificationRequest,
        data: {
          'doctorId': doctorId,
          'doctorName': doctorName,
          'email': email,
          'specialization': specialization,
          'phoneNumber': phoneNumber,
          'requestTime': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      // Send to all admin tokens
      for (final adminToken in adminFCMTokens) {
        await _sendNotificationToUser(adminToken, notification);
      }
      
      debugPrint('Sent doctor verification request to ${adminFCMTokens.length} admins');
    } catch (e) {
      debugPrint('Error sending doctor verification request to admin: $e');
    }
  }

  // UTILITY METHODS

  /// Send notification to a specific user via FCM token
  Future<void> _sendNotificationToUser(String fcmToken, NotificationModel notification) async {
    try {
      // Use the public method from notification manager
      await NotificationManager.instance.sendFCMMessage(fcmToken, notification);
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
    }
  }

  /// Format DateTime for display in notifications
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final notificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (notificationDate == today) {
      dateStr = 'Today';
    } else if (notificationDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  /// Subscribe user to role-based topics
  Future<void> subscribeUserToRoleTopics({
    required String userId,
    required String userRole, // 'patient', 'doctor', 'admin'
    List<String>? specializations,
    String? location,
  }) async {
    try {
      await NotificationManager.instance.subscribeToTopics(
        userType: userRole,
        userId: userId,
        specializations: specializations,
      );
      
      // Subscribe to location-based topics if provided
      if (location != null) {
        await FCMService.instance.subscribeToTopic('location_${location.toLowerCase()}');
      }
      
      debugPrint('Subscribed user $userId to $userRole topics');
    } catch (e) {
      debugPrint('Error subscribing user to role topics: $e');
    }
  }

  /// Unsubscribe user from role-based topics (for logout)
  Future<void> unsubscribeUserFromRoleTopics({
    required String userId,
    required String userRole,
    List<String>? specializations,
    String? location,
  }) async {
    try {
      await NotificationManager.instance.unsubscribeFromAllTopics(
        userType: userRole,
        userId: userId,
        specializations: specializations,
      );
      
      // Unsubscribe from location-based topics if provided
      if (location != null) {
        await FCMService.instance.unsubscribeFromTopic('location_${location.toLowerCase()}');
      }
      
      debugPrint('Unsubscribed user $userId from $userRole topics');
    } catch (e) {
      debugPrint('Error unsubscribing user from role topics: $e');
    }
  }

  /// Send bulk notifications to multiple users
  Future<void> sendBulkNotifications({
    required List<String> fcmTokens,
    required NotificationModel notification,
  }) async {
    try {
      for (final token in fcmTokens) {
        await _sendNotificationToUser(token, notification);
      }
      debugPrint('Sent bulk notification to ${fcmTokens.length} users');
    } catch (e) {
      debugPrint('Error sending bulk notifications: $e');
    }
  }

  /// Send topic-based notification
  Future<void> sendTopicNotification({
    required String topic,
    required NotificationModel notification,
  }) async {
    try {
      // This would typically be handled by your backend
      // For now, we'll just log it
      debugPrint('Would send topic notification to: $topic');
      debugPrint('Notification: ${notification.title} - ${notification.body}');
    } catch (e) {
      debugPrint('Error sending topic notification: $e');
    }
  }
}