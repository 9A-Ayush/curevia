import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// Doctor search screen with filters
class DoctorSearchScreen extends ConsumerStatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  ConsumerState<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends ConsumerState<DoctorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSpecialty;
  String? _selectedAvailability;
  double _minRating = 0.0;
  double _maxFee = 5000.0;
  bool _showFilters = false;

  final List<String> _specialties = [
    'All Specialties',
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
    'Orthopedics',
    'Neurology',
    'Psychiatry',
    'Gynecology',
    'ENT',
    'Ophthalmology',
    'Dentistry',
  ];

  final List<String> _availabilityOptions = [
    'All',
    'Available Now',
    'Today',
    'This Week',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpecialty = _specialties[0];
    _selectedAvailability = _availabilityOptions[0];
    _searchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchDoctors() {
    ref.read(doctorSearchProvider.notifier).searchDoctors(
      filters: DoctorSearchFilters(
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        specialty: _selectedSpecialty == 'All Specialties' ? null : _selectedSpecialty,
        minRating: _minRating,
        maxFee: _maxFee,
        isAvailable: _selectedAvailability == 'All' ? null : _selectedAvailability == 'Available',
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecialty = _specialties[0];
      _selectedAvailability = _availabilityOptions[0];
      _minRating = 0.0;
      _maxFee = 5000.0;
    });
    _searchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    final doctorSearchState = ref.watch(doctorSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: AppColors.textOnPrimary,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: doctorSearchState.isLoading && doctorSearchState.doctors.isEmpty,
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            // Filters
            if (_showFilters) _buildFilters(),

            // Results count
            if (doctorSearchState.doctors.isNotEmpty)
              _buildResultsCount(doctorSearchState.doctors.length),

            // Doctors list
            Expanded(
              child: _buildDoctorsList(doctorSearchState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: CustomTextField(
        controller: _searchController,
        hintText: 'Search by name, specialty...',
        prefixIcon: Icons.search,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _searchDoctors();
                },
              )
            : null,
        onChanged: (value) {
          // Debounce search
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_searchController.text == value) {
              _searchDoctors();
            }
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        border: Border(
          bottom: BorderSide(
            color: ThemeUtils.getBorderLightColor(context),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Specialty filter
          _buildFilterDropdown(
            label: 'Specialty',
            value: _selectedSpecialty!,
            items: _specialties,
            onChanged: (value) {
              setState(() {
                _selectedSpecialty = value;
              });
              _searchDoctors();
            },
          ),
          const SizedBox(height: 12),

          // Availability filter
          _buildFilterDropdown(
            label: 'Availability',
            value: _selectedAvailability!,
            items: _availabilityOptions,
            onChanged: (value) {
              setState(() {
                _selectedAvailability = value;
              });
              _searchDoctors();
            },
          ),
          const SizedBox(height: 12),

          // Rating filter
          _buildRatingFilter(),
          const SizedBox(height: 12),

          // Fee filter
          _buildFeeFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ThemeUtils.getBorderLightColor(context),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Minimum Rating',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            Text(
              _minRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
          ],
        ),
        Slider(
          value: _minRating,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          label: _minRating.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _minRating = value;
            });
          },
          onChangeEnd: (value) {
            _searchDoctors();
          },
        ),
      ],
    );
  }

  Widget _buildFeeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Maximum Fee',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            Text(
              '₹${_maxFee.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
          ],
        ),
        Slider(
          value: _maxFee,
          min: 0.0,
          max: 5000.0,
          divisions: 50,
          label: '₹${_maxFee.toStringAsFixed(0)}',
          onChanged: (value) {
            setState(() {
              _maxFee = value;
            });
          },
          onChangeEnd: (value) {
            _searchDoctors();
          },
        ),
      ],
    );
  }

  Widget _buildResultsCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'doctor' : 'doctors'} found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList(DoctorSearchState doctorSearchState) {
    if (doctorSearchState.isLoading && doctorSearchState.doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (doctorSearchState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                doctorSearchState.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _searchDoctors,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (doctorSearchState.doctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  fontWeight: FontWeight.bold,
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _searchDoctors();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doctorSearchState.doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctorSearchState.doctors[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DoctorCard(doctor: doctor),
          );
        },
      ),
    );
  }
}
