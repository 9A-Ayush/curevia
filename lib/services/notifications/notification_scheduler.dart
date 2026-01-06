import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';
import 'fcm_service.dart';
import 'notification_handler.dart';

/// Service for scheduling notifications (especially appointment reminders)
class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  static NotificationScheduler get instance => _instance;

  /// Schedule appointment reminder notifications
  /// Schedules multiple reminders: 24 hours, 2 hours, and 30 minutes before appointment
  Future<void> scheduleAppointmentReminders({
    required String appointmentId,
    required String doctorName,
    required String patientName,
    required DateTime appointmentTime,
    required String appointmentType,
    required bool isForDoctor,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();
      
      // Schedule 24-hour reminder
      final twentyFourHoursBefore = appointmentTime.subtract(const Duration(hours: 24));
      if (twentyFourHoursBefore.isAfter(now)) {
        await _scheduleAppointmentReminder(
          appointmentId: appointmentId,
          doctorName: doctorName,
          patientName: patientName,
          appointmentTime: appointmentTime,
          appointmentType: appointmentType,
          isForDoctor: isForDoctor,
          scheduledTime: twentyFourHoursBefore,
          reminderType: '24 hours',
          notificationId: '${appointmentId}_24h',
        );
      }

      // Schedule 2-hour reminder
      final twoHoursBefore = appointmentTime.subtract(const Duration(hours: 2));
      if (twoHoursBefore.isAfter(now)) {
        await _scheduleAppointmentReminder(
          appointmentId: appointmentId,
          doctorName: doctorName,
          patientName: patientName,
          appointmentTime: appointmentTime,
          appointmentType: appointmentType,
          isForDoctor: isForDoctor,
          scheduledTime: twoHoursBefore,
          reminderType: '2 hours',
          notificationId: '${appointmentId}_2h',
        );
      }

      // Schedule 30-minute reminder
      final thirtyMinutesBefore = appointmentTime.subtract(const Duration(minutes: 30));
      if (thirtyMinutesBefore.isAfter(now)) {
        await _scheduleAppointmentReminder(
          appointmentId: appointmentId,
          doctorName: doctorName,
          patientName: patientName,
          appointmentTime: appointmentTime,
          appointmentType: appointmentType,
          isForDoctor: isForDoctor,
          scheduledTime: thirtyMinutesBefore,
          reminderType: '30 minutes',
          notificationId: '${appointmentId}_30m',
        );
      }

      debugPrint('Scheduled appointment reminders for appointment: $appointmentId');
    } catch (e) {
      debugPrint('Error scheduling appointment reminders: $e');
    }
  }

  /// Schedule a single appointment reminder
  Future<void> _scheduleAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required String patientName,
    required DateTime appointmentTime,
    required String appointmentType,
    required bool isForDoctor,
    required DateTime scheduledTime,
    required String reminderType,
    required String notificationId,
  }) async {
    final title = isForDoctor 
        ? 'Upcoming Appointment'
        : 'Appointment Reminder';
    
    final body = isForDoctor
        ? 'You have an appointment with $patientName in $reminderType'
        : 'Your appointment with Dr. $doctorName is in $reminderType';

    final data = AppointmentReminderData(
      appointmentId: appointmentId,
      doctorName: doctorName,
      patientName: patientName,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
    );

    final notification = NotificationModel(
      id: notificationId,
      title: title,
      body: body,
      type: NotificationType.appointmentReminder,
      data: data.toJson(),
      timestamp: DateTime.now(),
    );

    await FCMService.instance.scheduleNotification(
      notification: notification,
      scheduledTime: scheduledTime,
    );
  }

  /// Cancel appointment reminders
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    try {
      // Cancel all reminder types for this appointment
      await FCMService.instance.cancelScheduledNotification('${appointmentId}_24h');
      await FCMService.instance.cancelScheduledNotification('${appointmentId}_2h');
      await FCMService.instance.cancelScheduledNotification('${appointmentId}_30m');
      
      debugPrint('Cancelled appointment reminders for: $appointmentId');
    } catch (e) {
      debugPrint('Error cancelling appointment reminders: $e');
    }
  }

  /// Reschedule appointment reminders (when appointment time changes)
  Future<void> rescheduleAppointmentReminders({
    required String appointmentId,
    required String doctorName,
    required String patientName,
    required DateTime newAppointmentTime,
    required String appointmentType,
    required bool isForDoctor,
    required String userId,
  }) async {
    try {
      // Cancel existing reminders
      await cancelAppointmentReminders(appointmentId);
      
      // Schedule new reminders
      await scheduleAppointmentReminders(
        appointmentId: appointmentId,
        doctorName: doctorName,
        patientName: patientName,
        appointmentTime: newAppointmentTime,
        appointmentType: appointmentType,
        isForDoctor: isForDoctor,
        userId: userId,
      );
      
      debugPrint('Rescheduled appointment reminders for: $appointmentId');
    } catch (e) {
      debugPrint('Error rescheduling appointment reminders: $e');
    }
  }

  /// Schedule medication reminder
  Future<void> scheduleMedicationReminder({
    required String medicationId,
    required String medicationName,
    required List<DateTime> reminderTimes,
    required String dosage,
    required String instructions,
  }) async {
    try {
      for (int i = 0; i < reminderTimes.length; i++) {
        final reminderTime = reminderTimes[i];
        final now = DateTime.now();
        
        if (reminderTime.isAfter(now)) {
          final notification = NotificationModel(
            id: '${medicationId}_${i}',
            title: 'Medication Reminder',
            body: 'Time to take your $medicationName ($dosage)',
            type: NotificationType.general,
            data: {
              'medicationId': medicationId,
              'medicationName': medicationName,
              'dosage': dosage,
              'instructions': instructions,
              'reminderIndex': i,
            },
            timestamp: DateTime.now(),
          );

          await FCMService.instance.scheduleNotification(
            notification: notification,
            scheduledTime: reminderTime,
          );
        }
      }
      
      debugPrint('Scheduled medication reminders for: $medicationName');
    } catch (e) {
      debugPrint('Error scheduling medication reminders: $e');
    }
  }

  /// Cancel medication reminders
  Future<void> cancelMedicationReminders(String medicationId) async {
    try {
      // Get all pending notifications
      final pendingNotifications = await FCMService.instance.getPendingNotifications();
      
      // Cancel notifications that match the medication ID
      for (final notification in pendingNotifications) {
        if (notification.id.toString().startsWith(medicationId)) {
          await FCMService.instance.cancelScheduledNotification(notification.id.toString());
        }
      }
      
      debugPrint('Cancelled medication reminders for: $medicationId');
    } catch (e) {
      debugPrint('Error cancelling medication reminders: $e');
    }
  }

  /// Schedule health checkup reminder
  Future<void> scheduleHealthCheckupReminder({
    required String checkupType,
    required DateTime reminderTime,
    required String message,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'health_checkup_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Health Checkup Reminder',
        body: message,
        type: NotificationType.general,
        data: {
          'checkupType': checkupType,
          'reminderTime': reminderTime.toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      await FCMService.instance.scheduleNotification(
        notification: notification,
        scheduledTime: reminderTime,
      );
      
      debugPrint('Scheduled health checkup reminder: $checkupType');
    } catch (e) {
      debugPrint('Error scheduling health checkup reminder: $e');
    }
  }

  /// Schedule follow-up appointment reminder
  Future<void> scheduleFollowUpReminder({
    required String originalAppointmentId,
    required String doctorName,
    required DateTime followUpDate,
    required String reason,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'followup_${originalAppointmentId}',
        title: 'Follow-up Appointment Reminder',
        body: 'Don\'t forget to schedule your follow-up with Dr. $doctorName for $reason',
        type: NotificationType.general,
        data: {
          'originalAppointmentId': originalAppointmentId,
          'doctorName': doctorName,
          'followUpDate': followUpDate.toIso8601String(),
          'reason': reason,
        },
        timestamp: DateTime.now(),
      );

      await FCMService.instance.scheduleNotification(
        notification: notification,
        scheduledTime: followUpDate,
      );
      
      debugPrint('Scheduled follow-up reminder for: $originalAppointmentId');
    } catch (e) {
      debugPrint('Error scheduling follow-up reminder: $e');
    }
  }

  /// Get all pending scheduled notifications
  Future<List<Map<String, dynamic>>> getPendingReminders() async {
    try {
      final pendingNotifications = await FCMService.instance.getPendingNotifications();
      
      return pendingNotifications.map((notification) => {
        'id': notification.id,
        'title': notification.title,
        'body': notification.body,
        'scheduledTime': notification.payload,
      }).toList();
    } catch (e) {
      debugPrint('Error getting pending reminders: $e');
      return [];
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllReminders() async {
    try {
      await FCMService.instance.cancelAllNotifications();
      debugPrint('Cancelled all scheduled reminders');
    } catch (e) {
      debugPrint('Error cancelling all reminders: $e');
    }
  }

  /// Schedule birthday reminder for patient
  Future<void> scheduleBirthdayReminder({
    required String userId,
    required String userName,
    required DateTime birthday,
  }) async {
    try {
      // Schedule for the birthday at 9 AM
      final birthdayReminder = DateTime(
        birthday.year,
        birthday.month,
        birthday.day,
        9, // 9 AM
      );

      final notification = NotificationModel(
        id: 'birthday_$userId',
        title: 'Happy Birthday! 🎉',
        body: 'Wishing you a very happy birthday, $userName! Stay healthy and happy.',
        type: NotificationType.general,
        data: {
          'userId': userId,
          'userName': userName,
          'birthday': birthday.toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      await FCMService.instance.scheduleNotification(
        notification: notification,
        scheduledTime: birthdayReminder,
      );
      
      debugPrint('Scheduled birthday reminder for: $userName');
    } catch (e) {
      debugPrint('Error scheduling birthday reminder: $e');
    }
  }
}