import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../screens/doctor/nearby_doctors_screen.dart';
import '../../utils/theme_utils.dart';
import '../../providers/location_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../screens/patient/doctor_detail_screen.dart';

/// Nearby doctors widget for home screen
class NearbyDoctors extends ConsumerWidget {
  const NearbyDoctors({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final position = ref.watch(currentPositionProvider);

    // If no location permission or position, show empty state
    if (!locationState.hasPermission || position == null) {
      return const SizedBox.shrink();
    }

    final nearbyDoctorsAsync = ref.watch(
      nearbyDoctorsProvider({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'radius': 10.0,
      }),
    );

    return nearbyDoctorsAsync.when(
      data: (doctors) {
        if (doctors.isEmpty) {
          return const SizedBox.shrink();
        }

        // Take only first 3 doctors
        final displayDoctors = doctors.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Doctors',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NearbyDoctorsScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayDoctors.length,
              itemBuilder: (context, index) {
                final doctor = displayDoctors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorDetailScreen(doctor: doctor),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThemeUtils.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeUtils.getShadowLightColor(context),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: ThemeUtils.getPrimaryColorWithOpacity(
                            context,
                            0.1,
                          ),
                          backgroundImage: doctor.profileImageUrl != null
                              ? NetworkImage(doctor.profileImageUrl!)
                              : null,
                          child: doctor.profileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: ThemeUtils.getPrimaryColor(context),
                                  size: 28,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      doctor.fullName,
                                      style: Theme.of(context).textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (doctor.isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Available',
                                        style: Theme.of(context).textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctor.specialty ?? 'General Medicine',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: ThemeUtils.getTextSecondaryColor(
                                        context,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (doctor.rating != null) ...[
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: AppColors.ratingFilled,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctor.rating!.toStringAsFixed(1),
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (doctor.experienceYears != null) ...[
                                    Icon(
                                      Icons.work_outline,
                                      size: 16,
                                      color: ThemeUtils.getTextSecondaryColor(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doctor.experienceYears}+ yrs',
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: ThemeUtils.getTextSecondaryColor(
                                              context,
                                            ),
                                          ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (doctor.consultationFee != null)
                                    Text(
                                      doctor.consultationFeeText,
                                      style: Theme.of(context).textTheme.titleSmall
                                          ?.copyWith(
                                            color: ThemeUtils.getPrimaryColor(context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
