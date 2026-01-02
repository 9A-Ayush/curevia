import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/appointment_model.dart';
import '../../constants/app_constants.dart';
import '../firebase/revenue_service.dart';

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

      for (final doc in allAppointmentsQuery.docs) {
        final appointment = AppointmentModel.fromMap(doc.data());
        uniquePatients.add(appointment.patientId);

        if (appointment.status == 'completed') {
          completedConsultations++;
        }
      }

      // Get monthly revenue from revenue service
      final revenueData = await RevenueService.getDoctorRevenue(
        doctorId: doctorId,
        startDate: startOfMonth,
        endDate: DateTime(now.year, now.month + 1, 0),
      );

      return {
        'todayAppointments': todayAppointmentsQuery.docs.length,
        'totalPatients': uniquePatients.length,
        'completedConsultations': completedConsultations,
        'monthlyRevenue': (revenueData['totalRevenue'] as double).round(),
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
      final doc = await _firestore
          .collection('doctor_schedules')
          .doc(doctorId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final schedule = <String, List<Map<String, dynamic>>>{};

        for (final day in [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ]) {
          if (data.containsKey(day) && data[day] is List) {
            schedule[day] = List<Map<String, dynamic>>.from(
              (data[day] as List).map((e) => Map<String, dynamic>.from(e)),
            );
          } else {
            schedule[day] = [];
          }
        }

        return schedule;
      }

      // Return default schedule if none exists
      return {
        'monday': [],
        'tuesday': [],
        'wednesday': [],
        'thursday': [],
        'friday': [],
        'saturday': [],
        'sunday': [],
      };
    } catch (e) {
      debugPrint('Error getting doctor schedule: $e');
      return {};
    }
  }

  /// Get doctor analytics data
  static Future<Map<String, dynamic>> getDoctorAnalytics(
    String doctorId,
    String period,
  ) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'This Week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'Last 3 Months':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'This Month':
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      final endDate = DateTime(now.year, now.month + 1, 0);

      // Get appointment data
      final appointmentsQuery = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      // Get revenue data from revenue service
      final revenueData = await RevenueService.getDoctorRevenue(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );

      final revenueByType = await RevenueService.getRevenueByType(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );

      int totalConsultations = 0;
      int completedConsultations = 0;
      final uniquePatients = <String>{};
      final newPatients = <String>{};

      for (final doc in appointmentsQuery.docs) {
        final appointment = AppointmentModel.fromMap(doc.data());
        totalConsultations++;

        if (appointment.status == 'completed') {
          completedConsultations++;
        }

        uniquePatients.add(appointment.patientId);

        // Check if this is a new patient (first appointment in period)
        final patientPreviousAppointments = await _firestore
            .collection(AppConstants.appointmentsCollection)
            .where('doctorId', isEqualTo: doctorId)
            .where('patientId', isEqualTo: appointment.patientId)
            .where(
              'appointmentDate',
              isLessThan: Timestamp.fromDate(startDate),
            )
            .limit(1)
            .get();

        if (patientPreviousAppointments.docs.isEmpty) {
          newPatients.add(appointment.patientId);
        }
      }

      final totalRevenue = revenueData['totalRevenue'] as double;
      final avgConsultationFee = revenueData['confirmedAppointments'] > 0 
          ? totalRevenue / revenueData['confirmedAppointments'] 
          : 0.0;

      return {
        'totalConsultations': totalConsultations,
        'completedConsultations': completedConsultations,
        'patientSatisfaction': 4.5, // TODO: Calculate from reviews
        'avgResponseTime': 5.0, // TODO: Calculate from actual data
        'revenue': totalRevenue.round(),
        'avgConsultationFee': avgConsultationFee.round(),
        'onlineRevenue': (revenueByType['online'] ?? 0).round(),
        'offlineRevenue': (revenueByType['offline'] ?? 0).round(),
        'totalPatients': uniquePatients.length,
        'newPatients': newPatients.length,
        'returningPatients': uniquePatients.length - newPatients.length,
        'confirmedAppointments': revenueData['confirmedAppointments'],
        'cancelledAppointments': revenueData['cancelledAppointments'],
        'netRevenue': totalRevenue.round(),
        'consultationsChange': '+0%', // TODO: Calculate change from previous period
        'satisfactionChange': '+0.0', // TODO: Calculate change
        'responseTimeChange': '-0.0 min', // TODO: Calculate change
        'revenueChange': '+0%', // TODO: Calculate change
      };
    } catch (e) {
      debugPrint('Error getting doctor analytics: $e');
      return {};
    }
  }

  /// Get doctor notifications
  static Future<List<Map<String, dynamic>>> getDoctorNotifications(
    String doctorId, {
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final timeAgo = createdAt != null ? _getTimeAgo(createdAt) : 'Just now';

        return {
          'id': doc.id,
          'title': data['title'] ?? 'Notification',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'general',
          'time': timeAgo,
          'isRead': data['isRead'] ?? false,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting doctor notifications: $e');
      return [];
    }
  }

  /// Block a time slot
  static Future<bool> blockTimeSlot({
    required String doctorId,
    required String date,
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    try {
      await _firestore.collection('blocked_slots').add({
        'doctorId': doctorId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'reason': reason ?? '',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      debugPrint('Error blocking time slot: $e');
      return false;
    }
  }

  /// Copy schedule to next week
  static Future<bool> copyScheduleToNextWeek(String doctorId) async {
    try {
      final schedule = await getDoctorSchedule(doctorId);

      // TODO: Implement actual schedule copying logic
      // This would involve creating new time slots for next week

      return true;
    } catch (e) {
      debugPrint('Error copying schedule: $e');
      return false;
    }
  }

  /// Create a new appointment
  static Future<bool> createAppointment({
    required String doctorId,
    required String patientName,
    required String date,
    required String time,
    required String consultationType,
  }) async {
    try {
      // TODO: Parse date and time properly
      // For now, create a basic appointment

      await _firestore.collection(AppConstants.appointmentsCollection).add({
        'doctorId': doctorId,
        'patientId': 'temp_patient_id', // TODO: Get actual patient ID
        'patientName': patientName,
        'appointmentDate': Timestamp.fromDate(DateTime.now()),
        'consultationType': consultationType,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      return false;
    }
  }

  /// Add a new patient
  static Future<bool> addPatient({
    required String doctorId,
    required String patientName,
    required String email,
    required String phone,
  }) async {
    try {
      // TODO: Implement proper patient registration
      // This would involve creating a user account and linking to doctor

      return true;
    } catch (e) {
      debugPrint('Error adding patient: $e');
      return false;
    }
  }

  /// Export patients as PDF
  static Future<bool> exportPatientsAsPDF(
    String doctorId,
    List<Map<String, dynamic>> patients,
  ) async {
    try {
      // TODO: Implement PDF export using pdf package
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Error exporting patients as PDF: $e');
      return false;
    }
  }

  /// Export patients as Excel
  static Future<bool> exportPatientsAsExcel(
    String doctorId,
    List<Map<String, dynamic>> patients,
  ) async {
    try {
      // TODO: Implement Excel export using excel package
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Error exporting patients as Excel: $e');
      return false;
    }
  }

  /// Helper method to calculate time ago
  static String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
