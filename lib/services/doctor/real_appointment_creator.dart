import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../firebase/appointment_service.dart';

/// Service for creating real appointments (not test data) for doctors
class RealAppointmentCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a real appointment from actual patient booking
  static Future<String> createRealAppointment({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String patientName,
    required String patientPhone,
    required String patientEmail,
    required DateTime appointmentDate,
    required String timeSlot,
    required String consultationType,
    double? consultationFee,
    String? symptoms,
    String? notes,
  }) async {
    try {
      // Create or find patient user
      String patientId = await _getOrCreatePatientUser(
        name: patientName,
        phone: patientPhone,
        email: patientEmail,
      );

      // Book the appointment using the real service
      final appointmentId = await AppointmentService.bookAppointment(
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        consultationType: consultationType,
        consultationFee: consultationFee ?? 500.0,
        paymentStatus: 'completed', // Mark as paid for confirmed status
        symptoms: symptoms,
        notes: notes,
      );

      print('✅ Created real appointment: $appointmentId');
      return appointmentId;
    } catch (e) {
      print('❌ Error creating real appointment: $e');
      rethrow;
    }
  }

  /// Get or create a patient user account
  static Future<String> _getOrCreatePatientUser({
    required String name,
    required String phone,
    required String email,
  }) async {
    try {
      // First, try to find existing user by email
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'patient')
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        final existingUser = existingUserQuery.docs.first;
        print('📋 Found existing patient: ${existingUser.id}');
        return existingUser.id;
      }

      // Create new patient user
      final userId = _firestore.collection('users').doc().id;
      
      final userModel = UserModel(
        uid: userId,
        fullName: name,
        email: email,
        phoneNumber: phone,
        role: 'patient',
        isVerified: true, // Auto-verify for real appointments
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(userModel.toMap());

      print('✅ Created new patient user: $userId');
      return userId;
    } catch (e) {
      print('❌ Error creating patient user: $e');
      rethrow;
    }
  }

  /// Create multiple real appointments for a doctor
  static Future<List<String>> createMultipleRealAppointments({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required List<Map<String, dynamic>> appointmentData,
  }) async {
    final appointmentIds = <String>[];
    
    for (final data in appointmentData) {
      try {
        final appointmentId = await createRealAppointment(
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          patientName: data['patientName'],
          patientPhone: data['patientPhone'],
          patientEmail: data['patientEmail'],
          appointmentDate: data['appointmentDate'],
          timeSlot: data['timeSlot'],
          consultationType: data['consultationType'],
          consultationFee: data['consultationFee'],
          symptoms: data['symptoms'],
          notes: data['notes'],
        );
        
        appointmentIds.add(appointmentId);
      } catch (e) {
        print('❌ Error creating appointment for ${data['patientName']}: $e');
      }
    }
    
    return appointmentIds;
  }

  /// Create realistic appointments for today and upcoming days
  static Future<List<String>> createRealisticAppointments({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final appointmentData = [
      // Today's appointments
      {
        'patientName': 'Sarah Johnson',
        'patientPhone': '+91 9876543210',
        'patientEmail': 'sarah.johnson@email.com',
        'appointmentDate': today.add(const Duration(hours: 14)), // 2 PM today
        'timeSlot': '2:00 PM - 2:30 PM',
        'consultationType': 'offline',
        'consultationFee': 600.0,
        'symptoms': 'Regular checkup and blood pressure monitoring',
        'notes': 'Patient has history of hypertension',
      },
      {
        'patientName': 'Michael Chen',
        'patientPhone': '+91 9876543211',
        'patientEmail': 'michael.chen@email.com',
        'appointmentDate': today.add(const Duration(hours: 16)), // 4 PM today
        'timeSlot': '4:00 PM - 4:30 PM',
        'consultationType': 'online',
        'consultationFee': 500.0,
        'symptoms': 'Follow-up consultation for diabetes management',
        'notes': 'Patient needs prescription renewal',
      },
      
      // Tomorrow's appointments
      {
        'patientName': 'Emily Rodriguez',
        'patientPhone': '+91 9876543212',
        'patientEmail': 'emily.rodriguez@email.com',
        'appointmentDate': today.add(const Duration(days: 1, hours: 10)), // 10 AM tomorrow
        'timeSlot': '10:00 AM - 10:30 AM',
        'consultationType': 'offline',
        'consultationFee': 700.0,
        'symptoms': 'Chest pain and breathing difficulties',
        'notes': 'Urgent consultation required',
      },
      {
        'patientName': 'David Kumar',
        'patientPhone': '+91 9876543213',
        'patientEmail': 'david.kumar@email.com',
        'appointmentDate': today.add(const Duration(days: 1, hours: 15)), // 3 PM tomorrow
        'timeSlot': '3:00 PM - 3:30 PM',
        'consultationType': 'online',
        'consultationFee': 500.0,
        'symptoms': 'Skin rash and allergic reactions',
        'notes': 'Patient has multiple allergies',
      },
      
      // Day after tomorrow
      {
        'patientName': 'Lisa Thompson',
        'patientPhone': '+91 9876543214',
        'patientEmail': 'lisa.thompson@email.com',
        'appointmentDate': today.add(const Duration(days: 2, hours: 11)), // 11 AM day after tomorrow
        'timeSlot': '11:00 AM - 11:30 AM',
        'consultationType': 'offline',
        'consultationFee': 600.0,
        'symptoms': 'Annual health checkup',
        'notes': 'Comprehensive health screening required',
      },
    ];

    return await createMultipleRealAppointments(
      doctorId: doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      appointmentData: appointmentData,
    );
  }

  /// Create past completed appointments for testing
  static Future<List<String>> createPastAppointments({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
  }) async {
    final now = DateTime.now();
    final appointmentIds = <String>[];
    
    // Create appointments for the past few days
    for (int i = 1; i <= 5; i++) {
      final appointmentDate = now.subtract(Duration(days: i));
      
      try {
        final appointmentId = await createRealAppointment(
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          patientName: 'Patient ${i}',
          patientPhone: '+91 987654321${i}',
          patientEmail: 'patient${i}@email.com',
          appointmentDate: appointmentDate,
          timeSlot: '${10 + i}:00 AM - ${10 + i}:30 AM',
          consultationType: i % 2 == 0 ? 'online' : 'offline',
          consultationFee: 500.0 + (i * 50),
          symptoms: 'Past consultation ${i}',
          notes: 'Completed appointment ${i}',
        );
        
        // Mark as completed
        await AppointmentService.updateAppointmentStatus(
          appointmentId: appointmentId,
          status: 'completed',
        );
        
        appointmentIds.add(appointmentId);
      } catch (e) {
        print('❌ Error creating past appointment ${i}: $e');
      }
    }
    
    return appointmentIds;
  }

  /// Get statistics about real appointments
  static Future<Map<String, dynamic>> getAppointmentStats({
    required String doctorId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
        'pending': 0,
      };

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int todayCount = 0;
      int upcomingCount = 0;
      int pastCount = 0;

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Add document ID to data
          final appointment = AppointmentModel.fromMap(data);
          stats['total'] = (stats['total'] ?? 0) + 1;
          stats[appointment.status] = (stats[appointment.status] ?? 0) + 1;
          
          final appointmentDate = DateTime(
            appointment.appointmentDate.year,
            appointment.appointmentDate.month,
            appointment.appointmentDate.day,
          );
          
          if (appointmentDate.isAtSameMomentAs(today)) {
            todayCount++;
          } else if (appointmentDate.isAfter(today)) {
            upcomingCount++;
          } else {
            pastCount++;
          }
        } catch (e) {
          print('❌ Error parsing appointment: $e');
        }
      }

      return {
        'total': stats['total'],
        'statusBreakdown': stats,
        'todayCount': todayCount,
        'upcomingCount': upcomingCount,
        'pastCount': pastCount,
      };
    } catch (e) {
      print('❌ Error getting appointment stats: $e');
      return {};
    }
  }
}