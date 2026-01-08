import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../models/notification_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/theme_utils.dart';
import '../../screens/video_consulting/appointment_booking_screen.dart' as video;
import '../../services/notifications/notification_manager.dart';

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
                                color: AppColors.success.withOpacity(0.1),
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
                    color: AppColors.success.withOpacity(0.1),
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
                    CustomButton(
                      text: 'Book Now',
                      onPressed: () => _bookVideoConsultation(context),
                      height: 36,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      backgroundColor: AppColors.secondary,
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
    // Navigate to doctor detail screen
    Navigator.pushNamed(
      context,
      '/doctor-detail',
      arguments: doctor,
    );
  }

  void _bookVideoConsultation(BuildContext context) async {
    try {
      // Navigate to video consultation booking screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => video.AppointmentBookingScreen(
            doctor: doctor,
            consultationType: 'online',
          ),
        ),
      );

      // If video consultation was booked successfully, send notification to doctor
      if (result == true) {
        await _sendDoctorNotification(
          context,
          'New Video Consultation Request',
          'You have a new video consultation booking request from a patient.',
          'video_consultation',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking video consultation: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendDoctorNotification(
    BuildContext context,
    String title,
    String body,
    String type,
  ) async {
    try {
      // Send notification using the new notification system
      await NotificationManager.instance.sendTestNotification(
        title: title,
        body: body,
        type: NotificationType.general, // Use general type for test notifications
        data: {
          'type': type,
          'doctorId': doctor.uid,
          'doctorName': doctor.fullName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dr. ${doctor.fullName} has been notified'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error sending notification to doctor: $e');
      // Don't show error to user as the booking might still be successful
    }
  }
}
