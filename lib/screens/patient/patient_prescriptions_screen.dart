import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/prescription_service.dart';
import '../../utils/theme_utils.dart';

/// Patient prescriptions screen
class PatientPrescriptionsScreen extends ConsumerStatefulWidget {
  const PatientPrescriptionsScreen({super.key});

  @override
  ConsumerState<PatientPrescriptionsScreen> createState() => _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState extends ConsumerState<PatientPrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PrescriptionModel> _allPrescriptions = [];
  List<PrescriptionModel> _activePrescriptions = [];
  List<PrescriptionModel> _completedPrescriptions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) return;

      final prescriptions = await PrescriptionService.getPatientPrescriptionsComprehensive(
        user.uid,
        user.fullName,
      );
      
      final now = DateTime.now();
      
      setState(() {
        _allPrescriptions = prescriptions;
        
        // Active prescriptions: those with medicines that are still being taken
        _activePrescriptions = prescriptions.where((prescription) {
          return prescription.medicines.any((medicine) {
            final endDate = prescription.prescriptionDate.add(Duration(days: medicine.duration));
            return endDate.isAfter(now);
          });
        }).toList();
        
        // Completed prescriptions: those where all medicines are finished
        _completedPrescriptions = prescriptions.where((prescription) {
          return prescription.medicines.every((medicine) {
            final endDate = prescription.prescriptionDate.add(Duration(days: medicine.duration));
            return endDate.isBefore(now);
          });
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prescriptions: $e')),
        );
      }
    }
  }

  List<PrescriptionModel> _getFilteredPrescriptions(List<PrescriptionModel> prescriptions) {
    if (_searchQuery.isEmpty) return prescriptions;
    
    return prescriptions.where((prescription) {
      return prescription.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             prescription.diagnosis?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
             prescription.medicines.any((medicine) => 
                 medicine.medicineName.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          tabs: [
            Tab(text: 'Active (${_activePrescriptions.length})'),
            Tab(text: 'Completed (${_completedPrescriptions.length})'),
            Tab(text: 'All (${_allPrescriptions.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: ThemeUtils.getSurfaceColor(context),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search prescriptions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ThemeUtils.getBackgroundColor(context),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPrescriptionsList(_getFilteredPrescriptions(_activePrescriptions)),
                      _buildPrescriptionsList(_getFilteredPrescriptions(_completedPrescriptions)),
                      _buildPrescriptionsList(_getFilteredPrescriptions(_allPrescriptions)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList(List<PrescriptionModel> prescriptions) {
    if (prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No prescriptions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your prescriptions from doctors will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadPrescriptions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel prescription) {
    final isActive = _activePrescriptions.contains(prescription);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPrescriptionDetails(prescription),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${prescription.doctorName}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.doctorSpecialty,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Completed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isActive ? AppColors.success : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${prescription.medicineCount} medicines',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (prescription.diagnosis != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 16,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diagnosis: ${prescription.diagnosis!}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Medicines preview
              if (prescription.medicines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 16,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Medicines: ${prescription.medicines.take(2).map((m) => m.medicineName).join(', ')}${prescription.medicines.length > 2 ? '...' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Follow-up indicator
              if (prescription.hasFollowUp) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Follow-up: ${prescription.formattedFollowUpDate ?? 'As advised'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionDetails(PrescriptionModel prescription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeUtils.getTextSecondaryColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Prescription Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPrescriptionDetailsContent(prescription),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionDetailsContent(PrescriptionModel prescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Doctor Info
        _buildDetailSection(
          'Doctor Information',
          [
            _buildDetailRow('Doctor', 'Dr. ${prescription.doctorName}'),
            _buildDetailRow('Specialty', prescription.doctorSpecialty),
            _buildDetailRow('Date', prescription.formattedDate),
          ],
        ),
        
        // Diagnosis
        if (prescription.diagnosis != null)
          _buildDetailSection(
            'Diagnosis',
            [_buildDetailRow('', prescription.diagnosis!)],
          ),
        
        // Symptoms
        if (prescription.symptoms != null)
          _buildDetailSection(
            'Symptoms',
            [_buildDetailRow('', prescription.symptoms!)],
          ),
        
        // Medicines
        _buildDetailSection(
          'Prescribed Medicines',
          prescription.medicines.map((medicine) => 
            _buildMedicineCard(medicine)
          ).toList(),
        ),
        
        // Instructions
        if (prescription.instructions?.isNotEmpty == true)
          _buildDetailSection(
            'Instructions',
            prescription.instructions!.map((instruction) => 
              _buildDetailRow('', instruction)
            ).toList(),
          ),
        
        // Precautions
        if (prescription.precautions?.isNotEmpty == true)
          _buildDetailSection(
            'Precautions',
            prescription.precautions!.map((precaution) => 
              _buildDetailRow('', precaution)
            ).toList(),
          ),
        
        // Tests
        if (prescription.hasTests)
          _buildDetailSection(
            'Recommended Tests',
            prescription.tests!.map((test) => 
              _buildDetailRow('', test)
            ).toList(),
          ),
        
        // Follow-up
        if (prescription.hasFollowUp)
          _buildDetailSection(
            'Follow-up',
            [
              if (prescription.followUpDate != null)
                _buildDetailRow('Date', prescription.formattedFollowUpDate!),
              if (prescription.followUpInstructions != null)
                _buildDetailRow('Instructions', prescription.followUpInstructions!),
            ],
          ),
        
        // Notes
        if (prescription.notes != null)
          _buildDetailSection(
            'Additional Notes',
            [_buildDetailRow('', prescription.notes!)],
          ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: label.isEmpty
          ? Text(value, style: Theme.of(context).textTheme.bodyMedium)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '$label:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMedicineCard(PrescribedMedicine medicine) {
    final now = DateTime.now();
    final startDate = DateTime.now(); // Assuming prescription date as start
    final endDate = startDate.add(Duration(days: medicine.duration));
    final isActive = endDate.isAfter(now);
    final daysRemaining = endDate.difference(now).inDays;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive 
              ? AppColors.success.withValues(alpha: 0.3)
              : ThemeUtils.getTextSecondaryColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medicine.fullName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive 
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? 'Active' : 'Completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive ? AppColors.success : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            medicine.completeInstruction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (isActive && daysRemaining > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$daysRemaining days remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (medicine.instructions != null) ...[
            const SizedBox(height: 4),
            Text(
              medicine.instructions!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}