import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/weather_model.dart';

/// Real-time weather service using OpenWeatherMap API
class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _geocodingUrl = 'https://api.openweathermap.org/geo/1.0';

  // API Key - will be set from environment or user input
  static String? _apiKey;

  // Cache settings
  static const String _cacheKey = 'weather_cache';
  static const String _cacheTimestampKey = 'weather_cache_timestamp';
  static const String _cacheLocationKey = 'weather_cache_location';
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Set the API key for weather requests
  static void setApiKey(String apiKey) {
    _apiKey = apiKey;
    debugPrint('Weather API key configured');
  }

  /// Get current weather by coordinates
  static Future<WeatherModel?> getCurrentWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('Weather API key not configured');
      return null;
    }

    try {
      // Check cache first
      final cachedWeather = await _getCachedWeather(latitude, longitude);
      if (cachedWeather != null) {
        return cachedWeather;
      }

      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      debugPrint(
        'Fetching weather from: ${url.toString().replaceAll(_apiKey!, '[API_KEY]')}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Weather request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherModel.fromOpenWeatherMap(data);

        // Cache the result
        await _cacheWeather(weather, latitude, longitude);

        debugPrint(
          'Weather fetched successfully: ${weather.condition} ${weather.temperature}°C',
        );
        return weather;
      } else if (response.statusCode == 401) {
        debugPrint('Invalid API key for weather service');
        return null;
      } else {
        debugPrint(
          'Weather API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  /// Get current weather by city name
  static Future<WeatherModel?> getCurrentWeatherByCity(String cityName) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('Weather API key not configured');
      return null;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Weather request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherModel.fromOpenWeatherMap(data);

        debugPrint(
          'Weather fetched for $cityName: ${weather.condition} ${weather.temperature}°C',
        );
        return weather;
      } else {
        debugPrint('Weather API error for $cityName: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather for $cityName: $e');
      return null;
    }
  }

  /// Get current weather using device location
  static Future<WeatherModel?> getCurrentWeatherByLocation() async {
    try {
      debugPrint('=== WEATHER SERVICE DEBUG ===');
      debugPrint('API Key configured: ${isConfigured}');
      debugPrint('API Key status: ${apiKeyStatus}');

      if (!isConfigured) {
        debugPrint('ERROR: Weather API key not configured');
        return null;
      }

      // Check location permissions
      debugPrint('Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied by user');
          // Try with a default location (London) as fallback
          debugPrint('Trying fallback location: London');
          return await getCurrentWeatherByCity('London');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        // Try with a default location (London) as fallback
        debugPrint('Trying fallback location: London');
        return await getCurrentWeatherByCity('London');
      }

      // Get current position
      debugPrint('Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint(
        'Location obtained: ${position.latitude}, ${position.longitude}',
      );

      // Fetch weather for current location
      final weather = await getCurrentWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );

      if (weather != null) {
        debugPrint(
          'Weather fetched successfully: ${weather.condition} ${weather.temperature}°C',
        );
      } else {
        debugPrint('Weather fetch returned null');
      }

      return weather;
    } catch (e) {
      debugPrint('Error getting location for weather: $e');
      debugPrint('Trying fallback location: London');
      // Try with a default location as fallback
      return await getCurrentWeatherByCity('London');
    }
  }

  /// Get 5-day weather forecast
  static Future<List<WeatherModel>?> getWeatherForecast(
    double latitude,
    double longitude,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('Weather API key not configured');
      return null;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Forecast request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'] ?? [];

        final forecasts = forecastList
            .map((item) => WeatherModel.fromOpenWeatherMapForecast(item))
            .toList();

        debugPrint('Weather forecast fetched: ${forecasts.length} items');
        return forecasts;
      } else {
        debugPrint('Forecast API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather forecast: $e');
      return null;
    }
  }

  /// Search cities by name for location selection
  static Future<List<CityLocation>?> searchCities(String query) async {
    if (_apiKey == null || _apiKey!.isEmpty || query.length < 2) {
      return null;
    }

    try {
      final url = Uri.parse(
        '$_geocodingUrl/direct?q=$query&limit=5&appid=$_apiKey',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw Exception('City search timed out');
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => CityLocation.fromJson(item)).toList();
      } else {
        debugPrint('City search API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error searching cities: $e');
      return null;
    }
  }

  /// Cache weather data
  static Future<void> _cacheWeather(
    WeatherModel weather,
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherJson = json.encode(weather.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final location = '$latitude,$longitude';

      await prefs.setString(_cacheKey, weatherJson);
      await prefs.setInt(_cacheTimestampKey, timestamp);
      await prefs.setString(_cacheLocationKey, location);
    } catch (e) {
      debugPrint('Error caching weather: $e');
    }
  }

  /// Get cached weather data if valid
  static Future<WeatherModel?> _getCachedWeather(
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherJson = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);
      final cachedLocation = prefs.getString(_cacheLocationKey);

      if (weatherJson == null || timestamp == null || cachedLocation == null) {
        return null;
      }

      // Check if cache is expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
        return null;
      }

      // Check if location is the same (within 1km)
      final locationParts = cachedLocation.split(',');
      if (locationParts.length != 2) return null;

      final cachedLat = double.parse(locationParts[0]);
      final cachedLon = double.parse(locationParts[1]);

      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        cachedLat,
        cachedLon,
      );

      if (distance > 1000) {
        // More than 1km away
        return null;
      }

      final weatherData = json.decode(weatherJson);
      return WeatherModel.fromJson(weatherData);
    } catch (e) {
      debugPrint('Error reading cached weather: $e');
      return null;
    }
  }

  /// Clear weather cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      await prefs.remove(_cacheLocationKey);
      debugPrint('Weather cache cleared');
    } catch (e) {
      debugPrint('Error clearing weather cache: $e');
    }
  }

  /// Check if API key is configured
  static bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get API key status for debugging
  static String get apiKeyStatus {
    if (_apiKey == null) return 'Not set';
    if (_apiKey!.isEmpty) return 'Empty';
    return 'Configured (${_apiKey!.substring(0, 8)}...)';
  }
}

/// City location model for search results
class CityLocation {
  final String name;
  final String country;
  final String? state;
  final double latitude;
  final double longitude;

  const CityLocation({
    required this.name,
    required this.country,
    this.state,
    required this.latitude,
    required this.longitude,
  });

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      state: json['state'],
      latitude: (json['lat'] ?? 0.0).toDouble(),
      longitude: (json['lon'] ?? 0.0).toDouble(),
    );
  }

  String get displayName {
    if (state != null) {
      return '$name, $state, $country';
    }
    return '$name, $country';
  }
}
