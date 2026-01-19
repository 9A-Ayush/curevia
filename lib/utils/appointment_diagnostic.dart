import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../constants/app_constants.dart';

/// Utility class for diagnosing and fixing appointment data issues
class AppointmentDiagnostic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check for appointments with missing or empty doctorId
  static Future<List<Map<String, dynamic>>> findAppointmentsWithMissingDoctorId() async {
    try {
      print('🔍 Checking for appointments with missing doctorId...');
      
      final querySnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .get();

      final problematicAppointments = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'] as String?;
        
        if (doctorId == null || doctorId.isEmpty) {
          problematicAppointments.add({
            'id': doc.id,
            'data': data,
            'issue': 'Missing or empty doctorId',
          });
          
          print('❌ Found appointment with missing doctorId:');
          print('  - ID: ${doc.id}');
          print('  - Patient: ${data['patientName'] ?? 'Unknown'}');
          print('  - Doctor: ${data['doctorName'] ?? 'Unknown'}');
          print('  - DoctorId: "$doctorId"');
        }
      }

      print('✅ Diagnostic complete. Found ${problematicAppointments.length} problematic appointments.');
      return problematicAppointments;
    } catch (e) {
      print('❌ Error during diagnostic: $e');
      return [];
    }
  }

  /// Check for appointments with invalid doctorId (doctor doesn't exist)
  static Future<List<Map<String, dynamic>>> findAppointmentsWithInvalidDoctorId() async {
    try {
      print('🔍 Checking for appointments with invalid doctorId...');
      
      final querySnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .get();

      final invalidAppointments = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'] as String?;
        
        if (doctorId != null && doctorId.isNotEmpty) {
          // Check if doctor exists
          final doctorDoc = await _firestore
              .collection(AppConstants.doctorsCollection)
              .doc(doctorId)
              .get();
          
          if (!doctorDoc.exists) {
            invalidAppointments.add({
              'id': doc.id,
              'data': data,
              'issue': 'Doctor does not exist',
              'doctorId': doctorId,
            });
            
            print('❌ Found appointment with invalid doctorId:');
            print('  - ID: ${doc.id}');
            print('  - Patient: ${data['patientName'] ?? 'Unknown'}');
            print('  - Doctor: ${data['doctorName'] ?? 'Unknown'}');
            print('  - DoctorId: "$doctorId" (does not exist)');
          }
        }
      }

      print('✅ Diagnostic complete. Found ${invalidAppointments.length} appointments with invalid doctorId.');
      return invalidAppointments;
    } catch (e) {
      print('❌ Error during diagnostic: $e');
      return [];
    }
  }

  /// Get summary of all appointment data issues
  static Future<Map<String, dynamic>> getAppointmentDataSummary() async {
    try {
      print('🔍 Getting appointment data summary...');
      
      final missingDoctorId = await findAppointmentsWithMissingDoctorId();
      final invalidDoctorId = await findAppointmentsWithInvalidDoctorId();
      
      final summary = {
        'totalIssues': missingDoctorId.length + invalidDoctorId.length,
        'missingDoctorId': missingDoctorId.length,
        'invalidDoctorId': invalidDoctorId.length,
        'missingDoctorIdAppointments': missingDoctorId,
        'invalidDoctorIdAppointments': invalidDoctorId,
      };
      
      print('📊 Appointment Data Summary:');
      print('  - Total Issues: ${summary['totalIssues']}');
      print('  - Missing DoctorId: ${summary['missingDoctorId']}');
      print('  - Invalid DoctorId: ${summary['invalidDoctorId']}');
      
      return summary;
    } catch (e) {
      print('❌ Error getting summary: $e');
      return {
        'error': e.toString(),
        'totalIssues': 0,
        'missingDoctorId': 0,
        'invalidDoctorId': 0,
      };
    }
  }

  /// Fix appointments with missing doctorId by trying to match with doctor name
  static Future<int> fixAppointmentsWithMissingDoctorId() async {
    try {
      print('🔧 Attempting to fix appointments with missing doctorId...');
      
      final problematicAppointments = await findAppointmentsWithMissingDoctorId();
      int fixedCount = 0;
      
      for (final appointment in problematicAppointments) {
        final data = appointment['data'] as Map<String, dynamic>;
        final doctorName = data['doctorName'] as String?;
        
        if (doctorName != null && doctorName.isNotEmpty) {
          // Try to find doctor by name
          final doctorsQuery = await _firestore
              .collection(AppConstants.doctorsCollection)
              .where('fullName', isEqualTo: doctorName)
              .limit(1)
              .get();
          
          if (doctorsQuery.docs.isNotEmpty) {
            final doctorDoc = doctorsQuery.docs.first;
            final doctorId = doctorDoc.id;
            
            // Update appointment with correct doctorId
            await _firestore
                .collection(AppConstants.appointmentsCollection)
                .doc(appointment['id'])
                .update({
              'doctorId': doctorId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            fixedCount++;
            print('✅ Fixed appointment ${appointment['id']} - added doctorId: $doctorId');
          } else {
            print('❌ Could not find doctor with name: $doctorName');
          }
        }
      }
      
      print('✅ Fixed $fixedCount out of ${problematicAppointments.length} appointments.');
      return fixedCount;
    } catch (e) {
      print('❌ Error fixing appointments: $e');
      return 0;
    }
  }

  /// Run complete diagnostic and fix
  static Future<Map<String, dynamic>> runCompleteCheck({bool autoFix = false}) async {
    try {
      print('🚀 Running complete appointment diagnostic...');
      
      final summary = await getAppointmentDataSummary();
      
      if (autoFix && summary['missingDoctorId'] > 0) {
        print('🔧 Auto-fix enabled, attempting to fix missing doctorId issues...');
        final fixedCount = await fixAppointmentsWithMissingDoctorId();
        summary['fixedCount'] = fixedCount;
      }
      
      return summary;
    } catch (e) {
      print('❌ Error during complete check: $e');
      return {'error': e.toString()};
    }
  }
}