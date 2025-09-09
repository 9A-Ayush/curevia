import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../screens/doctor/nearby_doctors_screen.dart';
import '../../utils/theme_utils.dart';

/// Nearby doctors widget for home screen
class NearbyDoctors extends ConsumerWidget {
  const NearbyDoctors({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data - replace with actual data from provider
    final doctors = [
      {
        'name': 'Dr. Emily Wilson',
        'specialty': 'General Medicine',
        'rating': 4.8,
        'distance': '0.5 km',
        'fee': '₹500',
        'isAvailable': true,
        'avatar': 'https://via.placeholder.com/50',
      },
      {
        'name': 'Dr. James Rodriguez',
        'specialty': 'Pediatrics',
        'rating': 4.9,
        'distance': '1.2 km',
        'fee': '₹600',
        'isAvailable': true,
        'avatar': 'https://via.placeholder.com/50',
      },
      {
        'name': 'Dr. Lisa Thompson',
        'specialty': 'Dermatology',
        'rating': 4.7,
        'distance': '2.1 km',
        'fee': '₹800',
        'isAvailable': false,
        'avatar': 'https://via.placeholder.com/50',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nearby Doctors',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
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
                    child: Icon(
                      Icons.person,
                      color: ThemeUtils.getPrimaryColor(context),
                      size: 28,
                    ),
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
                                doctor['name'] as String,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (doctor['isAvailable'] as bool)
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (doctor['isAvailable'] as bool)
                                    ? 'Available'
                                    : 'Busy',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: (doctor['isAvailable'] as bool)
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor['specialty'] as String,
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
                            Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.ratingFilled,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              doctor['rating'].toString(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: ThemeUtils.getTextSecondaryColor(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              doctor['distance'] as String,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ThemeUtils.getTextSecondaryColor(
                                      context,
                                    ),
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              doctor['fee'] as String,
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
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ThemeUtils.getPrimaryColorWithOpacity(
                            context,
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // TODO: Book appointment
                          },
                          icon: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: ThemeUtils.getPrimaryColor(context),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // TODO: Start video call
                          },
                          icon: const Icon(
                            Icons.video_call,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
