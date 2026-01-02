import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/medicine_model.dart';
import '../../services/medicine/medicine_service.dart';
import '../../widgets/common/custom_button.dart';

/// Detailed medicine information screen
class MedicineDetailScreen extends ConsumerStatefulWidget {
  final MedicineModel medicine;

  const MedicineDetailScreen({
    super.key,
    required this.medicine,
  });

  @override
  ConsumerState<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MedicineModel> _alternatives = [];
  bool _isLoadingAlternatives = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAlternatives();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlternatives() async {
    setState(() {
      _isLoadingAlternatives = true;
    });

    try {
      final alternatives = await MedicineService.getMedicineAlternatives(widget.medicine.id);
      setState(() {
        _alternatives = alternatives;
        _isLoadingAlternatives = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAlternatives = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.medicine.displayName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Medicine Header
          _buildMedicineHeader(),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDosageTab(),
                _buildSideEffectsTab(),
                _buildAlternativesTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildMedicineHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication,
                  color: AppColors.textOnPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.medicine.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.medicine.genericName != null &&
                        widget.medicine.genericName != widget.medicine.name) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Generic: ${widget.medicine.genericName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textOnPrimary.withOpacity(0.9),
                        ),
                      ),
                    ],
                    if (widget.medicine.manufacturer != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'By ${widget.medicine.manufacturer}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.medicine.price != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.medicine.formattedPrice,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.medicine.strength != null) ...[
                _buildHeaderChip(
                  widget.medicine.strength!,
                  Icons.fitness_center,
                ),
                const SizedBox(width: 8),
              ],
              if (widget.medicine.dosageForm != null) ...[
                _buildHeaderChip(
                  widget.medicine.dosageForm!,
                  Icons.medication_liquid,
                ),
                const SizedBox(width: 8),
              ],
              _buildHeaderChip(
                widget.medicine.prescriptionText,
                widget.medicine.isPrescriptionRequired == true
                    ? Icons.receipt_long
                    : Icons.shopping_cart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textOnPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Dosage'),
          Tab(text: 'Side Effects'),
          Tab(text: 'Alternatives'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.medicine.description != null) ...[
            _buildInfoSection(
              'Description',
              widget.medicine.description!,
              Icons.description,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.uses != null) ...[
            _buildInfoSection(
              'Uses',
              widget.medicine.uses!,
              Icons.healing,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.composition != null) ...[
            _buildInfoSection(
              'Composition',
              widget.medicine.composition!,
              Icons.science,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.therapeuticClass != null) ...[
            _buildInfoSection(
              'Therapeutic Class',
              widget.medicine.therapeuticClass!,
              Icons.category,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.storage != null) ...[
            _buildInfoSection(
              'Storage Instructions',
              widget.medicine.storage!,
              Icons.storage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDosageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.medicine.dosage != null) ...[
            _buildInfoSection(
              'Dosage',
              widget.medicine.dosage!,
              Icons.schedule,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.administration != null) ...[
            _buildInfoSection(
              'How to Take',
              widget.medicine.administration!,
              Icons.info,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.precautions != null && widget.medicine.precautions!.isNotEmpty) ...[
            _buildListSection(
              'Precautions',
              widget.medicine.precautions!,
              Icons.warning,
              AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSideEffectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.medicine.sideEffects != null && widget.medicine.sideEffects!.isNotEmpty) ...[
            _buildListSection(
              'Side Effects',
              widget.medicine.sideEffects!,
              Icons.warning_amber,
              AppColors.error,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.contraindications != null && widget.medicine.contraindications!.isNotEmpty) ...[
            _buildListSection(
              'Contraindications',
              widget.medicine.contraindications!,
              Icons.block,
              AppColors.error,
            ),
            const SizedBox(height: 20),
          ],
          if (widget.medicine.interactions != null && widget.medicine.interactions!.isNotEmpty) ...[
            _buildListSection(
              'Drug Interactions',
              widget.medicine.interactions!,
              Icons.merge_type,
              AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlternativesTab() {
    if (_isLoadingAlternatives) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_alternatives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No alternatives found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alternatives.length,
      itemBuilder: (context, index) {
        final alternative = _alternatives[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medication,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(alternative.displayName),
            subtitle: alternative.manufacturer != null
                ? Text('By ${alternative.manufacturer}')
                : null,
            trailing: alternative.price != null
                ? Text(
                    alternative.formattedPrice,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineDetailScreen(medicine: alternative),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Find Nearby Pharmacy',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.local_pharmacy, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        const Text('Find Pharmacy'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Find pharmacies near you that stock this medicine.'),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.location_on, color: AppColors.primary),
                          title: const Text('Nearby Pharmacies'),
                          subtitle: const Text('Within 5 km radius'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Implement map view with pharmacies
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening pharmacy map...')),
                            );
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.phone, color: AppColors.success),
                          title: const Text('Call Pharmacy'),
                          subtitle: const Text('Get availability info'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling pharmacy...')),
                            );
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              backgroundColor: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Consult Doctor',
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to doctor consultation
              },
            ),
          ),
        ],
      ),
    );
  }
}
