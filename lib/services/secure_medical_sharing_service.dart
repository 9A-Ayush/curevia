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

      // Get documents from both medical_documents collection and user's medical_records subcollection
      final documents = <MedicalDocument>[];
      
      for (final recordId in sharing.sharedRecordIds) {
        try {
          // First try medical_documents collection
          var doc = await _firestore
              .collection('medical_documents')
              .doc(recordId)
              .get();

          if (doc.exists) {
            final document = MedicalDocument.fromFirestore(doc);
            // Double-check patient ownership
            if (document.patientId == sharing.patientId) {
              documents.add(document);
            }
          } else {
            // Try user's medical_records subcollection
            doc = await _firestore
                .collection('users')
                .doc(sharing.patientId)
                .collection('medical_records')
                .doc(recordId)
                .get();

            if (doc.exists) {
              final recordData = doc.data()!;
              
              // Convert medical record to medical document format
              final document = MedicalDocument(
                id: doc.id,
                patientId: sharing.patientId,
                fileName: recordData['title'] ?? 'Medical Record',
                originalFileName: recordData['title'] ?? 'Medical Record',
                fileUrl: recordData['attachments']?.isNotEmpty == true 
                    ? recordData['attachments'][0] 
                    : '',
                cloudinaryPublicId: recordData['cloudinaryPublicId'] ?? '',
                fileType: _getFileTypeFromUrl(recordData['attachments']?.isNotEmpty == true 
                    ? recordData['attachments'][0] 
                    : ''),
                documentType: _getDocumentTypeFromUrl(recordData['attachments']?.isNotEmpty == true 
                    ? recordData['attachments'][0] 
                    : ''),
                category: _getCategoryFromType(recordData['type'] ?? 'general'),
                description: recordData['notes'] ?? recordData['diagnosis'] ?? '',
                uploadedAt: recordData['recordDate'] != null 
                    ? (recordData['recordDate'] as Timestamp).toDate()
                    : recordData['createdAt'] != null
                        ? (recordData['createdAt'] as Timestamp).toDate()
                        : DateTime.now(),
                fileSizeBytes: 0, // Not available from medical records
                metadata: {
                  'type': recordData['type'] ?? 'general',
                  'doctorName': recordData['doctorName'] ?? '',
                  'diagnosis': recordData['diagnosis'] ?? '',
                  'treatment': recordData['treatment'] ?? '',
                  'prescription': recordData['prescription'] ?? '',
                },
              );
              
              documents.add(document);
            }
          }
        } catch (e) {
          print('Error fetching document $recordId: $e');
        }
      }

      // Sort by upload date (newest first)
      documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return documents;
    } catch (e) {
      print('Error getting shared documents: $e');
      return [];
    }
  }

  /// Helper method to determine document type from URL
  static DocumentType _getDocumentTypeFromUrl(String url) {
    if (url.isEmpty) return DocumentType.text;
    
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return DocumentType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return DocumentType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return DocumentType.video;
      case 'mp3':
      case 'wav':
      case 'aac':
        return DocumentType.audio;
      default:
        return DocumentType.text;
    }
  }

  /// Helper method to get category from medical record type
  static DocumentCategory _getCategoryFromType(String type) {
    switch (type.toLowerCase()) {
      case 'lab_report':
      case 'lab':
        return DocumentCategory.labReport;
      case 'prescription':
        return DocumentCategory.prescription;
      case 'imaging':
      case 'xray':
      case 'mri':
        return DocumentCategory.mri;
      case 'ct':
        return DocumentCategory.ctScan;
      case 'consultation':
      case 'checkup':
        return DocumentCategory.consultation;
      case 'vaccination':
        return DocumentCategory.vaccination;
      case 'discharge':
        return DocumentCategory.discharge;
      default:
        return DocumentCategory.general;
    }
  }

  /// Helper method to get file type from URL
  static String _getFileTypeFromUrl(String url) {
    if (url.isEmpty) return 'unknown';
    
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'pdf';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'aac':
        return 'audio';
      case 'txt':
      case 'doc':
      case 'docx':
        return 'document';
      default:
        return 'unknown';
    }
  }

  /// Helper method to get MIME type from URL
  static String _getMimeTypeFromUrl(String url) {
    if (url.isEmpty) return 'text/plain';
    
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
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

      if (sharing == null) return [];

      // Get all patient allergies (from profile and medical records)
      final allAllergies = await getPatientAllergies(sharing.patientId);
      
      // If specific allergies were selected, filter them
      if (sharing.sharedAllergies.isNotEmpty) {
        return allAllergies.where((allergy) => 
          sharing.sharedAllergies.contains(allergy.id) ||
          sharing.sharedAllergies.contains(allergy.allergen.toLowerCase())
        ).toList();
      }
      
      // If no specific selection, return all allergies
      return allAllergies;
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

      if (sharing == null) return [];

      // Get all patient medications (from medical records)
      final allMedications = await getPatientMedications(sharing.patientId);
      
      // If specific medications were selected, filter them
      if (sharing.sharedMedications.isNotEmpty) {
        return allMedications.where((medication) => 
          sharing.sharedMedications.contains(medication.id) ||
          sharing.sharedMedications.contains(medication.medicationName.toLowerCase())
        ).toList();
      }
      
      // If no specific selection, return all medications
      return allMedications;
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

  /// Get patient allergies - Extract from medical records and user profile
  static Future<List<PatientAllergy>> getPatientAllergies(String patientId) async {
    try {
      final allergies = <PatientAllergy>[];
      final allergenSet = <String>{}; // To avoid duplicates

      // Get allergies from user profile
      final userDoc = await _firestore
          .collection('users')
          .doc(patientId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final profileAllergies = List<String>.from(userData['allergies'] ?? []);
        
        for (final allergen in profileAllergies) {
          if (allergen.trim().isNotEmpty && !allergenSet.contains(allergen.toLowerCase())) {
            allergenSet.add(allergen.toLowerCase());
            allergies.add(PatientAllergy(
              id: 'profile_${allergen.hashCode}',
              patientId: patientId,
              allergen: allergen,
              severity: 'mild', // Default since not specified in profile
              reaction: 'Not specified',
              firstOccurrence: null,
              notes: 'From user profile',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }
        }
      }

      // Get allergies mentioned in medical records
      final medicalRecordsSnapshot = await _firestore
          .collection('users')
          .doc(patientId)
          .collection('medical_records')
          .orderBy('recordDate', descending: true)
          .limit(50) // Get recent records
          .get();

      for (final doc in medicalRecordsSnapshot.docs) {
        final data = doc.data();
        final notes = (data['notes'] ?? '').toString().toLowerCase();
        final diagnosis = (data['diagnosis'] ?? '').toString().toLowerCase();
        final treatment = (data['treatment'] ?? '').toString().toLowerCase();
        final prescription = (data['prescription'] ?? '').toString().toLowerCase();
        
        // Look for allergy mentions in medical records
        final allergyKeywords = ['allergy', 'allergic', 'reaction', 'intolerance', 'hypersensitive'];
        final commonAllergens = [
          'penicillin', 'amoxicillin', 'aspirin', 'ibuprofen', 'sulfa',
          'peanut', 'tree nut', 'shellfish', 'fish', 'egg', 'milk', 'soy', 'wheat',
          'latex', 'dust', 'pollen', 'mold', 'pet dander', 'bee sting',
          'codeine', 'morphine', 'contrast dye', 'iodine'
        ];
        
        final fullText = '$notes $diagnosis $treatment $prescription';
        
        // Check for explicit allergy mentions
        for (final allergen in commonAllergens) {
          if (fullText.contains(allergen) && 
              allergyKeywords.any((keyword) => fullText.contains(keyword)) &&
              !allergenSet.contains(allergen)) {
            
            allergenSet.add(allergen);
            final recordDate = data['recordDate'] != null 
                ? (data['recordDate'] as Timestamp).toDate()
                : data['createdAt'] != null
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now();
            
            // Determine severity based on context
            String severity = 'mild';
            if (fullText.contains('severe') || fullText.contains('anaphylaxis') || 
                fullText.contains('emergency') || fullText.contains('epipen')) {
              severity = 'severe';
            } else if (fullText.contains('moderate') || fullText.contains('swelling') ||
                       fullText.contains('difficulty breathing')) {
              severity = 'moderate';
            }
            
            allergies.add(PatientAllergy(
              id: '${doc.id}_$allergen',
              patientId: patientId,
              allergen: allergen.toUpperCase(),
              severity: severity,
              reaction: _extractReactionFromText(fullText, allergen),
              firstOccurrence: recordDate,
              notes: 'Found in medical record: ${data['title'] ?? 'Medical Record'}',
              isActive: true,
              createdAt: recordDate,
              updatedAt: recordDate,
            ));
          }
        }

        // Look for general allergy patterns
        final allergyPatterns = [
          RegExp(r'allergic to (\w+)', caseSensitive: false),
          RegExp(r'allergy: (\w+)', caseSensitive: false),
          RegExp(r'(\w+) allergy', caseSensitive: false),
          RegExp(r'reaction to (\w+)', caseSensitive: false),
        ];

        for (final pattern in allergyPatterns) {
          final matches = pattern.allMatches(fullText);
          for (final match in matches) {
            final allergen = match.group(1)?.toLowerCase() ?? '';
            if (allergen.length > 2 && !allergenSet.contains(allergen) &&
                !['the', 'and', 'for', 'with', 'was', 'had'].contains(allergen)) {
              
              allergenSet.add(allergen);
              final recordDate = data['recordDate'] != null 
                  ? (data['recordDate'] as Timestamp).toDate()
                  : DateTime.now();
              
              allergies.add(PatientAllergy(
                id: '${doc.id}_${allergen.hashCode}',
                patientId: patientId,
                allergen: allergen.toUpperCase(),
                severity: 'moderate',
                reaction: 'Mentioned in medical record',
                firstOccurrence: recordDate,
                notes: 'Extracted from: ${data['title'] ?? 'Medical Record'}',
                isActive: true,
                createdAt: recordDate,
                updatedAt: recordDate,
              ));
            }
          }
        }
      }

      // Sort by severity and date
      allergies.sort((a, b) {
        final severityOrder = {'severe': 0, 'moderate': 1, 'mild': 2};
        final aOrder = severityOrder[a.severity] ?? 3;
        final bOrder = severityOrder[b.severity] ?? 3;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return b.createdAt.compareTo(a.createdAt);
      });

      return allergies;
    } catch (e) {
      print('Error getting patient allergies: $e');
      return [];
    }
  }

  /// Helper method to extract reaction description from text
  static String _extractReactionFromText(String text, String allergen) {
    final reactions = [
      'rash', 'hives', 'swelling', 'itching', 'breathing difficulty',
      'nausea', 'vomiting', 'diarrhea', 'anaphylaxis', 'shock'
    ];
    
    final foundReactions = <String>[];
    for (final reaction in reactions) {
      if (text.contains(reaction)) {
        foundReactions.add(reaction);
      }
    }
    
    return foundReactions.isNotEmpty 
        ? foundReactions.join(', ')
        : 'Allergic reaction';
  }

  /// Get patient medications - Extract from medical records
  static Future<List<PatientMedication>> getPatientMedications(String patientId) async {
    try {
      final medications = <PatientMedication>[];
      final medicationSet = <String>{}; // To avoid duplicates

      // Get medications from medical records
      final medicalRecordsSnapshot = await _firestore
          .collection('users')
          .doc(patientId)
          .collection('medical_records')
          .where('type', whereIn: ['prescription', 'consultation', 'checkup', 'followup'])
          .orderBy('recordDate', descending: true)
          .limit(30) // Get recent records that might have prescriptions
          .get();

      for (final doc in medicalRecordsSnapshot.docs) {
        final data = doc.data();
        final prescription = data['prescription']?.toString() ?? '';
        final treatment = data['treatment']?.toString() ?? '';
        final notes = data['notes']?.toString() ?? '';
        final recordDate = data['recordDate'] != null 
            ? (data['recordDate'] as Timestamp).toDate()
            : data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now();
        final doctorName = data['doctorName'] ?? 'Unknown Doctor';
        
        // Parse prescription text for medications
        final medicationText = '$prescription $treatment $notes';
        if (medicationText.trim().isNotEmpty) {
          
          // Enhanced medication patterns
          final medicationPatterns = [
            // Pattern: "Medication 500mg twice daily"
            RegExp(r'(\w+)\s+(\d+\s*mg)\s+(.*?(?:daily|twice|once|morning|evening|night|bid|tid|qid))', caseSensitive: false),
            // Pattern: "Medication tablet twice daily"
            RegExp(r'(\w+)\s+tablet\s+(.*?(?:daily|twice|once|morning|evening|night|bid|tid|qid))', caseSensitive: false),
            // Pattern: "Medication 5ml three times"
            RegExp(r'(\w+)\s+(\d+\s*ml)\s+(.*?(?:daily|twice|once|times|morning|evening|night))', caseSensitive: false),
            // Pattern: "Take Medication as needed"
            RegExp(r'take\s+(\w+)\s+(.*?(?:needed|directed|prescribed))', caseSensitive: false),
            // Pattern: "Medication: dosage instructions"
            RegExp(r'(\w+):\s*([^,\n]+)', caseSensitive: false),
            // Pattern: "1. Medication - instructions"
            RegExp(r'\d+\.\s*(\w+)\s*[-–]\s*([^,\n]+)', caseSensitive: false),
          ];
          
          bool foundStructuredMedication = false;
          
          for (final pattern in medicationPatterns) {
            final matches = pattern.allMatches(medicationText);
            for (final match in matches) {
              final medicationName = match.group(1)?.trim() ?? '';
              final dosageOrInstructions = match.group(2)?.trim() ?? '';
              
              if (medicationName.length > 2 && 
                  !medicationSet.contains(medicationName.toLowerCase()) &&
                  !_isCommonWord(medicationName)) {
                
                medicationSet.add(medicationName.toLowerCase());
                foundStructuredMedication = true;
                
                // Parse dosage and frequency
                final parsedMedication = _parseMedicationDetails(dosageOrInstructions);
                
                medications.add(PatientMedication(
                  id: '${doc.id}_${medicationName.hashCode}',
                  patientId: patientId,
                  medicationName: medicationName,
                  dosage: parsedMedication['dosage'] ?? dosageOrInstructions,
                  frequency: parsedMedication['frequency'] ?? 'As directed',
                  route: parsedMedication['route'] ?? 'oral',
                  startDate: recordDate,
                  endDate: null, // Assume ongoing unless specified
                  prescribedBy: doctorName,
                  reason: data['diagnosis'] ?? 'As prescribed',
                  notes: 'From medical record: ${data['title'] ?? 'Medical Record'}',
                  isActive: true,
                  createdAt: recordDate,
                  updatedAt: recordDate,
                ));
              }
            }
          }
          
          // Look for common medication names even without structured format
          if (!foundStructuredMedication) {
            final commonMedications = [
              'paracetamol', 'acetaminophen', 'ibuprofen', 'aspirin', 'amoxicillin',
              'azithromycin', 'ciprofloxacin', 'metformin', 'insulin', 'omeprazole',
              'atorvastatin', 'amlodipine', 'lisinopril', 'metoprolol', 'warfarin',
              'prednisone', 'albuterol', 'levothyroxine', 'gabapentin', 'tramadol'
            ];
            
            for (final medName in commonMedications) {
              if (medicationText.toLowerCase().contains(medName) &&
                  !medicationSet.contains(medName)) {
                
                medicationSet.add(medName);
                medications.add(PatientMedication(
                  id: '${doc.id}_${medName.hashCode}',
                  patientId: patientId,
                  medicationName: medName.toUpperCase(),
                  dosage: 'As prescribed',
                  frequency: 'As directed',
                  route: 'oral',
                  startDate: recordDate,
                  endDate: null,
                  prescribedBy: doctorName,
                  reason: data['diagnosis'] ?? 'Medical treatment',
                  notes: 'Mentioned in: ${data['title'] ?? 'Medical Record'}',
                  isActive: true,
                  createdAt: recordDate,
                  updatedAt: recordDate,
                ));
              }
            }
          }
          
          // If still no structured medications found but prescription text exists, create a general entry
          if (!foundStructuredMedication && prescription.trim().isNotEmpty && prescription.length > 10) {
            final generalId = '${doc.id}_general';
            if (!medicationSet.contains(generalId)) {
              medicationSet.add(generalId);
              medications.add(PatientMedication(
                id: generalId,
                patientId: patientId,
                medicationName: 'Prescribed Medication',
                dosage: 'As prescribed',
                frequency: 'As directed',
                route: 'oral',
                startDate: recordDate,
                endDate: null,
                prescribedBy: doctorName,
                reason: data['diagnosis'] ?? 'Medical treatment',
                notes: prescription.length > 100 ? '${prescription.substring(0, 100)}...' : prescription,
                isActive: true,
                createdAt: recordDate,
                updatedAt: recordDate,
              ));
            }
          }
        }
      }

      // Sort by date (newest first)
      medications.sort((a, b) => b.startDate.compareTo(a.startDate));
      
      return medications;
    } catch (e) {
      print('Error getting patient medications: $e');
      return [];
    }
  }

  /// Helper method to check if a word is too common to be a medication
  static bool _isCommonWord(String word) {
    final commonWords = [
      'the', 'and', 'for', 'with', 'was', 'had', 'take', 'tablet', 'capsule',
      'daily', 'twice', 'once', 'morning', 'evening', 'night', 'after', 'before',
      'food', 'meal', 'water', 'dose', 'medication', 'medicine', 'drug', 'pill'
    ];
    return commonWords.contains(word.toLowerCase()) || word.length < 3;
  }

  /// Helper method to parse medication details from instruction text
  static Map<String, String> _parseMedicationDetails(String instructions) {
    final result = <String, String>{};
    final text = instructions.toLowerCase();
    
    // Extract dosage
    final dosagePattern = RegExp(r'(\d+\s*(?:mg|ml|g|mcg|units?))', caseSensitive: false);
    final dosageMatch = dosagePattern.firstMatch(text);
    if (dosageMatch != null) {
      result['dosage'] = dosageMatch.group(1) ?? '';
    }
    
    // Extract frequency
    if (text.contains('once') || text.contains('daily') && !text.contains('twice')) {
      result['frequency'] = 'Once daily';
    } else if (text.contains('twice') || text.contains('bid')) {
      result['frequency'] = 'Twice daily';
    } else if (text.contains('three times') || text.contains('tid')) {
      result['frequency'] = 'Three times daily';
    } else if (text.contains('four times') || text.contains('qid')) {
      result['frequency'] = 'Four times daily';
    } else if (text.contains('as needed') || text.contains('prn')) {
      result['frequency'] = 'As needed';
    } else if (text.contains('morning')) {
      result['frequency'] = 'Morning';
    } else if (text.contains('evening') || text.contains('night')) {
      result['frequency'] = 'Evening';
    }
    
    // Extract route
    if (text.contains('injection') || text.contains('inject')) {
      result['route'] = 'injection';
    } else if (text.contains('topical') || text.contains('apply')) {
      result['route'] = 'topical';
    } else if (text.contains('inhale') || text.contains('inhaler')) {
      result['route'] = 'inhalation';
    } else if (text.contains('drops') || text.contains('eye')) {
      result['route'] = 'ophthalmic';
    } else {
      result['route'] = 'oral';
    }
    
    return result;
  }

  /// Get patient vitals from profile and medical records
  static Future<Map<String, dynamic>> getPatientVitals(String patientId) async {
    try {
      final vitals = <String, dynamic>{};

      // Get vitals from user profile
      final userDoc = await _firestore
          .collection('users')
          .doc(patientId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        // Basic vitals from profile
        if (userData['height'] != null) {
          vitals['height'] = '${userData['height']} cm';
        }
        if (userData['weight'] != null) {
          vitals['weight'] = '${userData['weight']} kg';
        }
        if (userData['bloodType'] != null) {
          vitals['bloodType'] = userData['bloodType'];
        }
        if (userData['dateOfBirth'] != null) {
          final dob = (userData['dateOfBirth'] as Timestamp).toDate();
          final age = DateTime.now().difference(dob).inDays ~/ 365;
          vitals['age'] = '$age years';
        }
      }

      // Get recent vitals from medical records
      final medicalRecordsSnapshot = await _firestore
          .collection('users')
          .doc(patientId)
          .collection('medical_records')
          .orderBy('recordDate', descending: true)
          .limit(10)
          .get();

      for (final doc in medicalRecordsSnapshot.docs) {
        final data = doc.data();
        final recordVitals = data['vitals'] as Map<String, dynamic>? ?? {};
        
        // Add vitals from medical records (most recent takes precedence)
        for (final entry in recordVitals.entries) {
          if (!vitals.containsKey(entry.key) && entry.value != null) {
            vitals[entry.key] = entry.value;
          }
        }
        
        // Parse vitals from notes if structured vitals not available
        final notes = data['notes']?.toString() ?? '';
        if (notes.isNotEmpty) {
          final vitalPatterns = {
            'bloodPressure': RegExp(r'bp:?\s*(\d+/\d+)', caseSensitive: false),
            'heartRate': RegExp(r'hr:?\s*(\d+)', caseSensitive: false),
            'temperature': RegExp(r'temp:?\s*(\d+\.?\d*)', caseSensitive: false),
            'respiratoryRate': RegExp(r'rr:?\s*(\d+)', caseSensitive: false),
            'oxygenSaturation': RegExp(r'spo2:?\s*(\d+)%?', caseSensitive: false),
          };
          
          for (final entry in vitalPatterns.entries) {
            if (!vitals.containsKey(entry.key)) {
              final match = entry.value.firstMatch(notes);
              if (match != null) {
                vitals[entry.key] = match.group(1);
              }
            }
          }
        }
      }

      return vitals;
    } catch (e) {
      print('Error getting patient vitals: $e');
      return {};
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