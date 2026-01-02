import 'package:cloud_firestore/cloud_firestore.dart';

/// Appointment model for booking and managing appointments
class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime appointmentDate;
  final String timeSlot;
  final String consultationType; // 'online', 'offline'
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled', 'rescheduled'
  final double? consultationFee;
  final String? paymentId;
  final String? paymentStatus; // 'pending', 'completed', 'failed', 'refunded', 'pay_on_clinic'
  final String? paymentMethod; // 'card', 'upi', 'netbanking', 'cash', etc.
  final DateTime? paymentReceivedAt; // When payment was actually received
  final String? symptoms;
  final String? notes;
  final String? prescriptionId;
  final String? meetingId; // For video consultation
  final String? meetingPassword;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final int? duration; // in minutes
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? cancelledBy; // 'patient' or 'doctor'
  final String? rescheduledFrom; // Previous appointment ID if rescheduled
  final bool? isFollowUp;
  final String? followUpFor; // Previous appointment ID
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.appointmentDate,
    required this.timeSlot,
    required this.consultationType,
    required this.status,
    this.consultationFee,
    this.paymentId,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentReceivedAt,
    this.symptoms,
    this.notes,
    this.prescriptionId,
    this.meetingId,
    this.meetingPassword,
    this.actualStartTime,
    this.actualEndTime,
    this.duration,
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
    this.rescheduledFrom,
    this.isFollowUp,
    this.followUpFor,
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AppointmentModel from Firestore document
  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorSpecialty: map['doctorSpecialty'] ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      timeSlot: map['timeSlot'] ?? '',
      consultationType: map['consultationType'] ?? 'offline',
      status: map['status'] ?? 'pending',
      consultationFee: map['consultationFee']?.toDouble(),
      paymentId: map['paymentId'],
      paymentStatus: map['paymentStatus'],
      paymentMethod: map['paymentMethod'],
      paymentReceivedAt: (map['paymentReceivedAt'] as Timestamp?)?.toDate(),
      symptoms: map['symptoms'],
      notes: map['notes'],
      prescriptionId: map['prescriptionId'],
      meetingId: map['meetingId'],
      meetingPassword: map['meetingPassword'],
      actualStartTime: (map['actualStartTime'] as Timestamp?)?.toDate(),
      actualEndTime: (map['actualEndTime'] as Timestamp?)?.toDate(),
      duration: map['duration'],
      cancellationReason: map['cancellationReason'],
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      cancelledBy: map['cancelledBy'],
      rescheduledFrom: map['rescheduledFrom'],
      isFollowUp: map['isFollowUp'],
      followUpFor: map['followUpFor'],
      additionalInfo: map['additionalInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert AppointmentModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'consultationType': consultationType,
      'status': status,
      'consultationFee': consultationFee,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentReceivedAt': paymentReceivedAt != null ? Timestamp.fromDate(paymentReceivedAt!) : null,
      'symptoms': symptoms,
      'notes': notes,
      'prescriptionId': prescriptionId,
      'meetingId': meetingId,
      'meetingPassword': meetingPassword,
      'actualStartTime': actualStartTime != null ? Timestamp.fromDate(actualStartTime!) : null,
      'actualEndTime': actualEndTime != null ? Timestamp.fromDate(actualEndTime!) : null,
      'duration': duration,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
      'rescheduledFrom': rescheduledFrom,
      'isFollowUp': isFollowUp,
      'followUpFor': followUpFor,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of AppointmentModel with updated fields
  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? doctorSpecialty,
    DateTime? appointmentDate,
    String? timeSlot,
    String? consultationType,
    String? status,
    double? consultationFee,
    String? paymentId,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? paymentReceivedAt,
    String? symptoms,
    String? notes,
    String? prescriptionId,
    String? meetingId,
    String? meetingPassword,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? duration,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? rescheduledFrom,
    bool? isFollowUp,
    String? followUpFor,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      consultationType: consultationType ?? this.consultationType,
      status: status ?? this.status,
      consultationFee: consultationFee ?? this.consultationFee,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReceivedAt: paymentReceivedAt ?? this.paymentReceivedAt,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      meetingId: meetingId ?? this.meetingId,
      meetingPassword: meetingPassword ?? this.meetingPassword,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      duration: duration ?? this.duration,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      rescheduledFrom: rescheduledFrom ?? this.rescheduledFrom,
      isFollowUp: isFollowUp ?? this.isFollowUp,
      followUpFor: followUpFor ?? this.followUpFor,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted appointment date and time
  String get formattedDateTime {
    final date = appointmentDate;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, $timeSlot';
  }

  /// Get formatted consultation fee
  String get formattedFee {
    if (consultationFee == null) return 'Free';
    return '₹${consultationFee!.toStringAsFixed(0)}';
  }

  /// Check if appointment is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      int.parse(timeSlot.split(':')[0]),
      int.parse(timeSlot.split(':')[1].split(' ')[0]),
    );
    return appointmentDateTime.isAfter(now) && (status == 'confirmed' || status == 'pending');
  }

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
           appointmentDate.month == now.month &&
           appointmentDate.day == now.day;
  }

  /// Check if appointment can be cancelled
  bool get canBeCancelled {
    return status == 'pending' || status == 'confirmed';
  }

  /// Check if appointment can be rescheduled
  bool get canBeRescheduled {
    return status == 'pending' || status == 'confirmed';
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'blue';
      case 'completed':
        return 'green';
      case 'cancelled':
        return 'red';
      case 'rescheduled':
        return 'purple';
      default:
        return 'grey';
    }
  }

  /// Get consultation type display text
  String get consultationTypeText {
    switch (consultationType) {
      case 'online':
        return 'Video Consultation';
      case 'offline':
        return 'In-Person Visit';
      default:
        return consultationType;
    }
  }

  @override
  String toString() {
    return 'AppointmentModel(id: $id, patientName: $patientName, doctorName: $doctorName, date: $formattedDateTime, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
