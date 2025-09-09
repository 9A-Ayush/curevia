import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Enum for time slot status
enum TimeSlotStatus {
  available,
  booked,
  blocked,
  expired,
}

/// Model representing a time slot for appointments
class TimeSlotModel extends Equatable {
  final String id;
  final String doctorId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final TimeSlotStatus status;
  final String? appointmentId;
  final String? blockedReason;
  final DateTime? blockedAt;
  final String? blockedBy;
  final bool isRecurring;
  final String? recurringPattern; // 'daily', 'weekly', 'monthly'
  final DateTime? recurringEndDate;
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeSlotModel({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.appointmentId,
    this.blockedReason,
    this.blockedAt,
    this.blockedBy,
    required this.isRecurring,
    this.recurringPattern,
    this.recurringEndDate,
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        doctorId,
        date,
        startTime,
        endTime,
        status,
        appointmentId,
        blockedReason,
        blockedAt,
        blockedBy,
        isRecurring,
        recurringPattern,
        recurringEndDate,
        additionalInfo,
        createdAt,
        updatedAt,
      ];

  TimeSlotModel copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    TimeSlotStatus? status,
    String? appointmentId,
    String? blockedReason,
    DateTime? blockedAt,
    String? blockedBy,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? recurringEndDate,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeSlotModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      appointmentId: appointmentId ?? this.appointmentId,
      blockedReason: blockedReason ?? this.blockedReason,
      blockedAt: blockedAt ?? this.blockedAt,
      blockedBy: blockedBy ?? this.blockedBy,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.name,
      'appointmentId': appointmentId,
      'blockedReason': blockedReason,
      'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : null,
      'blockedBy': blockedBy,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'recurringEndDate': recurringEndDate != null ? Timestamp.fromDate(recurringEndDate!) : null,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) {
    return TimeSlotModel(
      id: map['id'] ?? '',
      doctorId: map['doctorId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      status: TimeSlotStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TimeSlotStatus.available,
      ),
      appointmentId: map['appointmentId'],
      blockedReason: map['blockedReason'],
      blockedAt: (map['blockedAt'] as Timestamp?)?.toDate(),
      blockedBy: map['blockedBy'],
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      recurringEndDate: (map['recurringEndDate'] as Timestamp?)?.toDate(),
      additionalInfo: map['additionalInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Get formatted time range
  String get timeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  /// Get formatted date
  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Get duration in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Check if slot is available for booking
  bool get isAvailableForBooking {
    return status == TimeSlotStatus.available && 
           startTime.isAfter(DateTime.now());
  }

  /// Check if slot is in the past
  bool get isPast {
    return endTime.isBefore(DateTime.now());
  }

  /// Check if slot is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Check if slot is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case TimeSlotStatus.available:
        return 'Available';
      case TimeSlotStatus.booked:
        return 'Booked';
      case TimeSlotStatus.blocked:
        return 'Blocked';
      case TimeSlotStatus.expired:
        return 'Expired';
    }
  }

  /// Get day name
  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Get short day name
  String get shortDayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Get month name
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  /// Get short month name
  String get shortMonthName {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }
}

/// Model for doctor availability schedule
class DoctorScheduleModel extends Equatable {
  final String id;
  final String doctorId;
  final String dayOfWeek; // 'monday', 'tuesday', etc.
  final List<TimeSlotModel> timeSlots;
  final bool isAvailable;
  final String? unavailableReason;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorScheduleModel({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.timeSlots,
    required this.isAvailable,
    this.unavailableReason,
    this.effectiveFrom,
    this.effectiveTo,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        doctorId,
        dayOfWeek,
        timeSlots,
        isAvailable,
        unavailableReason,
        effectiveFrom,
        effectiveTo,
        isRecurring,
        createdAt,
        updatedAt,
      ];

  DoctorScheduleModel copyWith({
    String? id,
    String? doctorId,
    String? dayOfWeek,
    List<TimeSlotModel>? timeSlots,
    bool? isAvailable,
    String? unavailableReason,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    bool? isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorScheduleModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlots: timeSlots ?? this.timeSlots,
      isAvailable: isAvailable ?? this.isAvailable,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'dayOfWeek': dayOfWeek,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      'isAvailable': isAvailable,
      'unavailableReason': unavailableReason,
      'effectiveFrom': effectiveFrom != null ? Timestamp.fromDate(effectiveFrom!) : null,
      'effectiveTo': effectiveTo != null ? Timestamp.fromDate(effectiveTo!) : null,
      'isRecurring': isRecurring,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DoctorScheduleModel.fromMap(Map<String, dynamic> map) {
    return DoctorScheduleModel(
      id: map['id'] ?? '',
      doctorId: map['doctorId'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      timeSlots: (map['timeSlots'] as List<dynamic>?)
              ?.map((slot) => TimeSlotModel.fromMap(slot as Map<String, dynamic>))
              .toList() ??
          [],
      isAvailable: map['isAvailable'] ?? true,
      unavailableReason: map['unavailableReason'],
      effectiveFrom: (map['effectiveFrom'] as Timestamp?)?.toDate(),
      effectiveTo: (map['effectiveTo'] as Timestamp?)?.toDate(),
      isRecurring: map['isRecurring'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Get available time slots
  List<TimeSlotModel> get availableSlots {
    return timeSlots.where((slot) => slot.isAvailableForBooking).toList();
  }

  /// Get booked time slots
  List<TimeSlotModel> get bookedSlots {
    return timeSlots.where((slot) => slot.status == TimeSlotStatus.booked).toList();
  }
}
