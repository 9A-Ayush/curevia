import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

/// Service for searching and fetching registered patients
class PatientSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search registered patients by name or email
  static Future<List<UserModel>> searchPatients({
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'patient')
          .where('isActive', isEqualTo: true)
          .limit(limit);

      final querySnapshot = await query.get();
      List<UserModel> patients = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply text search filter (client-side)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        patients = patients.where((patient) {
          final query = searchQuery.toLowerCase();
          return patient.fullName.toLowerCase().contains(query) ||
              patient.email.toLowerCase().contains(query) ||
              (patient.phoneNumber?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Sort by name
      patients.sort((a, b) => a.fullName.compareTo(b.fullName));

      return patients;
    } catch (e) {
      print('Error searching patients: $e');
      return [];
    }
  }

  /// Get patient by ID
  static Future<UserModel?> getPatientById(String patientId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['role'] == 'patient') {
          return UserModel.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting patient by ID: $e');
      return null;
    }
  }

  /// Get recent patients for a doctor (from appointments)
  static Future<List<UserModel>> getRecentPatients({
    required String doctorId,
    int limit = 10,
  }) async {
    try {
      // Get recent appointments for this doctor
      final appointmentsQuery = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('appointmentDate', descending: true)
          .limit(limit * 2) // Get more to account for duplicates
          .get();

      // Extract unique patient IDs
      final patientIds = <String>{};
      for (final doc in appointmentsQuery.docs) {
        final data = doc.data();
        final patientId = data['patientId'] as String?;
        if (patientId != null) {
          patientIds.add(patientId);
        }
      }

      // Fetch patient details
      final patients = <UserModel>[];
      for (final patientId in patientIds.take(limit)) {
        final patient = await getPatientById(patientId);
        if (patient != null) {
          patients.add(patient);
        }
      }

      return patients;
    } catch (e) {
      print('Error getting recent patients: $e');
      return [];
    }
  }

  /// Get all registered patients (for admin use)
  static Future<List<UserModel>> getAllPatients({
    int limit = 100,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'patient')
          .where('isActive', isEqualTo: true)
          .orderBy('fullName')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all patients: $e');
      return [];
    }
  }
}