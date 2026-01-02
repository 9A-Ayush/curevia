import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/medical_record_model.dart';
import '../../providers/patient_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_report_provider.dart';
import '../../services/image_upload_service.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';

class MedicalRecordsScreen extends ConsumerStatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  ConsumerState<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends ConsumerState<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load medical reports after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedicalReports();
    });
  }

  void _loadMedicalReports() {
    final user = ref.read(authProvider).userModel;
    if (user != null) {
      ref.read(medicalReportProvider.notifier).loadMedicalReports(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientModel = ref.watch(currentPatientModelProvider);
    final medicalReportState = ref.watch(medicalReportProvider);

    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      appBar: AppBar(
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Medical Records'),
      ),
      body: Column(
        children: [
          // Header with info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeUtils.getPrimaryColor(context),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your medical records',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Access your health history and documents',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(Icons.security, 'Secure Storage'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.cloud_sync, 'Cloud Sync'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: ThemeUtils.getSurfaceColor(context),
            child: TabBar(
              controller: _tabController,
              labelColor: ThemeUtils.getPrimaryColor(context),
              unselectedLabelColor: ThemeUtils.getTextSecondaryColor(context),
              indicatorColor: ThemeUtils.getPrimaryColor(context),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
                Tab(text: 'Reports'),
                Tab(text: 'Documents'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ThemeUtils.getBackgroundColor(context),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(patientModel),
                  _buildHistoryTab(),
                  _buildReportsTab(),
                  _buildDocumentsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadOptions,
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Report'),
      ),
    );
  }

  Widget _buildOverviewTab(PatientModel? patientModel) {
    final medicalReportState = ref.watch(medicalReportProvider);
    final reports = medicalReportState.reports;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthSummaryCard(patientModel),
          const SizedBox(height: 20),
          _buildRecentReportsCard(reports),
          const SizedBox(height: 20),
          _buildAllergiesCard(patientModel),
          const SizedBox(height: 20),
          _buildCurrentMedicationsCard(reports),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard(PatientModel? patientModel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                      Text(
                        'Your current health overview',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHealthMetric(
              'Blood Group',
              patientModel?.bloodGroup ?? 'Not specified',
            ),
            _buildHealthMetric(
              'Height',
              patientModel?.height != null
                  ? '${patientModel!.height} cm'
                  : 'Not specified',
            ),
            _buildHealthMetric(
              'Weight',
              patientModel?.weight != null
                  ? '${patientModel!.weight} kg'
                  : 'Not specified',
            ),
            _buildHealthMetric('Age', _calculateAge(patientModel?.dateOfBirth)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesCard(PatientModel? patientModel) {
    final allergies = patientModel?.allergies ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allergies',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                  onPressed: _addAllergy,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (allergies.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeUtils.getSurfaceVariantColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.health_and_safety_outlined,
                      size: 48,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No allergies recorded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allergies
                    .map(
                      (allergy) => Chip(
                        label: Text(allergy),
                        backgroundColor: Colors.red[50],
                        labelStyle: TextStyle(color: Colors.red[700]),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.red[700],
                        ),
                        onDeleted: () => _removeAllergy(allergy),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportsCard(List<MedicalRecordModel> reports) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: ThemeUtils.getPrimaryColor(context),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Reports',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              Text(
                'No reports available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              )
            else
              ...reports
                  .take(3)
                  .map(
                    (report) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeUtils.getSurfaceVariantColor(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.article,
                            color: ThemeUtils.getPrimaryColor(context),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.title,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: ThemeUtils.getTextPrimaryColor(
                                          context,
                                        ),
                                      ),
                                ),
                                Text(
                                  _formatDate(report.recordDate),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ThemeUtils.getTextSecondaryColor(
                                          context,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMedicationsCard(List<MedicalRecordModel> reports) {
    // Extract medications from reports (from prescription field)
    final medications = <String>[];
    for (final report in reports) {
      if (report.prescription != null && report.prescription!.isNotEmpty) {
        // Split prescription by common delimiters to extract individual medications
        final prescriptionMeds = report.prescription!
            .split(RegExp(r'[,;\n]'))
            .map((med) => med.trim())
            .where((med) => med.isNotEmpty)
            .toList();
        medications.addAll(prescriptionMeds);
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Medications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                  onPressed: _addMedication,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (medications.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeUtils.getSurfaceVariantColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 48,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No medications recorded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...medications
                  .take(3)
                  .map(
                    (medication) => _buildMedicationItem(medication, '', ''),
                  ),
              if (medications.length > 3) ...[
                const SizedBox(height: 16),
                CustomButton(
                  text: 'View All Medications (${medications.length})',
                  onPressed: () {
                    // Navigate to detailed medications screen
                  },
                  isOutlined: true,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final medicalReportState = ref.watch(medicalReportProvider);
    final reports = medicalReportState.reports;

    if (medicalReportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (medicalReportState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeUtils.getErrorColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicalReportState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(text: 'Retry', onPressed: _loadMedicalReports),
          ],
        ),
      );
    }

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(
                  context,
                ).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 60,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Medical History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your medical history will appear here once you upload reports.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Upload First Report',
              onPressed: _showUploadOptions,
              icon: Icons.upload_file,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadMedicalReports(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...reports.map(
              (report) => _buildHistoryItem(
                date: _formatDate(report.recordDate),
                title: report.title,
                doctor: report.doctorName ?? 'Unknown Doctor',
                type: _getTypeDisplayName(report.type),
                status: 'Completed',
                report: report,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    final medicalReportState = ref.watch(medicalReportProvider);
    final reports = medicalReportState.reports;

    if (medicalReportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (medicalReportState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeUtils.getErrorColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading reports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicalReportState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(text: 'Retry', onPressed: _loadMedicalReports),
          ],
        ),
      );
    }

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(
                  context,
                ).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment,
                size: 60,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Medical Reports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload your medical reports to keep track of your health records.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Upload Report',
              onPressed: _showUploadOptions,
              icon: Icons.upload_file,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadMedicalReports(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...reports.map(
              (report) => _buildReportItem(
                title: report.title,
                date: _formatDate(report.recordDate),
                type: _getTypeDisplayName(report.type),
                status: 'Completed',
                report: report,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final medicalReportState = ref.watch(medicalReportProvider);
    final reports = medicalReportState.reports;

    if (medicalReportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (medicalReportState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeUtils.getErrorColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading documents',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicalReportState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(text: 'Retry', onPressed: _loadMedicalReports),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CustomButton(
            text: 'Upload Document',
            onPressed: _showUploadOptions,
            icon: Icons.upload_file,
          ),
          const SizedBox(height: 20),
          if (reports.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceVariantColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Documents Uploaded',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ThemeUtils.getTextPrimaryColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your medical documents to keep them organized and accessible.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...reports
                .where((report) => report.attachments.isNotEmpty)
                .map(
                  (report) => _buildDocumentItem(
                    title: report.title,
                    type: 'Image',
                    size: 'Unknown',
                    date: _formatDate(report.recordDate),
                    report: report,
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(String name, String dosage, String frequency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.medication,
              color: ThemeUtils.getPrimaryColor(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  '$dosage • $frequency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show medication options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String date,
    required String title,
    required String doctor,
    required String type,
    required String status,
    MedicalRecordModel? report,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
          child: Icon(
            Icons.medical_services,
            color: ThemeUtils.getPrimaryColor(context),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$doctor • $type',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ThemeUtils.getSuccessColor(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: ThemeUtils.getSuccessColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          // Navigate to detailed history item
        },
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required String date,
    required String type,
    required String status,
    MedicalRecordModel? report,
  }) {
    final isNormal = status == 'Normal' || status == 'Completed';
    final statusColor = isNormal ? AppColors.success : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.assignment, color: statusColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            if (report?.doctorName != null) ...[
              Text(
                'Dr. ${report!.doctorName}',
                style: TextStyle(
                  color: ThemeUtils.getTextSecondaryColor(context),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleReportAction(value, report),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          if (report != null) {
            _viewReportDetails(report);
          }
        },
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String type,
    required String size,
    required String date,
    MedicalRecordModel? report,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
          child: Icon(
            Icons.description,
            color: ThemeUtils.getPrimaryColor(context),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$type • $size',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {
            // Download document
          },
        ),
        onTap: () {
          // View document
        },
      ),
    );
  }

  String _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return 'Not specified';
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    return '$age years';
  }

  void _addAllergy() {
    final TextEditingController allergyController = TextEditingController();
    final TextEditingController severityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Allergy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: allergyController,
              decoration: const InputDecoration(
                labelText: 'Allergy Name',
                hintText: 'e.g., Peanuts, Penicillin',
                prefixIcon: Icon(Icons.warning_amber),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: severityController,
              decoration: const InputDecoration(
                labelText: 'Severity',
                hintText: 'e.g., Mild, Moderate, Severe',
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (allergyController.text.isNotEmpty) {
                Navigator.pop(context);
                // TODO: Save to Firestore
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added allergy: ${allergyController.text}'),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeAllergy(String allergy) {
    // Remove allergy logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Removed allergy: $allergy')));
  }

  void _addMedication() {
    final TextEditingController medicationController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController frequencyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicationController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  hintText: 'e.g., Aspirin, Metformin',
                  prefixIcon: Icon(Icons.medication),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 500mg, 10ml',
                  prefixIcon: Icon(Icons.science),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  hintText: 'e.g., Twice daily, Once a week',
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (medicationController.text.isNotEmpty) {
                Navigator.pop(context);
                // TODO: Save to Firestore
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added medication: ${medicationController.text}'),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Show upload options dialog
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: ThemeUtils.getBorderMediumColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Add Medical Report',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ThemeUtils.getPrimaryColor(
                          context,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: ThemeUtils.getPrimaryColor(context),
                      ),
                    ),
                    title: Text(
                      'Take Photo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    subtitle: Text(
                      'Capture a photo of your medical report',
                      style: TextStyle(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _uploadFromCamera();
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ThemeUtils.getPrimaryColor(
                          context,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.photo_library,
                        color: ThemeUtils.getPrimaryColor(context),
                      ),
                    ),
                    title: Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    subtitle: Text(
                      'Select an existing photo from your gallery',
                      style: TextStyle(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _uploadFromGallery();
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ThemeUtils.getPrimaryColor(
                          context,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: ThemeUtils.getPrimaryColor(context),
                      ),
                    ),
                    title: Text(
                      'Manual Entry',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    subtitle: Text(
                      'Enter report details manually',
                      style: TextStyle(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _addManualReport();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Upload from camera
  Future<void> _uploadFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        await _processUploadedImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  /// Upload from gallery
  Future<void> _uploadFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await _processUploadedImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image: $e');
    }
  }

  /// Process uploaded image
  Future<void> _processUploadedImage(File imageFile) async {
    final user = ref.read(authProvider).userModel;
    if (user == null) return;

    // For now, show a dialog to manually enter report details
    // This bypasses the Google Vision API requirement
    _showManualReportDialog(imageFile);
  }

  /// Show manual report entry dialog
  void _showManualReportDialog(File? imageFile) {
    final titleController = TextEditingController();
    final doctorController = TextEditingController();
    final hospitalController = TextEditingController();
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    String selectedType = 'consultation';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add Medical Report',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageFile != null) ...[
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(imageFile),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Report Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'consultation',
                      child: Text('Consultation'),
                    ),
                    DropdownMenuItem(
                      value: 'lab_test',
                      child: Text('Lab Test'),
                    ),
                    DropdownMenuItem(
                      value: 'prescription',
                      child: Text('Prescription'),
                    ),
                    DropdownMenuItem(
                      value: 'vaccination',
                      child: Text('Vaccination'),
                    ),
                    DropdownMenuItem(value: 'surgery', child: Text('Surgery')),
                    DropdownMenuItem(value: 'checkup', child: Text('Checkup')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital/Clinic Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: treatmentController,
                  decoration: const InputDecoration(
                    labelText: 'Treatment',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Prescription/Medications',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('Report Date: ${_formatDate(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a report title'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _saveManualReport(
                  imageFile: imageFile,
                  title: titleController.text.trim(),
                  type: selectedType,
                  recordDate: selectedDate,
                  doctorName: doctorController.text.trim().isEmpty
                      ? null
                      : doctorController.text.trim(),
                  hospitalName: hospitalController.text.trim().isEmpty
                      ? null
                      : hospitalController.text.trim(),
                  diagnosis: diagnosisController.text.trim().isEmpty
                      ? null
                      : diagnosisController.text.trim(),
                  treatment: treatmentController.text.trim().isEmpty
                      ? null
                      : treatmentController.text.trim(),
                  prescription: prescriptionController.text.trim().isEmpty
                      ? null
                      : prescriptionController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
              },
              child: const Text('Save Report'),
            ),
          ],
        ),
      ),
    );
  }

  /// Save manual report
  Future<void> _saveManualReport({
    File? imageFile,
    required String title,
    required String type,
    required DateTime recordDate,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
  }) async {
    final user = ref.read(authProvider).userModel;
    if (user == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      List<String> attachments = [];

      // Upload image if provided
      if (imageFile != null) {
        try {
          final xFile = XFile(imageFile.path);
          final imageUrl = await ImageUploadService.uploadMedicalDocument(
            imageFile: xFile,
            userId: user.uid,
          );
          attachments.add(imageUrl);
        } catch (e) {
          // Continue without image if upload fails
          print('Failed to upload image: $e');
        }
      }

      // Save to Firestore using the manual report method
      final recordId = await ref
          .read(medicalReportProvider.notifier)
          .addManualMedicalReport(
            userId: user.uid,
            title: title,
            type: type,
            recordDate: recordDate,
            doctorName: doctorName,
            hospitalName: hospitalName,
            diagnosis: diagnosis,
            treatment: treatment,
            prescription: prescription,
            notes: notes,
            attachments: attachments,
          );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (recordId != null) {
          _showSuccessSnackBar('Medical report saved successfully!');
        } else {
          _showErrorSnackBar('Failed to save medical report');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Error saving report: $e');
      }
    }
  }

  /// Add manual report
  void _addManualReport() {
    _showManualReportDialog(null);
  }

  /// Handle report actions
  void _handleReportAction(String action, MedicalRecordModel? report) {
    if (report == null) return;

    switch (action) {
      case 'view':
        _viewReportDetails(report);
        break;
      case 'edit':
        _editReport(report);
        break;
      case 'delete':
        _deleteReport(report);
        break;
    }
  }

  /// View report details
  void _viewReportDetails(MedicalRecordModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (report.doctorName != null) ...[
                Text('Doctor: ${report.doctorName}'),
                const SizedBox(height: 8),
              ],
              if (report.hospitalName != null) ...[
                Text('Hospital: ${report.hospitalName}'),
                const SizedBox(height: 8),
              ],
              if (report.diagnosis != null) ...[
                Text('Diagnosis: ${report.diagnosis}'),
                const SizedBox(height: 8),
              ],
              if (report.treatment != null) ...[
                Text('Treatment: ${report.treatment}'),
                const SizedBox(height: 8),
              ],
              Text('Date: ${_formatDate(report.recordDate)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Edit report
  void _editReport(MedicalRecordModel report) {
    final TextEditingController titleController =
        TextEditingController(text: report.title);
    final TextEditingController notesController =
        TextEditingController(text: report.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Report Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  // TODO: Update in Firestore
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating report: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Delete report
  void _deleteReport(MedicalRecordModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "${report.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = ref.read(authProvider).userModel;
              if (user != null) {
                final success = await ref
                    .read(medicalReportProvider.notifier)
                    .deleteMedicalReport(user.uid, report.id);

                if (success) {
                  _showSuccessSnackBar('Report deleted successfully');
                } else {
                  _showErrorSnackBar('Failed to delete report');
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get type display name
  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'lab_test':
        return 'Lab Test';
      case 'consultation':
        return 'Consultation';
      case 'prescription':
        return 'Prescription';
      case 'vaccination':
        return 'Vaccination';
      case 'surgery':
        return 'Surgery';
      case 'checkup':
        return 'Checkup';
      default:
        return type;
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
