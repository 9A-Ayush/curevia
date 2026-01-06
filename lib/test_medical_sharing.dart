import 'package:flutter/material.dart';
import 'services/medical_report_sharing_service.dart';
import 'models/medical_record_model.dart';

/// Test helper for medical report sharing functionality
class MedicalSharingTestHelper {
  /// Test sharing medical reports with a doctor
  static Future<void> testShareReports() async {
    try {
      print('🧪 Testing medical report sharing...');
      
      // Create sample medical records
      final sampleReports = [
        MedicalRecordModel(
          id: 'test_report_1',
          title: 'Blood Test Results',
          type: 'lab_test',
          recordDate: DateTime.now().subtract(const Duration(days: 7)),
          doctorName: 'Dr. Smith',
          hospitalName: 'City Hospital',
          diagnosis: 'Normal blood parameters',
          treatment: 'No treatment required',
          prescription: null,
          notes: 'All values within normal range',
          attachments: [],
          vitals: {},
          labResults: {
            'hemoglobin': '14.2 g/dL',
            'glucose': '95 mg/dL',
            'cholesterol': '180 mg/dL',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        MedicalRecordModel(
          id: 'test_report_2',
          title: 'Consultation Report',
          type: 'consultation',
          recordDate: DateTime.now().subtract(const Duration(days: 3)),
          doctorName: 'Dr. Johnson',
          hospitalName: 'General Hospital',
          diagnosis: 'Mild hypertension',
          treatment: 'Lifestyle modifications',
          prescription: 'Amlodipine 5mg once daily',
          notes: 'Follow up in 3 months',
          attachments: [],
          vitals: {
            'bloodPressure': '140/90 mmHg',
            'heartRate': '78 bpm',
            'temperature': '98.6°F',
          },
          labResults: {},
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

      // Test sharing with a sample doctor
      final sharingId = await MedicalReportSharingService.shareReportsWithDoctor(
        patientId: 'test_patient_123',
        patientName: 'John Doe',
        doctorId: 'test_doctor_456',
        selectedReportIds: sampleReports.map((r) => r.id).toList(),
        selectedAllergies: ['Penicillin', 'Shellfish'],
        patientVitals: {
          'height': 175.0,
          'weight': 70.0,
          'bloodGroup': 'O+',
          'age': 35,
        },
        message: 'Please review my recent medical reports for our upcoming consultation.',
        expirationTime: DateTime.now().add(const Duration(days: 7)),
      );

      if (sharingId != null) {
        print('✅ Medical reports shared successfully!');
        print('   Sharing ID: $sharingId');
        print('   Reports shared: ${sampleReports.length}');
        print('   Allergies shared: 2');
        print('   Expires in: 7 days');
        
        // Test getting sharing history
        await testGetSharingHistory('test_patient_123');
        
        // Test getting doctor's shared reports
        await testGetDoctorSharedReports('test_doctor_456');
        
      } else {
        print('❌ Failed to share medical reports');
      }
    } catch (e) {
      print('❌ Error testing medical report sharing: $e');
    }
  }

  /// Test getting patient sharing history
  static Future<void> testGetSharingHistory(String patientId) async {
    try {
      print('\n🔍 Testing sharing history retrieval...');
      
      final history = await MedicalReportSharingService.getPatientSharingHistory(patientId);
      
      print('✅ Retrieved sharing history successfully!');
      print('   Total sharing sessions: ${history.length}');
      
      for (final sharing in history) {
        print('   - Doctor: ${sharing['doctorName']}');
        print('     Status: ${sharing['sharingStatus']}');
        print('     Reports: ${(sharing['sharedReportIds'] as List?)?.length ?? 0}');
      }
    } catch (e) {
      print('❌ Error getting sharing history: $e');
    }
  }

  /// Test getting doctor's shared reports
  static Future<void> testGetDoctorSharedReports(String doctorId) async {
    try {
      print('\n👨‍⚕️ Testing doctor shared reports retrieval...');
      
      final sharedReports = await MedicalReportSharingService.getDoctorSharedReports(doctorId);
      
      print('✅ Retrieved doctor shared reports successfully!');
      print('   Total shared reports: ${sharedReports.length}');
      
      for (final sharing in sharedReports) {
        print('   - Patient: ${sharing['patientName']}');
        print('     Reports: ${(sharing['sharedReportIds'] as List?)?.length ?? 0}');
        print('     Viewed: ${sharing['viewedByDoctor'] ? 'Yes' : 'No'}');
      }
    } catch (e) {
      print('❌ Error getting doctor shared reports: $e');
    }
  }

  /// Test searching for doctors
  static Future<void> testSearchDoctors() async {
    try {
      print('\n🔍 Testing doctor search...');
      
      // Test getting all available doctors
      final allDoctors = await MedicalReportSharingService.getAvailableDoctors();
      print('✅ Found ${allDoctors.length} available doctors');
      
      // Test searching doctors
      final searchResults = await MedicalReportSharingService.searchDoctors('smith');
      print('✅ Search for "smith" returned ${searchResults.length} results');
      
      for (final doctor in searchResults.take(3)) {
        print('   - ${doctor.fullName} (${doctor.email})');
      }
    } catch (e) {
      print('❌ Error testing doctor search: $e');
    }
  }

  /// Test revoking sharing
  static Future<void> testRevokeSharing(String sharingId) async {
    try {
      print('\n🚫 Testing sharing revocation...');
      
      final success = await MedicalReportSharingService.revokeSharing(
        sharingId,
        'test_patient_123',
      );
      
      if (success) {
        print('✅ Sharing revoked successfully!');
      } else {
        print('❌ Failed to revoke sharing');
      }
    } catch (e) {
      print('❌ Error revoking sharing: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting Medical Report Sharing Tests...\n');
    
    await testShareReports();
    await testSearchDoctors();
    
    // Clean up expired sessions
    try {
      await MedicalReportSharingService.cleanupExpiredSharings();
      print('\n🧹 Cleanup completed successfully');
    } catch (e) {
      print('\n❌ Error during cleanup: $e');
    }
    
    print('\n✨ All tests completed!');
  }
}

/// Widget to test medical sharing functionality
class MedicalSharingTestWidget extends StatelessWidget {
  const MedicalSharingTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Sharing Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medical_services,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Medical Report Sharing Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test the medical report sharing functionality',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Running medical sharing tests...'),
                  ),
                );
                
                await MedicalSharingTestHelper.runAllTests();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tests completed! Check console for results.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}