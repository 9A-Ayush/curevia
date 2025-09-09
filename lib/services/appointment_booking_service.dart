import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import '../models/time_slot_model.dart';
import '../models/doctor_model.dart';

/// Service for managing appointment booking functionality
class AppointmentBookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static const String _appointmentsCollection = 'appointments';
  static const String _timeSlotsCollection = 'time_slots';
  static const String _doctorsCollection = 'doctors';
  static const String _doctorSchedulesCollection = 'doctor_schedules';

  /// Generate time slots for a doctor based on their schedule
  static Future<bool> generateTimeSlots({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> weeklySchedule,
    int slotDurationMinutes = 30,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();
      
      // Iterate through each day in the date range
      for (DateTime date = startDate; 
           date.isBefore(endDate) || date.isAtSameMomentAs(endDate); 
           date = date.add(const Duration(days: 1))) {
        
        final dayName = _getDayName(date.weekday);
        final daySchedule = weeklySchedule[dayName.toLowerCase()] as Map<String, dynamic>?;
        
        if (daySchedule == null || daySchedule['isAvailable'] != true) {
          continue; // Skip if doctor is not available on this day
        }
        
        final slots = daySchedule['slots'] as List<dynamic>?;
        if (slots == null || slots.isEmpty) continue;
        
        // Generate time slots for each time range
        for (final slotData in slots) {
          final startTime = slotData['startTime'] as String;
          final endTime = slotData['endTime'] as String;
          
          final slotStartTime = _parseTimeString(date, startTime);
          final slotEndTime = _parseTimeString(date, endTime);
          
          // Generate individual slots within the time range
          DateTime currentSlotStart = slotStartTime;
          while (currentSlotStart.isBefore(slotEndTime)) {
            final currentSlotEnd = currentSlotStart.add(Duration(minutes: slotDurationMinutes));
            
            if (currentSlotEnd.isAfter(slotEndTime)) break;
            
            final slotId = _firestore.collection(_timeSlotsCollection).doc().id;
            final timeSlot = TimeSlotModel(
              id: slotId,
              doctorId: doctorId,
              date: date,
              startTime: currentSlotStart,
              endTime: currentSlotEnd,
              status: TimeSlotStatus.available,
              isRecurring: false,
              createdAt: now,
              updatedAt: now,
            );
            
            batch.set(
              _firestore.collection(_timeSlotsCollection).doc(slotId),
              timeSlot.toMap(),
            );
            
            currentSlotStart = currentSlotEnd;
          }
        }
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error generating time slots: $e');
      return false;
    }
  }

  /// Get available time slots for a doctor on a specific date
  static Future<List<TimeSlotModel>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _firestore
          .collection(_timeSlotsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: TimeSlotStatus.available.name)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime')
          .get();

      return querySnapshot.docs
          .map((doc) => TimeSlotModel.fromMap(doc.data()))
          .where((slot) => slot.isAvailableForBooking)
          .toList();
    } catch (e) {
      debugPrint('Error getting available slots: $e');
      return [];
    }
  }

  /// Get available dates for a doctor (next 30 days with available slots)
  static Future<List<DateTime>> getAvailableDates({
    required String doctorId,
    int daysAhead = 30,
  }) async {
    try {
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: daysAhead));
      
      final querySnapshot = await _firestore
          .collection(_timeSlotsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: TimeSlotStatus.available.name)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final availableDates = <DateTime>{};
      for (final doc in querySnapshot.docs) {
        final slot = TimeSlotModel.fromMap(doc.data());
        if (slot.isAvailableForBooking) {
          availableDates.add(DateTime(
            slot.date.year,
            slot.date.month,
            slot.date.day,
          ));
        }
      }
      
      final sortedDates = availableDates.toList()..sort();
      return sortedDates;
    } catch (e) {
      debugPrint('Error getting available dates: $e');
      return [];
    }
  }

  /// Book an appointment
  static Future<String?> bookAppointment({
    required String doctorId,
    required String patientId,
    required String timeSlotId,
    required String patientName,
    required String doctorName,
    required String doctorSpecialty,
    required String consultationType, // 'online' or 'offline'
    required double consultationFee,
    String? symptoms,
    String? notes,
  }) async {
    try {
      // Check if time slot is still available
      final timeSlotDoc = await _firestore
          .collection(_timeSlotsCollection)
          .doc(timeSlotId)
          .get();

      if (!timeSlotDoc.exists) {
        throw Exception('Time slot not found');
      }

      final timeSlot = TimeSlotModel.fromMap(timeSlotDoc.data()!);
      if (!timeSlot.isAvailableForBooking) {
        throw Exception('Time slot is no longer available');
      }

      final appointmentId = _firestore.collection(_appointmentsCollection).doc().id;
      final now = DateTime.now();

      // Create appointment
      final appointment = AppointmentModel(
        id: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        appointmentDate: timeSlot.startTime,
        timeSlot: timeSlot.timeRange,
        consultationType: consultationType,
        status: 'pending',
        consultationFee: consultationFee,
        symptoms: symptoms,
        notes: notes,
        duration: timeSlot.durationMinutes,
        createdAt: now,
        updatedAt: now,
      );

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Add appointment
      batch.set(
        _firestore.collection(_appointmentsCollection).doc(appointmentId),
        appointment.toMap(),
      );

      // Update time slot status
      batch.update(
        _firestore.collection(_timeSlotsCollection).doc(timeSlotId),
        {
          'status': TimeSlotStatus.booked.name,
          'appointmentId': appointmentId,
          'updatedAt': Timestamp.fromDate(now),
        },
      );

      await batch.commit();
      return appointmentId;
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      return null;
    }
  }

  /// Reschedule an appointment
  static Future<bool> rescheduleAppointment({
    required String appointmentId,
    required String newTimeSlotId,
  }) async {
    try {
      // Get current appointment
      final appointmentDoc = await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);
      
      // Check if new time slot is available
      final newTimeSlotDoc = await _firestore
          .collection(_timeSlotsCollection)
          .doc(newTimeSlotId)
          .get();

      if (!newTimeSlotDoc.exists) {
        throw Exception('New time slot not found');
      }

      final newTimeSlot = TimeSlotModel.fromMap(newTimeSlotDoc.data()!);
      if (!newTimeSlot.isAvailableForBooking) {
        throw Exception('New time slot is not available');
      }

      final now = DateTime.now();
      final batch = _firestore.batch();

      // Update appointment with new time
      batch.update(
        _firestore.collection(_appointmentsCollection).doc(appointmentId),
        {
          'appointmentDate': Timestamp.fromDate(newTimeSlot.startTime),
          'timeSlot': newTimeSlot.timeRange,
          'status': 'rescheduled',
          'updatedAt': Timestamp.fromDate(now),
        },
      );

      // Free up old time slot
      final oldTimeSlotsQuery = await _firestore
          .collection(_timeSlotsCollection)
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      for (final doc in oldTimeSlotsQuery.docs) {
        batch.update(doc.reference, {
          'status': TimeSlotStatus.available.name,
          'appointmentId': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      // Book new time slot
      batch.update(
        _firestore.collection(_timeSlotsCollection).doc(newTimeSlotId),
        {
          'status': TimeSlotStatus.booked.name,
          'appointmentId': appointmentId,
          'updatedAt': Timestamp.fromDate(now),
        },
      );

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error rescheduling appointment: $e');
      return false;
    }
  }

  /// Cancel an appointment
  static Future<bool> cancelAppointment({
    required String appointmentId,
    required String cancellationReason,
    required String cancelledBy,
  }) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Update appointment status
      batch.update(
        _firestore.collection(_appointmentsCollection).doc(appointmentId),
        {
          'status': 'cancelled',
          'cancellationReason': cancellationReason,
          'cancelledBy': cancelledBy,
          'cancelledAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
      );

      // Free up the time slot
      final timeSlotsQuery = await _firestore
          .collection(_timeSlotsCollection)
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      for (final doc in timeSlotsQuery.docs) {
        batch.update(doc.reference, {
          'status': TimeSlotStatus.available.name,
          'appointmentId': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      return false;
    }
  }

  /// Get upcoming appointments for a user
  static Future<List<AppointmentModel>> getUpcomingAppointments(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      
      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('patientId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('appointmentDate')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting upcoming appointments: $e');
      return [];
    }
  }

  /// Get appointment history for a user
  static Future<List<AppointmentModel>> getAppointmentHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('patientId', isEqualTo: userId)
          .orderBy('appointmentDate', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting appointment history: $e');
      return [];
    }
  }

  /// Helper method to get day name from weekday number
  static String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Helper method to parse time string and create DateTime
  static DateTime _parseTimeString(DateTime date, String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Block time slots for a doctor
  static Future<bool> blockTimeSlots({
    required String doctorId,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String reason,
    required String blockedBy,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Find all available slots in the time range
      final querySnapshot = await _firestore
          .collection(_timeSlotsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: TimeSlotStatus.available.name)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDateTime))
          .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(endDateTime))
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': TimeSlotStatus.blocked.name,
          'blockedReason': reason,
          'blockedBy': blockedBy,
          'blockedAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error blocking time slots: $e');
      return false;
    }
  }

  /// Unblock time slots for a doctor
  static Future<bool> unblockTimeSlots({
    required String doctorId,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Find all blocked slots in the time range
      final querySnapshot = await _firestore
          .collection(_timeSlotsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: TimeSlotStatus.blocked.name)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDateTime))
          .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(endDateTime))
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': TimeSlotStatus.available.name,
          'blockedReason': null,
          'blockedBy': null,
          'blockedAt': null,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error unblocking time slots: $e');
      return false;
    }
  }
}
