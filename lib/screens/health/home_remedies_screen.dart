import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/home_remedy_model.dart';
import '../../services/home_remedies/home_remedies_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/theme_utils.dart';
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

  List<HomeRemedyModel> _remedies = [];
  List<RemedyCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
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
      _searchQuery = query;
      _debounceSearch();
    }
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == _searchController.text.trim()) {
        _performSearch();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await HomeRemediesService.getRemedyCategories();
      final remedies = await HomeRemediesService.getPopularRemedies(limit: 20);

      setState(() {
        _categories = categories;
        _remedies = remedies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      await _loadInitialData();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final remedies = await HomeRemediesService.searchRemedies(_searchQuery);
      setState(() {
        _remedies = remedies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _filterByCategory(String? category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      List<HomeRemedyModel> remedies;
      if (category == null) {
        remedies = await HomeRemediesService.getPopularRemedies(limit: 20);
      } else {
        remedies = await HomeRemediesService.getRemediesByCategory(category);
      }

      setState(() {
        _remedies = remedies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.textOnPrimary,
          tabs: const [
            Tab(text: 'Remedies'),
            Tab(text: 'Categories'),
            Tab(text: 'Herbs'),
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
                _buildHerbsTab(),
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
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
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
        if (_categories.isNotEmpty) _buildCategoriesFilter(),

        // Remedies List
        Expanded(child: _buildRemediesList()),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip('All', null);
          }

          final category = _categories[index - 1];
          return _buildCategoryChip(category.name, category.id);
        },
      ),
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
          _filterByCategory(selected ? value : null);
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_remedies.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _remedies.length,
      itemBuilder: (context, index) {
        final remedy = _remedies[index];
        return _buildRemedyCard(remedy);
      },
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
                      color: AppColors.success.withValues(alpha: 0.1),
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
                                remedy.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (remedy.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Verified',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For ${remedy.condition}',
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
              Row(
                children: [
                  _buildInfoChip(
                    remedy.formattedPreparationTime,
                    Icons.schedule,
                    AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    remedy.difficulty,
                    Icons.trending_up,
                    _getDifficultyColor(remedy.difficulty),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    '${remedy.effectiveness}/5',
                    Icons.star,
                    AppColors.warning,
                  ),
                ],
              ),

              if (remedy.symptoms.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: remedy.symptoms.take(3).map((symptom) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        symptom,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(RemedyCategory category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _tabController.animateTo(0); // Switch to remedies tab
          _filterByCategory(category.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    category.color,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category.iconName),
                  color: _getCategoryColor(category.color),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${category.remedyCount} remedies',
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

  Widget _buildHerbsTab() {
    return FutureBuilder<List<HerbModel>>(
      future: HomeRemediesService.getHerbsEncyclopedia(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading herbs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          );
        }

        final herbs = snapshot.data ?? [];

        if (herbs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco,
                  size: 64,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'No herbs available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: herbs.length,
          itemBuilder: (context, index) {
            final herb = herbs[index];
            return _buildHerbCard(herb);
          },
        );
      },
    );
  }

  Widget _buildHerbCard(HerbModel herb) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.eco, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        herb.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        herb.scientificName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              herb.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: herb.properties.take(4).map((property) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    property,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'indigo':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'lungs':
        return Icons.air;
      case 'stomach':
        return Icons.restaurant;
      case 'face':
        return Icons.face;
      case 'healing':
        return Icons.healing;
      case 'shield':
        return Icons.shield;
      case 'sleep':
        return Icons.bedtime;
      default:
        return Icons.local_florist;
    }
  }
}
