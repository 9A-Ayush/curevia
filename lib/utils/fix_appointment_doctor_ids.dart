import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// Utility to fix appointments with missing or invalid doctor IDs
class FixAppointmentDoctorIds {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fix all appointments with missing doctor IDs
  static Future<Map<String, dynamic>> fixAllAppointments() async {
    try {
      print('🔧 Starting appointment doctor ID fix process...');
      
      final results = {
        'totalProcessed': 0,
        'fixedByName': 0,
        'fixedByUserSearch': 0,
        'stillMissing': 0,
        'errors': <String>[],
      };

      // Get all appointments
      final appointmentsSnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .get();

      results['totalProcessed'] = appointmentsSnapshot.docs.length;
      print('📊 Processing ${appointmentsSnapshot.docs.length} appointments...');

      for (final appointmentDoc in appointmentsSnapshot.docs) {
        try {
          final data = appointmentDoc.data();
          final doctorId = data['doctorId'] as String?;
          final doctorName = data['doctorName'] as String?;

          // Skip if doctor ID is already valid
          if (doctorId != null && doctorId.isNotEmpty) {
            // Verify doctor exists
            final doctorExists = await _verifyDoctorExists(doctorId);
            if (doctorExists) {
              continue; // This appointment is fine
            }
            print('⚠️ Invalid doctor ID found: $doctorId for appointment ${appointmentDoc.id}');
          }

          if (doctorName == null || doctorName.isEmpty) {
            print('❌ No doctor name available for appointment ${appointmentDoc.id}');
            results['stillMissing'] = (results['stillMissing'] as int) + 1;
            continue;
          }

          print('🔍 Fixing appointment ${appointmentDoc.id} - Doctor: $doctorName');

          // Try to find doctor by name in doctors collection
          String? foundDoctorId = await _findDoctorByName(doctorName);

          // If not found in doctors collection, try users collection
          if (foundDoctorId == null) {
            foundDoctorId = await _findDoctorInUsers(doctorName);
            if (foundDoctorId != null) {
              results['fixedByUserSearch'] = (results['fixedByUserSearch'] as int) + 1;
            }
          } else {
            results['fixedByName'] = (results['fixedByName'] as int) + 1;
          }

          if (foundDoctorId != null) {
            // Update the appointment with the correct doctor ID
            await appointmentDoc.reference.update({
              'doctorId': foundDoctorId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('✅ Fixed appointment ${appointmentDoc.id} with doctor ID: $foundDoctorId');
          } else {
            print('❌ Could not find doctor for appointment ${appointmentDoc.id}');
            results['stillMissing'] = (results['stillMissing'] as int) + 1;
          }

        } catch (e) {
          final error = 'Error processing appointment ${appointmentDoc.id}: $e';
          print('❌ $error');
          (results['errors'] as List<String>).add(error);
        }
      }

      print('🎉 Fix process completed!');
      print('📊 Results:');
      print('  - Total Processed: ${results['totalProcessed']}');
      print('  - Fixed by Name: ${results['fixedByName']}');
      print('  - Fixed by User Search: ${results['fixedByUserSearch']}');
      print('  - Still Missing: ${results['stillMissing']}');
      print('  - Errors: ${(results['errors'] as List).length}');

      return results;
    } catch (e) {
      print('❌ Error in fix process: $e');
      return {
        'error': e.toString(),
        'totalProcessed': 0,
        'fixedByName': 0,
        'fixedByUserSearch': 0,
        'stillMissing': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Verify if a doctor exists in the doctors collection
  static Future<bool> _verifyDoctorExists(String doctorId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error verifying doctor $doctorId: $e');
      return false;
    }
  }

  /// Find doctor by name in doctors collection
  static Future<String?> _findDoctorByName(String doctorName) async {
    try {
      // Try exact match first
      final exactMatch = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('fullName', isEqualTo: doctorName)
          .limit(1)
          .get();

      if (exactMatch.docs.isNotEmpty) {
        return exactMatch.docs.first.id;
      }

      // Try case-insensitive search
      final allDoctors = await _firestore
          .collection(AppConstants.doctorsCollection)
          .get();

      for (final doc in allDoctors.docs) {
        final data = doc.data();
        final fullName = data['fullName'] as String?;
        if (fullName != null && 
            fullName.toLowerCase() == doctorName.toLowerCase()) {
          return doc.id;
        }
      }

      return null;
    } catch (e) {
      print('Error finding doctor by name $doctorName: $e');
      return null;
    }
  }

  /// Find doctor in users collection with doctor role
  static Future<String?> _findDoctorInUsers(String doctorName) async {
    try {
      // Try exact match first
      final exactMatch = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'doctor')
          .where('fullName', isEqualTo: doctorName)
          .limit(1)
          .get();

      if (exactMatch.docs.isNotEmpty) {
        return exactMatch.docs.first.id;
      }

      // Try case-insensitive search
      final allDoctorUsers = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'doctor')
          .get();

      for (final doc in allDoctorUsers.docs) {
        final data = doc.data();
        final fullName = data['fullName'] as String?;
        if (fullName != null && 
            fullName.toLowerCase() == doctorName.toLowerCase()) {
          return doc.id;
        }
      }

      return null;
    } catch (e) {
      print('Error finding doctor in users $doctorName: $e');
      return null;
    }
  }

  /// Get summary of current appointment issues
  static Future<Map<String, dynamic>> getIssuesSummary() async {
    try {
      print('🔍 Analyzing appointment doctor ID issues...');
      
      final appointmentsSnapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .get();

      final summary = {
        'totalAppointments': appointmentsSnapshot.docs.length,
        'missingDoctorId': 0,
        'invalidDoctorId': 0,
        'validDoctorId': 0,
        'missingAppointments': <Map<String, dynamic>>[],
        'invalidAppointments': <Map<String, dynamic>>[],
      };

      for (final doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'] as String?;
        final doctorName = data['doctorName'] as String?;

        if (doctorId == null || doctorId.isEmpty) {
          summary['missingDoctorId'] = (summary['missingDoctorId'] as int) + 1;
          (summary['missingAppointments'] as List).add({
            'id': doc.id,
            'doctorName': doctorName,
            'patientName': data['patientName'],
            'appointmentDate': data['appointmentDate'],
          });
        } else {
          // Check if doctor exists
          final doctorExists = await _verifyDoctorExists(doctorId);
          if (doctorExists) {
            summary['validDoctorId'] = (summary['validDoctorId'] as int) + 1;
          } else {
            summary['invalidDoctorId'] = (summary['invalidDoctorId'] as int) + 1;
            (summary['invalidAppointments'] as List).add({
              'id': doc.id,
              'doctorId': doctorId,
              'doctorName': doctorName,
              'patientName': data['patientName'],
              'appointmentDate': data['appointmentDate'],
            });
          }
        }
      }

      print('📊 Issues Summary:');
      print('  - Total Appointments: ${summary['totalAppointments']}');
      print('  - Valid Doctor ID: ${summary['validDoctorId']}');
      print('  - Missing Doctor ID: ${summary['missingDoctorId']}');
      print('  - Invalid Doctor ID: ${summary['invalidDoctorId']}');

      return summary;
    } catch (e) {
      print('❌ Error getting issues summary: $e');
      return {
        'error': e.toString(),
        'totalAppointments': 0,
        'missingDoctorId': 0,
        'invalidDoctorId': 0,
        'validDoctorId': 0,
      };
    }
  }
}