import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/home_provider.dart';
import '../../screens/weather/weather_detail_screen.dart';

/// Home screen header with greeting and notifications
class HomeHeader extends ConsumerWidget {
  final String userName;
  final String userRole;

  const HomeHeader({super.key, required this.userName, required this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final homeState = ref.watch(homeProvider);
    final healthMetrics = homeState.healthMetrics;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (userRole == AppConstants.doctorRole) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Doctor',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderButton(
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                    hasNotification: true,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderButton(
                    icon: Icons.refresh,
                    onTap: () {
                      // Refresh weather data
                      ref.invalidate(weatherProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Weather data refreshed!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weather and Health Status Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeatherDetailScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getWeatherIcon(
                                weatherAsync.value?.condition ?? 'Sunny',
                              ),
                              color: AppColors.textOnPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              weatherAsync.when(
                                data: (weather) => weather != null
                                    ? '${weather.temperature.round()}°C • ${weather.condition}'
                                    : '24°C • Sunny',
                                loading: () => 'Loading weather...',
                                error: (_, __) => 'Weather unavailable',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weatherAsync.when(
                            data: (weather) => weather != null
                                ? '${weather.location} • ${weather.description}'
                                : 'Perfect weather for outdoor activities!',
                            loading: () => 'Getting your location...',
                            error: (_, __) => 'Tap refresh to update weather',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textOnPrimary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textOnPrimary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppColors.textOnPrimary,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthMetrics?.healthStatus ?? 'Good',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Health',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: AppColors.textOnPrimary, size: 20)),
            if (hasNotification)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 3 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'overcast':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.grain;
      case 'stormy':
        return Icons.thunderstorm;
      case 'snowy':
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }
}

/// Weather widget for home header
class WeatherWidget extends StatelessWidget {
  final String temperature;
  final String condition;
  final String description;

  const WeatherWidget({
    super.key,
    required this.temperature,
    required this.condition,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textOnPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getWeatherIcon(condition),
            color: AppColors.textOnPrimary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temperature • $condition',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'overcast':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.grain;
      case 'stormy':
        return Icons.thunderstorm;
      case 'snowy':
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }
}

/// Health status indicator
class HealthStatusIndicator extends StatelessWidget {
  final String status;
  final Color color;

  const HealthStatusIndicator({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.favorite, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Health',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textOnPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
