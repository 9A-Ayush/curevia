/// Weather model for real-time weather data
class WeatherModel {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double pressure;
  final double windSpeed;
  final int windDirection;
  final int visibility;
  final int uvIndex;
  final String condition;
  final String description;
  final String location;
  final String country;
  final String iconCode;
  final DateTime timestamp;
  final DateTime? sunrise;
  final DateTime? sunset;

  const WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.visibility,
    required this.uvIndex,
    required this.condition,
    required this.description,
    required this.location,
    required this.country,
    required this.iconCode,
    required this.timestamp,
    this.sunrise,
    this.sunset,
  });

  /// Create WeatherModel from OpenWeatherMap API response
  factory WeatherModel.fromOpenWeatherMap(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?.first ?? {};
    final wind = json['wind'] ?? {};
    final sys = json['sys'] ?? {};

    return WeatherModel(
      temperature: (main['temp'] ?? 0.0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0.0).toDouble(),
      humidity: (main['humidity'] ?? 0).toInt(),
      pressure: (main['pressure'] ?? 0.0).toDouble(),
      windSpeed: (wind['speed'] ?? 0.0).toDouble(),
      windDirection: (wind['deg'] ?? 0).toInt(),
      visibility: ((json['visibility'] ?? 0) / 1000).round(), // Convert to km
      uvIndex: 0, // Not available in current weather, need separate call
      condition: _mapWeatherCondition(weather['main'] ?? ''),
      description: _capitalizeDescription(weather['description'] ?? ''),
      location: json['name'] ?? 'Unknown',
      country: sys['country'] ?? '',
      iconCode: weather['icon'] ?? '01d',
      timestamp: DateTime.now(),
      sunrise: sys['sunrise'] != null
          ? DateTime.fromMillisecondsSinceEpoch(sys['sunrise'] * 1000)
          : null,
      sunset: sys['sunset'] != null
          ? DateTime.fromMillisecondsSinceEpoch(sys['sunset'] * 1000)
          : null,
    );
  }

  /// Create WeatherModel from OpenWeatherMap forecast response
  factory WeatherModel.fromOpenWeatherMapForecast(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final weather = (json['weather'] as List?)?.first ?? {};
    final wind = json['wind'] ?? {};

    return WeatherModel(
      temperature: (main['temp'] ?? 0.0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0.0).toDouble(),
      humidity: (main['humidity'] ?? 0).toInt(),
      pressure: (main['pressure'] ?? 0.0).toDouble(),
      windSpeed: (wind['speed'] ?? 0.0).toDouble(),
      windDirection: (wind['deg'] ?? 0).toInt(),
      visibility: 10, // Default for forecast
      uvIndex: 0,
      condition: _mapWeatherCondition(weather['main'] ?? ''),
      description: _capitalizeDescription(weather['description'] ?? ''),
      location: 'Forecast',
      country: '',
      iconCode: weather['icon'] ?? '01d',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
    );
  }

  /// Create from JSON (for caching)
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      feelsLike: (json['feelsLike'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0).toInt(),
      pressure: (json['pressure'] ?? 0.0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0.0).toDouble(),
      windDirection: (json['windDirection'] ?? 0).toInt(),
      visibility: (json['visibility'] ?? 0).toInt(),
      uvIndex: (json['uvIndex'] ?? 0).toInt(),
      condition: json['condition'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      country: json['country'] ?? '',
      iconCode: json['iconCode'] ?? '01d',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      sunrise: json['sunrise'] != null ? DateTime.parse(json['sunrise']) : null,
      sunset: json['sunset'] != null ? DateTime.parse(json['sunset']) : null,
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'visibility': visibility,
      'uvIndex': uvIndex,
      'condition': condition,
      'description': description,
      'location': location,
      'country': country,
      'iconCode': iconCode,
      'timestamp': timestamp.toIso8601String(),
      'sunrise': sunrise?.toIso8601String(),
      'sunset': sunset?.toIso8601String(),
    };
  }

  /// Get temperature with unit
  String get temperatureString => '${temperature.round()}°C';

  /// Get feels like temperature with unit
  String get feelsLikeString => '${feelsLike.round()}°C';

  /// Get humidity with unit
  String get humidityString => '$humidity%';

  /// Get pressure with unit
  String get pressureString => '${pressure.round()} hPa';

  /// Get wind speed with unit
  String get windSpeedString => '${windSpeed.round()} m/s';

  /// Get wind direction as compass
  String get windDirectionString => _getWindDirection(windDirection);

  /// Get visibility with unit
  String get visibilityString => '$visibility km';

  /// Check if it's currently day or night
  bool get isDaytime {
    if (sunrise == null || sunset == null) {
      // Fallback: assume day between 6 AM and 6 PM
      final hour = DateTime.now().hour;
      return hour >= 6 && hour < 18;
    }

    final now = DateTime.now();
    return now.isAfter(sunrise!) && now.isBefore(sunset!);
  }

  /// Get weather advice based on conditions
  String get weatherAdvice {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return 'Perfect weather for outdoor activities!';
      case 'clouds':
      case 'cloudy':
        return 'Great weather for a walk or light exercise.';
      case 'rain':
      case 'drizzle':
        return 'Stay dry! Perfect for indoor workouts.';
      case 'thunderstorm':
        return 'Stay indoors and keep safe!';
      case 'snow':
        return 'Bundle up if you go outside!';
      case 'mist':
      case 'fog':
        return 'Be careful with visibility if traveling.';
      default:
        return 'Check the weather before heading out!';
    }
  }

  /// Get health recommendations based on weather
  List<String> get healthRecommendations {
    final recommendations = <String>[];

    if (temperature > 30) {
      recommendations.add('Stay hydrated - drink plenty of water');
      recommendations.add('Avoid prolonged sun exposure');
    } else if (temperature < 5) {
      recommendations.add('Dress warmly to prevent cold-related illness');
      recommendations.add('Protect exposed skin');
    }

    if (humidity > 80) {
      recommendations.add('High humidity - take breaks during exercise');
    } else if (humidity < 30) {
      recommendations.add('Low humidity - moisturize your skin');
    }

    if (windSpeed > 10) {
      recommendations.add('Strong winds - secure loose items');
    }

    if (condition.toLowerCase().contains('rain')) {
      recommendations.add('Stay dry to avoid getting sick');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Great weather for outdoor activities!');
    }

    return recommendations;
  }

  /// Map OpenWeatherMap condition to simplified condition
  static String _mapWeatherCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Clear';
      case 'clouds':
        return 'Cloudy';
      case 'rain':
        return 'Rain';
      case 'drizzle':
        return 'Drizzle';
      case 'thunderstorm':
        return 'Thunderstorm';
      case 'snow':
        return 'Snow';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return 'Mist';
      default:
        return 'Clear';
    }
  }

  /// Capitalize weather description
  static String _capitalizeDescription(String description) {
    if (description.isEmpty) return description;
    return description
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Convert wind direction degrees to compass direction
  static String _getWindDirection(int degrees) {
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];

    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  /// Copy with method for updates
  WeatherModel copyWith({
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? pressure,
    double? windSpeed,
    int? windDirection,
    int? visibility,
    int? uvIndex,
    String? condition,
    String? description,
    String? location,
    String? country,
    String? iconCode,
    DateTime? timestamp,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    return WeatherModel(
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      visibility: visibility ?? this.visibility,
      uvIndex: uvIndex ?? this.uvIndex,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      location: location ?? this.location,
      country: country ?? this.country,
      iconCode: iconCode ?? this.iconCode,
      timestamp: timestamp ?? this.timestamp,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
    );
  }

  @override
  String toString() {
    return 'WeatherModel(temperature: $temperature, condition: $condition, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherModel &&
        other.temperature == temperature &&
        other.condition == condition &&
        other.location == location &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return temperature.hashCode ^
        condition.hashCode ^
        location.hashCode ^
        timestamp.hashCode;
  }
}
