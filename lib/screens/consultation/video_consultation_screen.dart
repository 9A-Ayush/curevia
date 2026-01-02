import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../providers/doctor_provider.dart';
import '../../services/firebase/doctor_service.dart';
import '../../models/doctor_model.dart';
import '../../screens/video_consulting/appointment_booking_screen.dart' as video;

/// Video consultation booking screen
class VideoConsultationScreen extends ConsumerStatefulWidget {
  const VideoConsultationScreen({super.key});

  @override
  ConsumerState<VideoConsultationScreen> createState() =>
      _VideoConsultationScreenState();
}

class _VideoConsultationScreenState
    extends ConsumerState<VideoConsultationScreen> {
  String selectedSpecialty = 'All';

  final List<String> specialties = [
    'All',
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
    'Orthopedics',
    'Gynecology',
    'Psychiatry',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Try to load verified doctors first, then search if needed
      _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    try {
      // First try to get verified doctors
      ref.invalidate(verifiedDoctorsProvider);
      
      // Check if we have any doctors, if not create sample ones
      final verifiedDoctors = await DoctorService.getVerifiedDoctors();
      if (verifiedDoctors.isEmpty) {
        print('No doctors found, creating sample doctors...');
        await DoctorService.createSampleDoctors();
        // Refresh the provider after creating sample doctors
        ref.invalidate(verifiedDoctorsProvider);
      }
      
      // Also try the search provider as fallback
      ref
          .read(doctorSearchProvider.notifier)
          .searchDoctors(filters: const DoctorSearchFilters());
    } catch (e) {
      print('Error loading doctors: $e');
    }
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
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.video_call,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect with doctors online',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Get instant medical consultation from home',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
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
                    _buildInfoChip(Icons.access_time, 'Available 24/7'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.security, 'Secure & Private'),
                  ],
                ),
              ],
            ),
          ),

          // Specialty filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: specialties.length,
              itemBuilder: (context, index) {
                final specialty = specialties[index];
                final isSelected = selectedSpecialty == specialty;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSpecialty = specialty;
                    });

                    // Refresh both providers when specialty changes
                    _loadDoctors();
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
                        specialty,
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
          ),

          // Doctors list
          Expanded(child: _buildDoctorsList(doctorSearchState)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList(DoctorSearchState state) {
    // Also watch verified doctors as fallback
    final verifiedDoctorsAsync = ref.watch(verifiedDoctorsProvider);
    
    return verifiedDoctorsAsync.when(
      data: (verifiedDoctors) {
        // Use verified doctors if available, otherwise use search results
        final doctorsToShow = verifiedDoctors.isNotEmpty ? verifiedDoctors : state.doctors;
        
        // Filter by specialty if selected
        final filteredDoctors = selectedSpecialty == 'All' 
            ? doctorsToShow
            : doctorsToShow.where((doctor) => 
                doctor.specialty == selectedSpecialty ||
                (doctor.specialty?.toLowerCase().contains(selectedSpecialty.toLowerCase()) ?? false)
              ).toList();

        if (state.isLoading && doctorsToShow.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && doctorsToShow.isEmpty) {
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
                  'Failed to load doctors',
                  style: Theme.of(context).textTheme.titleMedium,
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
                CustomButton(
                  text: 'Retry',
                  onPressed: _loadDoctors,
                ),
              ],
            ),
          );
        }

        if (filteredDoctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_call_outlined,
                  size: 64,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedSpecialty == 'All' 
                      ? 'No doctors available'
                      : 'No $selectedSpecialty doctors available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedSpecialty == 'All'
                      ? 'No doctors have registered for video consultations yet'
                      : 'Try selecting a different specialty or check back later',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Refresh',
                  onPressed: _loadDoctors,
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
              child: DoctorCard(
                doctor: doctor,
                onTap: () => _startVideoConsultation(doctor),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // Fallback to search results if verified doctors fail
        if (state.doctors.isNotEmpty) {
          final filteredDoctors = selectedSpecialty == 'All' 
              ? state.doctors
              : state.doctors.where((doctor) => 
                  doctor.specialty == selectedSpecialty ||
                  (doctor.specialty?.toLowerCase().contains(selectedSpecialty.toLowerCase()) ?? false)
                ).toList();

          if (filteredDoctors.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = filteredDoctors[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DoctorCard(
                    doctor: doctor,
                    onTap: () => _startVideoConsultation(doctor),
                  ),
                );
              },
            );
          }
        }

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
                'Unable to load doctors',
                style: Theme.of(context).textTheme.titleMedium,
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
              CustomButton(
                text: 'Try Again',
                onPressed: _loadDoctors,
              ),
            ],
          ),
        );
      },
    );
  }

  void _startVideoConsultation(DoctorModel doctor) async {
    try {
      // Navigate directly to video consultation booking
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => video.AppointmentBookingScreen(
            doctor: doctor,
            consultationType: 'online',
          ),
        ),
      );

      // If booking was successful, show confirmation
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video consultation booked with Dr. ${doctor.fullName}'),
            backgroundColor: ThemeUtils.getSuccessColor(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking consultation: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
          ),
        );
      }
    }
  }
}
