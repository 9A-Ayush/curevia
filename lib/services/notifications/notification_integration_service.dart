import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/notification_model.dart';
import 'notification_initialization_service.dart';
import 'role_based_notification_service.dart';

import 'notification_manager.dart';
import 'notification_scheduler.dart';

/// Integration service that provides a unified interface for all notification operations
class NotificationIntegrationService {
  static final NotificationIntegrationService _instance = NotificationIntegrationService._internal();
  factory NotificationIntegrationService() => _instance;
  NotificationIntegrationService._internal();

  static NotificationIntegrationService get instance => _instance;

  // Private service instances - initialize immediately to avoid LateInitializationError
  final NotificationInitializationService _initService = NotificationInitializationService.instance;
  final RoleBasedNotificationService _roleService = RoleBasedNotificationService.instance;
  final NotificationManager _manager = NotificationManager.instance;
  final NotificationScheduler _scheduler = NotificationScheduler.instance;

  bool _isInitialized = false;

  /// Initialize the complete notification system
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    final result = await _initService.initializeNotificationSystem();
    _isInitialized = result;
    return result;
  }

  /// Setup notifications for a logged-in user
  Future<void> setupUserNotifications({
    required UserModel user,
    List<String>? specializations,
    String? location,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _initService.setupUserNotifications(
      user: user,
      specializations: specializations,
    );
  }

  /// Cleanup notifications on logout
  Future<void> cleanupUserNotifications({
    required String userId,
    required String userRole,
    List<String>? specializations,
    String? location,
  }) async {
    if (!_isInitialized) return;
    
    await _initService.cleanupUserNotifications(
      userId: userId,
      userRole: userRole,
    );
  }

  /// Get role-based notification service
  RoleBasedNotificationService get roleBasedService => _roleService;

  /// Get notification manager
  NotificationManager get manager => _manager;

  /// Get system status
  Map<String, dynamic> getSystemStatus() {
    if (!_isInitialized) return {'initialized': false};
    return _initService.getSystemStatus();
  }

  /// Check if system is ready
  bool get isReady => _isInitialized && _initService.isReady;

  /// Get current FCM token
  String? get currentFCMToken => _isInitialized ? _initService.currentFCMToken : null;

  // PATIENT NOTIFICATION METHODS

  /// Send appointment booking confirmation to patient
  Future<void> notifyPatientAppointmentBooked({
    required String patientId,
    required String patientFCMToken,
    required String doctorName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Send immediate confirmation
    await _roleService.sendAppointmentBookingConfirmation(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      doctorName: doctorName,
      appointmentId: appointmentId,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
    );

    // Schedule reminders
    await _scheduler.scheduleAppointmentReminders(
      appointmentId: appointmentId,
      doctorName: doctorName,
      patientName: 'Patient', // You might want to pass actual patient name
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
      isForDoctor: false,
      userId: patientId,
    );
  }

  /// Send payment success notification to patient
  Future<void> notifyPatientPaymentSuccess({
    required String patientId,
    required String patientFCMToken,
    required String paymentId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String doctorName,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendPaymentSuccessToPatient(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      paymentId: paymentId,
      orderId: orderId,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      doctorName: doctorName,
    );
  }

  /// Send comprehensive appointment booking confirmation to patient
  /// Includes both appointment details and payment confirmation
  Future<void> notifyPatientAppointmentBookedWithPayment({
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
    if (!_isInitialized) await initialize();
    
    await _roleService.sendAppointmentBookingWithPaymentConfirmation(
      patientId: patientId,
      patientName: patientName,
      patientFCMToken: patientFCMToken,
      doctorName: doctorName,
      appointmentId: appointmentId,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
      paymentId: paymentId,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
    );
  }

  /// Send health tip to patient
  Future<void> sendHealthTipToPatient({
    required String patientId,
    required String patientFCMToken,
    required String healthTip,
    required String category,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendHealthTipsReminder(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      healthTip: healthTip,
      category: category,
    );
  }

  /// Send engagement notification to patient
  Future<void> sendEngagementToPatient({
    required String patientId,
    required String patientFCMToken,
    required String message,
    required String engagementType,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendEngagementNotification(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      message: message,
      engagementType: engagementType,
    );
  }

  /// Notify patient of fitness goal achievement
  Future<void> notifyPatientFitnessGoalAchieved({
    required String patientId,
    required String patientFCMToken,
    required String goalName,
    required String achievement,
    required int streakDays,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendFitnessGoalAchieved(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      goalName: goalName,
      achievement: achievement,
      streakDays: streakDays,
    );
  }

  /// Notify patient when doctor reschedules appointment
  Future<void> notifyPatientAppointmentRescheduled({
    required String patientId,
    required String patientFCMToken,
    required String doctorName,
    required String appointmentId,
    required DateTime oldAppointmentTime,
    required DateTime newAppointmentTime,
    required String reason,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Send rescheduling notification
    await _roleService.sendDoctorRescheduledAppointment(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      doctorName: doctorName,
      appointmentId: appointmentId,
      oldAppointmentTime: oldAppointmentTime,
      newAppointmentTime: newAppointmentTime,
      reason: reason,
    );

    // Reschedule reminders for new time
    await _scheduler.rescheduleAppointmentReminders(
      appointmentId: appointmentId,
      doctorName: doctorName,
      patientName: 'Patient',
      newAppointmentTime: newAppointmentTime,
      appointmentType: 'Consultation',
      isForDoctor: false,
      userId: patientId,
    );
  }

  // DOCTOR NOTIFICATION METHODS

  /// Notify doctor of new appointment booking
  Future<void> notifyDoctorAppointmentBooked({
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Send immediate notification
    await _roleService.sendAppointmentBookingToDoctor(
      doctorId: doctorId,
      doctorFCMToken: doctorFCMToken,
      patientName: patientName,
      appointmentId: appointmentId,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
    );

    // Schedule reminders for doctor
    await _scheduler.scheduleAppointmentReminders(
      appointmentId: appointmentId,
      doctorName: 'Doctor',
      patientName: patientName,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
      isForDoctor: true,
      userId: doctorId,
    );
  }

  /// Notify doctor of payment received
  Future<void> notifyDoctorPaymentReceived({
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String paymentId,
    required double amount,
    required String currency,
    required String appointmentId,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendPaymentReceivedToDoctor(
      doctorId: doctorId,
      doctorFCMToken: doctorFCMToken,
      patientName: patientName,
      paymentId: paymentId,
      amount: amount,
      currency: currency,
      appointmentId: appointmentId,
    );
  }

  /// Notify doctor of appointment changes by patient
  Future<void> notifyDoctorAppointmentChanged({
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String appointmentId,
    required String action, // 'rescheduled' or 'cancelled'
    required DateTime originalTime,
    DateTime? newTime,
    String? reason,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendAppointmentRescheduledOrCancelledToDoctor(
      doctorId: doctorId,
      doctorFCMToken: doctorFCMToken,
      patientName: patientName,
      appointmentId: appointmentId,
      action: action,
      originalTime: originalTime,
      newTime: newTime,
      reason: reason,
    );

    // Cancel existing reminders if appointment is cancelled
    if (action == 'cancelled') {
      await _scheduler.cancelAppointmentReminders(appointmentId);
    }
    // Reschedule reminders if appointment is rescheduled
    else if (action == 'rescheduled' && newTime != null) {
      await _scheduler.rescheduleAppointmentReminders(
        appointmentId: appointmentId,
        doctorName: 'Doctor',
        patientName: patientName,
        newAppointmentTime: newTime,
        appointmentType: 'Consultation',
        isForDoctor: true,
        userId: doctorId,
      );
    }
  }

  /// Notify doctor of verification status update
  Future<void> notifyDoctorVerificationStatus({
    required String doctorId,
    required String doctorFCMToken,
    required String status,
    String? rejectionReason,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendVerificationStatusUpdate(
      doctorId: doctorId,
      doctorFCMToken: doctorFCMToken,
      status: status,
      rejectionReason: rejectionReason,
    );
  }

  // ADMIN NOTIFICATION METHODS

  /// Notify admin of new doctor verification request
  Future<void> notifyAdminDoctorVerificationRequest({
    required List<String> adminFCMTokens,
    required String doctorId,
    required String doctorName,
    required String email,
    required String specialization,
    required String phoneNumber,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _roleService.sendDoctorVerificationRequestToAdmin(
      adminFCMTokens: adminFCMTokens,
      doctorId: doctorId,
      doctorName: doctorName,
      email: email,
      specialization: specialization,
      phoneNumber: phoneNumber,
    );
  }

  // BULK AND TOPIC NOTIFICATIONS

  /// Send bulk notification to multiple users
  Future<void> sendBulkNotification({
    required List<String> fcmTokens,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) await initialize();
    
    final notification = NotificationModel(
      id: 'bulk_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      data: data ?? {},
      timestamp: DateTime.now(),
    );

    await _roleService.sendBulkNotifications(
      fcmTokens: fcmTokens,
      notification: notification,
    );
  }

  /// Send topic-based notification
  Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) await initialize();
    
    final notification = NotificationModel(
      id: 'topic_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      data: data ?? {},
      timestamp: DateTime.now(),
    );

    await _roleService.sendTopicNotification(
      topic: topic,
      notification: notification,
    );
  }

  // SCHEDULING METHODS

  /// Schedule medication reminder
  Future<void> scheduleMedicationReminder({
    required String medicationId,
    required String medicationName,
    required List<DateTime> reminderTimes,
    required String dosage,
    required String instructions,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _scheduler.scheduleMedicationReminder(
      medicationId: medicationId,
      medicationName: medicationName,
      reminderTimes: reminderTimes,
      dosage: dosage,
      instructions: instructions,
    );
  }

  /// Cancel medication reminders
  Future<void> cancelMedicationReminders(String medicationId) async {
    if (!_isInitialized) return;
    
    await _scheduler.cancelMedicationReminders(medicationId);
  }

  /// Schedule health checkup reminder
  Future<void> scheduleHealthCheckupReminder({
    required String checkupType,
    required DateTime reminderTime,
    required String message,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _scheduler.scheduleHealthCheckupReminder(
      checkupType: checkupType,
      reminderTime: reminderTime,
      message: message,
    );
  }

  // UTILITY METHODS

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    if (!_isInitialized) return;
    
    await _manager.handleAppLifecycleChange(state);
  }

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    if (!_isInitialized) return {};
    
    return await _manager.getNotificationStats();
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    if (!_isInitialized) return 0;
    
    return await _manager.getUnreadNotificationCount();
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (!_isInitialized) return;
    
    await _manager.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (!_isInitialized) return;
    
    await _manager.markAllAsRead();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    if (!_isInitialized) return;
    
    await _manager.deleteNotification(notificationId);
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    if (!_isInitialized) return;
    
    await _manager.clearAllNotifications();
  }

  /// Get all notifications
  Future<List<NotificationModel>> getAllNotifications() async {
    if (!_isInitialized) return [];
    
    return await _manager.getAllNotifications();
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    if (!_isInitialized) return [];
    
    return await _manager.getUnreadNotifications();
  }

  /// Refresh FCM token
  Future<String?> refreshFCMToken() async {
    if (!_isInitialized) await initialize();
    
    return await _initService.refreshFCMToken();
  }

  /// Check and request notification permissions
  Future<bool> checkAndRequestPermissions() async {
    if (!_isInitialized) await initialize();
    
    return await _initService.checkAndRequestPermissions();
  }

  // CONVENIENCE METHODS FOR COMMON SCENARIOS

  /// Handle complete appointment booking flow
  Future<void> handleAppointmentBooking({
    required String patientId,
    required String patientFCMToken,
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String doctorName,
    required String appointmentId,
    required DateTime appointmentTime,
    required String appointmentType,
  }) async {
    // Notify patient
    await notifyPatientAppointmentBooked(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      doctorName: doctorName,
      appointmentId: appointmentId,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
    );

    // Notify doctor
    await notifyDoctorAppointmentBooked(
      doctorId: doctorId,
      doctorFCMToken: doctorFCMToken,
      patientName: patientName,
      appointmentId: appointmentId,
      appointmentTime: appointmentTime,
      appointmentType: appointmentType,
    );
  }

  /// Handle complete payment flow
  Future<void> handlePaymentSuccess({
    required String patientId,
    required String patientFCMToken,
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required String doctorName,
    required String paymentId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String appointmentId,
  }) async {
    // Notify patient
    await notifyPatientPaymentSuccess(
      patientId: patientId,
      patientFCMToken: patientFCMToken,
      paymentId: paymentId,
      orderId: orderId,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      doctorName: doctorName,
    );

    // Notify doctor
    await notifyDoctorPaymentReceived(
      doctorId: doctorId,
      doctorFCMToken: doctorFCMToken,
      patientName: patientName,
      paymentId: paymentId,
      amount: amount,
      currency: currency,
      appointmentId: appointmentId,
    );
  }

  /// Handle appointment cancellation flow
  Future<void> handleAppointmentCancellation({
    required String appointmentId,
    required String doctorId,
    required String doctorFCMToken,
    required String patientName,
    required DateTime originalTime,
    String? reason,
  }) async {
    // Notify doctor
    await notifyDoctorAppointmentChanged(
      doctorId: doctorId,
      doctorFCMToken: doctorFCMToken,
      patientName: patientName,
      appointmentId: appointmentId,
      action: 'cancelled',
      originalTime: originalTime,
      reason: reason,
    );

    // Cancel scheduled reminders
    await _scheduler.cancelAppointmentReminders(appointmentId);
  }
}