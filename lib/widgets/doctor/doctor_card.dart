import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/theme_utils.dart';

/// Doctor card widget for displaying doctor information
class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback? onTap;
  final bool showBookButton;

  const DoctorCard({
    super.key,
    required this.doctor,
    this.onTap,
    this.showBookButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _navigateToDoctorProfile(context),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Doctor Avatar
                CircleAvatar(
                  radius: 30,
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
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Doctor Info
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
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (doctor.isVerified == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Verified',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialty ?? 'General Medicine',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (doctor.qualification != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          doctor.qualification!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Doctor Stats
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.star,
                  value: doctor.rating?.toStringAsFixed(1) ?? 'N/A',
                  label: '(${doctor.totalReviews ?? 0})',
                  color: AppColors.ratingFilled,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.work_outline,
                  value: doctor.experienceText,
                  color: AppColors.textSecondary,
                ),
                const Spacer(),
                if (doctor.consultationFee != null)
                  Text(
                    doctor.consultationFeeText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            if (doctor.clinicName != null || doctor.city != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [
                        doctor.clinicName,
                        doctor.city,
                      ].where((e) => e != null).join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Availability and Actions
            const SizedBox(height: 12),
            Row(
              children: [
                // Availability Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Action Buttons
                if (showBookButton) ...[
                  if (doctor.isAvailableOnline == true)
                    CustomIconButton(
                      icon: Icons.video_call,
                      onPressed: () => _bookVideoConsultation(context),
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.1,
                      ),
                      iconColor: AppColors.secondary,
                      tooltip: 'Video Call',
                    ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'Book',
                    onPressed: () => _bookAppointment(context),
                    height: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    String? label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ],
    );
  }

  void _navigateToDoctorProfile(BuildContext context) {
    // TODO: Navigate to doctor profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${doctor.fullName}\'s profile'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _bookAppointment(BuildContext context) {
    // TODO: Navigate to appointment booking screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking appointment with ${doctor.fullName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _bookVideoConsultation(BuildContext context) {
    // TODO: Navigate to video consultation booking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking video call with ${doctor.fullName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
