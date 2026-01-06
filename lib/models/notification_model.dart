/// Notification models for FCM push notifications
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'general'),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

/// Notification types with their configurations
enum NotificationType {
  // Patient notifications
  appointmentBookingConfirmation,
  appointmentReminder,
  paymentSuccess,
  healthTipsReminder,
  doctorRescheduledAppointment,
  engagementNotification,
  fitnessGoalAchieved,
  
  // Doctor notifications
  appointmentBooking,
  paymentReceived,
  appointmentRescheduledOrCancelled,
  verificationStatusUpdate,
  
  // Admin notifications
  doctorVerificationRequest,
  
  // Shared notifications
  medicalReportShared,
  general;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      // Patient notifications
      case 'appointment_booking_confirmation':
        return NotificationType.appointmentBookingConfirmation;
      case 'appointment_reminder':
        return NotificationType.appointmentReminder;
      case 'payment_success':
        return NotificationType.paymentSuccess;
      case 'health_tips_reminder':
        return NotificationType.healthTipsReminder;
      case 'doctor_rescheduled_appointment':
        return NotificationType.doctorRescheduledAppointment;
      case 'engagement_notification':
        return NotificationType.engagementNotification;
      case 'fitness_goal_achieved':
        return NotificationType.fitnessGoalAchieved;
      
      // Doctor notifications
      case 'appointment_booking':
        return NotificationType.appointmentBooking;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'appointment_rescheduled_or_cancelled':
        return NotificationType.appointmentRescheduledOrCancelled;
      case 'verification_status_update':
        return NotificationType.verificationStatusUpdate;
      
      // Admin notifications
      case 'doctor_verification_request':
        return NotificationType.doctorVerificationRequest;
      
      // Shared notifications
      case 'medical_report_shared':
        return NotificationType.medicalReportShared;
      default:
        return NotificationType.general;
    }
  }

  @override
  String toString() {
    switch (this) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
        return 'appointment_booking_confirmation';
      case NotificationType.appointmentReminder:
        return 'appointment_reminder';
      case NotificationType.paymentSuccess:
        return 'payment_success';
      case NotificationType.healthTipsReminder:
        return 'health_tips_reminder';
      case NotificationType.doctorRescheduledAppointment:
        return 'doctor_rescheduled_appointment';
      case NotificationType.engagementNotification:
        return 'engagement_notification';
      case NotificationType.fitnessGoalAchieved:
        return 'fitness_goal_achieved';
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        return 'appointment_booking';
      case NotificationType.paymentReceived:
        return 'payment_received';
      case NotificationType.appointmentRescheduledOrCancelled:
        return 'appointment_rescheduled_or_cancelled';
      case NotificationType.verificationStatusUpdate:
        return 'verification_status_update';
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        return 'doctor_verification_request';
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        return 'medical_report_shared';
      case NotificationType.general:
        return 'general';
    }
  }

  /// Get the sound file name for Android
  String get androidSoundFile {
    switch (this) {
      // High priority notifications with appointment sound
      case NotificationType.appointmentBookingConfirmation:
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentBooking:
      case NotificationType.doctorRescheduledAppointment:
      case NotificationType.appointmentRescheduledOrCancelled:
        return 'appointment_notification';
      
      // Payment notifications with payment sound
      case NotificationType.paymentSuccess:
      case NotificationType.paymentReceived:
        return 'payment_notification';
      
      // Admin and verification notifications
      case NotificationType.doctorVerificationRequest:
      case NotificationType.verificationStatusUpdate:
        return 'verification_notification';
      
      // Gentle notifications with appointment sound (softer alternative)
      case NotificationType.healthTipsReminder:
      case NotificationType.engagementNotification:
      case NotificationType.fitnessGoalAchieved:
      case NotificationType.medicalReportShared:
        return 'appointment_notification';
      
      // Default sound for general notifications
      case NotificationType.general:
        return 'appointment_notification';
    }
  }

  /// Get the sound file name for iOS
  String get iosSoundFile {
    switch (this) {
      // High priority notifications with appointment sound
      case NotificationType.appointmentBookingConfirmation:
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentBooking:
      case NotificationType.doctorRescheduledAppointment:
      case NotificationType.appointmentRescheduledOrCancelled:
        return 'appointment_notification.mp3';
      
      // Payment notifications with payment sound
      case NotificationType.paymentSuccess:
      case NotificationType.paymentReceived:
        return 'payment_notification.mp3';
      
      // Admin and verification notifications
      case NotificationType.doctorVerificationRequest:
      case NotificationType.verificationStatusUpdate:
        return 'verification_notification.mp3';
      
      // Gentle notifications with appointment sound (softer alternative)
      case NotificationType.healthTipsReminder:
      case NotificationType.engagementNotification:
      case NotificationType.fitnessGoalAchieved:
      case NotificationType.medicalReportShared:
        return 'appointment_notification.mp3';
      
      // Default sound for general notifications
      case NotificationType.general:
        return 'appointment_notification.mp3';
    }
  }

  /// Get notification channel ID for Android
  String get channelId {
    switch (this) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
      case NotificationType.appointmentReminder:
        return 'patient_appointment_notifications';
      case NotificationType.paymentSuccess:
        return 'patient_payment_notifications';
      case NotificationType.healthTipsReminder:
        return 'patient_health_tips';
      case NotificationType.doctorRescheduledAppointment:
        return 'patient_appointment_changes';
      case NotificationType.engagementNotification:
        return 'patient_engagement';
      case NotificationType.fitnessGoalAchieved:
        return 'patient_fitness_achievements';
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        return 'doctor_appointment_notifications';
      case NotificationType.paymentReceived:
        return 'doctor_payment_notifications';
      case NotificationType.appointmentRescheduledOrCancelled:
        return 'doctor_appointment_changes';
      case NotificationType.verificationStatusUpdate:
        return 'doctor_verification_updates';
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        return 'admin_verification_requests';
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        return 'medical_sharing_notifications';
      case NotificationType.general:
        return 'general_notifications';
    }
  }

  /// Get notification channel name for Android
  String get channelName {
    switch (this) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
      case NotificationType.appointmentReminder:
        return 'Appointment Notifications';
      case NotificationType.paymentSuccess:
        return 'Payment Confirmations';
      case NotificationType.healthTipsReminder:
        return 'Health Tips';
      case NotificationType.doctorRescheduledAppointment:
        return 'Appointment Changes';
      case NotificationType.engagementNotification:
        return 'Health Engagement';
      case NotificationType.fitnessGoalAchieved:
        return 'Fitness Achievements';
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        return 'New Appointments';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.appointmentRescheduledOrCancelled:
        return 'Appointment Updates';
      case NotificationType.verificationStatusUpdate:
        return 'Verification Status';
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        return 'Doctor Verification Requests';
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        return 'Medical Report Sharing';
      case NotificationType.general:
        return 'General Notifications';
    }
  }

  /// Get notification channel description for Android
  String get channelDescription {
    switch (this) {
      // Patient notifications
      case NotificationType.appointmentBookingConfirmation:
        return 'Confirmations for booked appointments';
      case NotificationType.appointmentReminder:
        return 'Reminders for upcoming appointments';
      case NotificationType.paymentSuccess:
        return 'Confirmations for successful payments';
      case NotificationType.healthTipsReminder:
        return 'Periodic health tips and wellness reminders';
      case NotificationType.doctorRescheduledAppointment:
        return 'Notifications when doctors reschedule appointments';
      case NotificationType.engagementNotification:
        return 'Motivational messages and health check-ins';
      case NotificationType.fitnessGoalAchieved:
        return 'Celebrations for completed fitness goals';
      
      // Doctor notifications
      case NotificationType.appointmentBooking:
        return 'Notifications for new patient bookings';
      case NotificationType.paymentReceived:
        return 'Notifications for received payments';
      case NotificationType.appointmentRescheduledOrCancelled:
        return 'Updates when patients reschedule or cancel';
      case NotificationType.verificationStatusUpdate:
        return 'Updates on doctor verification status';
      
      // Admin notifications
      case NotificationType.doctorVerificationRequest:
        return 'New doctor verification requests requiring review';
      
      // Shared notifications
      case NotificationType.medicalReportShared:
        return 'Notifications when medical reports are shared';
      case NotificationType.general:
        return 'General app notifications';
    }
  }

  /// Get notification importance level
  bool get isHighPriority {
    switch (this) {
      // High priority notifications
      case NotificationType.appointmentBookingConfirmation:
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentBooking:
      case NotificationType.doctorVerificationRequest:
      case NotificationType.verificationStatusUpdate:
      case NotificationType.doctorRescheduledAppointment:
      case NotificationType.appointmentRescheduledOrCancelled:
      case NotificationType.medicalReportShared:
        return true;
      
      // Medium/Low priority notifications
      case NotificationType.paymentSuccess:
      case NotificationType.paymentReceived:
      case NotificationType.healthTipsReminder:
      case NotificationType.engagementNotification:
      case NotificationType.fitnessGoalAchieved:
      case NotificationType.general:
        return false;
    }
  }
}

/// Appointment reminder notification data
class AppointmentReminderData {
  final String appointmentId;
  final String doctorName;
  final String patientName;
  final DateTime appointmentTime;
  final String appointmentType;

  const AppointmentReminderData({
    required this.appointmentId,
    required this.doctorName,
    required this.patientName,
    required this.appointmentTime,
    required this.appointmentType,
  });

  factory AppointmentReminderData.fromJson(Map<String, dynamic> json) {
    return AppointmentReminderData(
      appointmentId: json['appointmentId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      patientName: json['patientName'] ?? '',
      appointmentTime: DateTime.parse(json['appointmentTime'] ?? DateTime.now().toIso8601String()),
      appointmentType: json['appointmentType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'doctorName': doctorName,
      'patientName': patientName,
      'appointmentTime': appointmentTime.toIso8601String(),
      'appointmentType': appointmentType,
    };
  }
}

/// Payment success notification data
class PaymentSuccessData {
  final String paymentId;
  final String orderId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime paymentTime;

  const PaymentSuccessData({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentTime,
  });

  factory PaymentSuccessData.fromJson(Map<String, dynamic> json) {
    return PaymentSuccessData(
      paymentId: json['paymentId'] ?? '',
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'INR',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentTime: DateTime.parse(json['paymentTime'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentTime': paymentTime.toIso8601String(),
    };
  }
}

/// Doctor verification request notification data
class DoctorVerificationData {
  final String doctorId;
  final String doctorName;
  final String email;
  final String specialization;
  final DateTime requestTime;

  const DoctorVerificationData({
    required this.doctorId,
    required this.doctorName,
    required this.email,
    required this.specialization,
    required this.requestTime,
  });

  factory DoctorVerificationData.fromJson(Map<String, dynamic> json) {
    return DoctorVerificationData(
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      email: json['email'] ?? '',
      specialization: json['specialization'] ?? '',
      requestTime: DateTime.parse(json['requestTime'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'email': email,
      'specialization': specialization,
      'requestTime': requestTime.toIso8601String(),
    };
  }
}