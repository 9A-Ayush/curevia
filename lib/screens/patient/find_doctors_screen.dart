import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/doctor_provider.dart';
import '../../services/firebase/doctor_service.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/theme_utils.dart';
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
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
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

  Future<void> _ensureSampleDoctors() async {
    try {
      final verifiedDoctors = await DoctorService.getVerifiedDoctors();
      if (verifiedDoctors.isEmpty) {
        print('No doctors found, creating sample doctors...');
        await DoctorService.createSampleDoctors();
        // Refresh the provider after creating sample doctors
        ref.invalidate(verifiedDoctorsProvider);
      }
    } catch (e) {
      print('Error ensuring sample doctors: $e');
    }
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ThemeUtils.getSurfaceColor(context),
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
              backgroundColor: ThemeUtils.getSurfaceColor(context),
              selectedColor: ThemeUtils.getPrimaryColor(context),
              labelStyle: TextStyle(
                color: isSelected 
                    ? ThemeUtils.getTextOnPrimaryColor(context) 
                    : ThemeUtils.getTextPrimaryColor(context),
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
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.person_search,
                      size: 60,
                      color: ThemeUtils.getPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No doctors available yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No doctors have registered on the platform yet. Doctors can sign up and complete their verification to appear here.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _ensureSampleDoctors();
                        ref.invalidate(verifiedDoctorsProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeUtils.getPrimaryColor(context),
                        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                Icon(Icons.search_off, size: 64, color: ThemeUtils.getTextSecondaryColor(context)),
                const SizedBox(height: 16),
                Text(
                  'No doctors found',
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ThemeUtils.getErrorColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: ThemeUtils.getErrorColor(context),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unable to load doctors',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.getTextPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your internet connection and try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _ensureSampleDoctors();
                    ref.invalidate(verifiedDoctorsProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeUtils.getPrimaryColor(context),
                    foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
