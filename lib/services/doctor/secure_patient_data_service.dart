import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/patient_medical_data_model.dart';
import '../../models/medical_record_model.dart';
import '../../models/medical_record_sharing_model.dart';
import '../../models/appointment_model.dart';
import '../../constants/app_constants.dart';
import '../../utils/firestore_index_helper.dart';

/// Secure service for doctors to view patient medical data in real-time
/// Implements strict access controls and audit logging
class SecurePatientDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _accessLogCollection = 'doctor_access_logs';
  static const String _vitalsCollection = 'patient_vitals';
  static const String _allergiesCollection = 'patient_allergies';
  static const String _medicationsCollection = 'patient_medications';

  /// Get real-time patient medical data stream for authorized doctor
  static Stream<PatientMedicalData?> getPatientMedicalDataStream({
    required String doctorId,
    required String patientId,
    required String appointmentId,
  }) async* {
    try {
      // Validate doctor authorization first
      final isAuthorized = await _validateDoctorAccess(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
      );

      if (!isAuthorized) {
        await _logUnauthorizedAccess(doctorId, patientId, appointmentId);
        yield null;
        return;
      }

      // Log authorized access
      await _logAuthorizedAccess(doctorId, patientId, appointmentId);

      // Create combined stream of all patient data
      yield* _createCombinedPatientDataStream(patientId, doctorId);

    } catch (e) {
      debugPrint('Error in getPatientMedicalDataStream: $e');
      yield null;
    }
  }

  /// Get patient medical records stream (real-time)
  static Stream<List<MedicalRecordModel>> getPatientMedicalRecordsStream({
    required String doctorId,
    required String patientId,
    required String appointmentId,
  }) async* {
    try {
      final isAuthorized = await _validateDoctorAccess(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
      );

      if (!isAuthorized) {
        yield [];
        return;
      }

      yield* _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .collection('medical_records')
          .orderBy('recordDate', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
              .toList());

    } catch (e) {
      debugPrint('Error getting medical records stream: $e');
      yield [];
    }
  }

  /// Get patient allergies stream (real-time) - Extract from medical records and user profile
  static Stream<List<PatientAllergy>> getPatientAllergiesStream({
    required String doctorId,
    required String patientId,
    required String appointmentId,
  }) async* {
    try {
      final isAuthorized = await _validateDoctorAccess(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
      );

      if (!isAuthorized) {
        yield [];
        return;
      }

      // Get allergies from user profile and medical records - same source as medical records
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      final allergies = <PatientAllergy>[];

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        // Get allergies from user profile
        final profileAllergies = List<String>.from(userData['allergies'] ?? []);
        for (final allergen in profileAllergies) {
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

      // Get allergies mentioned in medical records
      yield* _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .collection('medical_records')
          .orderBy('recordDate', descending: true)
          .snapshots()
          .map((snapshot) {
            final recordAllergies = List<PatientAllergy>.from(allergies);
            
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final notes = (data['notes'] ?? '').toString().toLowerCase();
              final diagnosis = (data['diagnosis'] ?? '').toString().toLowerCase();
              final treatment = (data['treatment'] ?? '').toString().toLowerCase();
              
              // Look for allergy mentions in medical records
              final allergyKeywords = ['allergy', 'allergic', 'reaction', 'intolerance'];
              final commonAllergens = ['penicillin', 'peanut', 'shellfish', 'latex', 'dust', 'pollen'];
              
              for (final allergen in commonAllergens) {
                final fullText = '$notes $diagnosis $treatment';
                if (fullText.contains(allergen) && 
                    allergyKeywords.any((keyword) => fullText.contains(keyword))) {
                  
                  // Check if we already have this allergen
                  final exists = recordAllergies.any((a) => 
                    a.allergen.toLowerCase().contains(allergen));
                  
                  if (!exists) {
                    final recordDate = (data['recordDate'] as Timestamp).toDate();
                    recordAllergies.add(PatientAllergy(
                      id: '${doc.id}_$allergen',
                      patientId: patientId,
                      allergen: allergen.toUpperCase(),
                      severity: 'moderate', // Assume moderate if mentioned in medical record
                      reaction: 'Mentioned in medical record',
                      firstOccurrence: recordDate,
                      notes: 'Found in medical record: ${data['title'] ?? 'Medical Record'}',
                      isActive: true,
                      createdAt: recordDate,
                      updatedAt: recordDate,
                    ));
                  }
                }
              }
            }
            
            // Sort by severity and date
            recordAllergies.sort((a, b) {
              final severityOrder = {'severe': 0, 'moderate': 1, 'mild': 2};
              final aOrder = severityOrder[a.severity] ?? 3;
              final bOrder = severityOrder[b.severity] ?? 3;
              if (aOrder != bOrder) return aOrder.compareTo(bOrder);
              return b.createdAt.compareTo(a.createdAt);
            });
            
            return recordAllergies;
          });

    } catch (e) {
      if (FirestoreIndexHelper.isIndexError(e)) {
        FirestoreIndexHelper.logIndexError(
          e.toString(),
          context: 'Patient Allergies Stream from Medical Records',
        );
      }
      debugPrint('Error getting allergies from medical records: $e');
      yield [];
    }
  }

  /// Create allergies from user profile data
  static Future<List<PatientAllergy>> _createAllergiesFromUserProfile(String patientId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final allergiesList = List<String>.from(userData['allergies'] ?? []);

      return allergiesList.map((allergen) => PatientAllergy(
        id: 'profile_allergy_${allergen.hashCode}',
        patientId: patientId,
        allergen: allergen,
        severity: 'mild', // Default severity since not specified in profile
        reaction: 'Not specified',
        firstOccurrence: null,
        notes: 'From user profile',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
    } catch (e) {
      debugPrint('Error creating allergies from user profile: $e');
      return [];
    }
  }

  /// Get patient current medications stream (real-time) - Extract from medical records
  static Stream<List<PatientMedication>> getPatientMedicationsStream({
    required String doctorId,
    required String patientId,
    required String appointmentId,
  }) async* {
    try {
      final isAuthorized = await _validateDoctorAccess(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
      );

      if (!isAuthorized) {
        yield [];
        return;
      }

      // Get medications from medical records - same source as medical records
      yield* _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .collection('medical_records')
          .where('type', whereIn: ['prescription', 'consultation', 'checkup'])
          .orderBy('recordDate', descending: true)
          .limit(20) // Get recent records that might have prescriptions
          .snapshots()
          .map((snapshot) {
            final medications = <PatientMedication>[];
            
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final prescription = data['prescription']?.toString() ?? '';
              final treatment = data['treatment']?.toString() ?? '';
              final notes = data['notes']?.toString() ?? '';
              final recordDate = (data['recordDate'] as Timestamp).toDate();
              final doctorName = data['doctorName'] ?? 'Unknown Doctor';
              
              // Parse prescription text for medications
              final medicationText = '$prescription $treatment $notes';
              if (medicationText.trim().isNotEmpty) {
                
                // Common medication patterns
                final medicationPatterns = [
                  RegExp(r'(\w+)\s+(\d+\s*mg)\s+(.*?(?:daily|twice|once|morning|evening|night))', caseSensitive: false),
                  RegExp(r'(\w+)\s+tablet\s+(.*?(?:daily|twice|once))', caseSensitive: false),
                  RegExp(r'(\w+)\s+(\d+\s*ml)\s+(.*?(?:daily|twice|once))', caseSensitive: false),
                ];
                
                for (final pattern in medicationPatterns) {
                  final matches = pattern.allMatches(medicationText);
                  for (final match in matches) {
                    final medicationName = match.group(1) ?? '';
                    final dosage = match.group(2) ?? '';
                    final frequency = match.group(3) ?? '';
                    
                    if (medicationName.length > 2) { // Filter out very short matches
                      medications.add(PatientMedication(
                        id: '${doc.id}_${medicationName.hashCode}',
                        patientId: patientId,
                        medicationName: medicationName,
                        dosage: dosage,
                        frequency: frequency,
                        route: 'oral', // Default
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
                
                // If no structured medications found, create a general entry
                if (medications.isEmpty && prescription.trim().isNotEmpty) {
                  medications.add(PatientMedication(
                    id: '${doc.id}_general',
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
            
            // Remove duplicates and sort by date
            final uniqueMedications = <String, PatientMedication>{};
            for (final med in medications) {
              final key = '${med.medicationName}_${med.dosage}';
              if (!uniqueMedications.containsKey(key) || 
                  uniqueMedications[key]!.startDate.isBefore(med.startDate)) {
                uniqueMedications[key] = med;
              }
            }
            
            final result = uniqueMedications.values.toList();
            result.sort((a, b) => b.startDate.compareTo(a.startDate));
            
            return result;
          });

    } catch (e) {
      if (FirestoreIndexHelper.isIndexError(e)) {
        FirestoreIndexHelper.logIndexError(
          e.toString(),
          context: 'Patient Medications Stream from Medical Records',
        );
      }
      debugPrint('Error getting medications from medical records: $e');
      yield [];
    }
  }

  /// Get patient vitals stream (real-time) - Extract from medical records
  static Stream<List<PatientVitals>> getPatientVitalsStream({
    required String doctorId,
    required String patientId,
    required String appointmentId,
    int limit = 10,
  }) async* {
    try {
      final isAuthorized = await _validateDoctorAccess(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
      );

      if (!isAuthorized) {
        yield [];
        return;
      }

      // Get vitals from medical records - same source as medical records
      yield* _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .collection('medical_records')
          .orderBy('recordDate', descending: true)
          .limit(limit * 2) // Get more records to filter for vitals
          .snapshots()
          .map((snapshot) {
            final vitals = <PatientVitals>[];
            
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final vitalsData = Map<String, dynamic>.from(data['vitals'] ?? {});
              
              if (vitalsData.isNotEmpty) {
                // Convert medical record vitals to PatientVitals model
                final recordDate = (data['recordDate'] as Timestamp).toDate();
                final doctorName = data['doctorName'] ?? 'Unknown Doctor';
                
                final patientVital = PatientVitals(
                  id: '${doc.id}_vitals',
                  patientId: patientId,
                  systolicBP: _parseDouble(vitalsData['systolicBP'] ?? vitalsData['bloodPressureSystolic']),
                  diastolicBP: _parseDouble(vitalsData['diastolicBP'] ?? vitalsData['bloodPressureDiastolic']),
                  heartRate: _parseInt(vitalsData['heartRate'] ?? vitalsData['pulse']),
                  temperature: _parseDouble(vitalsData['temperature']),
                  weight: _parseDouble(vitalsData['weight']),
                  height: _parseDouble(vitalsData['height']),
                  respiratoryRate: _parseInt(vitalsData['respiratoryRate'] ?? vitalsData['respiration']),
                  oxygenSaturation: _parseDouble(vitalsData['oxygenSaturation'] ?? vitalsData['spo2']),
                  bloodSugar: _parseDouble(vitalsData['bloodSugar'] ?? vitalsData['glucose']),
                  notes: 'From medical record: ${data['title'] ?? 'Medical Record'}',
                  recordedBy: doctorName,
                  recordedAt: recordDate,
                  createdAt: recordDate,
                );
                
                vitals.add(patientVital);
              }
            }
            
            // Sort by date and limit
            vitals.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
            return vitals.take(limit).toList();
          });

    } catch (e) {
      if (FirestoreIndexHelper.isIndexError(e)) {
        FirestoreIndexHelper.logIndexError(
          e.toString(),
          context: 'Patient Vitals Stream from Medical Records',
        );
      }
      debugPrint('Error getting vitals from medical records: $e');
      yield [];
    }
  }

  /// Create vitals from user profile data
  static Future<PatientVitals?> _createVitalsFromUserProfile(String patientId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final height = userData['height']?.toDouble();
      final weight = userData['weight']?.toDouble();

      // Only create vitals if we have some basic data
      if (height == null && weight == null) return null;

      return PatientVitals(
        id: 'profile_vitals_${DateTime.now().millisecondsSinceEpoch}',
        patientId: patientId,
        height: height,
        weight: weight,
        // Set other vitals to null since they're not in user profile
        systolicBP: null,
        diastolicBP: null,
        heartRate: null,
        temperature: null,
        respiratoryRate: null,
        oxygenSaturation: null,
        bloodSugar: null,
        notes: 'Basic vitals from user profile',
        recordedBy: 'system',
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating vitals from user profile: $e');
      return null;
    }
  }

  /// Get patient basic info (one-time fetch with authorization)
  static Future<PatientBasicInfo?> getPatientBasicInfo({
    required String doctorId,
    required String patientId,
    required String appointmentId,
  }) async {
    try {
      final isAuthorized = await _validateDoctorAccess(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
      );

      if (!isAuthorized) return null;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return PatientBasicInfo.fromMap(data);

    } catch (e) {
      debugPrint('Error getting patient basic info: $e');
      return null;
    }
  }

  /// Add new patient vitals (doctor can record during consultation)
  static Future<String?> addPatientVitals({
    required String doctorId,
    required String patientId,
    required String appointmentId,
    required PatientVitals vitals,
  }) async {
    try {
      final isAuthorized = await _validateDoctorAccess(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
      );

      if (!isAuthorized) return null;

      final vitalsData = vitals.toMap();
      vitalsData['recordedBy'] = doctorId;
      vitalsData['recordedAt'] = Timestamp.fromDate(DateTime.now());
      vitalsData['createdAt'] = Timestamp.fromDate(DateTime.now());

      final docRef = await _firestore
          .collection(_vitalsCollection)
          .add(vitalsData);

      await _logDataModification(
        doctorId: doctorId,
        patientId: patientId,
        appointmentId: appointmentId,
        action: 'add_vitals',
        recordId: docRef.id,
      );

      return docRef.id;

    } catch (e) {
      debugPrint('Error adding patient vitals: $e');
      return null;
    }
  }

  /// Get doctor's access history for a patient
  static Future<List<DoctorAccessLog>> getDoctorAccessHistory({
    required String doctorId,
    required String patientId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_accessLogCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .orderBy('accessTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DoctorAccessLog.fromFirestore(doc))
          .toList();

    } catch (e) {
      debugPrint('Error getting access history: $e');
      return [];
    }
  }

  /// Validate if doctor has authorized access to patient data
  static Future<bool> _validateDoctorAccess({
    required String doctorId,
    required String patientId,
    required String appointmentId,
  }) async {
    try {
      // Check if appointment exists and is valid
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) return false;

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);
      
      // Validate appointment belongs to doctor and patient
      if (appointment.doctorId != doctorId || appointment.patientId != patientId) {
        return false;
      }

      // Check if appointment is within valid timeframe (24 hours before to 24 hours after)
      final now = DateTime.now();
      final appointmentTime = appointment.appointmentDate;
      final validFrom = appointmentTime.subtract(const Duration(hours: 24));
      final validUntil = appointmentTime.add(const Duration(hours: 24));

      if (now.isBefore(validFrom) || now.isAfter(validUntil)) {
        return false;
      }

      // Check appointment status
      final validStatuses = ['confirmed', 'in_progress', 'completed'];
      if (!validStatuses.contains(appointment.status)) {
        return false;
      }

      return true;

    } catch (e) {
      debugPrint('Error validating doctor access: $e');
      return false;
    }
  }

  /// Create combined real-time stream of all patient data
  static Stream<PatientMedicalData> _createCombinedPatientDataStream(
    String patientId,
    String doctorId,
  ) async* {
    try {
      // Get patient basic info first
      final patientDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      if (!patientDoc.exists) return;

      final patientData = patientDoc.data()!;
      final basicInfo = PatientBasicInfo.fromMap(patientData);

      // Get all data from medical records - single source of truth
      await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
        try {
          // Get medical records
          final medicalRecordsSnapshot = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(patientId)
              .collection('medical_records')
              .orderBy('recordDate', descending: true)
              .limit(20)
              .get();

          final medicalRecords = medicalRecordsSnapshot.docs
              .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
              .toList();

          // Extract vitals from medical records
          final vitalsHistory = <PatientVitals>[];
          for (final record in medicalRecords) {
            if (record.hasVitals) {
              final vitals = record.vitals;
              vitalsHistory.add(PatientVitals(
                id: '${record.id}_vitals',
                patientId: patientId,
                systolicBP: _parseDouble(vitals['systolicBP'] ?? vitals['bloodPressureSystolic']),
                diastolicBP: _parseDouble(vitals['diastolicBP'] ?? vitals['bloodPressureDiastolic']),
                heartRate: _parseInt(vitals['heartRate'] ?? vitals['pulse']),
                temperature: _parseDouble(vitals['temperature']),
                weight: _parseDouble(vitals['weight']),
                height: _parseDouble(vitals['height']),
                respiratoryRate: _parseInt(vitals['respiratoryRate']),
                oxygenSaturation: _parseDouble(vitals['oxygenSaturation']),
                bloodSugar: _parseDouble(vitals['bloodSugar']),
                notes: 'From ${record.title}',
                recordedBy: record.doctorName ?? 'Unknown',
                recordedAt: record.recordDate,
                createdAt: record.recordDate,
              ));
            }
          }

          // Extract allergies from user profile
          final allergies = <PatientAllergy>[];
          final profileAllergies = List<String>.from(patientData['allergies'] ?? []);
          for (final allergen in profileAllergies) {
            allergies.add(PatientAllergy(
              id: 'profile_${allergen.hashCode}',
              patientId: patientId,
              allergen: allergen,
              severity: 'mild',
              reaction: 'Not specified',
              firstOccurrence: null,
              notes: 'From user profile',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }

          // Extract medications from medical records
          final medications = <PatientMedication>[];
          for (final record in medicalRecords.where((r) => 
              r.prescription != null && r.prescription!.isNotEmpty)) {
            medications.add(PatientMedication(
              id: '${record.id}_medication',
              patientId: patientId,
              medicationName: 'Prescribed Medication',
              dosage: 'As prescribed',
              frequency: 'As directed',
              route: 'oral',
              startDate: record.recordDate,
              endDate: null,
              prescribedBy: record.doctorName ?? 'Unknown',
              reason: record.diagnosis ?? 'Medical treatment',
              notes: record.prescription!.length > 100 
                  ? '${record.prescription!.substring(0, 100)}...' 
                  : record.prescription!,
              isActive: true,
              createdAt: record.recordDate,
              updatedAt: record.recordDate,
            ));
          }

          // Create combined data model
          final combinedData = PatientMedicalData(
            patientId: patientId,
            patientName: patientData['fullName'] ?? 'Unknown Patient',
            profileImageUrl: patientData['profileImageUrl'],
            basicInfo: basicInfo,
            medicalRecords: medicalRecords,
            allergies: allergies,
            currentMedications: medications,
            latestVitals: vitalsHistory.isNotEmpty ? vitalsHistory.first : null,
            vitalsHistory: vitalsHistory,
            lastUpdated: DateTime.now(),
          );

          yield combinedData;
          
          // Break after first yield to avoid infinite loop
          break;

        } catch (e) {
          debugPrint('Error in combined stream: $e');
        }
      }

    } catch (e) {
      debugPrint('Error creating combined stream: $e');
    }
  }

  /// Log authorized access
  static Future<void> _logAuthorizedAccess(
    String doctorId,
    String patientId,
    String appointmentId,
  ) async {
    try {
      await _firestore.collection(_accessLogCollection).add({
        'doctorId': doctorId,
        'patientId': patientId,
        'appointmentId': appointmentId,
        'accessType': 'authorized_view',
        'accessTime': FieldValue.serverTimestamp(),
        'wasAuthorized': true,
        'deviceInfo': 'Flutter App',
      });
    } catch (e) {
      debugPrint('Error logging authorized access: $e');
    }
  }

  /// Log unauthorized access attempt
  static Future<void> _logUnauthorizedAccess(
    String doctorId,
    String patientId,
    String appointmentId,
  ) async {
    try {
      await _firestore.collection(_accessLogCollection).add({
        'doctorId': doctorId,
        'patientId': patientId,
        'appointmentId': appointmentId,
        'accessType': 'unauthorized_attempt',
        'accessTime': FieldValue.serverTimestamp(),
        'wasAuthorized': false,
        'blockReason': 'Invalid appointment or access outside allowed timeframe',
        'deviceInfo': 'Flutter App',
      });
    } catch (e) {
      debugPrint('Error logging unauthorized access: $e');
    }
  }

  /// Log data modification
  static Future<void> _logDataModification({
    required String doctorId,
    required String patientId,
    required String appointmentId,
    required String action,
    required String recordId,
  }) async {
    try {
      await _firestore.collection(_accessLogCollection).add({
        'doctorId': doctorId,
        'patientId': patientId,
        'appointmentId': appointmentId,
        'accessType': action,
        'recordId': recordId,
        'accessTime': FieldValue.serverTimestamp(),
        'wasAuthorized': true,
        'deviceInfo': 'Flutter App',
      });
    } catch (e) {
      debugPrint('Error logging data modification: $e');
    }
  }

  /// Clean up expired access logs (call periodically)
  static Future<void> cleanupExpiredAccessLogs() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _firestore
          .collection(_accessLogCollection)
          .where('accessTime', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} expired access logs');

    } catch (e) {
      debugPrint('Error cleaning up access logs: $e');
    }
  }

  /// Helper method to parse double values from dynamic data
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Try to parse string like "120/80" for blood pressure
      if (value.contains('/')) {
        final parts = value.split('/');
        if (parts.isNotEmpty) {
          return double.tryParse(parts[0].trim());
        }
      }
      return double.tryParse(value);
    }
    return null;
  }

  /// Helper method to parse int values from dynamic data
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Add sample vitals data for testing (development only)
  static Future<void> addSampleVitalsData(String patientId) async {
    try {
      final sampleVitals = [
        {
          'patientId': patientId,
          'systolicBP': 120.0,
          'diastolicBP': 80.0,
          'heartRate': 72,
          'temperature': 98.6,
          'weight': 70.0,
          'height': 175.0,
          'respiratoryRate': 16,
          'oxygenSaturation': 98.0,
          'bloodSugar': 95.0,
          'notes': 'Normal vitals - routine checkup',
          'recordedBy': 'Dr. Sample',
          'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        },
        {
          'patientId': patientId,
          'systolicBP': 118.0,
          'diastolicBP': 78.0,
          'heartRate': 68,
          'temperature': 98.4,
          'weight': 69.5,
          'height': 175.0,
          'respiratoryRate': 15,
          'oxygenSaturation': 99.0,
          'bloodSugar': 92.0,
          'notes': 'Excellent vitals - follow-up visit',
          'recordedBy': 'Dr. Sample',
          'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        },
        {
          'patientId': patientId,
          'systolicBP': 125.0,
          'diastolicBP': 82.0,
          'heartRate': 75,
          'temperature': 98.8,
          'weight': 70.2,
          'height': 175.0,
          'respiratoryRate': 17,
          'oxygenSaturation': 97.0,
          'bloodSugar': 98.0,
          'notes': 'Slightly elevated BP - monitor',
          'recordedBy': 'Dr. Sample',
          'recordedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 14))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 14))),
        },
      ];

      for (final vitals in sampleVitals) {
        await _firestore.collection(_vitalsCollection).add(vitals);
      }

      debugPrint('Sample vitals data added for patient: $patientId');
    } catch (e) {
      debugPrint('Error adding sample vitals data: $e');
    }
  }

  /// Add sample allergies data for testing (development only)
  static Future<void> addSampleAllergiesData(String patientId) async {
    try {
      final sampleAllergies = [
        {
          'patientId': patientId,
          'allergen': 'Penicillin',
          'severity': 'severe',
          'reaction': 'Skin rash and difficulty breathing',
          'firstOccurrence': Timestamp.fromDate(DateTime(2020, 5, 15)),
          'notes': 'Avoid all penicillin-based antibiotics',
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        {
          'patientId': patientId,
          'allergen': 'Peanuts',
          'severity': 'moderate',
          'reaction': 'Hives and swelling',
          'firstOccurrence': Timestamp.fromDate(DateTime(2018, 3, 10)),
          'notes': 'Carry EpiPen when eating out',
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        {
          'patientId': patientId,
          'allergen': 'Dust mites',
          'severity': 'mild',
          'reaction': 'Sneezing and runny nose',
          'firstOccurrence': Timestamp.fromDate(DateTime(2019, 8, 22)),
          'notes': 'Seasonal symptoms, manageable with antihistamines',
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      ];

      for (final allergy in sampleAllergies) {
        await _firestore.collection(_allergiesCollection).add(allergy);
      }

      debugPrint('Sample allergies data added for patient: $patientId');
    } catch (e) {
      debugPrint('Error adding sample allergies data: $e');
    }
  }

  /// Add sample medications data for testing (development only)
  static Future<void> addSampleMedicationsData(String patientId) async {
    try {
      final sampleMedications = [
        {
          'patientId': patientId,
          'medicationName': 'Lisinopril',
          'dosage': '10mg',
          'frequency': 'Once daily',
          'route': 'oral',
          'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
          'endDate': null, // Ongoing
          'prescribedBy': 'Dr. Smith',
          'reason': 'High blood pressure',
          'notes': 'Take with food to avoid stomach upset',
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        {
          'patientId': patientId,
          'medicationName': 'Metformin',
          'dosage': '500mg',
          'frequency': 'Twice daily',
          'route': 'oral',
          'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
          'endDate': null, // Ongoing
          'prescribedBy': 'Dr. Johnson',
          'reason': 'Type 2 diabetes',
          'notes': 'Monitor blood sugar levels regularly',
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        {
          'patientId': patientId,
          'medicationName': 'Vitamin D3',
          'dosage': '1000 IU',
          'frequency': 'Once daily',
          'route': 'oral',
          'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 90))),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
          'prescribedBy': 'Dr. Wilson',
          'reason': 'Vitamin D deficiency',
          'notes': 'Take with meals for better absorption',
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      ];

      for (final medication in sampleMedications) {
        await _firestore.collection(_medicationsCollection).add(medication);
      }

      debugPrint('Sample medications data added for patient: $patientId');
    } catch (e) {
      debugPrint('Error adding sample medications data: $e');
    }
  }
}

/// Doctor access log model
class DoctorAccessLog {
  final String id;
  final String doctorId;
  final String patientId;
  final String appointmentId;
  final String accessType;
  final DateTime accessTime;
  final bool wasAuthorized;
  final String? blockReason;
  final String? recordId;
  final String? deviceInfo;

  const DoctorAccessLog({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.appointmentId,
    required this.accessType,
    required this.accessTime,
    required this.wasAuthorized,
    this.blockReason,
    this.recordId,
    this.deviceInfo,
  });

  factory DoctorAccessLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorAccessLog(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      accessType: data['accessType'] ?? '',
      accessTime: (data['accessTime'] as Timestamp).toDate(),
      wasAuthorized: data['wasAuthorized'] ?? false,
      blockReason: data['blockReason'],
      recordId: data['recordId'],
      deviceInfo: data['deviceInfo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'appointmentId': appointmentId,
      'accessType': accessType,
      'accessTime': Timestamp.fromDate(accessTime),
      'wasAuthorized': wasAuthorized,
      'blockReason': blockReason,
      'recordId': recordId,
      'deviceInfo': deviceInfo,
    };
  }
}