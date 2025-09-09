import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/appointment_model.dart';
import '../../constants/app_constants.dart';

/// Service for doctor-specific operations
class DoctorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get doctor statistics
  static Future<Map<String, int>> getDoctorStats(String doctorId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get today's appointments
      final todayAppointmentsQuery = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where(
            'appointmentDate',
            isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
          )
          .get();

      // Get total patients (unique patient IDs)
      final allAppointmentsQuery = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final uniquePatients = <String>{};
      int completedConsultations = 0;
      double monthlyRevenue = 0;

      for (final doc in allAppointmentsQuery.docs) {
        final appointment = AppointmentModel.fromMap(doc.data());
        uniquePatients.add(appointment.patientId);

        if (appointment.status == 'completed') {
          completedConsultations++;

          // Calculate monthly revenue
          if (appointment.appointmentDate.isAfter(startOfMonth)) {
            monthlyRevenue += appointment.consultationFee ?? 0;
          }
        }
      }

      return {
        'todayAppointments': todayAppointmentsQuery.docs.length,
        'totalPatients': uniquePatients.length,
        'completedConsultations': completedConsultations,
        'monthlyRevenue': monthlyRevenue.round(),
      };
    } catch (e) {
      debugPrint('Error getting doctor stats: $e');
      return {
        'todayAppointments': 0,
        'totalPatients': 0,
        'completedConsultations': 0,
        'monthlyRevenue': 0,
      };
    }
  }

  /// Get today's appointments for a doctor
  static Future<List<AppointmentModel>> getTodayAppointments(
    String doctorId,
  ) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final querySnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where(
            'appointmentDate',
            isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
          )
          .orderBy('appointmentDate')
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting today\'s appointments: $e');
      return [];
    }
  }

  /// Get doctor's appointments for a specific date range
  static Future<List<AppointmentModel>> getDoctorAppointments({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId);

      if (startDate != null) {
        query = query.where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy('appointmentDate', descending: true).limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map(
            (doc) =>
                AppointmentModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor appointments: $e');
      return [];
    }
  }

  /// Update appointment status
  static Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (notes != null) {
        updateData['doctorNotes'] = notes;
      }

      if (status == 'in_progress' || status == 'inprogress') {
        updateData['actualStartTime'] = Timestamp.fromDate(DateTime.now());
      } else if (status == 'completed') {
        updateData['actualEndTime'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .update(updateData);

      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }

  /// Get doctor's patients
  static Future<List<Map<String, dynamic>>> getDoctorPatients(
    String doctorId,
  ) async {
    try {
      final appointmentsQuery = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final patientsMap = <String, Map<String, dynamic>>{};

      for (final doc in appointmentsQuery.docs) {
        final appointment = AppointmentModel.fromMap(doc.data());
        final patientId = appointment.patientId;

        if (!patientsMap.containsKey(patientId)) {
          patientsMap[patientId] = {
            'patientId': patientId,
            'patientName': appointment.patientName,
            'totalAppointments': 1,
            'lastAppointment': appointment.appointmentDate,
            'status': appointment.status,
          };
        } else {
          patientsMap[patientId]!['totalAppointments']++;
          final lastAppointment =
              patientsMap[patientId]!['lastAppointment'] as DateTime;
          if (appointment.appointmentDate.isAfter(lastAppointment)) {
            patientsMap[patientId]!['lastAppointment'] =
                appointment.appointmentDate;
            patientsMap[patientId]!['status'] = appointment.status;
          }
        }
      }

      return patientsMap.values.toList();
    } catch (e) {
      debugPrint('Error getting doctor patients: $e');
      return [];
    }
  }

  /// Create or update doctor profile
  static Future<bool> updateDoctorProfile({
    required String doctorId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .set(profileData, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Error updating doctor profile: $e');
      return false;
    }
  }

  /// Get doctor profile
  static Future<Map<String, dynamic>?> getDoctorProfile(String doctorId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting doctor profile: $e');
      return null;
    }
  }

  /// Get doctor's schedule
  static Future<Map<String, List<Map<String, dynamic>>>> getDoctorSchedule(
    String doctorId,
  ) async {
    try {
      // This would typically come from a schedule collection
      // For now, return a mock schedule
      return {
        'monday': [
          {'startTime': '09:00', 'endTime': '12:00', 'type': 'consultation'},
          {'startTime': '14:00', 'endTime': '17:00', 'type': 'consultation'},
        ],
        'tuesday': [
          {'startTime': '09:00', 'endTime': '12:00', 'type': 'consultation'},
          {'startTime': '14:00', 'endTime': '17:00', 'type': 'consultation'},
        ],
        'wednesday': [
          {'startTime': '09:00', 'endTime': '12:00', 'type': 'consultation'},
          {'startTime': '14:00', 'endTime': '17:00', 'type': 'consultation'},
        ],
        'thursday': [
          {'startTime': '09:00', 'endTime': '12:00', 'type': 'consultation'},
          {'startTime': '14:00', 'endTime': '17:00', 'type': 'consultation'},
        ],
        'friday': [
          {'startTime': '09:00', 'endTime': '12:00', 'type': 'consultation'},
          {'startTime': '14:00', 'endTime': '17:00', 'type': 'consultation'},
        ],
        'saturday': [
          {'startTime': '09:00', 'endTime': '13:00', 'type': 'consultation'},
        ],
        'sunday': [], // Off day
      };
    } catch (e) {
      debugPrint('Error getting doctor schedule: $e');
      return {};
    }
  }
}
