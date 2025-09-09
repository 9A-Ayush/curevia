import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import '../models/doctor_model.dart';
import '../services/weather/weather_service.dart';

/// Home screen state
class HomeState {
  final bool isLoading;
  final String? error;
  final List<AppointmentModel> upcomingAppointments;
  final List<DoctorModel> nearbyDoctors;
  final List<HealthTip> healthTips;
  final List<RecentActivity> recentActivities;
  final WeatherInfo? weatherInfo;

  const HomeState({
    this.isLoading = false,
    this.error,
    this.upcomingAppointments = const [],
    this.nearbyDoctors = const [],
    this.healthTips = const [],
    this.recentActivities = const [],
    this.weatherInfo,
  });

  HomeState copyWith({
    bool? isLoading,
    String? error,
    List<AppointmentModel>? upcomingAppointments,
    List<DoctorModel>? nearbyDoctors,
    List<HealthTip>? healthTips,
    List<RecentActivity>? recentActivities,
    WeatherInfo? weatherInfo,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      nearbyDoctors: nearbyDoctors ?? this.nearbyDoctors,
      healthTips: healthTips ?? this.healthTips,
      recentActivities: recentActivities ?? this.recentActivities,
      weatherInfo: weatherInfo ?? this.weatherInfo,
    );
  }
}

/// Health tip model
class HealthTip {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;

  const HealthTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.createdAt,
  });

  factory HealthTip.fromMap(Map<String, dynamic> map) {
    return HealthTip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

/// Recent activity model
class RecentActivity {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? relatedId;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.relatedId,
  });

  factory RecentActivity.fromMap(Map<String, dynamic> map) {
    return RecentActivity(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      relatedId: map['relatedId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'relatedId': relatedId,
    };
  }
}

/// Weather info model
class WeatherInfo {
  final double temperature;
  final String condition;
  final String description;
  final String location;

  const WeatherInfo({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.location,
  });

  factory WeatherInfo.fromMap(Map<String, dynamic> map) {
    return WeatherInfo(
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      condition: map['condition'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'condition': condition,
      'description': description,
      'location': location,
    };
  }
}

/// Home provider notifier
class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  /// Load all home screen data
  Future<void> loadHomeData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Load data concurrently
      final futures = await Future.wait([
        _loadUpcomingAppointments(),
        _loadNearbyDoctors(),
        _loadHealthTips(),
        _loadRecentActivities(),
      ]);

      state = state.copyWith(
        isLoading: false,
        upcomingAppointments: futures[0] as List<AppointmentModel>,
        nearbyDoctors: futures[1] as List<DoctorModel>,
        healthTips: futures[2] as List<HealthTip>,
        recentActivities: futures[3] as List<RecentActivity>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load upcoming appointments
  Future<List<AppointmentModel>> _loadUpcomingAppointments() async {
    try {
      // Get current user ID from auth provider
      // For now, return mock data
      return [
        AppointmentModel(
          id: '1',
          patientId: 'patient1',
          doctorId: 'doctor1',
          patientName: 'John Doe',
          doctorName: 'Dr. Sarah Johnson',
          doctorSpecialty: 'Cardiologist',
          appointmentDate: DateTime.now().add(const Duration(hours: 2)),
          timeSlot: '2:30 PM',
          consultationType: 'video',
          status: 'confirmed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        AppointmentModel(
          id: '2',
          patientId: 'patient1',
          doctorId: 'doctor2',
          patientName: 'John Doe',
          doctorName: 'Dr. Michael Chen',
          doctorSpecialty: 'Dermatologist',
          appointmentDate: DateTime.now().add(const Duration(days: 1)),
          timeSlot: '10:00 AM',
          consultationType: 'offline',
          status: 'confirmed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// Load nearby doctors
  Future<List<DoctorModel>> _loadNearbyDoctors() async {
    try {
      // For now, return mock data
      // In production, get user location and fetch nearby doctors
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Load health tips
  Future<List<HealthTip>> _loadHealthTips() async {
    try {
      // Return static health tips for now
      return [
        HealthTip(
          id: '1',
          title: 'Stay Hydrated',
          description:
              'Drink at least 8 glasses of water daily for optimal health',
          category: 'nutrition',
          createdAt: DateTime.now(),
        ),
        HealthTip(
          id: '2',
          title: 'Exercise Regularly',
          description:
              '30 minutes of daily exercise can improve your overall wellbeing',
          category: 'fitness',
          createdAt: DateTime.now(),
        ),
        HealthTip(
          id: '3',
          title: 'Eat Healthy',
          description: 'Include fruits and vegetables in your daily diet',
          category: 'nutrition',
          createdAt: DateTime.now(),
        ),
        HealthTip(
          id: '4',
          title: 'Get Enough Sleep',
          description:
              '7-9 hours of quality sleep is essential for good health',
          category: 'wellness',
          createdAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// Load recent activities
  Future<List<RecentActivity>> _loadRecentActivities() async {
    try {
      return [
        RecentActivity(
          id: '1',
          type: 'appointment',
          title: 'Appointment with Dr. Smith',
          subtitle: 'Completed • 2 days ago',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        RecentActivity(
          id: '2',
          type: 'prescription',
          title: 'Prescription uploaded',
          subtitle: 'Dr. Johnson • 3 days ago',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
        RecentActivity(
          id: '3',
          type: 'reminder',
          title: 'Health checkup reminder',
          subtitle: 'Due in 5 days',
          timestamp: DateTime.now().add(const Duration(days: 5)),
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// Refresh home data
  Future<void> refreshData() async {
    await loadHomeData();
  }
}

/// Home provider instance
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});

/// Weather provider - now uses real API data with smart fallbacks
final weatherProvider = FutureProvider<WeatherInfo?>((ref) async {
  try {
    debugPrint('=== WEATHER PROVIDER DEBUG ===');
    debugPrint('Attempting to fetch weather data...');

    // Try location-based weather first
    var weatherModel = await WeatherService.getCurrentWeatherByLocation();

    // If location fails, try with a default city
    if (weatherModel == null) {
      debugPrint('Location-based weather failed, trying default city...');
      weatherModel = await WeatherService.getCurrentWeatherByCity('London');
    }

    // If still null, try another major city
    if (weatherModel == null) {
      debugPrint('London weather failed, trying New York...');
      weatherModel = await WeatherService.getCurrentWeatherByCity('New York');
    }

    if (weatherModel != null) {
      debugPrint(
        'Weather data received: ${weatherModel.location} - ${weatherModel.temperature}°C',
      );
      // Convert WeatherModel to WeatherInfo for compatibility
      return WeatherInfo(
        temperature: weatherModel.temperature,
        condition: weatherModel.condition,
        description: weatherModel.weatherAdvice,
        location: weatherModel.location,
      );
    }

    debugPrint('All weather attempts failed, using fallback data');
    // Fallback to mock data if all API calls fail
    return const WeatherInfo(
      temperature: 24.0,
      condition: 'Sunny',
      description: 'Weather service temporarily unavailable',
      location: 'Default Location',
    );
  } catch (e) {
    debugPrint('Weather provider error: $e');
    // Return fallback data on error
    return const WeatherInfo(
      temperature: 24.0,
      condition: 'Sunny',
      description: 'Weather data unavailable',
      location: 'Error Location',
    );
  }
});
