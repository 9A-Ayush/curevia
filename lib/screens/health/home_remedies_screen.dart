import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../models/home_remedy_model.dart';
import '../../providers/home_remedies_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/theme_utils.dart';
import '../../services/data_initialization_service.dart';
import '../../services/firebase/home_remedies_service.dart';
import 'remedy_detail_screen.dart';

/// Home Remedies Screen for natural treatments and herbs
class HomeRemediesScreen extends ConsumerStatefulWidget {
  const HomeRemediesScreen({super.key});

  @override
  ConsumerState<HomeRemediesScreen> createState() => _HomeRemediesScreenState();
}

class _HomeRemediesScreenState extends ConsumerState<HomeRemediesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategory;
  String _searchQuery = '';
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Reduced to 2 tabs
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  void _loadInitialData() {
    setState(() {
      _selectedCategory = null;
    });
  }

  /// Force seed home remedies data
  Future<void> _forceSeedData() async {
    setState(() {
      _isSeeding = true;
    });
    
    try {
      // Invalidate all providers to force refresh
      ref.invalidate(remedyCategoriesProvider);
      ref.invalidate(allRemediesProvider);
      ref.invalidate(seedRemediesDataProvider);
      
      // Force seed data
      await ref.read(seedRemediesDataProvider.future);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home remedies data refreshed successfully'),
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

  /// Share remedy information
  void _shareRemedy(HomeRemedyModel remedy) {
    final StringBuffer shareText = StringBuffer();
    
    shareText.writeln('🌿 ${remedy.title}');
    shareText.writeln('Category: ${remedy.categoryName}');
    shareText.writeln();
    shareText.writeln('📝 ${remedy.description}');
    shareText.writeln();
    shareText.writeln('⏱️ Preparation Time: ${remedy.preparationTime}');
    shareText.writeln('📊 Difficulty: ${remedy.difficulty}');
    
    if (remedy.tags.isNotEmpty) {
      shareText.writeln('🏷️ Tags: ${remedy.tags.join(', ')}');
    }
    
    shareText.writeln();
    shareText.writeln('---');
    shareText.writeln('Shared from Curevia - Your Smart Path to Better Health');
    shareText.writeln('⚠️ Always consult with a healthcare provider before using home remedies.');
    
    Share.share(
      shareText.toString(),
      subject: '🌿 Home Remedy: ${remedy.title}',
    );
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

  /// Force complete reseed of all data
  Future<void> _forceCompleteReseed() async {
    try {
      setState(() {
        _isSeeding = true;
      });
      
      print('=== FORCE COMPLETE RESEED ===');
      
      // Clear and reseed remedies
      await HomeRemediesService.seedHomeRemediesData();
      
      // Invalidate all providers
      ref.invalidate(remedyCategoriesProvider);
      ref.invalidate(allRemediesProvider);
      ref.invalidate(seedRemediesDataProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete reseed completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in complete reseed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complete reseed failed: $e'),
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

  /// Clear all data (for testing)
  Future<void> _clearAllData() async {
    try {
      setState(() {
        _isSeeding = true;
      });
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text('This will delete all remedies data. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // This would require adding a clear method to the service
        print('Data clearing requested - implement clear method in service');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data clearing not implemented yet'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error clearing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Home Remedies'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
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
                case 'clear_data':
                  _clearAllData();
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
              const PopupMenuItem(
                value: 'clear_data',
                child: Text('Clear All Data'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
          indicatorColor: AppColors.textOnPrimary,
          tabs: const [
            Tab(text: 'Remedies'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Header
          _buildSearchHeader(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRemediesTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Natural Healing',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover time-tested natural remedies and herbal treatments',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textOnPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _searchController,
            hintText: 'Search remedies, conditions, or herbs...',
            prefixIcon: Icons.search,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery = '';
                      _loadInitialData();
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRemediesTab() {
    return Column(
      children: [
        // Categories Filter
        _buildCategoriesFilter(),

        // Remedies List
        Expanded(child: _buildRemediesList()),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    final categoriesAsync = ref.watch(remedyCategoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) {
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip('All', null);
              }

              final category = categories[index - 1];
              return _buildCategoryChip(category.name, category.name);
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (error, stack) => const SizedBox(height: 60),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? value : null;
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        labelStyle: TextStyle(
          color: isSelected
              ? AppColors.primary
              : ThemeUtils.getTextSecondaryColor(context),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRemediesList() {
    // Show loading during seeding
    if (_isSeeding) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading remedies data...'),
          ],
        ),
      );
    }

    // Use search if there's a query, otherwise use category filter
    if (_searchQuery.isNotEmpty) {
      final searchAsync = ref.watch(searchRemediesProvider(_searchQuery));
      return searchAsync.when(
        data: (remedies) => _buildRemediesGrid(remedies),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      );
    } else if (_selectedCategory != null) {
      final categoryAsync = ref.watch(remediesByCategoryProvider(_selectedCategory!));
      return categoryAsync.when(
        data: (remedies) => _buildRemediesGrid(remedies),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      );
    } else {
      final allRemediesAsync = ref.watch(allRemediesProvider);
      return allRemediesAsync.when(
        data: (remedies) => _buildRemediesGrid(remedies),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      );
    }
  }

  Widget _buildRemediesGrid(List<HomeRemedyModel> remedies) {
    if (remedies.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: remedies.length,
      itemBuilder: (context, index) {
        final remedy = remedies[index];
        return _buildRemedyCard(remedy);
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
            'Unable to load remedies',
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
              ref.invalidate(remedyCategoriesProvider);
              ref.invalidate(allRemediesProvider);
              ref.invalidate(seedRemediesDataProvider);
              setState(() {
                _isSeeding = true;
              });
              // Retry seeding
              ref.read(seedRemediesDataProvider.future).then((_) {
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
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist,
            size: 64,
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No remedies found for "$_searchQuery"'
                : 'No remedies available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different terms or browse categories',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRemedyCard(HomeRemedyModel remedy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RemedyDetailScreen(remedy: remedy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Remedy Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_florist,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Remedy Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                remedy.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, size: 20),
                              onPressed: () => _shareRemedy(remedy),
                              color: AppColors.primary,
                              tooltip: 'Share remedy',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remedy.categoryName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remedy.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(
                                  context,
                                ),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Remedy Details
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(
                    remedy.preparationTime,
                    Icons.schedule,
                    AppColors.info,
                  ),
                  _buildInfoChip(
                    remedy.difficulty,
                    Icons.trending_up,
                    _getDifficultyColor(remedy.difficulty),
                  ),
                ],
              ),

              if (remedy.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: remedy.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  Widget _buildCategoriesTab() {
    // Show loading during seeding
    if (_isSeeding) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading categories...'),
          ],
        ),
      );
    }

    final categoriesAsync = ref.watch(remedyCategoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0, // Changed from 1.2 to 1.0 for more vertical space
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildCategoryCard(HomeRemedyCategoryModel category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _tabController.animateTo(0); // Switch to remedies tab
          setState(() {
            _selectedCategory = category.name;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category.name),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  category.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.remedies.length} remedies',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'respiratory health':
        return Icons.air;
      case 'immunity boosting':
        return Icons.shield;
      case 'skin care':
        return Icons.face;
      case 'digestive health':
        return Icons.restaurant;
      case 'oral care':
        return Icons.medical_services;
      case 'hair care':
        return Icons.face_retouching_natural;
      case 'sleep and relaxation':
        return Icons.bedtime;
      case 'joint and muscle pain relief':
        return Icons.healing;
      case 'stress and mental wellness':
        return Icons.psychology;
      case 'women\'s health':
        return Icons.female;
      case 'children\'s common ailments':
        return Icons.child_care;
      case 'first aid':
        return Icons.medical_services;
      case 'pet-safe remedies':
        return Icons.pets;
      case 'ayurveda-based treatments':
        return Icons.spa;
      case 'disease-specific remedies':
        return Icons.local_hospital;
      case 'herb encyclopedia':
        return Icons.eco;
      case 'common otc natural products':
        return Icons.local_pharmacy;
      default:
        return Icons.local_florist;
    }
  }
}
