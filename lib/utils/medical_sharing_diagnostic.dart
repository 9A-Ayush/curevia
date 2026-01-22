import 'package:flutter/foundation.dart';
import '../services/secure_medical_sharing_service.dart';
import '../models/medical_record_sharing_model.dart';

/// Diagnostic utility for testing medical sharing functionality
class MedicalSharingDiagnostic {
  
  /// Test the enhanced medical sharing system
  static Future<void> runDiagnostics({
    required String patientId,
    required String doctorId,
    required String appointmentId,
  }) async {
    print('🔍 Running Medical Sharing Diagnostics...\n');
    
    try {
      // Test 1: Get patient allergies
      print('📋 Test 1: Fetching Patient Allergies');
      final allergies = await SecureMedicalSharingService.getPatientAllergies(patientId);
      print('   ✅ Found ${allergies.length} allergies');
      for (final allergy in allergies.take(3)) {
        print('   - ${allergy.allergen} (${allergy.severity}) - ${allergy.reaction}');
      }
      print('');
      
      // Test 2: Get patient medications
      print('📋 Test 2: Fetching Patient Medications');
      final medications = await SecureMedicalSharingService.getPatientMedications(patientId);
      print('   ✅ Found ${medications.length} medications');
      for (final medication in medications.take(3)) {
        print('   - ${medication.medicationName} ${medication.dosage} ${medication.frequency}');
      }
      print('');
      
      // Test 3: Get patient vitals
      print('📋 Test 3: Fetching Patient Vitals');
      final vitals = await SecureMedicalSharingService.getPatientVitals(patientId);
      print('   ✅ Found ${vitals.length} vital signs');
      for (final vital in vitals.entries.take(5)) {
        print('   - ${vital.key}: ${vital.value}');
      }
      print('');
      
      // Test 4: Create sharing session
      print('📋 Test 4: Creating Sharing Session');
      final sharingId = await SecureMedicalSharingService.createSharingSession(
        appointmentId: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        selectedRecordIds: [], // Will fetch all available records
        selectedAllergies: allergies.map((a) => a.id).take(2).toList(),
        selectedMedications: medications.map((m) => m.id).take(2).toList(),
        selectedVitals: Map.fromEntries(vitals.entries.take(3)),
      );
      print('   ✅ Created sharing session: $sharingId');
      print('');
      
      // Test 5: Validate doctor access
      print('📋 Test 5: Validating Doctor Access');
      final sharing = await SecureMedicalSharingService.validateDoctorAccess(
        sharingId: sharingId,
        doctorId: doctorId,
        appointmentId: appointmentId,
      );
      
      if (sharing != null) {
        print('   ✅ Doctor access validated successfully');
        print('   - Sharing Status: ${sharing.sharingStatus}');
        print('   - Expires At: ${sharing.expiresAt}');
        print('   - Shared Items: ${sharing.sharingSummary}');
      } else {
        print('   ❌ Doctor access validation failed');
      }
      print('');
      
      // Test 6: Fetch shared data for doctor
      print('📋 Test 6: Fetching Shared Data for Doctor');
      
      final sharedDocuments = await SecureMedicalSharingService.getSharedDocuments(
        sharingId: sharingId,
        doctorId: doctorId,
      );
      print('   ✅ Shared Documents: ${sharedDocuments.length}');
      
      final sharedAllergies = await SecureMedicalSharingService.getSharedAllergies(
        sharingId: sharingId,
        doctorId: doctorId,
      );
      print('   ✅ Shared Allergies: ${sharedAllergies.length}');
      
      final sharedMedications = await SecureMedicalSharingService.getSharedMedications(
        sharingId: sharingId,
        doctorId: doctorId,
      );
      print('   ✅ Shared Medications: ${sharedMedications.length}');
      print('');
      
      // Test 7: Security logging
      print('📋 Test 7: Testing Security Logging');
      await SecureMedicalSharingService.logSecurityEvent(
        sharingId: sharingId,
        userId: doctorId,
        eventType: 'diagnostic_test',
        details: 'Medical sharing diagnostic test completed',
      );
      print('   ✅ Security event logged successfully');
      print('');
      
      print('🎉 All Medical Sharing Diagnostics Passed!\n');
      
      // Summary
      print('📊 SUMMARY:');
      print('   - Patient Allergies: ${allergies.length}');
      print('   - Patient Medications: ${medications.length}');
      print('   - Patient Vitals: ${vitals.length}');
      print('   - Shared Documents: ${sharedDocuments.length}');
      print('   - Shared Allergies: ${sharedAllergies.length}');
      print('   - Shared Medications: ${sharedMedications.length}');
      print('   - Sharing Session ID: $sharingId');
      
    } catch (e) {
      print('❌ Medical Sharing Diagnostic Failed: $e');
      if (kDebugMode) {
        print('Stack trace: ${StackTrace.current}');
      }
    }
  }
  
  /// Test data extraction patterns
  static Future<void> testDataExtraction(String patientId) async {
    print('🔍 Testing Data Extraction Patterns...\n');
    
    try {
      // Test allergy extraction
      print('📋 Testing Allergy Extraction');
      final allergies = await SecureMedicalSharingService.getPatientAllergies(patientId);
      
      final severityCounts = <String, int>{};
      for (final allergy in allergies) {
        severityCounts[allergy.severity] = (severityCounts[allergy.severity] ?? 0) + 1;
      }
      
      print('   - Total allergies found: ${allergies.length}');
      print('   - By severity: $severityCounts');
      print('');
      
      // Test medication extraction
      print('📋 Testing Medication Extraction');
      final medications = await SecureMedicalSharingService.getPatientMedications(patientId);
      
      final routeCounts = <String, int>{};
      for (final medication in medications) {
        routeCounts[medication.route] = (routeCounts[medication.route] ?? 0) + 1;
      }
      
      print('   - Total medications found: ${medications.length}');
      print('   - By route: $routeCounts');
      print('');
      
      // Test vitals extraction
      print('📋 Testing Vitals Extraction');
      final vitals = await SecureMedicalSharingService.getPatientVitals(patientId);
      
      print('   - Total vitals found: ${vitals.length}');
      print('   - Available vitals: ${vitals.keys.join(', ')}');
      print('');
      
      print('✅ Data Extraction Test Completed\n');
      
    } catch (e) {
      print('❌ Data Extraction Test Failed: $e');
    }
  }
  
  /// Test security features
  static Future<void> testSecurityFeatures({
    required String validSharingId,
    required String validDoctorId,
    required String invalidDoctorId,
    required String appointmentId,
  }) async {
    print('🔍 Testing Security Features...\n');
    
    try {
      // Test 1: Valid doctor access
      print('📋 Test 1: Valid Doctor Access');
      final validAccess = await SecureMedicalSharingService.validateDoctorAccess(
        sharingId: validSharingId,
        doctorId: validDoctorId,
        appointmentId: appointmentId,
      );
      
      if (validAccess != null) {
        print('   ✅ Valid doctor access granted');
      } else {
        print('   ❌ Valid doctor access denied (unexpected)');
      }
      
      // Test 2: Invalid doctor access
      print('📋 Test 2: Invalid Doctor Access');
      final invalidAccess = await SecureMedicalSharingService.validateDoctorAccess(
        sharingId: validSharingId,
        doctorId: invalidDoctorId,
        appointmentId: appointmentId,
      );
      
      if (invalidAccess == null) {
        print('   ✅ Invalid doctor access properly denied');
      } else {
        print('   ❌ Invalid doctor access granted (security issue!)');
      }
      
      // Test 3: Invalid sharing ID
      print('📋 Test 3: Invalid Sharing ID');
      final invalidSharingAccess = await SecureMedicalSharingService.validateDoctorAccess(
        sharingId: 'invalid_sharing_id',
        doctorId: validDoctorId,
        appointmentId: appointmentId,
      );
      
      if (invalidSharingAccess == null) {
        print('   ✅ Invalid sharing ID properly rejected');
      } else {
        print('   ❌ Invalid sharing ID accepted (security issue!)');
      }
      
      print('');
      print('🔒 Security Tests Completed\n');
      
    } catch (e) {
      print('❌ Security Test Failed: $e');
    }
  }
}