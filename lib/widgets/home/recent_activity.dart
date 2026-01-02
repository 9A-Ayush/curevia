import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/activity_service.dart';
import '../../models/activity_model.dart';
import '../../constants/app_colors.dart';

/// Recent activity widget for home screen with real-time tracking
class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'appointment_booked':
      case 'appointment_completed':
        return Icons.calendar_today;
      case 'prescription_received':
        return Icons.medication;
      case 'health_record_added':
        return Icons.folder;
      case 'symptom_check':
        return Icons.medical_services;
      case 'medicine_search':
        return Icons.search;
      default:
        return Icons.info;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'appointment_booked':
        return AppColors.info;
      case 'appointment_completed':
        return AppColors.success;
      case 'prescription_received':
        return AppColors.secondary;
      case 'health_record_added':
        return AppColors.warning;
      case 'symptom_check':
        return AppColors.error;
      case 'medicine_search':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<ActivityModel>>(
      stream: ActivityService.getActivitiesStream(
        userId: user.uid,
        limit: 5,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final activities = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final color = _getColorForType(activity.type);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeUtils.getShadowLightColor(context),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getIconForType(activity.type),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activity.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
