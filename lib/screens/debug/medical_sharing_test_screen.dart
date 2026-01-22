import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../utils/medical_sharing_diagnostic.dart';
import '../../services/secure_medical_sharing_service.dart';

/// Debug screen for testing enhanced medical sharing functionality
class MedicalSharingTestScreen extends ConsumerStatefulWidget {
  const MedicalSharingTestScreen({super.key});

  @override
  ConsumerState<MedicalSharingTestScreen> createState() => _MedicalSharingTestScreenState();
}

class _MedicalSharingTestScreenState extends ConsumerState<MedicalSharingTestScreen> {
  final _patientIdController = TextEditingController();
  final _doctorIdController = TextEditingController();
  final _appointmentIdController = TextEditingController();
  
  bool _isLoading = false;
  String _output = '';
  
  @override
  void initState() {
    super.initState();
    _initializeWithCurrentUser();
  }
  
  void _initializeWithCurrentUser() {
    final user = ref.read(currentUserModelProvider);
    if (user != null) {
      if (user.role == 'patient') {
        _patientIdController.text = user.uid;
      } else if (user.role == 'doctor') {
        _doctorIdController.text = user.uid;
      }
    }
  }
  
  @override
  void dispose() {
    _patientIdController.dispose();
    _doctorIdController.dispose();
    _appointmentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Medical Sharing Test'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Parameters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _patientIdController,
                      decoration: const InputDecoration(
                        labelText: 'Patient ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _doctorIdController,
                      decoration: const InputDecoration(
                        labelText: 'Doctor ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _appointmentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Appointment ID (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Tests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testAllergies,
                          icon: const Icon(Icons.warning, size: 18),
                          label: const Text('Test Allergies'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testMedications,
                          icon: const Icon(Icons.medication, size: 18),
                          label: const Text('Test Medications'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testVitals,
                          icon: const Icon(Icons.favorite, size: 18),
                          label: const Text('Test Vitals'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testFullDiagnostic,
                          icon: const Icon(Icons.analytics, size: 18),
                          label: const Text('Full Diagnostic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testDataExtraction,
                          icon: const Icon(Icons.data_exploration, size: 18),
                          label: const Text('Data Extraction'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Output
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Test Output',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _clearOutput,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear Output',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                              _output.isEmpty ? 'Test output will appear here...' : _output,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _clearOutput() {
    setState(() {
      _output = '';
    });
  }
  
  void _addOutput(String text) {
    setState(() {
      _output += '$text\n';
    });
  }
  
  Future<void> _testAllergies() async {
    if (_patientIdController.text.isEmpty) {
      _showError('Please enter a Patient ID');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addOutput('🔍 Testing Patient Allergies...');
      
      final allergies = await SecureMedicalSharingService.getPatientAllergies(
        _patientIdController.text,
      );
      
      _addOutput('✅ Found ${allergies.length} allergies:');
      
      for (final allergy in allergies) {
        _addOutput('  - ${allergy.allergen} (${allergy.severity})');
        _addOutput('    Reaction: ${allergy.reaction}');
        _addOutput('    Notes: ${allergy.notes ?? 'None'}');
        _addOutput('');
      }
      
      if (allergies.isEmpty) {
        _addOutput('ℹ️ No allergies found for this patient');
      }
      
    } catch (e) {
      _addOutput('❌ Error testing allergies: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testMedications() async {
    if (_patientIdController.text.isEmpty) {
      _showError('Please enter a Patient ID');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addOutput('🔍 Testing Patient Medications...');
      
      final medications = await SecureMedicalSharingService.getPatientMedications(
        _patientIdController.text,
      );
      
      _addOutput('✅ Found ${medications.length} medications:');
      
      for (final medication in medications) {
        _addOutput('  - ${medication.medicationName}');
        _addOutput('    Dosage: ${medication.dosage}');
        _addOutput('    Frequency: ${medication.frequency}');
        _addOutput('    Route: ${medication.route}');
        _addOutput('    Prescribed by: ${medication.prescribedBy}');
        _addOutput('');
      }
      
      if (medications.isEmpty) {
        _addOutput('ℹ️ No medications found for this patient');
      }
      
    } catch (e) {
      _addOutput('❌ Error testing medications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testVitals() async {
    if (_patientIdController.text.isEmpty) {
      _showError('Please enter a Patient ID');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addOutput('🔍 Testing Patient Vitals...');
      
      final vitals = await SecureMedicalSharingService.getPatientVitals(
        _patientIdController.text,
      );
      
      _addOutput('✅ Found ${vitals.length} vital signs:');
      
      for (final vital in vitals.entries) {
        _addOutput('  - ${vital.key}: ${vital.value}');
      }
      
      if (vitals.isEmpty) {
        _addOutput('ℹ️ No vitals found for this patient');
      }
      
    } catch (e) {
      _addOutput('❌ Error testing vitals: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testFullDiagnostic() async {
    if (_patientIdController.text.isEmpty || _doctorIdController.text.isEmpty) {
      _showError('Please enter both Patient ID and Doctor ID');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addOutput('🔍 Running Full Medical Sharing Diagnostic...');
      
      // Capture print output
      final originalPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addOutput(message);
        }
      };
      
      await MedicalSharingDiagnostic.runDiagnostics(
        patientId: _patientIdController.text,
        doctorId: _doctorIdController.text,
        appointmentId: _appointmentIdController.text.isEmpty 
            ? 'test_appointment_${DateTime.now().millisecondsSinceEpoch}'
            : _appointmentIdController.text,
      );
      
      // Restore original print
      debugPrint = originalPrint;
      
    } catch (e) {
      _addOutput('❌ Error running full diagnostic: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testDataExtraction() async {
    if (_patientIdController.text.isEmpty) {
      _showError('Please enter a Patient ID');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      _addOutput('🔍 Testing Data Extraction Patterns...');
      
      // Capture print output
      final originalPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addOutput(message);
        }
      };
      
      await MedicalSharingDiagnostic.testDataExtraction(
        _patientIdController.text,
      );
      
      // Restore original print
      debugPrint = originalPrint;
      
    } catch (e) {
      _addOutput('❌ Error testing data extraction: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}