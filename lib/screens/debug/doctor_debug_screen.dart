import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase/doctor_service.dart';
import '../../services/doctor/secure_patient_data_service.dart';
import '../../constants/app_constants.dart';

class DoctorDebugScreen extends StatefulWidget {
  const DoctorDebugScreen({super.key});

  @override
  State<DoctorDebugScreen> createState() => _DoctorDebugScreenState();
}

class _DoctorDebugScreenState extends State<DoctorDebugScreen> {
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
        
        if (isActive == true) {
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

          if (needsUpdate) {
            updates['updatedAt'] = FieldValue.serverTimestamp();
            await FirebaseFirestore.instance
                .collection(AppConstants.doctorsCollection)
                .doc(doctor['id'])
                .update(updates);
            fixedCount++;
          }
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
}