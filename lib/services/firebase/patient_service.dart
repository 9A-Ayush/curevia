import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

/// Patient service for Firestore operations
class PatientService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get patient by ID
  static Future<PatientModel?> getPatientById(String patientId) async {
    try {
      // First get the user document
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final userModel = UserModel.fromMap(userData);

      // If not a patient, return null
      if (userModel.role != 'patient') return null;

      // Try to get patient-specific data
      final patientDoc = await _firestore
          .collection(AppConstants.patientsCollection)
          .doc(patientId)
          .get();

      if (patientDoc.exists) {
        // Patient data exists, create PatientModel
        final patientData = patientDoc.data()!;
        return PatientModel.fromUserModel(userModel, patientData);
      } else {
        // No patient data, create basic PatientModel from UserModel
        return PatientModel(
          uid: userModel.uid,
          email: userModel.email,
          fullName: userModel.fullName,
          role: userModel.role,
          phoneNumber: userModel.phoneNumber,
          profileImageUrl: userModel.profileImageUrl,
          createdAt: userModel.createdAt,
          updatedAt: userModel.updatedAt,
          isActive: userModel.isActive,
          isVerified: userModel.isVerified,
          additionalInfo: userModel.additionalInfo,
        );
      }
    } catch (e) {
      throw Exception('Failed to get patient: $e');
    }
  }

  /// Update patient data
  static Future<void> updatePatient(PatientModel patient) async {
    try {
      // Update user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patient.uid)
          .update({
        'fullName': patient.fullName,
        'phoneNumber': patient.phoneNumber,
        'profileImageUrl': patient.profileImageUrl,
        'updatedAt': Timestamp.fromDate(patient.updatedAt),
        'additionalInfo': patient.additionalInfo,
      });

      // Update/create patient-specific document
      final patientData = {
        'dateOfBirth': patient.dateOfBirth != null 
            ? Timestamp.fromDate(patient.dateOfBirth!) 
            : null,
        'gender': patient.gender,
        'bloodGroup': patient.bloodGroup,
        'height': patient.height,
        'weight': patient.weight,
        'allergies': patient.allergies,
        'medicalHistory': patient.medicalHistory,
        'emergencyContactName': patient.emergencyContactName,
        'emergencyContactPhone': patient.emergencyContactPhone,
        'address': patient.address,
        'city': patient.city,
        'state': patient.state,
        'pincode': patient.pincode,
        'updatedAt': Timestamp.fromDate(patient.updatedAt),
      };

      await _firestore
          .collection(AppConstants.patientsCollection)
          .doc(patient.uid)
          .set(patientData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  /// Create patient profile
  static Future<void> createPatientProfile({
    required String userId,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      final patientData = {
        'dateOfBirth': dateOfBirth != null 
            ? Timestamp.fromDate(dateOfBirth) 
            : null,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'height': height,
        'weight': weight,
        'allergies': allergies ?? [],
        'medicalHistory': medicalHistory ?? [],
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore
          .collection(AppConstants.patientsCollection)
          .doc(userId)
          .set(patientData);
    } catch (e) {
      throw Exception('Failed to create patient profile: $e');
    }
  }

  /// Get patient's family members
  static Future<List<PatientModel>> getFamilyMembers(String patientId) async {
    try {
      // This would typically involve a family_members collection
      // For now, return empty list
      return [];
    } catch (e) {
      throw Exception('Failed to get family members: $e');
    }
  }

  /// Add family member
  static Future<void> addFamilyMember({
    required String patientId,
    required String memberName,
    required String relationship,
    String? memberPhone,
    String? memberEmail,
  }) async {
    try {
      // Implementation for adding family members
      // This would involve a family_members collection
    } catch (e) {
      throw Exception('Failed to add family member: $e');
    }
  }
}
