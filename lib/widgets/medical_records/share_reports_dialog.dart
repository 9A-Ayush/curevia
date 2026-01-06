import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/medical_record_model.dart';
import '../../models/user_model.dart';
import '../../services/medical_report_sharing_service.dart';
import '../../utils/theme_utils.dart';
import '../../constants/app_colors.dart';
import '../common/custom_button.dart';

class ShareReportsDialog extends ConsumerStatefulWidget {
  final List<MedicalRecordModel> availableReports;
  final String patientId;
  final String patientName;
  final List<String> patientAllergies;
  final Map<String, dynamic> patientVitals;

  const ShareReportsDialog({
    super.key,
    required this.availableReports,
    required this.patientId,
    required this.patientName,
    required this.patientAllergies,
    required this.patientVitals,
  });

  @override
  ConsumerState<ShareReportsDialog> createState() => _ShareReportsDialogState();
}

class _ShareReportsDialogState extends ConsumerState<ShareReportsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Selected items
  final Set<String> _selectedReportIds = {};
  final Set<String> _selectedAllergies = {};
  UserModel? _selectedDoctor;
  
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _doctorSearchController = TextEditingController();
  
  // State
  List<UserModel> _availableDoctors = [];
  List<UserModel> _filteredDoctors = [];
  bool _isLoadingDoctors = false;
  bool _isSharing = false;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAvailableDoctors();
    
    // Initialize with all allergies selected
    _selectedAllergies.addAll(widget.patientAllergies);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _doctorSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableDoctors() async {
    setState(() => _isLoadingDoctors = true);
    
    try {
      final doctors = await MedicalReportSharingService.getAvailableDoctors();
      setState(() {
        _availableDoctors = doctors;
        _filteredDoctors = doctors;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load doctors: $e');
    } finally {
      setState(() => _isLoadingDoctors = false);
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = _availableDoctors;
      } else {
        _filteredDoctors = _availableDoctors
            .where((doctor) =>
                doctor.fullName.toLowerCase().contains(query.toLowerCase()) ||
                doctor.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _shareReports() async {
    if (_selectedDoctor == null) {
      _showErrorSnackBar('Please select a doctor');
      return;
    }

    if (_selectedReportIds.isEmpty) {
      _showErrorSnackBar('Please select at least one medical report');
      return;
    }

    setState(() => _isSharing = true);

    try {
      final selectedReports = widget.availableReports
          .where((report) => _selectedReportIds.contains(report.id))
          .toList();

      final sharingId = await MedicalReportSharingService.shareReportsWithDoctor(
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorId: _selectedDoctor!.uid,
        selectedReportIds: selectedReports.map((r) => r.id).toList(),
        selectedAllergies: _selectedAllergies.toList(),
        patientVitals: widget.patientVitals,
        message: _messageController.text.trim().isEmpty 
            ? null 
            : _messageController.text.trim(),
        expirationTime: _expirationDate,
      );

      if (sharingId != null) {
        Navigator.of(context).pop(true); // Return success
        _showSuccessSnackBar(
          'Medical reports shared successfully with Dr. ${_selectedDoctor!.fullName}',
        );
      } else {
        _showErrorSnackBar('Failed to share medical reports');
      }
    } catch (e) {
      _showErrorSnackBar('Error sharing reports: $e');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share Medical Reports',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
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
                  Tab(text: 'Select Doctor'),
                  Tab(text: 'Select Reports'),
                  Tab(text: 'Review & Send'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSelectDoctorTab(),
                  _buildSelectReportsTab(),
                  _buildReviewTab(),
                ],
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceVariantColor(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: _isSharing ? 'Sharing...' : 'Share Reports',
                      onPressed: _isSharing ? null : _shareReports,
                      isLoading: _isSharing,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectDoctorTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a doctor to share your medical reports with:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
          
          // Search Field
          TextField(
            controller: _doctorSearchController,
            decoration: InputDecoration(
              hintText: 'Search doctors by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _filterDoctors,
          ),
          const SizedBox(height: 16),

          // Doctors List
          Expanded(
            child: _isLoadingDoctors
                ? const Center(child: CircularProgressIndicator())
                : _filteredDoctors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: ThemeUtils.getTextSecondaryColor(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No doctors found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _filteredDoctors[index];
                          final isSelected = _selectedDoctor?.uid == doctor.uid;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: ThemeUtils.getPrimaryColor(context),
                                ),
                              ),
                              title: Text(
                                doctor.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: ThemeUtils.getTextPrimaryColor(context),
                                ),
                              ),
                              subtitle: Text(
                                doctor.email,
                                style: TextStyle(
                                  color: ThemeUtils.getTextSecondaryColor(context),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: ThemeUtils.getPrimaryColor(context),
                                    )
                                  : null,
                              selected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedDoctor = doctor;
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select medical reports to share:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),

          // Select All/None
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedReportIds.clear();
                    _selectedReportIds.addAll(
                      widget.availableReports.map((r) => r.id),
                    );
                  });
                },
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedReportIds.clear();
                  });
                },
                child: const Text('Select None'),
              ),
            ],
          ),

          // Reports List
          Expanded(
            child: widget.availableReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No medical reports available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.availableReports.length,
                    itemBuilder: (context, index) {
                      final report = widget.availableReports[index];
                      final isSelected = _selectedReportIds.contains(report.id);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedReportIds.add(report.id);
                              } else {
                                _selectedReportIds.remove(report.id);
                              }
                            });
                          },
                          title: Text(
                            report.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ThemeUtils.getTextPrimaryColor(context),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.typeDisplayName,
                                style: TextStyle(
                                  color: ThemeUtils.getTextSecondaryColor(context),
                                ),
                              ),
                              Text(
                                report.formattedDate,
                                style: TextStyle(
                                  color: ThemeUtils.getTextSecondaryColor(context),
                                  fontSize: 12,
                                ),
                              ),
                              if (report.doctorName != null)
                                Text(
                                  'Dr. ${report.doctorName}',
                                  style: TextStyle(
                                    color: ThemeUtils.getTextSecondaryColor(context),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          secondary: Icon(
                            Icons.description,
                            color: ThemeUtils.getPrimaryColor(context),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Allergies Section
          Text(
            'Patient Allergies:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          
          if (widget.patientAllergies.isEmpty)
            Text(
              'No allergies recorded',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.patientAllergies.map((allergy) {
                final isSelected = _selectedAllergies.contains(allergy);
                return FilterChip(
                  label: Text(allergy),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAllergies.add(allergy);
                      } else {
                        _selectedAllergies.remove(allergy);
                      }
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review and Send',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),

            // Selected Doctor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sharing with:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedDoctor != null)
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
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
                                  _selectedDoctor!.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: ThemeUtils.getTextPrimaryColor(context),
                                  ),
                                ),
                                Text(
                                  _selectedDoctor!.email,
                                  style: TextStyle(
                                    color: ThemeUtils.getTextSecondaryColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'No doctor selected',
                        style: TextStyle(
                          color: ThemeUtils.getErrorColor(context),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Reports
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Reports (${_selectedReportIds.length}):',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedReportIds.isEmpty)
                      Text(
                        'No reports selected',
                        style: TextStyle(
                          color: ThemeUtils.getErrorColor(context),
                        ),
                      )
                    else
                      ...widget.availableReports
                          .where((report) => _selectedReportIds.contains(report.id))
                          .map((report) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      size: 16,
                                      color: ThemeUtils.getPrimaryColor(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${report.title} (${report.formattedDate})',
                                        style: TextStyle(
                                          color: ThemeUtils.getTextPrimaryColor(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Allergies
            if (_selectedAllergies.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Allergies (${_selectedAllergies.length}):',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _selectedAllergies.map((allergy) => Chip(
                          label: Text(allergy),
                          backgroundColor: Colors.red[50],
                          labelStyle: TextStyle(color: Colors.red[700]),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Expiration Date
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Expires:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${_expirationDate.day}/${_expirationDate.month}/${_expirationDate.year}',
                        style: TextStyle(
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expirationDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _expirationDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message (Optional):',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Add a message for the doctor...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}