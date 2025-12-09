import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../models/medicine_model.dart';
import '../../services/medicine/medicine_service.dart';
import '../../widgets/common/loading_overlay.dart';
import 'medicine_detail_screen.dart';

/// Medicine directory screen
class MedicineDirectoryScreen extends ConsumerStatefulWidget {
  const MedicineDirectoryScreen({super.key});

  @override
  ConsumerState<MedicineDirectoryScreen> createState() =>
      _MedicineDirectoryScreenState();
}

class _MedicineDirectoryScreenState
    extends ConsumerState<MedicineDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Load sample data for demonstration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSampleData();
    });
  }

  void _loadSampleData() {
    // For demo purposes, we'll use sample data
    // In production, this would load from Firestore
  }

  final List<String> _categories = [
    'All',
    'Pain Relief',
    'Antibiotics',
    'Vitamins',
    'Cold & Flu',
    'Digestive',
    'Heart',
    'Diabetes',
    'Blood Pressure',
  ];

  final List<Medicine> _medicines = [
    Medicine(
      name: 'Paracetamol',
      genericName: 'Acetaminophen',
      category: 'Pain Relief',
      description: 'Used to treat pain and reduce fever',
      dosage: '500mg - 1000mg every 4-6 hours',
      sideEffects: ['Nausea', 'Stomach upset', 'Allergic reactions'],
      precautions: ['Do not exceed 4g per day', 'Avoid alcohol'],
      price: '₹25 - ₹50',
    ),
    Medicine(
      name: 'Amoxicillin',
      genericName: 'Amoxicillin',
      category: 'Antibiotics',
      description: 'Antibiotic used to treat bacterial infections',
      dosage: '250mg - 500mg every 8 hours',
      sideEffects: ['Diarrhea', 'Nausea', 'Skin rash'],
      precautions: ['Complete full course', 'Take with food'],
      price: '₹80 - ₹150',
    ),
    Medicine(
      name: 'Vitamin D3',
      genericName: 'Cholecalciferol',
      category: 'Vitamins',
      description: 'Essential vitamin for bone health',
      dosage: '1000 IU - 2000 IU daily',
      sideEffects: ['Constipation', 'Kidney stones (high doses)'],
      precautions: ['Take with fat-containing meal'],
      price: '₹200 - ₹400',
    ),
    Medicine(
      name: 'Cetirizine',
      genericName: 'Cetirizine HCl',
      category: 'Cold & Flu',
      description: 'Antihistamine for allergies and cold symptoms',
      dosage: '10mg once daily',
      sideEffects: ['Drowsiness', 'Dry mouth', 'Fatigue'],
      precautions: ['Avoid alcohol', 'May cause drowsiness'],
      price: '₹30 - ₹80',
    ),
    Medicine(
      name: 'Omeprazole',
      genericName: 'Omeprazole',
      category: 'Digestive',
      description: 'Proton pump inhibitor for acid reflux',
      dosage: '20mg once daily before meals',
      sideEffects: ['Headache', 'Nausea', 'Diarrhea'],
      precautions: ['Take before breakfast', 'Long-term use monitoring'],
      price: '₹60 - ₹120',
    ),
  ];

  List<Medicine> get _filteredMedicines {
    var filtered = _medicines;

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((m) => m.category == _selectedCategory)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (m) =>
                m.name.toLowerCase().contains(query) ||
                m.genericName.toLowerCase().contains(query) ||
                m.description.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Medicine Directory'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ThemeUtils.isDarkMode(context)
                  ? AppColors.darkPrimaryGradient
                  : AppColors.primaryGradient,
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
                        color: ThemeUtils.getTextOnPrimaryColor(
                          context,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_pharmacy,
                        color: ThemeUtils.getTextOnPrimaryColor(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medicine Information',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: ThemeUtils.getTextOnPrimaryColor(
                                    context,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Find detailed information about medicines',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ThemeUtils.getTextOnPrimaryColor(
                                    context,
                                  ).withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getWarningColor(
                      context,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ThemeUtils.getWarningColor(
                        context,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: ThemeUtils.getTextOnPrimaryColor(context),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Always consult a doctor before taking any medication',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getTextOnPrimaryColor(
                                  context,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Search medicines...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ThemeUtils.getPrimaryColor(context)
                          : ThemeUtils.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? ThemeUtils.getPrimaryColor(context)
                            : ThemeUtils.getBorderLightColor(context),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? ThemeUtils.getTextOnPrimaryColor(context)
                              : ThemeUtils.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Medicines list
          Expanded(child: _buildMedicinesList()),
        ],
      ),
    );
  }

  Widget _buildMedicinesList() {
    final medicines = _filteredMedicines;

    if (medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No medicines found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final medicine = medicines[index];
        return _buildMedicineCard(medicine);
      },
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 8,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    medicine.category,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(medicine.category),
                  color: _getCategoryColor(medicine.category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      medicine.genericName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    medicine.category,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  medicine.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getCategoryColor(medicine.category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            medicine.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.medication,
                size: 16,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  medicine.dosage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ),
              Text(
                medicine.price,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ThemeUtils.getPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showMedicineDetails(medicine),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeUtils.getPrimaryColor(context),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pain Relief':
        return AppColors.error;
      case 'Antibiotics':
        return AppColors.warning;
      case 'Vitamins':
        return AppColors.success;
      case 'Cold & Flu':
        return AppColors.info;
      case 'Digestive':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pain Relief':
        return Icons.healing;
      case 'Antibiotics':
        return Icons.biotech;
      case 'Vitamins':
        return Icons.eco;
      case 'Cold & Flu':
        return Icons.ac_unit;
      case 'Digestive':
        return Icons.restaurant;
      default:
        return Icons.medication;
    }
  }

  void _showMedicineDetails(Medicine medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: ThemeUtils.getBorderLightColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      medicine.genericName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildDetailSection('Description', medicine.description),
                    _buildDetailSection('Dosage', medicine.dosage),
                    _buildDetailSection('Price Range', medicine.price),

                    const SizedBox(height: 16),
                    Text(
                      'Side Effects',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final effect in medicine.sideEffects)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: ThemeUtils.getErrorColor(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              effect,
                              style: TextStyle(
                                color: ThemeUtils.getTextPrimaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    Text(
                      'Precautions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final precaution in medicine.precautions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: ThemeUtils.getWarningColor(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                precaution,
                                style: TextStyle(
                                  color: ThemeUtils.getTextPrimaryColor(
                                    context,
                                  ),
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

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }


}

class Medicine {
  final String name;
  final String genericName;
  final String category;
  final String description;
  final String dosage;
  final List<String> sideEffects;
  final List<String> precautions;
  final String price;

  Medicine({
    required this.name,
    required this.genericName,
    required this.category,
    required this.description,
    required this.dosage,
    required this.sideEffects,
    required this.precautions,
    required this.price,
  });
}
