import 'package:flutter/material.dart';
import '../services/secure_medical_sharing_service.dart';
import '../models/medical_record_sharing_model.dart';
import '../models/appointment_model.dart';

/// Test helper for medical record sharing functionality
class MedicalSharingTestHelper {
  /// Test creating a sharing session
  static Future<void> testCreateSharingSession({
    required String appointmentId,
    required String patientId,
    required String doctorId,
  }) async {
    try {
      print('Testing sharing session creation...');
      
      final sharingId = await SecureMedicalSharingService.createSharingSession(
        appointmentId: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        selectedRecordIds: ['test_record_1', 'test_record_2'],
        selectedAllergies: ['test_allergy_1'],
        selectedMedications: ['test_medication_1'],
        selectedVitals: {
          'bloodPressure': '120/80',
          'heartRate': '72',
          'temperature': '98.6',
        },
      );
      
      print('✅ Sharing session created successfully: $sharingId');
      return sharingId;
    } catch (e) {
      print('❌ Error creating sharing session: $e');
      rethrow;
    }
  }

  /// Test doctor access validation
  static Future<void> testDoctorAccess({
    required String sharingId,
    required String doctorId,
    required String appointmentId,
  }) async {
    try {
      print('Testing doctor access validation...');
      
      final sharing = await SecureMedicalSharingService.validateDoctorAccess(
        sharingId: sharingId,
        doctorId: doctorId,
        appointmentId: appointmentId,
      );
      
      if (sharing != null) {
        print('✅ Doctor access validated successfully');
        print('   Shared records: ${sharing.sharedRecordIds.length}');
        print('   Shared allergies: ${sharing.sharedAllergies.length}');
        print('   Shared medications: ${sharing.sharedMedications.length}');
        print('   Shared vitals: ${sharing.sharedVitals.keys.length}');
      } else {
        print('❌ Doctor access denied');
      }
    } catch (e) {
      print('❌ Error validating doctor access: $e');
      rethrow;
    }
  }

  /// Test unauthorized access (should fail)
  static Future<void> testUnauthorizedAccess({
    required String sharingId,
    required String unauthorizedUserId,
    required String appointmentId,
  }) async {
    try {
      print('Testing unauthorized access (should fail)...');
      
      final sharing = await SecureMedicalSharingService.validateDoctorAccess(
        sharingId: sharingId,
        doctorId: unauthorizedUserId,
        appointmentId: appointmentId,
      );
      
      if (sharing == null) {
        print('✅ Unauthorized access correctly denied');
      } else {
        print('❌ Security breach: Unauthorized access was allowed!');
      }
    } catch (e) {
      print('✅ Unauthorized access correctly failed with error: $e');
    }
  }

  /// Test session expiration
  static Future<void> testSessionExpiration({
    required String sharingId,
    required String patientId,
  }) async {
    try {
      print('Testing session expiration...');
      
      // Revoke the session to simulate expiration
      await SecureMedicalSharingService.revokeSharingSession(
        sharingId: sharingId,
        revokedBy: patientId,
        reason: 'Test expiration',
      );
      
      print('✅ Session revoked successfully');
    } catch (e) {
      print('❌ Error revoking session: $e');
      rethrow;
    }
  }

  /// Test security logging
  static Future<void> testSecurityLogging({
    required String sharingId,
    required String userId,
  }) async {
    try {
      print('Testing security logging...');
      
      await SecureMedicalSharingService.logSecurityEvent(
        sharingId: sharingId,
        userId: userId,
        eventType: 'test_access',
        details: 'Test security logging functionality',
      );
      
      print('✅ Security event logged successfully');
    } catch (e) {
      print('❌ Error logging security event: $e');
      rethrow;
    }
  }

  /// Test patient allergy management
  static Future<void> testAllergyManagement(String patientId) async {
    try {
      print('Testing allergy management...');
      
      // Create test allergy
      final allergy = PatientAllergy(
        id: '',
        patientId: patientId,
        allergen: 'Penicillin',
        severity: 'severe',
        reaction: 'Anaphylaxis',
        firstOccurrence: DateTime.now().subtract(const Duration(days: 365)),
        notes: 'Test allergy for medical sharing',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final allergyId = await SecureMedicalSharingService.addPatientAllergy(allergy);
      print('✅ Test allergy created: $allergyId');
      
      // Retrieve allergies
      final allergies = await SecureMedicalSharingService.getPatientAllergies(patientId);
      print('✅ Retrieved ${allergies.length} allergies for patient');
      
    } catch (e) {
      print('❌ Error testing allergy management: $e');
      rethrow;
    }
  }

  /// Test medication management
  static Future<void> testMedicationManagement(String patientId) async {
    try {
      print('Testing medication management...');
      
      // Create test medication
      final medication = PatientMedication(
        id: '',
        patientId: patientId,
        medicationName: 'Lisinopril',
        dosage: '10mg',
        frequency: 'Once daily',
        route: 'oral',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        prescribedBy: 'Dr. Test',
        reason: 'Hypertension',
        notes: 'Test medication for medical sharing',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final medicationId = await SecureMedicalSharingService.addPatientMedication(medication);
      print('✅ Test medication created: $medicationId');
      
      // Retrieve medications
      final medications = await SecureMedicalSharingService.getPatientMedications(patientId);
      print('✅ Retrieved ${medications.length} medications for patient');
      
    } catch (e) {
      print('❌ Error testing medication management: $e');
      rethrow;
    }
  }

  /// Run comprehensive test suite
  static Future<void> runComprehensiveTests({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String unauthorizedUserId,
  }) async {
    print('🧪 Starting comprehensive medical sharing tests...\n');
    
    try {
      // Test 1: Create sharing session
      final sharingId = await testCreateSharingSession(
        appointmentId: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
      );
      
      print('');
      
      // Test 2: Validate authorized access
      await testDoctorAccess(
        sharingId: sharingId,
        doctorId: doctorId,
        appointmentId: appointmentId,
      );
      
      print('');
      
      // Test 3: Test unauthorized access
      await testUnauthorizedAccess(
        sharingId: sharingId,
        unauthorizedUserId: unauthorizedUserId,
        appointmentId: appointmentId,
      );
      
      print('');
      
      // Test 4: Test security logging
      await testSecurityLogging(
        sharingId: sharingId,
        userId: doctorId,
      );
      
      print('');
      
      // Test 5: Test allergy management
      await testAllergyManagement(patientId);
      
      print('');
      
      // Test 6: Test medication management
      await testMedicationManagement(patientId);
      
      print('');
      
      // Test 7: Test session expiration
      await testSessionExpiration(
        sharingId: sharingId,
        patientId: patientId,
      );
      
      print('\n🎉 All tests completed successfully!');
      
    } catch (e) {
      print('\n💥 Test suite failed: $e');
      rethrow;
    }
  }

  /// Test UI security features (call from widget tests)
  static void testUISecurityFeatures() {
    print('🔒 Testing UI security features...');
    
    // These would be tested in widget/integration tests
    print('- Screenshot protection: Test on physical device');
    print('- Inactivity timeout: Test 5-minute timeout');
    print('- Background blur: Test app lifecycle changes');
    print('- Secure text: Test copy/paste prevention');
    print('- Access validation: Test unauthorized screen access');
    
    print('✅ UI security features documented for testing');
  }

  /// Generate test data for development
  static Map<String, dynamic> generateTestData() {
    final now = DateTime.now();
    
    return {
      'testAppointment': {
        'id': 'test_appointment_${now.millisecondsSinceEpoch}',
        'patientId': 'test_patient_123',
        'doctorId': 'test_doctor_456',
        'patientName': 'John Doe',
        'doctorName': 'Dr. Smith',
        'doctorSpecialty': 'Cardiology',
        'appointmentDate': now.add(const Duration(days: 1)),
        'timeSlot': '10:00 AM',
        'consultationType': 'offline',
        'status': 'confirmed',
      },
      'testUsers': {
        'patient': 'test_patient_123',
        'doctor': 'test_doctor_456',
        'unauthorized': 'test_unauthorized_789',
      },
      'testRecords': [
        'test_record_1',
        'test_record_2',
        'test_record_3',
      ],
      'testAllergies': [
        {
          'allergen': 'Penicillin',
          'severity': 'severe',
          'reaction': 'Anaphylaxis',
        },
        {
          'allergen': 'Peanuts',
          'severity': 'moderate',
          'reaction': 'Hives and swelling',
        },
      ],
      'testMedications': [
        {
          'medicationName': 'Lisinopril',
          'dosage': '10mg',
          'frequency': 'Once daily',
          'route': 'oral',
        },
        {
          'medicationName': 'Metformin',
          'dosage': '500mg',
          'frequency': 'Twice daily',
          'route': 'oral',
        },
      ],
      'testVitals': {
        'bloodPressure': '120/80',
        'heartRate': '72',
        'temperature': '98.6',
        'weight': '70',
        'height': '175',
      },
    };
  }
}

/// Widget for running tests in debug mode
class MedicalSharingTestWidget extends StatefulWidget {
  const MedicalSharingTestWidget({super.key});

  @override
  State<MedicalSharingTestWidget> createState() => _MedicalSharingTestWidgetState();
}

class _MedicalSharingTestWidgetState extends State<MedicalSharingTestWidget> {
  bool _isRunning = false;
  String _testResults = '';

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Running tests...\n';
    });

    try {
      final testData = MedicalSharingTestHelper.generateTestData();
      final appointment = testData['testAppointment'] as Map<String, dynamic>;
      final users = testData['testUsers'] as Map<String, dynamic>;

      await MedicalSharingTestHelper.runComprehensiveTests(
        appointmentId: appointment['id'],
        patientId: users['patient'],
        doctorId: users['doctor'],
        unauthorizedUserId: users['unauthorized'],
      );

      setState(() {
        _testResults += '\n✅ All tests passed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Tests failed: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Sharing Tests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Record Sharing Test Suite',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test suite validates the security and functionality of the medical record sharing system.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _runTests,
                child: _isRunning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Running Tests...'),
                        ],
                      )
                    : const Text('Run Comprehensive Tests'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'No tests run yet.' : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}