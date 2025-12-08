import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../providers/doctor_provider.dart';

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
      ref
          .read(doctorSearchProvider.notifier)
          .searchDoctors(filters: const DoctorSearchFilters());
    });
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
                        ).withValues(alpha: 0.2),
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
                                  color: Colors.white.withValues(alpha: 0.9),
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

                    ref
                        .read(doctorSearchProvider.notifier)
                        .searchDoctors(
                          filters: DoctorSearchFilters(
                            specialty: specialty == 'All' ? null : specialty,
                          ),
                        );
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
        color: Colors.white.withValues(alpha: 0.2),
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
    if (state.isLoading) {
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
              onPressed: () {
                ref
                    .read(doctorSearchProvider.notifier)
                    .searchDoctors(
                      filters: DoctorSearchFilters(
                        specialty: selectedSpecialty == 'All'
                            ? null
                            : selectedSpecialty,
                      ),
                    );
              },
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
              Icons.video_call_outlined,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different specialty or check back later',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.doctors.length,
      itemBuilder: (context, index) {
        final doctor = state.doctors[index];
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

  void _startVideoConsultation(doctor) {
    // TODO: Implement video consultation booking
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Video Consultation'),
        content: Text('Book a video consultation with ${doctor.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Book Now',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to actual booking screen with doctor details
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Booking'),
                  content: const Text(
                    'You will be redirected to the appointment booking page to select a time slot.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening booking page...'),
                          ),
                        );
                      },
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
