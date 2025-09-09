import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor_model.dart';
import '../services/firebase/doctor_service.dart';

/// Doctor search filters
class DoctorSearchFilters {
  final String? searchQuery;
  final String? specialty;
  final String? city;
  final double? minRating;
  final double? maxFee;
  final String? consultationType;
  final bool? isAvailable;
  final GeoPoint? userLocation;
  final double? radiusKm;

  const DoctorSearchFilters({
    this.searchQuery,
    this.specialty,
    this.city,
    this.minRating,
    this.maxFee,
    this.consultationType,
    this.isAvailable,
    this.userLocation,
    this.radiusKm,
  });

  DoctorSearchFilters copyWith({
    String? searchQuery,
    String? specialty,
    String? city,
    double? minRating,
    double? maxFee,
    String? consultationType,
    bool? isAvailable,
    GeoPoint? userLocation,
    double? radiusKm,
  }) {
    return DoctorSearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      specialty: specialty ?? this.specialty,
      city: city ?? this.city,
      minRating: minRating ?? this.minRating,
      maxFee: maxFee ?? this.maxFee,
      consultationType: consultationType ?? this.consultationType,
      isAvailable: isAvailable ?? this.isAvailable,
      userLocation: userLocation ?? this.userLocation,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  bool get hasFilters {
    return searchQuery != null ||
           specialty != null ||
           city != null ||
           minRating != null ||
           maxFee != null ||
           consultationType != null ||
           isAvailable != null ||
           userLocation != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorSearchFilters &&
           other.searchQuery == searchQuery &&
           other.specialty == specialty &&
           other.city == city &&
           other.minRating == minRating &&
           other.maxFee == maxFee &&
           other.consultationType == consultationType &&
           other.isAvailable == isAvailable &&
           other.userLocation == userLocation &&
           other.radiusKm == radiusKm;
  }

  @override
  int get hashCode {
    return Object.hash(
      searchQuery,
      specialty,
      city,
      minRating,
      maxFee,
      consultationType,
      isAvailable,
      userLocation,
      radiusKm,
    );
  }
}

/// Doctor search state
class DoctorSearchState {
  final List<DoctorModel> doctors;
  final bool isLoading;
  final String? error;
  final DoctorSearchFilters filters;
  final bool hasMore;

  const DoctorSearchState({
    this.doctors = const [],
    this.isLoading = false,
    this.error,
    this.filters = const DoctorSearchFilters(),
    this.hasMore = true,
  });

  DoctorSearchState copyWith({
    List<DoctorModel>? doctors,
    bool? isLoading,
    String? error,
    DoctorSearchFilters? filters,
    bool? hasMore,
  }) {
    return DoctorSearchState(
      doctors: doctors ?? this.doctors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Doctor search provider
class DoctorSearchNotifier extends StateNotifier<DoctorSearchState> {
  DoctorSearchNotifier() : super(const DoctorSearchState());

  /// Search doctors with filters
  Future<void> searchDoctors({
    DoctorSearchFilters? filters,
    bool clearPrevious = true,
  }) async {
    try {
      if (clearPrevious) {
        state = state.copyWith(
          isLoading: true,
          error: null,
          filters: filters ?? state.filters,
        );
      } else {
        state = state.copyWith(isLoading: true, error: null);
      }

      final searchFilters = filters ?? state.filters;
      final doctors = await DoctorService.searchDoctors(
        searchQuery: searchFilters.searchQuery,
        specialty: searchFilters.specialty,
        city: searchFilters.city,
        minRating: searchFilters.minRating,
        maxFee: searchFilters.maxFee,
        consultationType: searchFilters.consultationType,
        isAvailable: searchFilters.isAvailable,
        userLocation: searchFilters.userLocation,
        radiusKm: searchFilters.radiusKm,
      );

      state = state.copyWith(
        doctors: clearPrevious ? doctors : [...state.doctors, ...doctors],
        isLoading: false,
        hasMore: doctors.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update search filters
  void updateFilters(DoctorSearchFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Clear search results
  void clearResults() {
    state = const DoctorSearchState();
  }

  /// Load more doctors
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await searchDoctors(clearPrevious: false);
  }

  /// Get nearby doctors
  Future<void> getNearbyDoctors({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final doctors = await DoctorService.getNearbyDoctors(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      state = state.copyWith(
        doctors: doctors,
        isLoading: false,
        filters: state.filters.copyWith(
          userLocation: GeoPoint(latitude, longitude),
          radiusKm: radiusKm,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get top-rated doctors
  Future<void> getTopRatedDoctors() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final doctors = await DoctorService.getTopRatedDoctors();

      state = state.copyWith(
        doctors: doctors,
        isLoading: false,
        filters: state.filters.copyWith(minRating: 4.0),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get doctors by specialty
  Future<void> getDoctorsBySpecialty(String specialty) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final doctors = await DoctorService.getDoctorsBySpecialty(specialty);

      state = state.copyWith(
        doctors: doctors,
        isLoading: false,
        filters: state.filters.copyWith(specialty: specialty),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Doctor search provider instance
final doctorSearchProvider = StateNotifierProvider<DoctorSearchNotifier, DoctorSearchState>((ref) {
  return DoctorSearchNotifier();
});

/// Specialties provider
final specialtiesProvider = FutureProvider<List<String>>((ref) async {
  return await DoctorService.getAllSpecialties();
});

/// Individual doctor provider
final doctorProvider = FutureProvider.family<DoctorModel?, String>((ref, doctorId) async {
  return await DoctorService.getDoctorById(doctorId);
});

/// Nearby doctors provider
final nearbyDoctorsProvider = FutureProvider.family<List<DoctorModel>, Map<String, double>>((ref, location) async {
  return await DoctorService.getNearbyDoctors(
    latitude: location['latitude']!,
    longitude: location['longitude']!,
    radiusKm: location['radius'] ?? 10.0,
  );
});

/// Top-rated doctors provider
final topRatedDoctorsProvider = FutureProvider<List<DoctorModel>>((ref) async {
  return await DoctorService.getTopRatedDoctors();
});

/// Available doctors provider
final availableDoctorsProvider = FutureProvider.family<List<DoctorModel>, String>((ref, consultationType) async {
  return await DoctorService.getAvailableDoctors(consultationType: consultationType);
});
