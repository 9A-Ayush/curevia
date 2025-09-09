import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for handling location-related operations
class LocationService {
  static const double defaultLatitude = 28.6139; // New Delhi
  static const double defaultLongitude = 77.2090;

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Get current position with error handling
  static Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // Check and request permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionDeniedException();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedForeverException();
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit ?? const Duration(seconds: 15),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get last known position
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  /// Get position with fallback to last known or default
  static Future<Position> getPositionWithFallback() async {
    try {
      // Try to get current position
      Position? position = await getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      if (position != null) {
        return position;
      }

      // Fallback to last known position
      position = await getLastKnownPosition();
      if (position != null) {
        return position;
      }

      // Fallback to default location
      return Position(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } catch (e) {
      print('Error in getPositionWithFallback: $e');
      // Return default position
      return Position(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  /// Calculate distance between two points
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert to kilometers
  }

  /// Get address from coordinates (reverse geocoding)
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }

      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Get coordinates from address (geocoding)
  static Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      return null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Check if location is within radius
  static bool isWithinRadius(
    double centerLat,
    double centerLng,
    double pointLat,
    double pointLng,
    double radiusKm,
  ) {
    double distance = calculateDistance(
      centerLat,
      centerLng,
      pointLat,
      pointLng,
    );
    return distance <= radiusKm;
  }

  /// Get location permission status for UI
  static Future<LocationPermissionStatus> getLocationPermissionStatus() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await checkLocationPermission();
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionStatus.granted;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Stream of position updates
  static Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Get bearing between two points
  static double getBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  /// Get destination point given distance and bearing
  static Position getDestinationPoint(
    double startLat,
    double startLng,
    double distanceKm,
    double bearing,
  ) {
    // This is a simplified calculation
    // For production, use a proper geodesic calculation library
    const double earthRadius = 6371; // km

    double lat1Rad = startLat * (math.pi / 180);
    double bearingRad = bearing * (math.pi / 180);

    double lat2Rad = math.asin(
      lat1Rad + (distanceKm / earthRadius) * math.cos(bearingRad),
    );
    double lng2Rad =
        (startLng * (math.pi / 180)) +
        math.atan2(
          (distanceKm / earthRadius) * math.sin(bearingRad) / math.cos(lat1Rad),
          math.cos(distanceKm / earthRadius) -
              math.sin(lat1Rad) * math.sin(lat2Rad),
        );

    return Position(
      latitude: lat2Rad * (180 / math.pi),
      longitude: lng2Rad * (180 / math.pi),
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}

/// Location permission status enum
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Custom exceptions
class LocationServiceDisabledException implements Exception {
  final String message = 'Location services are disabled';
}

class LocationPermissionDeniedException implements Exception {
  final String message = 'Location permission denied';
}

class LocationPermissionDeniedForeverException implements Exception {
  final String message = 'Location permission denied forever';
}
