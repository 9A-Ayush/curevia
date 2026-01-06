import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/home_provider.dart';
import '../../utils/theme_utils.dart';
import '../../screens/fitness/fitness_tracker_screen.dart';
import '../../screens/health/bmi_calculator_screen.dart';
import '../../services/health/health_metrics_service.dart';
import '../../services/health/bmi_service.dart';

/// Health metrics card for home screen
class HealthMetricsCard extends ConsumerWidget {
  const HealthMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final healthMetrics = homeState.healthMetrics;
    final activityStats = homeState.activityStats;

    // Show loading state while data is being fetched
    if (homeState.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Health Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceVariantColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // Show error state if there's an error
    if (homeState.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Health Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeUtils.getErrorColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeUtils.getErrorColor(context).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ThemeUtils.getErrorColor(context),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load health metrics',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getErrorColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(homeProvider.notifier).loadHomeData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // Show default metrics if no data is available
    if (healthMetrics == null && activityStats == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Health Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceVariantColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: ThemeUtils.getTextSecondaryColor(context),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No health metrics available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(homeProvider.notifier).loadHomeData();
                    },
                    child: const Text('Load Metrics'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FitnessTrackerScreen(),
                    ),
                  );
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
              // BMI Card
              Expanded(
                child: FutureBuilder<double?>(
                  future: BmiService.getCurrentBMI(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final bmi = snapshot.data!;
                      final category = BmiService.getBMICategory(bmi);
                      Color bmiColor;
                      
                      switch (category.color) {
                        case 'info':
                          bmiColor = AppColors.info;
                          break;
                        case 'success':
                          bmiColor = AppColors.success;
                          break;
                        case 'warning':
                          bmiColor = AppColors.warning;
                          break;
                        case 'error':
                          bmiColor = AppColors.error;
                          break;
                        default:
                          bmiColor = AppColors.primary;
                      }
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BmiCalculatorScreen(),
                            ),
                          );
                        },
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.calculate,
                          label: 'BMI',
                          value: bmi.toStringAsFixed(1),
                          subtitle: category.category,
                          color: bmiColor,
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BmiCalculatorScreen(),
                            ),
                          );
                        },
                        child: _buildMetricCard(
                          context: context,
                          icon: Icons.calculate,
                          label: 'BMI',
                          value: '--',
                          subtitle: 'Calculate',
                          color: AppColors.secondary,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (healthMetrics != null) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateHeartRate(context, ref),
                    child: _buildMetricCard(
                      context: context,
                      icon: Icons.favorite,
                      label: 'Heart Rate',
                      value: '${healthMetrics.heartRate}',
                      subtitle: 'bpm',
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
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
                  child: GestureDetector(
                    onTap: () => _updateWeight(context, ref, healthMetrics.weight),
                    child: _buildMetricCard(
                      context: context,
                      icon: Icons.monitor_weight,
                      label: 'Weight',
                      value: healthMetrics.weight.toStringAsFixed(1),
                      subtitle: 'kg',
                      color: AppColors.info,
                    ),
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

  /// Update weight with user input
  void _updateWeight(BuildContext context, WidgetRef ref, double currentWeight) {
    final weightController = TextEditingController(text: currentWeight.toStringAsFixed(1));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your current weight:'),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weightText = weightController.text.trim();
              if (weightText.isEmpty) return;
              
              final weight = double.tryParse(weightText);
              if (weight == null || weight <= 0 || weight > 500) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid weight (1-500 kg)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              try {
                await HealthMetricsService.updateWeight(weight);
                ref.invalidate(homeProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Weight updated to ${weight.toStringAsFixed(1)} kg'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update weight: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Update heart rate with user input or simulation
  void _updateHeartRate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Heart Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how to update your heart rate:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await HealthMetricsService.simulateRealTimeHeartRate();
                  ref.invalidate(homeProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Heart rate updated!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Simulate Reading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
