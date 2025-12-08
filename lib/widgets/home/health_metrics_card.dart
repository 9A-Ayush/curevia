import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/home_provider.dart';
import '../../utils/theme_utils.dart';

/// Health metrics card for home screen
class HealthMetricsCard extends ConsumerWidget {
  const HealthMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final healthMetrics = homeState.healthMetrics;
    final activityStats = homeState.activityStats;

    if (healthMetrics == null && activityStats == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/fitness-tracker');
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (activityStats != null) ...[
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    value: activityStats.dailySteps.toString(),
                    subtitle: '${activityStats.dailyGoal} goal',
                    color: AppColors.primary,
                    progress: activityStats.progressPercentage / 100,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (healthMetrics != null) ...[
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                    value: '${healthMetrics.heartRate}',
                    subtitle: 'bpm',
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (activityStats != null) ...[
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: activityStats.caloriesBurned.toStringAsFixed(0),
                    subtitle: 'kcal',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (healthMetrics != null) ...[
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    icon: Icons.monitor_weight,
                    label: 'Weight',
                    value: healthMetrics.weight.toStringAsFixed(1),
                    subtitle: 'kg',
                    color: AppColors.info,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (progress != null)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
