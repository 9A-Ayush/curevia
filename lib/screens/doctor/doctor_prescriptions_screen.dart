import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import 'create_prescription_screen.dart';

/// Doctor prescriptions management screen
class DoctorPrescriptionsScreen extends ConsumerStatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  ConsumerState<DoctorPrescriptionsScreen> createState() => _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState extends ConsumerState<DoctorPrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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

  void _loadPrescriptions() {
    final user = ref.read(authProvider).userModel;
    if (user != null) {
      ref.read(prescriptionProvider.notifier).loadDoctorPrescriptions(user.uid);
    }
  }

  List<PrescriptionModel> _getFilteredPrescriptions(List<PrescriptionModel> prescriptions, String filter) {
    List<PrescriptionModel> filtered;
    
    switch (filter) {
      case 'today':
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        filtered = prescriptions.where((p) => 
            p.prescriptionDate.year == today.year &&
            p.prescriptionDate.month == today.month &&
            p.prescriptionDate.day == today.day).toList();
        break;
      case 'recent':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        filtered = prescriptions.where((p) => p.prescriptionDate.isAfter(weekAgo)).toList();
        break;
      default:
        filtered = prescriptions;
    }
    
    if (_searchQuery.isEmpty) return filtered;
    
    return filtered.where((prescription) {
      return prescription.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             prescription.diagnosis?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
             prescription.medicines.any((medicine) => 
                 medicine.medicineName.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionState = ref.watch(prescriptionProvider);
    final allPrescriptions = prescriptionState.prescriptions;
    final todayPrescriptions = _getFilteredPrescriptions(allPrescriptions, 'today');
    final recentPrescriptions = _getFilteredPrescriptions(allPrescriptions, 'recent');
    final filteredAllPrescriptions = _getFilteredPrescriptions(allPrescriptions, 'all');

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Prescriptions'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          tabs: [
            Tab(text: 'Today (${todayPrescriptions.length})'),
            Tab(text: 'Recent (${recentPrescriptions.length})'),
            Tab(text: 'All (${filteredAllPrescriptions.length})'),
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
            child: prescriptionState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prescriptionState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${prescriptionState.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadPrescriptions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPrescriptionsList(todayPrescriptions),
                          _buildPrescriptionsList(recentPrescriptions),
                          _buildPrescriptionsList(filteredAllPrescriptions),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreatePrescription(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Prescription'),
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
              'Create your first prescription to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
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
                          prescription.patientName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                        prescription.diagnosis!,
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
                        prescription.medicines.take(2).map((m) => m.medicineName).join(', ') +
                            (prescription.medicines.length > 2 ? '...' : ''),
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
        // Patient Info
        _buildDetailSection(
          'Patient Information',
          [
            _buildDetailRow('Name', prescription.patientName),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeUtils.getTextSecondaryColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicine.fullName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            medicine.completeInstruction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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

  void _navigateToCreatePrescription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePrescriptionScreen(),
      ),
    ).then((_) => _loadPrescriptions());
  }
}