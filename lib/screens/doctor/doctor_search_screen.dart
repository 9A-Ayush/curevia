import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_text_field.dart';

import '../../providers/doctor_provider.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../widgets/doctor/doctor_filters.dart';

/// Doctor search screen
class DoctorSearchScreen extends ConsumerStatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  ConsumerState<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends ConsumerState<DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorSearchProvider.notifier).getTopRatedDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(doctorSearchProvider.notifier).loadMore();
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    final filters = ref
        .read(doctorSearchProvider)
        .filters
        .copyWith(searchQuery: query.isEmpty ? null : query);
    ref.read(doctorSearchProvider.notifier).searchDoctors(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(doctorSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (searchState.filters.hasFilters)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                        color: ThemeUtils.getTextOnPrimaryColor(
                          context,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on,
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
                            'Find qualified doctors',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: ThemeUtils.getTextOnPrimaryColor(
                                    context,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Search by specialty, location, or name',
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
                Row(
                  children: [
                    _buildInfoChip(Icons.verified, 'Verified Doctors'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.star, 'Top Rated'),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'Search doctors, specialties...',
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch();
                  }
                });
              },
              onSubmitted: (value) => _performSearch(),
            ),
          ),

          // Quick Filters
          _buildQuickFilters(),

          // Results
          Expanded(child: _buildResults(searchState)),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('Nearby', 'nearby'),
          const SizedBox(width: 8),
          _buildFilterChip('Online', 'online'),
          const SizedBox(width: 8),
          _buildFilterChip('Top Rated', 'top_rated'),
          const SizedBox(width: 8),
          ...AppConstants.doctorSpecialties
              .take(5)
              .map(
                (specialty) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(specialty, specialty),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = value == null
        ? !ref.watch(doctorSearchProvider).filters.hasFilters
        : _isFilterSelected(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _applyQuickFilter(value),
      selectedColor: ThemeUtils.getPrimaryColor(context).withValues(alpha: 0.2),
      checkmarkColor: ThemeUtils.getPrimaryColor(context),
    );
  }

  bool _isFilterSelected(String value) {
    final filters = ref.watch(doctorSearchProvider).filters;
    switch (value) {
      case 'nearby':
        return filters.userLocation != null;
      case 'online':
        return filters.consultationType == 'online';
      case 'top_rated':
        return filters.minRating != null && filters.minRating! >= 4.0;
      default:
        return filters.specialty == value;
    }
  }

  void _applyQuickFilter(String? value) {
    final notifier = ref.read(doctorSearchProvider.notifier);

    if (value == null) {
      notifier.clearResults();
      notifier.getTopRatedDoctors();
    } else {
      switch (value) {
        case 'nearby':
          // TODO: Get user location and search nearby
          break;
        case 'online':
          notifier.searchDoctors(
            filters: const DoctorSearchFilters(consultationType: 'online'),
          );
          break;
        case 'top_rated':
          notifier.getTopRatedDoctors();
          break;
        default:
          notifier.getDoctorsBySpecialty(value);
      }
    }
  }

  Widget _buildResults(DoctorSearchState state) {
    if (state.isLoading && state.doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
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
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(doctorSearchProvider.notifier).getTopRatedDoctors(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.doctors.isEmpty) {
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
              'No doctors found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.doctors.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.doctors.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final doctor = state.doctors[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DoctorCard(doctor: doctor),
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorFilters(
        currentFilters: ref.read(doctorSearchProvider).filters,
        onApplyFilters: (filters) {
          ref
              .read(doctorSearchProvider.notifier)
              .searchDoctors(filters: filters);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeUtils.getTextOnPrimaryColor(context).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: ThemeUtils.getTextOnPrimaryColor(context),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextOnPrimaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
