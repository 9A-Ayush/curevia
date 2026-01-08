import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../services/data_initialization_service.dart';
import '../../services/firebase/medicine_service.dart';

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
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
  }

  /// Force seed medicine data
  Future<void> _forceSeedData() async {
    setState(() {
      _isSeeding = true;
    });
    
    try {
      // Invalidate all providers to force refresh
      ref.invalidate(medicineCategoriesProvider);
      ref.invalidate(allMedicinesProvider);
      ref.invalidate(seedMedicineDataProvider);
      
      // Force seed data
      await ref.read(seedMedicineDataProvider.future);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine data refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  /// Test data initialization manually
  Future<void> _testDataInitialization() async {
    try {
      setState(() {
        _isSeeding = true;
      });
      
      print('=== MANUAL DATA INITIALIZATION TEST ===');
      await DataInitializationService.forceReinitialize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data initialization test completed - check console'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in manual data initialization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  /// Force complete reseed of all medicine data
  Future<void> _forceCompleteReseed() async {
    try {
      setState(() {
        _isSeeding = true;
      });
      
      print('=== FORCE COMPLETE MEDICINE RESEED ===');
      
      // Clear and reseed medicines
      await MedicineService.seedMedicineData();
      
      // Invalidate all providers
      ref.invalidate(medicineCategoriesProvider);
      ref.invalidate(allMedicinesProvider);
      ref.invalidate(seedMedicineDataProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete medicine reseed completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in complete medicine reseed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complete medicine reseed failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
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
        actions: [
          IconButton(
            onPressed: _forceSeedData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'test_init':
                  _testDataInitialization();
                  break;
                case 'force_reseed':
                  _forceCompleteReseed();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test_init',
                child: Text('Test Data Init'),
              ),
              const PopupMenuItem(
                value: 'force_reseed',
                child: Text('Force Complete Reseed'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
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
                        ).withOpacity(0.2),
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
                                  ).withOpacity(0.9),
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
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ThemeUtils.getWarningColor(
                        context,
                      ).withOpacity(0.3),
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
          _buildCategoryFilter(),

          // Medicines list
          Expanded(child: _buildMedicinesList()),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categoriesAsync = ref.watch(medicineCategoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) {
        final allCategories = ['All', ...categories];
        
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final category = allCategories[index];
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
        );
      },
      loading: () => const SizedBox(height: 50),
      error: (error, stack) => const SizedBox(height: 50),
    );
  }

  Widget _buildMedicinesList() {
    // Show loading during seeding
    if (_isSeeding) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading medicine data...'),
          ],
        ),
      );
    }

    // Use search if there's a query, otherwise use category filter
    if (_searchController.text.isNotEmpty) {
      final searchAsync = ref.watch(searchMedicinesProvider(_searchController.text));
      return searchAsync.when(
        data: (medicines) => _buildMedicinesGrid(medicines),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      );
    } else if (_selectedCategory != 'All') {
      final categoryAsync = ref.watch(medicinesByCategoryProvider(_selectedCategory));
      return categoryAsync.when(
        data: (medicines) => _buildMedicinesGrid(medicines),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      );
    } else {
      final allMedicinesAsync = ref.watch(allMedicinesProvider);
      return allMedicinesAsync.when(
        data: (medicines) => _buildMedicinesGrid(medicines),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      );
    }
  }

  Widget _buildMedicinesGrid(List<MedicineModel> medicines) {
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

  Widget _buildErrorState() {
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
            'Unable to load medicines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Force refresh all providers
              ref.invalidate(medicineCategoriesProvider);
              ref.invalidate(allMedicinesProvider);
              ref.invalidate(seedMedicineDataProvider);
              setState(() {
                _isSeeding = true;
              });
              // Retry seeding
              ref.read(seedMedicineDataProvider.future).then((_) {
                if (mounted) {
                  setState(() {
                    _isSeeding = false;
                  });
                }
              }).catchError((e) {
                if (mounted) {
                  setState(() {
                    _isSeeding = false;
                  });
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeUtils.getPrimaryColor(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine) {
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
                    medicine.categoryName,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(medicine.categoryName),
                  color: _getCategoryColor(medicine.categoryName),
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
                      medicine.chemical,
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
                    medicine.categoryName,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  medicine.categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getCategoryColor(medicine.categoryName),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            medicine.uses,
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
      case 'Vitamins & Supplements':
        return AppColors.success;
      case 'Common Cold & Flu':
        return AppColors.info;
      case 'Digestive Health':
        return AppColors.secondary;
      case 'Heart (Cardiac Care)':
        return AppColors.error;
      case 'Diabetes':
        return AppColors.warning;
      case 'Blood Pressure':
        return AppColors.primary;
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
      case 'Vitamins & Supplements':
        return Icons.eco;
      case 'Common Cold & Flu':
        return Icons.ac_unit;
      case 'Digestive Health':
        return Icons.restaurant;
      case 'Heart (Cardiac Care)':
        return Icons.favorite;
      case 'Diabetes':
        return Icons.bloodtype;
      case 'Blood Pressure':
        return Icons.monitor_heart;
      default:
        return Icons.medication;
    }
  }

  void _showMedicineDetails(MedicineModel medicine) {
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
                      medicine.chemical,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildDetailSection('Uses', medicine.uses),
                    _buildDetailSection('Dosage', medicine.dosage),
                    _buildDetailSection('Price Range', medicine.price),

                    const SizedBox(height: 16),
                    Text(
                      'Available Brands',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: medicine.brands.map((brand) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ThemeUtils.getPrimaryColor(context).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          brand,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeUtils.getPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
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
