import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../models/appointment_model.dart';
import '../../models/medical_document_model.dart';
import '../../models/medical_record_sharing_model.dart';
import '../../services/secure_medical_sharing_service.dart';
import '../../services/cloudinary/medical_document_service.dart';
import '../../providers/auth_provider.dart';

/// Screen for selecting medical records to share during appointment booking
class MedicalRecordSelectionScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  final VoidCallback? onSharingComplete;

  const MedicalRecordSelectionScreen({
    super.key,
    required this.appointment,
    this.onSharingComplete,
  });

  @override
  ConsumerState<MedicalRecordSelectionScreen> createState() =>
      _MedicalRecordSelectionScreenState();
}

class _MedicalRecordSelectionScreenState
    extends ConsumerState<MedicalRecordSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Selection states
  final Set<String> _selectedDocuments = {};
  final Set<String> _selectedAllergies = {};
  final Set<String> _selectedMedications = {};
  bool _shareVitals = false;
  
  // Data
  List<MedicalDocument> _documents = [];
  List<PatientAllergy> _allergies = [];
  List<PatientMedication> _medications = [];
  Map<String, dynamic> _vitals = {};
  
  // UI states
  bool _isLoading = true;
  bool _isSharing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = ref.read(currentUserModelProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load data in parallel
      final futures = await Future.wait([
        CloudinaryMedicalDocumentService.getDocuments(patientId: user.uid),
        SecureMedicalSharingService.getPatientAllergies(user.uid),
        SecureMedicalSharingService.getPatientMedications(user.uid),
        _getVitalsFromMedicalRecords(user.uid), // Get real vitals from medical records
      ]);

      setState(() {
        _documents = futures[0] as List<MedicalDocument>;
        _allergies = futures[1] as List<PatientAllergy>;
        _medications = futures[2] as List<PatientMedication>;
        _vitals = futures[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get vitals from medical records - same source as medical records
  Future<Map<String, dynamic>> _getVitalsFromMedicalRecords(String patientId) async {
    try {
      // Get vitals from medical records
      final medicalRecordsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('medical_records')
          .orderBy('recordDate', descending: true)
          .limit(10) // Get recent records
          .get();

      Map<String, dynamic> latestVitals = {};

      for (final doc in medicalRecordsSnapshot.docs) {
        final data = doc.data();
        final vitalsData = Map<String, dynamic>.from(data['vitals'] ?? {});
        
        if (vitalsData.isNotEmpty) {
          // Use the most recent vitals found
          if (latestVitals.isEmpty) {
            // Convert to display format
            if (vitalsData['systolicBP'] != null && vitalsData['diastolicBP'] != null) {
              latestVitals['bloodPressure'] = '${vitalsData['systolicBP']}/${vitalsData['diastolicBP']}';
            }
            if (vitalsData['heartRate'] != null) {
              latestVitals['heartRate'] = vitalsData['heartRate'].toString();
            }
            if (vitalsData['temperature'] != null) {
              latestVitals['temperature'] = vitalsData['temperature'].toString();
            }
            if (vitalsData['weight'] != null) {
              latestVitals['weight'] = vitalsData['weight'].toString();
            }
            if (vitalsData['height'] != null) {
              latestVitals['height'] = vitalsData['height'].toString();
            }
            break; // Use the most recent record with vitals
          }
        }
      }

      // If no vitals found in medical records, try user profile
      if (latestVitals.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (userData['height'] != null) {
            latestVitals['height'] = userData['height'].toString();
          }
          if (userData['weight'] != null) {
            latestVitals['weight'] = userData['weight'].toString();
          }
        }
      }

      return latestVitals;
    } catch (e) {
      print('Error getting vitals from medical records: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Share Medical Records'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Reports', icon: Icon(Icons.description, size: 20)),
            Tab(text: 'Allergies', icon: Icon(Icons.warning, size: 20)),
            Tab(text: 'Medications', icon: Icon(Icons.medication, size: 20)),
            Tab(text: 'Vitals', icon: Icon(Icons.favorite, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Doctor and appointment info
          _buildAppointmentInfo(),
          
          // Privacy notice
          _buildPrivacyNotice(),
          
          // Content tabs
          Expanded(
            child: _isLoading
                ? _buildLoadingView()
                : _error != null
                    ? _buildErrorView()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDocumentsTab(),
                          _buildAllergiesTab(),
                          _buildMedicationsTab(),
                          _buildVitalsTab(),
                        ],
                      ),
          ),
          
          // Bottom action bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.person,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sharing with Dr. ${widget.appointment.doctorName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.appointment.doctorSpecialty} • ${widget.appointment.formattedDateTime}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your records will be securely shared and visible only to this doctor during your appointment. Records cannot be downloaded or shared.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your medical records...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading records',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPatientData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description,
        title: 'No Medical Reports',
        subtitle: 'You don\'t have any medical reports to share',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        final isSelected = _selectedDocuments.contains(document.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedDocuments.add(document.id);
                } else {
                  _selectedDocuments.remove(document.id);
                }
              });
            },
            title: Text(document.originalFileName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${document.category.displayName} • ${_formatDate(document.uploadedAt)}'),
                if (document.description != null)
                  Text(
                    document.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            secondary: Icon(
              _getDocumentIcon(document.documentType),
              color: ThemeUtils.getPrimaryColor(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllergiesTab() {
    if (_allergies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.warning,
        title: 'No Allergies Recorded',
        subtitle: 'You don\'t have any allergies on record',
        actionText: 'Add Allergy',
        onAction: _showAddAllergyDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allergies.length,
      itemBuilder: (context, index) {
        final allergy = _allergies[index];
        final isSelected = _selectedAllergies.contains(allergy.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedAllergies.add(allergy.id);
                } else {
                  _selectedAllergies.remove(allergy.id);
                }
              });
            },
            title: Text(allergy.allergen),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${allergy.severity.toUpperCase()} • ${allergy.reaction}'),
                if (allergy.notes != null)
                  Text(
                    allergy.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            secondary: Icon(
              Icons.warning,
              color: _getSeverityColor(allergy.severity),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medication,
        title: 'No Medications Recorded',
        subtitle: 'You don\'t have any current medications on record',
        actionText: 'Add Medication',
        onAction: _showAddMedicationDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final medication = _medications[index];
        final isSelected = _selectedMedications.contains(medication.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedMedications.add(medication.id);
                } else {
                  _selectedMedications.remove(medication.id);
                }
              });
            },
            title: Text(medication.medicationName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${medication.dosage} • ${medication.frequency}'),
                Text('${medication.route} • Started: ${_formatDate(medication.startDate)}'),
                if (medication.reason != null)
                  Text(
                    'For: ${medication.reason}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            secondary: Icon(
              Icons.medication,
              color: ThemeUtils.getPrimaryColor(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalsTab() {
    if (_vitals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite,
        title: 'No Vital Signs',
        subtitle: 'You don\'t have any recent vital signs recorded',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: ThemeUtils.getPrimaryColor(context)),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Vital Signs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._vitals.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            _getVitalDisplayName(entry.key),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _shareVitals,
                    onChanged: (value) {
                      setState(() {
                        _shareVitals = value ?? false;
                      });
                    },
                    title: const Text('Share vital signs with doctor'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final hasSelection = _selectedDocuments.isNotEmpty ||
        _selectedAllergies.isNotEmpty ||
        _selectedMedications.isNotEmpty ||
        _shareVitals;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSelection) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getSelectionSummary(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getPrimaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSharing ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSharing || !hasSelection ? null : _shareRecords,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeUtils.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Share Records'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectionSummary() {
    final items = <String>[];
    if (_selectedDocuments.isNotEmpty) {
      items.add('${_selectedDocuments.length} report${_selectedDocuments.length > 1 ? 's' : ''}');
    }
    if (_selectedAllergies.isNotEmpty) {
      items.add('${_selectedAllergies.length} allerg${_selectedAllergies.length > 1 ? 'ies' : 'y'}');
    }
    if (_selectedMedications.isNotEmpty) {
      items.add('${_selectedMedications.length} medication${_selectedMedications.length > 1 ? 's' : ''}');
    }
    if (_shareVitals) {
      items.add('vital signs');
    }

    return 'Sharing: ${items.join(', ')}';
  }

  Future<void> _shareRecords() async {
    try {
      setState(() {
        _isSharing = true;
      });

      final user = ref.read(currentUserModelProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final sharingId = await SecureMedicalSharingService.createSharingSession(
        appointmentId: widget.appointment.id,
        patientId: user.uid,
        doctorId: widget.appointment.doctorId,
        selectedRecordIds: _selectedDocuments.toList(),
        selectedAllergies: _selectedAllergies.toList(),
        selectedMedications: _selectedMedications.toList(),
        selectedVitals: _shareVitals ? _vitals : {},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Medical records shared successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        widget.onSharingComplete?.call();
        Navigator.pop(context, sharingId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing records: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _showAddAllergyDialog() {
    // Implementation for adding new allergy
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allergy'),
        content: const Text('This feature will be implemented to allow patients to add new allergies.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddMedicationDialog() {
    // Implementation for adding new medication
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: const Text('This feature will be implemented to allow patients to add current medications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
      case DocumentType.image:
        return Icons.image;
      case DocumentType.video:
        return Icons.video_file;
      case DocumentType.audio:
        return Icons.audio_file;
      case DocumentType.text:
        return Icons.text_snippet;
      default:
        return Icons.description;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'mild':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _getVitalDisplayName(String key) {
    switch (key) {
      case 'bloodPressure':
        return 'Blood Pressure';
      case 'heartRate':
        return 'Heart Rate';
      case 'temperature':
        return 'Temperature';
      case 'weight':
        return 'Weight (kg)';
      case 'height':
        return 'Height (cm)';
      default:
        return key;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}