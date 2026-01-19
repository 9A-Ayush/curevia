import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firebase/doctor_service.dart';
import '../../services/doctor/secure_patient_data_service.dart';
import '../../services/notifications/fcm_service.dart';
import '../../services/notifications/fcm_direct_service.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import 'appointment_debug_screen.dart';

class DoctorDebugScreen extends ConsumerStatefulWidget {
  const DoctorDebugScreen({super.key});

  @override
  ConsumerState<DoctorDebugScreen> createState() => _DoctorDebugScreenState();
}

class _DoctorDebugScreenState extends ConsumerState<DoctorDebugScreen> {
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _verifiedDoctors = [];
  bool _isLoading = false;
  String _debugOutput = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      // Get all doctors from database
      final allDocsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.doctorsCollection)
          .get();

      _allDoctors = allDocsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Get verified doctors using the service
      final verifiedDoctorModels = await DoctorService.getVerifiedDoctors();
      _verifiedDoctors = verifiedDoctorModels.map((doctor) => {
        'id': doctor.uid,
        'fullName': doctor.fullName,
        'specialty': doctor.specialty,
        'isVerified': doctor.isVerified,
        'verificationStatus': doctor.verificationStatus,
        'isActive': doctor.isActive,
      }).toList();

      _generateDebugOutput();
    } catch (e) {
      setState(() {
        _debugOutput = 'Error loading doctors: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateDebugOutput() {
    final buffer = StringBuffer();
    buffer.writeln('=== DOCTOR DEBUG REPORT ===\n');
    
    buffer.writeln('Total doctors in database: ${_allDoctors.length}');
    buffer.writeln('Verified doctors returned by service: ${_verifiedDoctors.length}\n');

    if (_allDoctors.isEmpty) {
      buffer.writeln('❌ NO DOCTORS FOUND IN DATABASE');
    } else {
      buffer.writeln('--- ALL DOCTORS IN DATABASE ---');
      for (int i = 0; i < _allDoctors.length; i++) {
        final doctor = _allDoctors[i];
        buffer.writeln('\n${i + 1}. ${doctor['fullName'] ?? 'Unknown'}');
        buffer.writeln('   ID: ${doctor['id']}');
        buffer.writeln('   Specialty: ${doctor['specialty'] ?? 'N/A'}');
        buffer.writeln('   isActive: ${doctor['isActive']}');
        buffer.writeln('   isVerified: ${doctor['isVerified']}');
        buffer.writeln('   verificationStatus: ${doctor['verificationStatus']}');
        
        // Check if this doctor would pass the filter
        final isActive = doctor['isActive'] == true;
        final isVerified = doctor['isVerified'] == true;
        final status = doctor['verificationStatus'];
        final passesFilter = isActive && 
                           isVerified && 
                           (status == 'verified' || status == 'approved');
        
        buffer.writeln('   Shows to patients: ${passesFilter ? '✅ YES' : '❌ NO'}');
        
        if (!passesFilter) {
          String reason = '';
          if (!isActive) reason = 'Not active';
          else if (!isVerified) reason = 'isVerified = false';
          else reason = 'Wrong verificationStatus ($status)';
          buffer.writeln('   Reason blocked: $reason');
        }
      }
    }

    setState(() {
      _debugOutput = buffer.toString();
    });
  }

  Future<void> _fixDoctorVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      int fixedCount = 0;
      final buffer = StringBuffer();
      buffer.writeln('=== FIXING DOCTOR VERIFICATION ===\n');

      for (final doctor in _allDoctors) {
        final status = doctor['verificationStatus'];
        final isVerified = doctor['isVerified'];
        final isActive = doctor['isActive'];
        
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Fix doctors that have verificationStatus = 'verified' but isVerified != true
        if (status == 'verified' && isVerified != true) {
          updates['isVerified'] = true;
          needsUpdate = true;
          buffer.writeln('Fixing ${doctor['fullName']}: setting isVerified = true');
        }
        
        // Fix doctors that have isVerified = true but wrong status
        if (isVerified == true && (status != 'verified' && status != 'approved')) {
          updates['verificationStatus'] = 'verified';
          needsUpdate = true;
          buffer.writeln('Fixing ${doctor['fullName']}: setting verificationStatus = verified');
        }

        // CRITICAL FIX: Set isActive = true for verified doctors that don't have it set
        if ((status == 'verified' || isVerified == true) && isActive != true) {
          updates['isActive'] = true;
          needsUpdate = true;
          buffer.writeln('Fixing ${doctor['fullName']}: setting isActive = true');
        }

        if (needsUpdate) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection(AppConstants.doctorsCollection)
              .doc(doctor['id'])
              .update(updates);
          fixedCount++;
        }
      }

      buffer.writeln('\nFixed $fixedCount doctors');
      buffer.writeln('=== FIX COMPLETE ===');

      setState(() {
        _debugOutput = buffer.toString();
      });

      // Reload doctors after fix
      await _loadDoctors();
    } catch (e) {
      setState(() {
        _debugOutput = 'Error fixing doctors: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DoctorService.createSampleDoctors();
      setState(() {
        _debugOutput = 'Sample doctors created successfully!';
      });
      await _loadDoctors();
    } catch (e) {
      setState(() {
        _debugOutput = 'Error creating sample doctors: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Debug'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loadDoctors,
                    child: const Text('Refresh Debug'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fixDoctorVerification,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Fix Verification'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createSampleDoctors,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Create Sample Doctors'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addSampleMedicalData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Add Sample Medical Data'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testFCMIntegration,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Test FCM Integration'),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _debugOutput.isEmpty ? 'Click "Refresh Debug" to start' : _debugOutput,
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

  Future<void> _addSampleMedicalData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use a sample patient ID - you can replace this with an actual patient ID
      const samplePatientId = 'pdsDFGlOtVhZY990h6fzj9zQmeH3'; // Replace with actual patient ID
      
      final buffer = StringBuffer();
      buffer.writeln('=== ADDING SAMPLE MEDICAL DATA ===\n');
      
      // Add sample vitals data
      await SecurePatientDataService.addSampleVitalsData(samplePatientId);
      buffer.writeln('✅ Added sample vitals data');
      
      // Add sample allergies data
      await SecurePatientDataService.addSampleAllergiesData(samplePatientId);
      buffer.writeln('✅ Added sample allergies data');
      
      // Add sample medications data
      await SecurePatientDataService.addSampleMedicationsData(samplePatientId);
      buffer.writeln('✅ Added sample medications data');
      
      buffer.writeln('\n=== SAMPLE DATA ADDED SUCCESSFULLY ===');
      buffer.writeln('Patient ID: $samplePatientId');
      buffer.writeln('\nNow you can test the secure patient medical viewer');
      buffer.writeln('with real data in the vitals, allergies, and medications tabs.');

      setState(() {
        _debugOutput = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _debugOutput = 'Error adding sample medical data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFCMIntegration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final buffer = StringBuffer();
      buffer.writeln('=== FCM INTEGRATION TEST ===\n');
      
      // Initialize FCM service if not already done
      if (!FCMService.instance.isInitialized) {
        buffer.writeln('🔄 Initializing FCM Service...');
        try {
          await FCMService.instance.initialize();
          buffer.writeln('✅ FCM Service initialized');
        } catch (e) {
          buffer.writeln('❌ FCM Service initialization failed: $e');
          buffer.writeln('This might be due to:');
          buffer.writeln('• Google Play Services not available');
          buffer.writeln('• Firebase configuration issues');
          buffer.writeln('• Network connectivity problems');
        }
      } else {
        buffer.writeln('✅ FCM Service already initialized');
      }
      
      // Try to get FCM token with retry logic
      String? fcmToken;
      for (int attempt = 1; attempt <= 3; attempt++) {
        buffer.writeln('\n🔄 Attempting to get FCM token (attempt $attempt/3)...');
        
        try {
          // First try to get current token
          fcmToken = FCMService.instance.fcmToken;
          
          // If null, try to get saved token
          if (fcmToken == null) {
            buffer.writeln('   Current token is null, checking saved token...');
            fcmToken = await FCMService.instance.getSavedFCMToken();
          }
          
          // If still null, try to force refresh
          if (fcmToken == null) {
            buffer.writeln('   No saved token, forcing FCM service refresh...');
            await FCMService.instance.initialize();
            await Future.delayed(Duration(seconds: 2));
            fcmToken = FCMService.instance.fcmToken;
          }
          
          if (fcmToken != null) {
            buffer.writeln('✅ FCM Token obtained successfully!');
            buffer.writeln('Token: ${fcmToken.substring(0, 20)}...');
            buffer.writeln('Full Token: $fcmToken');
            break;
          } else {
            buffer.writeln('❌ FCM Token is null (attempt $attempt)');
            if (attempt < 3) {
              buffer.writeln('⏳ Waiting 3 seconds before retry...');
              await Future.delayed(Duration(seconds: 3));
            }
          }
        } catch (e) {
          buffer.writeln('❌ Error getting FCM token (attempt $attempt): $e');
          if (attempt < 3) {
            buffer.writeln('⏳ Waiting 3 seconds before retry...');
            await Future.delayed(Duration(seconds: 3));
          }
        }
      }
      
      if (fcmToken != null) {
        // Test backend connectivity
        buffer.writeln('\n🔄 Testing backend connectivity...');
        try {
          final healthStatus = await FCMDirectService.getServiceHealth();
          if (healthStatus != null) {
            buffer.writeln('✅ Backend service is running');
            buffer.writeln('Status: ${healthStatus['status']}');
            
            // Test FCM token validation
            buffer.writeln('\n🔄 Testing FCM token validation...');
            final isValid = await FCMDirectService.validateFCMToken(fcmToken);
            buffer.writeln('Token validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');
            
            // Test sending notification
            buffer.writeln('\n🔄 Sending test notification...');
            final success = await FCMDirectService.sendTestNotification(
              fcmToken: fcmToken,
              title: '🧪 FCM Test from Flutter',
              body: 'This is a test notification sent from the debug screen!',
              data: {'test': 'true', 'source': 'debug_screen'},
              channelId: 'test_notifications',
              sound: 'default',
            );
            
            if (success) {
              buffer.writeln('✅ Test notification sent successfully!');
              buffer.writeln('📱 Check your device for the notification.');
            } else {
              buffer.writeln('❌ Failed to send test notification');
              buffer.writeln('Check backend logs for more details.');
            }
            
            buffer.writeln('\n=== FCM INTEGRATION TEST COMPLETE ===');
            buffer.writeln('✅ FCM Service: Working');
            buffer.writeln('✅ Backend Integration: Working');
            buffer.writeln('✅ Token Validation: ${isValid ? 'Working' : 'Failed'}');
            buffer.writeln('✅ Notification Sending: ${success ? 'Working' : 'Failed'}');
            
          } else {
            buffer.writeln('❌ Backend service not reachable');
            buffer.writeln('Make sure email service is running on localhost:3000');
            buffer.writeln('\n📋 Your FCM Token (copy this for manual testing):');
            buffer.writeln(fcmToken);
            buffer.writeln('\n🔧 Manual Test Command:');
            buffer.writeln('curl -X POST http://localhost:3000/test-fcm \\');
            buffer.writeln('  -H "Content-Type: application/json" \\');
            buffer.writeln('  -d \'{"fcmToken":"$fcmToken","title":"Test","body":"Hello!"}\'');
          }
        } catch (e) {
          buffer.writeln('❌ Backend connectivity test failed: $e');
          buffer.writeln('\n📋 Your FCM Token (copy this for manual testing):');
          buffer.writeln(fcmToken);
          buffer.writeln('\n🔧 Manual Test Command:');
          buffer.writeln('curl -X POST http://localhost:3000/test-fcm \\');
          buffer.writeln('  -H "Content-Type: application/json" \\');
          buffer.writeln('  -d \'{"fcmToken":"$fcmToken","title":"Test","body":"Hello!"}\'');
        }
        
      } else {
        buffer.writeln('\n❌ Failed to get FCM token after 3 attempts');
        buffer.writeln('\n🔧 Troubleshooting Steps:');
        buffer.writeln('1. Check if Google Play Services is installed and updated');
        buffer.writeln('2. Ensure device has internet connectivity');
        buffer.writeln('3. Check if Firebase project is properly configured');
        buffer.writeln('4. Verify google-services.json is in android/app/');
        buffer.writeln('5. Try restarting the app');
        buffer.writeln('\n📋 Alternative Testing:');
        buffer.writeln('You can test the backend with a dummy token:');
        buffer.writeln('curl -X POST http://localhost:3000/validate-fcm-token \\');
        buffer.writeln('  -H "Content-Type: application/json" \\');
        buffer.writeln('  -d \'{"fcmToken":"dummy_token"}\'');
      }

      setState(() {
        _debugOutput = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _debugOutput = 'Error testing FCM integration: $e\n\nThis might be due to:\n• Google Play Services not available\n• Firebase configuration issues\n• Network connectivity problems\n\nTry restarting the app or check your internet connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}