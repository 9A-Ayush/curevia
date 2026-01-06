import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/medical_record_sharing_model.dart';
import '../models/medical_document_model.dart';
import '../models/appointment_model.dart';

/// Service for secure medical record sharing with strict access control
class SecureMedicalSharingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sharingCollection = 'medical_record_sharing';
  static const String _allergiesCollection = 'patient_allergies';
  static const String _medicationsCollection = 'patient_medications';
  static const String _accessLogCollection = 'record_access_logs';

  /// Create a secure sharing session for an appointment
  static Future<String> createSharingSession({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required List<String> selectedRecordIds,
    required List<String> selectedAllergies,
    required List<String> selectedMedications,
    required Map<String, dynamic> selectedVitals,
    DateTime? expirationTime,
  }) async {
    try {
      // Validate appointment exists and belongs to patient and doctor
      final appointment = await _validateAppointment(appointmentId, patientId, doctorId);
      if (appointment == null) {
        throw Exception('Invalid appointment or unauthorized access');
      }

      // Set expiration time (default: 24 hours after appointment)
      final expiresAt = expirationTime ?? appointment.appointmentDate.add(const Duration(hours: 24));

      // Create sharing record
      final sharing = MedicalRecordSharing(
        id: '', // Will be set by Firestore
        appointmentId: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        sharedRecordIds: selectedRecordIds,
        sharedAllergies: selectedAllergies,
        sharedMedications: selectedMedications,
        sharedVitals: selectedVitals,
        sharingStatus: 'active',
        sharedAt: DateTime.now(),
        expiresAt: expiresAt,
        accessLog: {},
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_sharingCollection)
          .add(sharing.toFirestore());

      // Log the sharing creation
      await _logAccess(
        sharingId: docRef.id,
        accessedBy: patientId,
        accessType: 'share_created',
        wasBlocked: false,
      );

      return docRef.id;
    } catch (e) {
      print('Error creating sharing session: $e');
      throw Exception('Failed to create sharing session: $e');
    }
  }

  /// Validate doctor access to shared records
  static Future<MedicalRecordSharing?> validateDoctorAccess({
    required String sharingId,
    required String doctorId,
    required String appointmentId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .get();

      if (!doc.exists) {
        await _logAccess(
          sharingId: sharingId,
          accessedBy: doctorId,
          accessType: 'access_denied',
          wasBlocked: true,
          blockReason: 'Sharing session not found',
        );
        return null;
      }

      final sharing = MedicalRecordSharing.fromFirestore(doc);

      // Validate access conditions
      if (!sharing.isValidForAccess) {
        await _logAccess(
          sharingId: sharingId,
          accessedBy: doctorId,
          accessType: 'access_denied',
          wasBlocked: true,
          blockReason: 'Sharing session expired or inactive',
        );
        return null;
      }

      if (sharing.doctorId != doctorId || sharing.appointmentId != appointmentId) {
        await _logAccess(
          sharingId: sharingId,
          accessedBy: doctorId,
          accessType: 'access_denied',
          wasBlocked: true,
          blockReason: 'Unauthorized doctor or appointment mismatch',
        );
        return null;
      }

      // Update access time
      await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .update({
        'accessedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log successful access
      await _logAccess(
        sharingId: sharingId,
        accessedBy: doctorId,
        accessType: 'view',
        wasBlocked: false,
      );

      return sharing;
    } catch (e) {
      print('Error validating doctor access: $e');
      return null;
    }
  }

  /// Get shared medical documents for a doctor
  static Future<List<MedicalDocument>> getSharedDocuments({
    required String sharingId,
    required String doctorId,
  }) async {
    try {
      final sharing = await validateDoctorAccess(
        sharingId: sharingId,
        doctorId: doctorId,
        appointmentId: '', // Will be validated in validateDoctorAccess
      );

      if (sharing == null) return [];

      if (sharing.sharedRecordIds.isEmpty) return [];

      // Get documents with additional security check
      final documents = <MedicalDocument>[];
      for (final recordId in sharing.sharedRecordIds) {
        try {
          final doc = await _firestore
              .collection('medical_documents')
              .doc(recordId)
              .get();

          if (doc.exists) {
            final document = MedicalDocument.fromFirestore(doc);
            // Double-check patient ownership
            if (document.patientId == sharing.patientId) {
              documents.add(document);
            }
          }
        } catch (e) {
          print('Error fetching document $recordId: $e');
        }
      }

      return documents;
    } catch (e) {
      print('Error getting shared documents: $e');
      return [];
    }
  }

  /// Get shared allergies for a doctor
  static Future<List<PatientAllergy>> getSharedAllergies({
    required String sharingId,
    required String doctorId,
  }) async {
    try {
      final sharing = await validateDoctorAccess(
        sharingId: sharingId,
        doctorId: doctorId,
        appointmentId: '',
      );

      if (sharing == null || sharing.sharedAllergies.isEmpty) return [];

      final allergies = <PatientAllergy>[];
      for (final allergyId in sharing.sharedAllergies) {
        try {
          final doc = await _firestore
              .collection(_allergiesCollection)
              .doc(allergyId)
              .get();

          if (doc.exists) {
            final allergy = PatientAllergy.fromFirestore(doc);
            if (allergy.patientId == sharing.patientId) {
              allergies.add(allergy);
            }
          }
        } catch (e) {
          print('Error fetching allergy $allergyId: $e');
        }
      }

      return allergies;
    } catch (e) {
      print('Error getting shared allergies: $e');
      return [];
    }
  }

  /// Get shared medications for a doctor
  static Future<List<PatientMedication>> getSharedMedications({
    required String sharingId,
    required String doctorId,
  }) async {
    try {
      final sharing = await validateDoctorAccess(
        sharingId: sharingId,
        doctorId: doctorId,
        appointmentId: '',
      );

      if (sharing == null || sharing.sharedMedications.isEmpty) return [];

      final medications = <PatientMedication>[];
      for (final medicationId in sharing.sharedMedications) {
        try {
          final doc = await _firestore
              .collection(_medicationsCollection)
              .doc(medicationId)
              .get();

          if (doc.exists) {
            final medication = PatientMedication.fromFirestore(doc);
            if (medication.patientId == sharing.patientId) {
              medications.add(medication);
            }
          }
        } catch (e) {
          print('Error fetching medication $medicationId: $e');
        }
      }

      return medications;
    } catch (e) {
      print('Error getting shared medications: $e');
      return [];
    }
  }

  /// Revoke sharing session
  static Future<void> revokeSharingSession({
    required String sharingId,
    required String revokedBy,
    String? reason,
  }) async {
    try {
      await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .update({
        'sharingStatus': 'revoked',
        'revokedAt': FieldValue.serverTimestamp(),
        'revokedBy': revokedBy,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logAccess(
        sharingId: sharingId,
        accessedBy: revokedBy,
        accessType: 'revoked',
        wasBlocked: false,
        blockReason: reason,
      );
    } catch (e) {
      print('Error revoking sharing session: $e');
      throw Exception('Failed to revoke sharing session: $e');
    }
  }

  /// Get sharing sessions for a patient
  static Future<List<MedicalRecordSharing>> getPatientSharingSessions({
    required String patientId,
    bool activeOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_sharingCollection)
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MedicalRecordSharing.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting patient sharing sessions: $e');
      return [];
    }
  }

  /// Get sharing sessions for a doctor
  static Future<List<MedicalRecordSharing>> getDoctorSharingSessions({
    required String doctorId,
    bool activeOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_sharingCollection)
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true);

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MedicalRecordSharing.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting doctor sharing sessions: $e');
      return [];
    }
  }

  /// Log access attempt (for security auditing)
  static Future<void> logSecurityEvent({
    required String sharingId,
    required String userId,
    required String eventType,
    String? details,
  }) async {
    await _logAccess(
      sharingId: sharingId,
      accessedBy: userId,
      accessType: eventType,
      wasBlocked: eventType.contains('blocked') || eventType.contains('denied'),
      blockReason: details,
    );
  }

  /// Get patient allergies
  static Future<List<PatientAllergy>> getPatientAllergies(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_allergiesCollection)
          .where('patientId', isEqualTo: patientId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PatientAllergy.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting patient allergies: $e');
      return [];
    }
  }

  /// Get patient medications
  static Future<List<PatientMedication>> getPatientMedications(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_medicationsCollection)
          .where('patientId', isEqualTo: patientId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PatientMedication.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting patient medications: $e');
      return [];
    }
  }

  /// Add patient allergy
  static Future<String> addPatientAllergy(PatientAllergy allergy) async {
    try {
      final docRef = await _firestore
          .collection(_allergiesCollection)
          .add(allergy.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding patient allergy: $e');
      throw Exception('Failed to add allergy: $e');
    }
  }

  /// Add patient medication
  static Future<String> addPatientMedication(PatientMedication medication) async {
    try {
      final docRef = await _firestore
          .collection(_medicationsCollection)
          .add(medication.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding patient medication: $e');
      throw Exception('Failed to add medication: $e');
    }
  }

  /// Private helper methods

  /// Validate appointment exists and matches patient/doctor
  static Future<AppointmentModel?> _validateAppointment(
    String appointmentId,
    String patientId,
    String doctorId,
  ) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!doc.exists) return null;

      final appointment = AppointmentModel.fromMap(doc.data()!);
      
      if (appointment.patientId != patientId || appointment.doctorId != doctorId) {
        return null;
      }

      return appointment;
    } catch (e) {
      print('Error validating appointment: $e');
      return null;
    }
  }

  /// Log access for security auditing
  static Future<void> _logAccess({
    required String sharingId,
    required String accessedBy,
    required String accessType,
    required bool wasBlocked,
    String? blockReason,
  }) async {
    try {
      final log = RecordAccessLog(
        id: '',
        sharingId: sharingId,
        accessedBy: accessedBy,
        accessType: accessType,
        accessTime: DateTime.now(),
        wasBlocked: wasBlocked,
        blockReason: blockReason,
      );

      await _firestore
          .collection(_accessLogCollection)
          .add(log.toFirestore());
    } catch (e) {
      print('Error logging access: $e');
    }
  }

  /// Generate secure hash for additional validation
  static String _generateSecureHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if sharing session has expired
  static Future<void> cleanupExpiredSessions() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_sharingCollection)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'sharingStatus': 'expired',
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('Cleaned up ${snapshot.docs.length} expired sharing sessions');
    } catch (e) {
      print('Error cleaning up expired sessions: $e');
    }
  }
}