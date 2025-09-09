import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../services/video_consulting_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
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

  List<DoctorModel> _doctors = [];
  List<String> _specialties = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _selectedSpecialty;
  String? _searchQuery;
  double? _maxFee;
  double? _minRating;

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
      _loadMoreDoctors();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        VideoConsultingService.getAvailableDoctors(limit: 20),
        VideoConsultingService.getSpecialties(),
      ]);

      setState(() {
        _doctors = futures[0] as List<DoctorModel>;
        _specialties = futures[1] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading doctors: $e')));
      }
    }
  }

  Future<void> _loadMoreDoctors() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreDoctors = await VideoConsultingService.getAvailableDoctors(
        specialty: _selectedSpecialty,
        searchQuery: _searchQuery,
        maxFee: _maxFee,
        minRating: _minRating,
        limit: 10,
      );

      setState(() {
        _doctors.addAll(moreDoctors);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _searchDoctors() async {
    setState(() => _isLoading = true);

    try {
      final doctors = await VideoConsultingService.getAvailableDoctors(
        specialty: _selectedSpecialty,
        searchQuery: _searchQuery,
        maxFee: _maxFee,
        minRating: _minRating,
        limit: 20,
      );

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching doctors: $e')));
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Consultation'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        automaticallyImplyLeading: widget.showBackButton,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter doctors',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Search doctors by name, specialty...',
              prefixIcon: Icons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = null;
                        _searchDoctors();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              onChanged: (value) {
                _searchQuery = value.isEmpty ? null : value;
              },
              onSubmitted: (value) => _searchDoctors(),
            ),
          ),

          // Specialty filter chips
          if (_specialties.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _specialties.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSpecialtyChip('All', null);
                  }
                  final specialty = _specialties[index - 1];
                  return _buildSpecialtyChip(specialty, specialty);
                },
              ),
            ),

          // Doctors list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _doctors.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _doctors.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildDoctorCard(_doctors[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyChip(String label, String? value) {
    final isSelected = _selectedSpecialty == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSpecialty = selected ? value : null;
          });
          _searchDoctors();
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(doctor: doctor),
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
                children: [
                  // Doctor avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: doctor.profileImageUrl != null
                        ? NetworkImage(doctor.profileImageUrl!)
                        : null,
                    child: doctor.profileImageUrl == null
                        ? Icon(Icons.person, size: 30, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Doctor info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialty ?? 'General Physician',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.experienceText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Rating and fee
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (doctor.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doctor.rating!.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        doctor.consultationFeeText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Languages and availability
              Row(
                children: [
                  if (doctor.languages != null && doctor.languages!.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: doctor.languages!.take(3).map((language) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Text(
                              language,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Book now button
                  CustomButton(
                    text: 'Book Now',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DoctorProfileScreen(doctor: doctor),
                        ),
                      );
                    },
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ],
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
              Icons.video_call_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or filters',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Clear Filters',
              onPressed: () {
                setState(() {
                  _selectedSpecialty = null;
                  _searchQuery = null;
                  _maxFee = null;
                  _minRating = null;
                  _searchController.clear();
                });
                _searchDoctors();
              },
              backgroundColor: AppColors.primary,
              textColor: AppColors.textOnPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Doctors',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Rating filter
          Text(
            'Minimum Rating',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minRating ?? 0,
            min: 0,
            max: 5,
            divisions: 10,
            label: _minRating?.toStringAsFixed(1) ?? '0.0',
            onChanged: (value) {
              setState(() {
                _minRating = value == 0 ? null : value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Fee filter
          Text(
            'Maximum Fee (₹)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _maxFee ?? 2000,
            min: 0,
            max: 2000,
            divisions: 20,
            label: _maxFee?.toStringAsFixed(0) ?? '2000',
            onChanged: (value) {
              setState(() {
                _maxFee = value == 2000 ? null : value;
              });
            },
          ),

          const SizedBox(height: 24),

          // Apply filters button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Apply Filters',
              onPressed: () {
                Navigator.pop(context);
                _searchDoctors();
              },
              backgroundColor: AppColors.primary,
              textColor: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
