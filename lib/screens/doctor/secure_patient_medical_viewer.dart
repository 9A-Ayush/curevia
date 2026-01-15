import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient_medical_data_model.dart';
import '../../models/medical_record_model.dart';
import '../../models/medical_record_sharing_model.dart';
import '../../services/doctor/secure_patient_data_service.dart';
import '../../services/secure_viewing_service.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';

/// Secure medical data viewer for doctors - NO SHARING, NO SCREENSHOTS
/// Real-time data fetching with strict access controls and comprehensive medical information
class SecurePatientMedicalViewer extends ConsumerStatefulWidget {
  final String doctorId;
  final String patientId;
  final String appointmentId;
  final String patientName;

  const SecurePatientMedicalViewer({
    super.key,
    required this.doctorId,
    required this.patientId,
    required this.appointmentId,
    required this.patientName,
  });

  @override
  ConsumerState<SecurePatientMedicalViewer> createState() => _SecurePatientMedicalViewerState();
}

class _SecurePatientMedicalViewerState extends ConsumerState<SecurePatientMedicalViewer>
    with SingleTickerProviderStateMixin, SecureViewingMixin, WidgetsBindingObserver {
  late TabController _tabController;
  
  // UI states
  bool _isLoading = true;
  bool _hasAccess = false;
  String? _error;
  bool _sessionExpired = false;
  int _selectedTabIndex = 0;

  // Real-time data streams
  Stream<PatientMedicalData?>? _patientDataStream;
  Stream<List<MedicalRecordModel>>? _medicalRecordsStream;
  Stream<List<PatientAllergy>>? _allergiesStream;
  Stream<List<PatientMedication>>? _medicationsStream;
  Stream<List<PatientVitals>>? _vitalsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 5, vsync: this);
    _initializeSecureViewing();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    SecureViewingService.handleAppLifecycleChange(state);
    
    // Additional security: close screen when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleSessionExpired();
    }
  }

  /// Initialize secure viewing and data streams
  Future<void> _initializeSecureViewing() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Validate access first
      final hasAccess = await _validateAccess();
      if (!hasAccess) {
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
        return;
      }

      // Initialize data streams
      _initializeDataStreams();

      setState(() {
        _hasAccess = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _disableScreenSecurity();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildSecureAppBar(),
        body: _buildSecureBody(),
        bottomNavigationBar: _buildTabNavigation(),
      ),
    );
  }

  /// Build secure app bar with security indicators
  PreferredSizeWidget _buildSecureAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medical Records - ${widget.patientName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(
                _isScreenSecure ? Icons.security : Icons.security_outlined,
                size: 12,
                color: _isScreenSecure ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                _isScreenSecure ? 'Secure View' : 'Securing...',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Security status indicator
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography, size: 12),
              SizedBox(width: 4),
              Text('NO SHARING', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  /// Build secure body with real-time data
  Widget _buildSecureBody() {
    if (_sessionExpired) {
      return _buildSessionExpiredView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (!_hasAccess) {
      return _buildAccessDeniedView();
    }

    return StreamBuilder<PatientMedicalData?>
>(
      stream: _patientDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        if (snapshot.hasError) {
          return _buildErrorView(error: snapshot.error.toString());
        }

        final patientData = snapshot.data;
        if (patientData == null) {
          return _buildNoDataView();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(patientData),
            _buildMedicalRecordsTab(),
            _buildAllergiesTab(),
            _buildMedicationsTab(),
            _buildVitalsTab(),
          ],
        );
      },
    );
  }

  /// Build tab navigation
  Widget _buildTabNavigation() {
    return Container(
      color: AppColors.primaryColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.person), text: 'Overview'),
          Tab(icon: Icon(Icons.medical_services), text: 'Records'),
          Tab(icon: Icon(Icons.warning), text: 'Allergies'),
          Tab(icon: Icon(Icons.medication), text: 'Medications'),
          Tab(icon: Icon(Icons.monitor_heart), text: 'Vitals'),
        ],
      ),
    );
  }

  /// Build overview tab with patient summary
  Widget _buildOverviewTab(PatientMedicalData patientData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientInfoCard(patientData),
          const SizedBox(height: 16),
          _buildEmergencyContactCard(patientData),
          const SizedBox(height: 16),
          _buildMedicalSummaryCard(patientData),
        ],
      ),
    );
  }

  /// Build patient information card
  Widget _buildPatientInfoCard(PatientMedicalData patientData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Patient Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Name', patientData.patientName),
            if (patientData.basicInfo.age != null)
              _buildInfoRow('Age', '${patientData.basicInfo.age} years'),
            if (patientData.basicInfo.gender != null)
              _buildInfoRow('Gender', patientData.basicInfo.gender!),
            if (patientData.basicInfo.bloodGroup != null)
              _buildInfoRow('Blood Type', patientData.basicInfo.bloodGroup!),
            _buildInfoRow('Last Updated', _formatDate(patientData.lastUpdated)),
          ],
        ),
      ),
    );
  }

  /// Build emergency contact card
  Widget _buildEmergencyContactCard(PatientMedicalData patientData) {
    if (patientData.basicInfo.emergencyContactName == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Emergency Contact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Name', patientData.basicInfo.emergencyContactName!),
            if (patientData.basicInfo.emergencyContactPhone != null)
              _buildInfoRow('Phone', patientData.basicInfo.emergencyContactPhone!),
          ],
        ),
      ),
    );
  }

  /// Build medical summary card
  Widget _buildMedicalSummaryCard(PatientMedicalData patientData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Medical Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (patientData.basicInfo.medicalHistory.isNotEmpty) ...[
              Text(
                'Medical History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...patientData.basicInfo.medicalHistory.map((history) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $history'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (patientData.criticalAlerts.isNotEmpty) ...[
              Text(
                'Critical Alerts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ...patientData.criticalAlerts.map((alert) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(alert, style: TextStyle(color: Colors.red.shade700))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build medical records tab
  Widget _buildMedicalRecordsTab() {
    return StreamBuilder<List<MedicalRecordModel>>(
      stream: _medicalRecordsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        if (snapshot.hasError) {
          return _buildErrorView(error: snapshot.error.toString());
        }

        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return _buildEmptyStateView('No medical records found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildMedicalRecordCard(record);
          },
        );
      },
    );
  }

  /// Build medical record card
  Widget _buildMedicalRecordCard(MedicalRecordModel record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(record.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (record.description.isNotEmpty) ...[
              Text(record.description),
              const SizedBox(height: 8),
            ],
            if (record.diagnosis.isNotEmpty) ...[
              Text(
                'Diagnosis: ${record.diagnosis}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            if (record.prescription.isNotEmpty) ...[
              Text(
                'Prescription: ${record.prescription}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build allergies tab
  Widget _buildAllergiesTab() {
    return StreamBuilder<List<PatientAllergy>>(
      stream: _allergiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        if (snapshot.hasError) {
          return _buildErrorView(error: snapshot.error.toString());
        }

        final allergies = snapshot.data ?? [];
        if (allergies.isEmpty) {
          return _buildEmptyStateView('No known allergies');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allergies.length,
          itemBuilder: (context, index) {
            final allergy = allergies[index];
            return _buildAllergyCard(allergy);
          },
        );
      },
    );
  }

  /// Build allergy card
  Widget _buildAllergyCard(PatientAllergy allergy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allergy.allergen,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(allergy.severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    allergy.severity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (allergy.reaction.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reaction: ${allergy.reaction}'),
            ],
            if (allergy.notes != null && allergy.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${allergy.notes}'),
            ],
          ],
        ),
      ),
    );
  }

  /// Build medications tab
  Widget _buildMedicationsTab() {
    return StreamBuilder<List<PatientMedication>>(
      stream: _medicationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        if (snapshot.hasError) {
          return _buildErrorView(error: snapshot.error.toString());
        }

        final medications = snapshot.data ?? [];
        if (medications.isEmpty) {
          return _buildEmptyStateView('No current medications');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            return _buildMedicationCard(medication);
          },
        );
      },
    );
  }

  /// Build medication card
  Widget _buildMedicationCard(PatientMedication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    medication.medicationName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: medication.isCurrentlyActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    medication.isCurrentlyActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Dosage', medication.dosage),
            _buildInfoRow('Frequency', medication.frequency),
            if (medication.prescribedBy != null)
              _buildInfoRow('Prescribed by', medication.prescribedBy!),
            _buildInfoRow('Start Date', _formatDate(medication.startDate)),
            if (medication.endDate != null)
              _buildInfoRow('End Date', _formatDate(medication.endDate!)),
            if (medication.notes != null && medication.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${medication.notes}'),
            ],
          ],
        ),
      ),
    );
  }

  /// Build vitals tab
  Widget _buildVitalsTab() {
    return StreamBuilder<List<PatientVitals>>(
      stream: _vitalsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        if (snapshot.hasError) {
          return _buildErrorView(error: snapshot.error.toString());
        }

        final vitals = snapshot.data ?? [];
        
        // Debug: Print vitals data to console
        if (vitals.isNotEmpty) {
          print('🩺 Vitals data found: ${vitals.length} records');
          for (var vital in vitals) {
            print('  - ID: ${vital.id}');
            print('  - BP: ${vital.systolicBP}/${vital.diastolicBP}');
            print('  - HR: ${vital.heartRate}');
            print('  - Temp: ${vital.temperature}');
            print('  - Date: ${vital.recordedAt}');
          }
        } else {
          print('🩺 No vitals data found for patient: ${widget.patientId}');
        }
        
        if (vitals.isEmpty) {
          return _buildEmptyStateView('No vital signs recorded');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vitals.length,
          itemBuilder: (context, index) {
            final vital = vitals[index];
            return _buildVitalsCard(vital);
          },
        );
      },
    );
  }

  /// Build vitals card
  Widget _buildVitalsCard(PatientVitals vitals) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Vital Signs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(vitals.recordedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(),
            
            // Blood Pressure and Heart Rate
            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    'Blood Pressure', 
                    vitals.bloodPressure ?? 'Not recorded'
                  ),
                ),
                Expanded(
                  child: _buildVitalItem(
                    'Heart Rate', 
                    vitals.heartRate != null ? '${vitals.heartRate} bpm' : 'Not recorded'
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Temperature and Oxygen Saturation
            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    'Temperature', 
                    vitals.temperature != null ? '${vitals.temperature}°C' : 'Not recorded'
                  ),
                ),
                Expanded(
                  child: _buildVitalItem(
                    'Oxygen Sat', 
                    vitals.oxygenSaturation != null ? '${vitals.oxygenSaturation}%' : 'Not recorded'
                  ),
                ),
              ],
            ),
            
            // Weight and Height (if available)
            if (vitals.weight != null || vitals.height != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildVitalItem(
                      'Weight', 
                      vitals.weight != null ? '${vitals.weight} kg' : 'Not recorded'
                    ),
                  ),
                  Expanded(
                    child: _buildVitalItem(
                      'Height', 
                      vitals.height != null ? '${vitals.height} cm' : 'Not recorded'
                    ),
                  ),
                ],
              ),
            ],
            
            // Additional vitals if available
            if (vitals.respiratoryRate != null || vitals.bloodSugar != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (vitals.respiratoryRate != null)
                    Expanded(
                      child: _buildVitalItem(
                        'Respiratory Rate', 
                        '${vitals.respiratoryRate} /min'
                      ),
                    ),
                  if (vitals.bloodSugar != null)
                    Expanded(
                      child: _buildVitalItem(
                        'Blood Sugar', 
                        '${vitals.bloodSugar} mg/dL'
                      ),
                    ),
                  if (vitals.respiratoryRate == null || vitals.bloodSugar == null)
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
            
            // Notes if available
            if (vitals.notes != null && vitals.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(vitals.notes!),
                  ],
                ),
              ),
            ],
            
            // Recorded by information
            if (vitals.recordedBy != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Recorded by: ${vitals.recordedBy}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build vital item
  Widget _buildVitalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading secure medical data...'),
        ],
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView({String? error}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading medical data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeSecureViewing,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build no data view
  Widget _buildNoDataView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No medical data available',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  /// Build empty state view
  Widget _buildEmptyStateView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  /// Build session expired view
  Widget _buildSessionExpiredView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_off,
            size: 64,
            color: Colors.orange[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Session Expired',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'For security reasons, this session has expired.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build access denied view
  Widget _buildAccessDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Access Denied',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'You do not have permission to view this patient\'s medical data.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  /// Get severity color for allergies
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.yellow[700]!;
      case 'moderate':
        return Colors.orange[700]!;
      case 'severe':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Handle session expiration
  void _handleSessionExpired() {
    if (mounted) {
      setState(() {
        _sessionExpired = true;
      });
      _disableScreenSecurity();
    }
  }

  /// Validate doctor access to patient data
  Future<bool> _validateAccess() async {
    try {
      return await SecurePatientDataService._validateDoctorAccess(
        doctorId: widget.doctorId,
        patientId: widget.patientId,
        appointmentId: widget.appointmentId,
      );
    } catch (e) {
      return false;
    }
  }

  /// Initialize data streams
  void _initializeDataStreams() {
    _patientDataStream = SecurePatientDataService.getPatientMedicalDataStream(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
    );

    _medicalRecordsStream = SecurePatientDataService.getPatientMedicalRecordsStream(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
    );

    _allergiesStream = SecurePatientDataService.getPatientAllergiesStream(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
    );

    _medicationsStream = SecurePatientDataService.getPatientMedicationsStream(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
    );

    _vitalsStream = SecurePatientDataService.getPatientVitalsStream(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
    );
  }
}

/// Secure viewing mixin for screenshot prevention
mixin SecureViewingMixin<T extends StatefulWidget> on State<T> {
  bool _isScreenSecure = false;

  @override
  void initState() {
    super.initState();
    _enableScreenSecurity();
  }

  /// Enable screen security (prevent screenshots)
  Future<void> _enableScreenSecurity() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
      
      // Note: Actual screenshot prevention would require platform-specific implementation
      // This is a placeholder for the security mechanism
      
      if (mounted) {
        setState(() {
          _isScreenSecure = true;
        });
      }
    } catch (e) {
      print('Failed to enable screen security: $e');
    }
  }

  /// Disable screen security
  Future<void> _disableScreenSecurity() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
      
      if (mounted) {
        setState(() {
          _isScreenSecure = false;
        });
      }
    } catch (e) {
      print('Failed to disable screen security: $e');
    }
  }
}