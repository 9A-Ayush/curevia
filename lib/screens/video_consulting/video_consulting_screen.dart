import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../providers/doctor_provider.dart';
import '../../services/firebase/doctor_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../widgets/doctor/doctor_filters.dart';
import '../../utils/theme_utils.dart';
import 'doctor_profile_screen.dart';

/// Main video consulting screen with doctor list and search
class VideoConsultingScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const VideoConsultingScreen({super.key, this.showBackButton = false});

  @override
  ConsumerState<VideoConsultingScreen> createState() =>
      _VideoConsultingScreenState();
}

class _VideoConsultingScreenState extends ConsumerState<VideoConsultingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DoctorSearchFilters _currentFilters = const DoctorSearchFilters();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
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
      // Load more functionality can be added here if needed
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Ensure sample doctors exist
      final verifiedDoctors = await DoctorService.getVerifiedDoctors();
      if (verifiedDoctors.isEmpty) {
        print('No doctors found, creating sample doctors...');
        await DoctorService.createSampleDoctors();
        ref.invalidate(verifiedDoctorsProvider);
      }

      // Load doctors with video consultation filter
      ref.read(doctorSearchProvider.notifier).searchDoctors(
        filters: _currentFilters.copyWith(
          consultationType: 'online', // Video consultation specific
        ),
      );
    } catch (e) {
      print('Error loading doctors: $e');
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorFilters(
        currentFilters: _currentFilters.copyWith(
          consultationType: 'online',
        ),
        onApplyFilters: (filters) {
          setState(() {
            _currentFilters = filters;
            _searchController.text = filters.searchQuery ?? '';
          });
          ref.read(doctorSearchProvider.notifier).searchDoctors(filters: filters);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onSearchChanged(String query) {
    final filters = _currentFilters.copyWith(
      searchQuery: query.isEmpty ? null : query,
      consultationType: 'online',
    );
    setState(() {
      _currentFilters = filters;
    });
    ref.read(doctorSearchProvider.notifier).searchDoctors(filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final doctorSearchState = ref.watch(doctorSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Consultation'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_currentFilters.hasFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
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
          // Header with search
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.video_call,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video Consultation',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Connect with doctors online',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                CustomTextField(
                  controller: _searchController,
                  hintText: 'Search doctors by name or specialty...',
                  prefixIcon: Icons.search,
                  onChanged: _onSearchChanged,
                  fillColor: Colors.white,
                  borderRadius: 12,
                ),
              ],
            ),
          ),

          // Doctors list
          Expanded(child: _buildDoctorsList(doctorSearchState)),
        ],
      ),
    );
  }

  Widget _buildDoctorsList(AsyncValue<DoctorSearchState> doctorSearchState) {
    return doctorSearchState.when(
      data: (searchState) {
        if (searchState.isLoading && searchState.doctors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (searchState.doctors.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: searchState.doctors.length,
          itemBuilder: (context, index) {
            final doctor = searchState.doctors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DoctorCard(
                doctor: doctor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorProfileScreen(doctor: doctor),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading doctors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
              Icons.video_call_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Clear Filters',
              onPressed: () {
                setState(() {
                  _currentFilters = const DoctorSearchFilters();
                  _searchController.clear();
                });
                _loadInitialData();
              },
              backgroundColor: AppColors.primary,
              textColor: AppColors.textOnPrimary,
            ),
          ],
        ),
      ),
    );
  }
}