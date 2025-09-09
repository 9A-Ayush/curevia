import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';
import '../../constants/app_constants.dart';

/// Service for appointment-related operations
class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Book a new appointment
  static Future<String> bookAppointment({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
    required String doctorSpecialty,
    required DateTime appointmentDate,
    required String timeSlot,
    required String consultationType,
    double? consultationFee,
    String? symptoms,
    String? notes,
  }) async {
    try {
      final appointmentId = _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc()
          .id;

      final appointment = AppointmentModel(
        id: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        consultationType: consultationType,
        status: 'pending',
        consultationFee: consultationFee,
        symptoms: symptoms,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .set(appointment.toMap());

      // Update doctor's availability
      await _updateDoctorAvailability(
        doctorId,
        appointmentDate,
        timeSlot,
        false,
      );

      return appointmentId;
    } catch (e) {
      throw Exception('Failed to book appointment: $e');
    }
  }

  /// Get appointments for a user
  static Future<List<AppointmentModel>> getUserAppointments({
    required String userId,
    String? status,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('patientId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query
          .orderBy('appointmentDate', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                AppointmentModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get user appointments: $e');
    }
  }

  /// Get doctor appointments
  static Future<List<AppointmentModel>> getDoctorAppointments({
    required String doctorId,
    String? status,
    DateTime? date,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        query = query
            .where(
              'appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where(
              'appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
            );
      }

      final querySnapshot = await query
          .orderBy('appointmentDate')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                AppointmentModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get doctor appointments: $e');
    }
  }

  /// Get appointment by ID
  static Future<AppointmentModel?> getAppointmentById(
    String appointmentId,
  ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (doc.exists) {
        return AppointmentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment: $e');
    }
  }

  /// Update appointment status
  static Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    String? cancellationReason,
    String? cancelledBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': Timestamp.now(),
      };

      if (status == 'cancelled') {
        updateData['cancellationReason'] = cancellationReason;
        updateData['cancelledBy'] = cancelledBy;
        updateData['cancelledAt'] = Timestamp.now();

        // Free up the time slot
        final appointment = await getAppointmentById(appointmentId);
        if (appointment != null) {
          await _updateDoctorAvailability(
            appointment.doctorId,
            appointment.appointmentDate,
            appointment.timeSlot,
            true,
          );
        }
      }

      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  /// Reschedule appointment
  static Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    try {
      final appointment = await getAppointmentById(appointmentId);
      if (appointment == null) {
        throw Exception('Appointment not found');
      }

      // Free up the old time slot
      await _updateDoctorAvailability(
        appointment.doctorId,
        appointment.appointmentDate,
        appointment.timeSlot,
        true,
      );

      // Book the new time slot
      await _updateDoctorAvailability(
        appointment.doctorId,
        newDate,
        newTimeSlot,
        false,
      );

      // Update appointment
      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .update({
            'appointmentDate': Timestamp.fromDate(newDate),
            'timeSlot': newTimeSlot,
            'status': 'rescheduled',
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  /// Get available time slots for a doctor on a specific date
  static Future<List<String>> getAvailableTimeSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      // Get doctor's general availability for the day
      final doctorDoc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor not found');
      }

      final doctorData = doctorDoc.data()!;
      final availability = doctorData['availability'] as Map<String, dynamic>?;

      if (availability == null) {
        return [];
      }

      // Get day of week (Monday = 1, Sunday = 7)
      final dayOfWeek = date.weekday;
      final dayName = _getDayName(dayOfWeek);

      final dayAvailability =
          availability[dayName.toLowerCase()] as Map<String, dynamic>?;

      if (dayAvailability == null || dayAvailability['isAvailable'] != true) {
        return [];
      }

      final allSlots = List<String>.from(dayAvailability['slots'] ?? []);

      // Get booked appointments for the date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final bookedAppointments = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final bookedSlots = bookedAppointments.docs
          .map((doc) => doc.data()['timeSlot'] as String)
          .toSet();

      // Filter out booked slots and past slots for today
      final availableSlots = allSlots.where((slot) {
        if (bookedSlots.contains(slot)) return false;

        // If it's today, filter out past slots
        if (_isToday(date)) {
          final now = DateTime.now();
          final slotTime = _parseTimeSlot(slot);
          if (slotTime != null) {
            final slotDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              slotTime.hour,
              slotTime.minute,
            );
            return slotDateTime.isAfter(
              now.add(const Duration(hours: 1)),
            ); // 1 hour buffer
          }
        }

        return true;
      }).toList();

      return availableSlots;
    } catch (e) {
      throw Exception('Failed to get available time slots: $e');
    }
  }

  /// Update doctor availability (internal method)
  static Future<void> _updateDoctorAvailability(
    String doctorId,
    DateTime date,
    String timeSlot,
    bool isAvailable,
  ) async {
    // This is a simplified implementation
    // In a real app, you might want to maintain a separate availability collection
    // for more complex scheduling logic
  }

  /// Get upcoming appointments for a user
  static Future<List<AppointmentModel>> getUpcomingAppointments({
    required String userId,
    int limit = 5,
  }) async {
    try {
      final now = DateTime.now();

      // Get all future appointments for the user
      final querySnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('patientId', isEqualTo: userId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          )
          .orderBy('appointmentDate')
          .limit(limit * 2) // Get more to filter client-side
          .get();

      // Filter for pending and confirmed appointments
      List<AppointmentModel> appointments = querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .where(
            (appointment) =>
                appointment.status == 'pending' ||
                appointment.status == 'confirmed',
          )
          .take(limit)
          .toList();

      return appointments;
    } catch (e) {
      throw Exception('Failed to get upcoming appointments: $e');
    }
  }

  /// Helper methods
  static String _getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static DateTime? _parseTimeSlot(String timeSlot) {
    try {
      // Parse time slot like "09:00 AM" or "14:30"
      final parts = timeSlot.split(' ');
      final timePart = parts[0];
      final amPm = parts.length > 1 ? parts[1].toUpperCase() : null;

      final timeParts = timePart.split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (amPm == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(
        2000,
        1,
        1,
        hour,
        minute,
      ); // Date doesn't matter, only time
    } catch (e) {
      return null;
    }
  }

  /// Stream of appointments for real-time updates
  static Stream<List<AppointmentModel>> getAppointmentsStream({
    required String userId,
    String? status,
  }) {
    Query query = _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('patientId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppointmentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }
}
