import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Location state
class LocationState {
  final Position? currentPosition;
  final String? currentAddress;
  final bool isLoading;
  final String? error;
  final LocationPermissionStatus permissionStatus;

  const LocationState({
    this.currentPosition,
    this.currentAddress,
    this.isLoading = false,
    this.error,
    this.permissionStatus = LocationPermissionStatus.denied,
  });

  LocationState copyWith({
    Position? currentPosition,
    String? currentAddress,
    bool? isLoading,
    String? error,
    LocationPermissionStatus? permissionStatus,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      currentAddress: currentAddress ?? this.currentAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionStatus: permissionStatus ?? this.permissionStatus,
    );
  }

  bool get hasLocation => currentPosition != null;
  bool get hasPermission =>
      permissionStatus == LocationPermissionStatus.granted;
}

/// Location provider
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState()) {
    _checkPermissionStatus();
  }

  /// Check current permission status
  Future<void> _checkPermissionStatus() async {
    final status = await LocationService.getLocationPermissionStatus();
    state = state.copyWith(permissionStatus: status);
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await LocationService.requestLocationPermission();
      final status = await LocationService.getLocationPermissionStatus();

      state = state.copyWith(isLoading: false, permissionStatus: status);

      return status == LocationPermissionStatus.granted;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get current location
  Future<void> getCurrentLocation() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final position = await LocationService.getCurrentPosition();

      if (position != null) {
        // Get address for the position
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        state = state.copyWith(
          currentPosition: position,
          currentAddress: address,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to get current location',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get location with fallback
  Future<void> getLocationWithFallback() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final position = await LocationService.getPositionWithFallback();

      // Get address for the position
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      state = state.copyWith(
        currentPosition: position,
        currentAddress: address,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set location manually (from address search)
  Future<void> setLocationFromAddress(String address) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final position = await LocationService.getCoordinatesFromAddress(address);

      if (position != null) {
        state = state.copyWith(
          currentPosition: position,
          currentAddress: address,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to find location for: $address',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear location
  void clearLocation() {
    state = const LocationState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await LocationService.openLocationSettings();
    // Recheck permission after user returns
    await _checkPermissionStatus();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await LocationService.openAppSettings();
    // Recheck permission after user returns
    await _checkPermissionStatus();
  }
}

/// Location provider instance
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);

/// Current position provider
final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(locationProvider).currentPosition;
});

/// Current address provider
final currentAddressProvider = Provider<String?>((ref) {
  return ref.watch(locationProvider).currentAddress;
});

/// Location permission provider
final locationPermissionProvider = Provider<LocationPermissionStatus>((ref) {
  return ref.watch(locationProvider).permissionStatus;
});

/// Has location provider
final hasLocationProvider = Provider<bool>((ref) {
  return ref.watch(locationProvider).hasLocation;
});

/// Location loading provider
final locationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(locationProvider).isLoading;
});

/// Location error provider
final locationErrorProvider = Provider<String?>((ref) {
  return ref.watch(locationProvider).error;
});

/// Distance calculator provider
final distanceProvider = Provider.family<double?, Map<String, double>>((
  ref,
  coordinates,
) {
  final currentPosition = ref.watch(currentPositionProvider);
  if (currentPosition == null) return null;

  return LocationService.calculateDistance(
    currentPosition.latitude,
    currentPosition.longitude,
    coordinates['latitude']!,
    coordinates['longitude']!,
  );
});

/// Formatted distance provider
final formattedDistanceProvider = Provider.family<String?, Map<String, double>>(
  (ref, coordinates) {
    final distance = ref.watch(distanceProvider(coordinates));
    if (distance == null) return null;

    return LocationService.formatDistance(distance);
  },
);
