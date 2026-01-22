import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../models/medical_record_sharing_model.dart';
import '../../models/medical_document_model.dart';
import '../../models/appointment_model.dart';
import '../../models/medical_record_model.dart';
import '../../services/secure_medical_sharing_service.dart';
import '../../services/secure_viewing_service.dart';
import '../../providers/auth_provider.dart';
import '../patient/pdf_viewer_screen.dart';

/// Secure viewer for doctors to view shared medical records
class SecureMedicalRecordsViewer extends ConsumerStatefulWidget {
  final String sharingId;
  final AppointmentModel appointment;

  const SecureMedicalRecordsViewer({
    super.key,
    required this.sharingId,
    required this.appointment,
  });

  @override
  ConsumerState<SecureMedicalRecordsViewer> createState() =>
      _SecureMedicalRecordsViewerState();
}

class _SecureMedicalRecordsViewerState extends ConsumerState<SecureMedicalRecordsViewer>
    with SingleTickerProviderStateMixin, SecureViewingMixin, WidgetsBindingObserver {
  late TabController _tabController;
  
  // Data
  MedicalRecordSharing? _sharing;
  List<MedicalDocument> _documents = [];
  List<PatientAllergy> _allergies = [];
  List<PatientMedication> _medications = [];
  Map<String, dynamic> _vitals = {};
  
  // UI states
  bool _isLoading = true;
  bool _hasAccess = false;
  String? _error;
  bool _sessionExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _validateAccessAndLoadData();
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
  }

  Future<void> _validateAccessAndLoadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = ref.read(currentUserModelProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate doctor access
      final sharing = await SecureMedicalSharingService.validateDoctorAccess(
        sharingId: widget.sharingId,
        doctorId: user.uid,
        appointmentId: widget.appointment.id,
      );

      if (sharing == null) {
        setState(() {
          _hasAccess = false;
          _error = 'Access denied. You do not have permission to view these records.';
          _isLoading = false;
        });
        return;
      }

      // Load shared data
      final futures = await Future.wait([
        SecureMedicalSharingService.getSharedDocuments(
          sharingId: widget.sharingId,
          doctorId: user.uid,
        ),
        SecureMedicalSharingService.getSharedAllergies(
          sharingId: widget.sharingId,
          doctorId: user.uid,
        ),
        SecureMedicalSharingService.getSharedMedications(
          sharingId: widget.sharingId,
          doctorId: user.uid,
        ),
      ]);

      // Get patient vitals if shared
      Map<String, dynamic> vitals = {};
      if (sharing.sharedVitals.isNotEmpty) {
        vitals = sharing.sharedVitals;
      } else {
        // Get all patient vitals if none specifically selected
        vitals = await SecureMedicalSharingService.getPatientVitals(sharing.patientId);
      }

      setState(() {
        _sharing = sharing;
        _documents = futures[0] as List<MedicalDocument>;
        _allergies = futures[1] as List<PatientAllergy>;
        _medications = futures[2] as List<PatientMedication>;
        _vitals = vitals;
        _hasAccess = true;
        _isLoading = false;
      });

      // Log successful access
      await SecureMedicalSharingService.logSecurityEvent(
        sharingId: widget.sharingId,
        userId: user.uid,
        eventType: 'records_viewed',
        details: 'Doctor accessed shared medical records',
      );

    } catch (e) {
      setState(() {
        _error = e.toString();
        _hasAccess = false;
        _isLoading = false;
      });
    }
  }

  void _handleInactivityTimeout() {
    setState(() {
      _sessionExpired = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired due to inactivity'),
        backgroundColor: Colors.orange,
      ),
    );
    
    Navigator.pop(context);
  }

  void _handleAppBackgrounded() {
    // Log security event
    final user = ref.read(currentUserModelProvider);
    if (user != null) {
      SecureMedicalSharingService.logSecurityEvent(
        sharingId: widget.sharingId,
        userId: user.uid,
        eventType: 'app_backgrounded',
        details: 'App went to background while viewing records',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionExpired) {
      return _buildSessionExpiredView();
    }

    return SecureViewWrapper(
      onInactivityTimeout: _handleInactivityTimeout,
      onAppBackgrounded: _handleAppBackgrounded,
      child: Scaffold(
        backgroundColor: ThemeUtils.getBackgroundColor(context),
        appBar: AppBar(
          title: const Text('Medical Records'),
          backgroundColor: ThemeUtils.getPrimaryColor(context),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _showSecurityInfo,
              icon: const Icon(Icons.security),
              tooltip: 'Security Information',
            ),
          ],
          bottom: _hasAccess && !_isLoading
              ? TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(
                      text: 'Reports (${_documents.length})',
                      icon: const Icon(Icons.description, size: 20),
                    ),
                    Tab(
                      text: 'Allergies (${_allergies.length})',
                      icon: const Icon(Icons.warning, size: 20),
                    ),
                    Tab(
                      text: 'Medications (${_medications.length})',
                      icon: const Icon(Icons.medication, size: 20),
                    ),
                    Tab(
                      text: 'Vitals',
                      icon: const Icon(Icons.favorite, size: 20),
                    ),
                  ],
                )
              : null,
        ),
        body: Stack(
          children: [
            _buildBody(),
            buildInactivityWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (!_hasAccess || _error != null) {
      return _buildAccessDeniedView();
    }

    return Column(
      children: [
        // Patient and sharing info
        _buildPatientInfo(),
        
        // Content tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDocumentsTab(),
              _buildAllergiesTab(),
              _buildMedicationsTab(),
              _buildVitalsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Validating access and loading records...'),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'You do not have permission to view these medical records.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionExpiredView() {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_off,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Session Expired',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your viewing session has expired due to inactivity for security reasons.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    if (_sharing == null) return const SizedBox();

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
                      'Patient: ${widget.appointment.patientName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Appointment: ${widget.appointment.formattedDateTime}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Secure',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Shared: ${_sharing!.sharingSummary}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.description,
        title: 'No Medical Reports Shared',
        subtitle: 'The patient has not shared any medical reports for this appointment.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDocumentIcon(document.documentType),
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
            title: SecureText(
              document.originalFileName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SecureText('${document.category.displayName} • ${_formatDate(document.uploadedAt)}'),
                if (document.description != null)
                  SecureText(
                    document.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _viewDocument(document),
              icon: const Icon(Icons.visibility),
              tooltip: 'View Document',
            ),
            onTap: () => _viewDocument(document),
          ),
        );
      },
    );
  }

  Widget _buildAllergiesTab() {
    if (_allergies.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.warning,
        title: 'No Allergies Shared',
        subtitle: 'The patient has not shared any allergy information for this appointment.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allergies.length,
      itemBuilder: (context, index) {
        final allergy = _allergies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getSeverityColor(allergy.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning,
                color: _getSeverityColor(allergy.severity),
              ),
            ),
            title: SecureText(
              allergy.allergen,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SecureText('Severity: ${allergy.severity.toUpperCase()}'),
                SecureText('Reaction: ${allergy.reaction}'),
                if (allergy.notes != null)
                  SecureText(
                    'Notes: ${allergy.notes!}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.medication,
        title: 'No Medications Shared',
        subtitle: 'The patient has not shared any current medication information for this appointment.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final medication = _medications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medication,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
            title: SecureText(
              medication.medicationName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SecureText('Dosage: ${medication.dosage}'),
                SecureText('Frequency: ${medication.frequency}'),
                SecureText('Route: ${medication.route}'),
                SecureText('Started: ${_formatDate(medication.startDate)}'),
                if (medication.reason != null)
                  SecureText(
                    'Reason: ${medication.reason!}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalsTab() {
    if (_vitals.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.favorite,
        title: 'No Vital Signs Shared',
        subtitle: 'The patient has not shared any vital signs for this appointment.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
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
                    'Patient Vital Signs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._vitals.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: SecureText(
                        _getVitalDisplayName(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SecureText(
                      entry.value.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String subtitle,
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
          ],
        ),
      ),
    );
  }

  void _viewDocument(MedicalDocument document) async {
    resetWarningTimer();
    
    // Log document access
    final user = ref.read(currentUserModelProvider);
    if (user != null) {
      await SecureMedicalSharingService.logSecurityEvent(
        sharingId: widget.sharingId,
        userId: user.uid,
        eventType: 'document_viewed',
        details: 'Viewed document: ${document.originalFileName}',
      );
    }

    // Create a dummy medical record for the secure viewer
    final dummyRecord = MedicalRecordModel(
      id: document.id,
      title: document.originalFileName,
      type: document.category.toString(),
      recordDate: document.uploadedAt,
      attachments: [],
      vitals: {},
      labResults: {},
      createdAt: document.uploadedAt,
      updatedAt: document.uploadedAt,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecureViewWrapper(
          onInactivityTimeout: _handleInactivityTimeout,
          onAppBackgrounded: _handleAppBackgrounded,
          child: PdfViewerScreen(
            medicalRecord: dummyRecord,
            pdfUrl: document.fileUrl,
          ),
        ),
      ),
    );
  }

  void _showSecurityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Security Information'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This is a secure viewing session with the following protections:'),
            SizedBox(height: 12),
            Text('• Screenshots and screen recording are disabled'),
            Text('• Content is hidden when app goes to background'),
            Text('• Session expires after 5 minutes of inactivity'),
            Text('• Text selection and copying is disabled'),
            Text('• All access is logged for security auditing'),
            SizedBox(height: 12),
            Text(
              'These records are shared only for this appointment and cannot be saved or shared.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
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
        return 'Blood Pressure:';
      case 'heartRate':
        return 'Heart Rate (bpm):';
      case 'temperature':
        return 'Temperature (°F):';
      case 'weight':
        return 'Weight (kg):';
      case 'height':
        return 'Height (cm):';
      case 'bloodType':
        return 'Blood Type:';
      case 'age':
        return 'Age:';
      case 'respiratoryRate':
        return 'Respiratory Rate:';
      case 'oxygenSaturation':
        return 'Oxygen Saturation:';
      case 'bmi':
        return 'BMI:';
      default:
        return '${key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')}:';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}