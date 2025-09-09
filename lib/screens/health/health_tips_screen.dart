import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_text_field.dart';

/// Health tips screen with daily health advice
class HealthTipsScreen extends ConsumerStatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  ConsumerState<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends ConsumerState<HealthTipsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<HealthTip> _filteredTips = [];

  final List<String> _categories = [
    'All',
    'Nutrition',
    'Exercise',
    'Mental Health',
    'Sleep',
    'Hydration',
    'Prevention',
  ];

  final List<HealthTip> _healthTips = [
    HealthTip(
      id: '1',
      title: 'Stay Hydrated',
      description: 'Drink at least 8 glasses of water daily for optimal health. Water helps maintain body temperature, lubricates joints, and aids in digestion.',
      category: 'Hydration',
      icon: Icons.water_drop,
      color: AppColors.info,
      tips: [
        'Start your day with a glass of water',
        'Keep a water bottle with you',
        'Eat water-rich foods like fruits and vegetables',
        'Monitor your urine color - pale yellow is ideal',
      ],
    ),
    HealthTip(
      id: '2',
      title: 'Exercise Regularly',
      description: '30 minutes of daily exercise can improve your overall wellbeing, boost mood, and reduce risk of chronic diseases.',
      category: 'Exercise',
      icon: Icons.fitness_center,
      color: AppColors.success,
      tips: [
        'Start with 10-15 minutes if you\'re a beginner',
        'Choose activities you enjoy',
        'Include both cardio and strength training',
        'Take the stairs instead of elevators',
      ],
    ),
    HealthTip(
      id: '3',
      title: 'Eat Balanced Meals',
      description: 'Include fruits, vegetables, whole grains, and lean proteins in your daily diet for optimal nutrition.',
      category: 'Nutrition',
      icon: Icons.restaurant,
      color: AppColors.warning,
      tips: [
        'Fill half your plate with vegetables',
        'Choose whole grains over refined grains',
        'Include lean proteins like fish, chicken, beans',
        'Limit processed and sugary foods',
      ],
    ),
    HealthTip(
      id: '4',
      title: 'Get Quality Sleep',
      description: '7-9 hours of quality sleep is essential for good health, immune function, and mental clarity.',
      category: 'Sleep',
      icon: Icons.bedtime,
      color: AppColors.secondary,
      tips: [
        'Maintain a consistent sleep schedule',
        'Create a relaxing bedtime routine',
        'Keep your bedroom cool and dark',
        'Avoid screens 1 hour before bed',
      ],
    ),
    HealthTip(
      id: '5',
      title: 'Manage Stress',
      description: 'Chronic stress can impact your physical and mental health. Learn healthy coping strategies.',
      category: 'Mental Health',
      icon: Icons.psychology,
      color: AppColors.accent,
      tips: [
        'Practice deep breathing exercises',
        'Try meditation or mindfulness',
        'Stay connected with friends and family',
        'Take regular breaks during work',
      ],
    ),
    HealthTip(
      id: '6',
      title: 'Wash Your Hands',
      description: 'Regular handwashing is one of the best ways to prevent illness and infection.',
      category: 'Prevention',
      icon: Icons.wash,
      color: AppColors.primary,
      tips: [
        'Wash for at least 20 seconds with soap',
        'Wash before eating and after using restroom',
        'Use hand sanitizer when soap isn\'t available',
        'Avoid touching your face with unwashed hands',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredTips = _healthTips;
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
        title: const Text('Health Tips'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
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
              children: [
                CustomTextField(
                  controller: _searchController,
                  label: 'Search health tips...',
                  prefixIcon: Icons.search,
                  onChanged: (value) => _filterTips(),
                ),
                const SizedBox(height: 16),
                _buildCategoryFilter(),
              ],
            ),
          ),

          // Tips List
          Expanded(
            child: _filteredTips.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTips.length,
                    itemBuilder: (context, index) {
                      final tip = _filteredTips[index];
                      return _buildTipCard(tip);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: EdgeInsets.only(right: index < _categories.length - 1 ? 12 : 0),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _filterTips();
                });
              },
              backgroundColor: ThemeUtils.getSurfaceVariantColor(context),
              selectedColor: ThemeUtils.getPrimaryColor(context).withValues(alpha: 0.2),
              checkmarkColor: ThemeUtils.getPrimaryColor(context),
              labelStyle: TextStyle(
                color: isSelected 
                    ? ThemeUtils.getPrimaryColor(context)
                    : ThemeUtils.getTextSecondaryColor(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard(HealthTip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTipDetails(tip),
        borderRadius: BorderRadius.circular(16),
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
                      color: tip.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tip.icon,
                      color: tip.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tip.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tip.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tip.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tip.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'No health tips found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterTips() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredTips = _healthTips.where((tip) {
        final matchesSearch = query.isEmpty ||
            tip.title.toLowerCase().contains(query) ||
            tip.description.toLowerCase().contains(query) ||
            tip.category.toLowerCase().contains(query);
        
        final matchesCategory = _selectedCategory == 'All' ||
            tip.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showTipDetails(HealthTip tip) {
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
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: tip.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            tip.icon,
                            color: tip.color,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: tip.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tip.category,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: tip.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tips to Follow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...tip.tips.map((tipText) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 8, right: 12),
                            decoration: BoxDecoration(
                              color: tip.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tipText,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HealthTip {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final List<String> tips;

  HealthTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.tips,
  });
}
