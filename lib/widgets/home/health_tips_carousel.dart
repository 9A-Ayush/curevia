import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';

/// Health tips carousel for home screen
class HealthTipsCarousel extends StatelessWidget {
  const HealthTipsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': 'Stay Hydrated',
        'description':
            'Drink at least 8 glasses of water daily for optimal health',
        'icon': Icons.water_drop,
        'color': AppColors.info,
      },
      {
        'title': 'Exercise Regularly',
        'description':
            '30 minutes of daily exercise can improve your overall wellbeing',
        'icon': Icons.fitness_center,
        'color': AppColors.success,
      },
      {
        'title': 'Eat Healthy',
        'description': 'Include fruits and vegetables in your daily diet',
        'icon': Icons.restaurant,
        'color': AppColors.warning,
      },
      {
        'title': 'Get Enough Sleep',
        'description':
            '7-9 hours of quality sleep is essential for good health',
        'icon': Icons.bedtime,
        'color': AppColors.secondary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Tips',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all health tips
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 260,
                margin: EdgeInsets.only(
                  right: index < tips.length - 1 ? 16 : 0,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tip['color'] as Color,
                      (tip['color'] as Color).withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tip['icon'] as IconData,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tip['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        tip['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
