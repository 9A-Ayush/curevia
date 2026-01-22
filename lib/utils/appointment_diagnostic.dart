import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';

/// Diagnostic utility for checking appointment data in Firebase
class AppointmentDiagnostic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check all appointments in the database
  static Future<Map<String, dynamic>> checkAllAppointments() async {
    try {
      print('🔍 Checking all appointments in database...');
      
      final querySnapshot = await _firestore
          .collection('appointments')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final appointments = <Map<String, dynamic>>[];
      final doctorIds = <String>{};
      final patientIds = <String>{};
      final statuses = <String, int>{};

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Add document ID to data
          final appointment = AppointmentModel.fromMap(data);
          
          appointments.add({
            'id': appointment.id,
            'doctorId': appointment.doctorId,
            'doctorName': appointment.doctorName,
            'patientId': appointment.patientId,
            'patientName': appointment.patientName,
            'status': appointment.status,
            'appointmentDate': appointment.appointmentDate.toString(),
            'timeSlot': appointment.timeSlot,
            'consultationType': appointment.consultationType,
          });

          doctorIds.add(appointment.doctorId);
          patientIds.add(appointment.patientId);
          statuses[appointment.status] = (statuses[appointment.status] ?? 0) + 1;
        } catch (e) {
          print('❌ Error parsing appointment ${doc.id}: $e');
        }
      }

      final result = {
        'totalAppointments': appointments.length,
        'appointments': appointments,
        'uniqueDoctors': doctorIds.length,
        'uniquePatients': patientIds.length,
        'statusBreakdown': statuses,
        'doctorIds': doctorIds.toList(),
        'patientIds': patientIds.toList(),
      };

      print('📊 Appointment Summary:');
      print('   Total appointments: ${result['totalAppointments']}');
      print('   Unique doctors: ${result['uniqueDoctors']}');
      print('   Unique patients: ${result['uniquePatients']}');
      print('   Status breakdown: ${result['statusBreakdown']}');

      return result;
    } catch (e) {
      print('❌ Error checking appointments: $e');
      return {'error': e.toString()};
    }
  }

  /// Check appointments for a specific doctor
  static Future<Map<String, dynamic>> checkDoctorAppointments(String doctorId) async {
    try {
      print('🔍 Checking appointments for doctor: $doctorId');
      
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('appointmentDate', descending: true)
          .get();

      final appointments = <Map<String, dynamic>>[];
      final statuses = <String, int>{};
      final today = DateTime.now();

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Add document ID to data
          final appointment = AppointmentModel.fromMap(data);
          
          final isToday = appointment.appointmentDate.year == today.year &&
                         appointment.appointmentDate.month == today.month &&
                         appointment.appointmentDate.day == today.day;
          
          final isUpcoming = appointment.appointmentDate.isAfter(today);
          
          appointments.add({
            'id': appointment.id,
            'patientName': appointment.patientName,
            'status': appointment.status,
            'appointmentDate': appointment.appointmentDate.toString(),
            'timeSlot': appointment.timeSlot,
            'consultationType': appointment.consultationType,
            'isToday': isToday,
            'isUpcoming': isUpcoming,
            'daysDifference': appointment.appointmentDate.difference(today).inDays,
          });

          statuses[appointment.status] = (statuses[appointment.status] ?? 0) + 1;
        } catch (e) {
          print('❌ Error parsing appointment ${doc.id}: $e');
        }
      }

      final result = {
        'doctorId': doctorId,
        'totalAppointments': appointments.length,
        'appointments': appointments,
        'statusBreakdown': statuses,
        'todayAppointments': appointments.where((a) => a['isToday'] == true).length,
        'upcomingAppointments': appointments.where((a) => a['isUpcoming'] == true && a['isToday'] == false).length,
      };

      print('📊 Doctor $doctorId Appointment Summary:');
      print('   Total appointments: ${result['totalAppointments']}');
      print('   Today\'s appointments: ${result['todayAppointments']}');
      print('   Upcoming appointments: ${result['upcomingAppointments']}');
      print('   Status breakdown: ${result['statusBreakdown']}');

      return result;
    } catch (e) {
      print('❌ Error checking doctor appointments: $e');
      return {'error': e.toString()};
    }
  }

  /// Check all doctors in the database
  static Future<Map<String, dynamic>> checkAllDoctors() async {
    try {
      print('🔍 Checking all doctors in database...');
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      final doctors = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final user = UserModel.fromMap(data);
          
          doctors.add({
            'id': user.uid,
            'name': user.fullName,
            'email': user.email,
            'specialty': user.additionalInfo?['specialty'],
            'isVerified': user.isVerified,
            'createdAt': user.createdAt.toString(),
          });
        } catch (e) {
          print('❌ Error parsing doctor ${doc.id}: $e');
        }
      }

      final result = {
        'totalDoctors': doctors.length,
        'doctors': doctors,
        'verifiedDoctors': doctors.where((d) => d['isVerified'] == true).length,
      };

      print('📊 Doctor Summary:');
      print('   Total doctors: ${result['totalDoctors']}');
      print('   Verified doctors: ${result['verifiedDoctors']}');

      return result;
    } catch (e) {
      print('❌ Error checking doctors: $e');
      return {'error': e.toString()};
    }
  }

  /// Check all patients in the database
  static Future<Map<String, dynamic>> checkAllPatients() async {
    try {
      print('🔍 Checking all patients in database...');
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      final patients = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final user = UserModel.fromMap(data);
          
          patients.add({
            'id': user.uid,
            'name': user.fullName,
            'email': user.email,
            'createdAt': user.createdAt.toString(),
          });
        } catch (e) {
          print('❌ Error parsing patient ${doc.id}: $e');
        }
      }

      final result = {
        'totalPatients': patients.length,
        'patients': patients,
      };

      print('📊 Patient Summary:');
      print('   Total patients: ${result['totalPatients']}');

      return result;
    } catch (e) {
      print('❌ Error checking patients: $e');
      return {'error': e.toString()};
    }
  }

  /// Run comprehensive diagnostic
  static Future<Map<String, dynamic>> runComprehensiveDiagnostic() async {
    print('🚀 Running comprehensive appointment diagnostic...');
    
    final results = <String, dynamic>{};
    
    try {
      results['appointments'] = await checkAllAppointments();
      results['doctors'] = await checkAllDoctors();
      results['patients'] = await checkAllPatients();
      
      // Cross-reference data
      final appointmentData = results['appointments'] as Map<String, dynamic>;
      final doctorData = results['doctors'] as Map<String, dynamic>;
      
      if (appointmentData['doctorIds'] != null && doctorData['doctors'] != null) {
        final appointmentDoctorIds = Set<String>.from(appointmentData['doctorIds']);
        final allDoctorIds = Set<String>.from(
          (doctorData['doctors'] as List).map((d) => d['id']),
        );
        
        results['analysis'] = {
          'doctorsWithAppointments': appointmentDoctorIds.length,
          'doctorsWithoutAppointments': allDoctorIds.difference(appointmentDoctorIds).length,
          'orphanedAppointments': appointmentDoctorIds.difference(allDoctorIds).length,
        };
      }
      
      print('✅ Comprehensive diagnostic completed');
      return results;
    } catch (e) {
      print('❌ Error in comprehensive diagnostic: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Test real-time stream for a doctor
  static Stream<List<AppointmentModel>> testDoctorStream(String doctorId) {
    print('🔄 Testing real-time stream for doctor: $doctorId');
    
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentDate')
        .snapshots()
        .map((snapshot) {
          print('🔄 Stream update: ${snapshot.docs.length} documents');
          
          final appointments = <AppointmentModel>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              data['id'] = doc.id; // Add document ID to data
              final appointment = AppointmentModel.fromMap(data);
              appointments.add(appointment);
              print('   - ${appointment.patientName}: ${appointment.status} on ${appointment.appointmentDate}');
            } catch (e) {
              print('   - Error parsing ${doc.id}: $e');
            }
          }
          
          return appointments;
        });
  }
}