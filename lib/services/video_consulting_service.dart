import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../models/video_call_model.dart';
import '../models/time_slot_model.dart';
import '../models/review_model.dart';

/// Service for managing video consulting functionality
class VideoConsultingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static const String _doctorsCollection = 'doctors';
  static const String _appointmentsCollection = 'appointments';
  static const String _videoCallsCollection = 'video_calls';
  static const String _timeSlotsCollection = 'time_slots';
  static const String _reviewsCollection = 'reviews';

  /// Get all available doctors for video consultation
  static Future<List<DoctorModel>> getAvailableDoctors({
    String? specialty,
    String? searchQuery,
    double? maxFee,
    double? minRating,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_doctorsCollection)
          .where('isAvailableOnline', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true);

      // Apply filters
      if (specialty != null && specialty.isNotEmpty) {
        query = query.where('specialty', isEqualTo: specialty);
      }

      if (maxFee != null) {
        query = query.where('consultationFee', isLessThanOrEqualTo: maxFee);
      }

      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      List<DoctorModel> doctors = querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply search filter locally (Firestore doesn't support case-insensitive search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        doctors = doctors.where((doctor) {
          final query = searchQuery.toLowerCase();
          return doctor.fullName.toLowerCase().contains(query) ||
                 (doctor.specialty?.toLowerCase().contains(query) ?? false) ||
                 (doctor.qualification?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Sort by rating and then by experience
      doctors.sort((a, b) {
        final ratingComparison = (b.rating ?? 0).compareTo(a.rating ?? 0);
        if (ratingComparison != 0) return ratingComparison;
        return (b.experienceYears ?? 0).compareTo(a.experienceYears ?? 0);
      });

      return doctors;
    } catch (e) {
      debugPrint('Error getting available doctors: $e');
      return [];
    }
  }

  /// Get doctor by ID
  static Future<DoctorModel?> getDoctorById(String doctorId) async {
    try {
      final doc = await _firestore
          .collection(_doctorsCollection)
          .doc(doctorId)
          .get();

      if (doc.exists) {
        return DoctorModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting doctor by ID: $e');
      return null;
    }
  }

  /// Get available time slots for a doctor
  static Future<List<TimeSlotModel>> getDoctorAvailableSlots(
    String doctorId, {
    DateTime? startDate,
    DateTime? endDate,
    int daysAhead = 7,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? start.add(Duration(days: daysAhead));

      final querySnapshot = await _firestore
          .collection(_timeSlotsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: TimeSlotStatus.available.name)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date')
          .orderBy('startTime')
          .get();

      return querySnapshot.docs
          .map((doc) => TimeSlotModel.fromMap(doc.data()))
          .where((slot) => slot.isAvailableForBooking)
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor available slots: $e');
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
    required double consultationFee,
    String? symptoms,
    String? notes,
  }) async {
    try {
      final appointmentId = _firestore.collection(_appointmentsCollection).doc().id;
      final now = DateTime.now();

      // Get the time slot
      final timeSlotDoc = await _firestore
          .collection(_timeSlotsCollection)
          .doc(timeSlotId)
          .get();

      if (!timeSlotDoc.exists) {
        throw Exception('Time slot not found');
      }

      final timeSlot = TimeSlotModel.fromMap(timeSlotDoc.data()!);
      
      if (!timeSlot.isAvailableForBooking) {
        throw Exception('Time slot is not available');
      }

      // Create appointment
      final appointment = AppointmentModel(
        id: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        appointmentDate: timeSlot.date,
        timeSlot: timeSlot.timeRange,
        consultationType: 'online',
        status: 'pending',
        consultationFee: consultationFee,
        symptoms: symptoms,
        notes: notes,
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

  /// Create video call session for appointment
  static Future<VideoCallModel?> createVideoCallSession(
    String appointmentId,
  ) async {
    try {
      // Get appointment details
      final appointmentDoc = await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);
      
      final videoCallId = _firestore.collection(_videoCallsCollection).doc().id;
      final roomId = 'room_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      // Create video call
      final videoCall = VideoCallModel(
        id: videoCallId,
        appointmentId: appointmentId,
        roomId: roomId,
        meetingLink: 'https://meet.curevia.com/room/$roomId', // Placeholder URL
        status: VideoCallStatus.scheduled,
        scheduledStartTime: appointment.appointmentDate,
        plannedDurationMinutes: appointment.duration ?? 30,
        participants: [
          VideoCallParticipant(
            id: appointment.doctorId,
            name: appointment.doctorName,
            role: ParticipantRole.doctor,
            isHost: true,
            joinedAt: now,
            isMuted: false,
            isVideoEnabled: true,
          ),
          VideoCallParticipant(
            id: appointment.patientId,
            name: appointment.patientName,
            role: ParticipantRole.patient,
            isHost: false,
            joinedAt: now,
            isMuted: false,
            isVideoEnabled: true,
          ),
        ],
        isRecorded: false,
        createdAt: now,
        updatedAt: now,
      );

      // Save video call
      await _firestore
          .collection(_videoCallsCollection)
          .doc(videoCallId)
          .set(videoCall.toMap());

      // Update appointment with video call info
      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update({
        'meetingId': videoCallId,
        'meetingPassword': roomId,
        'updatedAt': Timestamp.fromDate(now),
      });

      return videoCall;
    } catch (e) {
      debugPrint('Error creating video call session: $e');
      return null;
    }
  }

  /// Get user appointments
  static Future<List<AppointmentModel>> getUserAppointments(
    String userId, {
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_appointmentsCollection)
          .where('patientId', isEqualTo: userId)
          .orderBy('appointmentDate', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting user appointments: $e');
      return [];
    }
  }

  /// Get doctor appointments
  static Future<List<AppointmentModel>> getDoctorAppointments(
    String doctorId, {
    String? status,
    DateTime? date,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay));
      }

      query = query.orderBy('appointmentDate').limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor appointments: $e');
      return [];
    }
  }

  /// Cancel appointment
  static Future<bool> cancelAppointment(
    String appointmentId,
    String cancellationReason,
    String cancelledBy,
  ) async {
    try {
      final now = DateTime.now();
      final batch = _firestore.batch();

      // Get appointment
      final appointmentDoc = await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found');
      }

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);

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

      // Free up the time slot if it exists
      if (appointment.timeSlot != null) {
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
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      return false;
    }
  }

  /// Get doctor reviews
  static Future<List<ReviewModel>> getDoctorReviews(
    String doctorId, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('targetId', isEqualTo: doctorId)
          .where('targetType', isEqualTo: 'doctor')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor reviews: $e');
      return [];
    }
  }

  /// Get specialties list
  static Future<List<String>> getSpecialties() async {
    try {
      final querySnapshot = await _firestore
          .collection(_doctorsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final specialties = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final specialty = data['specialty'] as String?;
        if (specialty != null && specialty.isNotEmpty) {
          specialties.add(specialty);
        }
      }

      final sortedSpecialties = specialties.toList()..sort();
      return sortedSpecialties;
    } catch (e) {
      debugPrint('Error getting specialties: $e');
      return [];
    }
  }

  /// Search doctors with advanced filters
  static Future<List<DoctorModel>> searchDoctors({
    String? query,
    String? specialty,
    String? city,
    double? minRating,
    double? maxFee,
    List<String>? languages,
    bool? isAvailableOnline,
    bool? isAvailableOffline,
    String? sortBy, // 'rating', 'experience', 'fee'
    bool ascending = false,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore
          .collection(_doctorsCollection)
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true);

      // Apply filters
      if (specialty != null && specialty.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('specialty', isEqualTo: specialty);
      }

      if (city != null && city.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('city', isEqualTo: city);
      }

      if (minRating != null) {
        firestoreQuery = firestoreQuery.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      if (maxFee != null) {
        firestoreQuery = firestoreQuery.where('consultationFee', isLessThanOrEqualTo: maxFee);
      }

      if (isAvailableOnline != null) {
        firestoreQuery = firestoreQuery.where('isAvailableOnline', isEqualTo: isAvailableOnline);
      }

      if (isAvailableOffline != null) {
        firestoreQuery = firestoreQuery.where('isAvailableOffline', isEqualTo: isAvailableOffline);
      }

      firestoreQuery = firestoreQuery.limit(limit);

      final querySnapshot = await firestoreQuery.get();
      List<DoctorModel> doctors = querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply local filters
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        doctors = doctors.where((doctor) {
          return doctor.fullName.toLowerCase().contains(searchQuery) ||
                 (doctor.specialty?.toLowerCase().contains(searchQuery) ?? false) ||
                 (doctor.qualification?.toLowerCase().contains(searchQuery) ?? false) ||
                 (doctor.about?.toLowerCase().contains(searchQuery) ?? false);
        }).toList();
      }

      if (languages != null && languages.isNotEmpty) {
        doctors = doctors.where((doctor) {
          return doctor.languages?.any((lang) => languages.contains(lang)) ?? false;
        }).toList();
      }

      // Apply sorting
      if (sortBy != null) {
        doctors.sort((a, b) {
          int comparison = 0;
          switch (sortBy) {
            case 'rating':
              comparison = (a.rating ?? 0).compareTo(b.rating ?? 0);
              break;
            case 'experience':
              comparison = (a.experienceYears ?? 0).compareTo(b.experienceYears ?? 0);
              break;
            case 'fee':
              comparison = (a.consultationFee ?? 0).compareTo(b.consultationFee ?? 0);
              break;
            default:
              comparison = a.fullName.compareTo(b.fullName);
          }
          return ascending ? comparison : -comparison;
        });
      }

      return doctors;
    } catch (e) {
      debugPrint('Error searching doctors: $e');
      return [];
    }
  }
}
