import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../widgets/common/custom_text_field.dart';
import 'doctor_detail_screen.dart';

/// Find doctors screen for patients
class FindDoctorsScreen extends ConsumerStatefulWidget {
  const FindDoctorsScreen({super.key});

  @override
  ConsumerState<FindDoctorsScreen> createState() => _FindDoctorsScreenState();
}

class _FindDoctorsScreenState extends ConsumerState<FindDoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSpecialty;
  String _searchQuery = '';

  final List<String> _specialties = [
    'All',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Orthopedic',
    'Psychiatrist',
    'General Physician',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildSpecialtyFilter(),
          Expanded(child: _buildDoctorsList()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: CustomTextField(
        controller: _searchController,
        hintText: 'Search doctors by name or specialty...',
        prefixIcon: Icons.search,
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          final specialty = _specialties[index];
          final isSelected = _selectedSpecialty == specialty || 
                           (specialty == 'All' && _selectedSpecialty == null);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(specialty),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSpecialty = specialty == 'All' ? null : specialty;
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorsList() {
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);

    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No verified doctors available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check back later',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        
        final filteredDoctors = doctors.where((doctor) {
          final matchesSearch = _searchQuery.isEmpty ||
              doctor.fullName.toLowerCase().contains(_searchQuery) ||
              (doctor.specialty?.toLowerCase().contains(_searchQuery) ?? false);
          
          final matchesSpecialty = _selectedSpecialty == null ||
              doctor.specialty == _selectedSpecialty;

          return matchesSearch && matchesSpecialty;
        }).toList();

        if (filteredDoctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No doctors found',
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
          itemCount: filteredDoctors.length,
          itemBuilder: (context, index) {
            final doctor = filteredDoctors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailScreen(doctor: doctor),
                    ),
                  );
                },
                child: DoctorCard(doctor: doctor),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading doctors',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(verifiedDoctorsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
