import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor_model.dart';
import '../../constants/app_constants.dart';

/// Service for doctor-related operations
class DoctorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search doctors with filters
  static Future<List<DoctorModel>> searchDoctors({
    String? searchQuery,
    String? specialty,
    String? city,
    double? minRating,
    double? maxFee,
    String? consultationType,
    bool? isAvailable,
    GeoPoint? userLocation,
    double? radiusKm,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.doctorsCollection)
          .where('isActive', isEqualTo: true);

      // Apply filters
      if (specialty != null && specialty.isNotEmpty) {
        query = query.where('specialty', isEqualTo: specialty);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      if (maxFee != null) {
        query = query.where('consultationFee', isLessThanOrEqualTo: maxFee);
      }

      if (consultationType != null) {
        if (consultationType == 'online') {
          query = query.where('isAvailableOnline', isEqualTo: true);
        } else if (consultationType == 'offline') {
          query = query.where('isAvailableOffline', isEqualTo: true);
        }
      }

      if (isAvailable == true) {
        query = query.where('isActive', isEqualTo: true);
      }

      // Order by rating (descending) and limit results
      query = query.orderBy('rating', descending: true).limit(limit);

      final querySnapshot = await query.get();
      List<DoctorModel> doctors = querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply text search filter (client-side for now)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        doctors = doctors.where((doctor) {
          final query = searchQuery.toLowerCase();
          return doctor.fullName.toLowerCase().contains(query) ||
              (doctor.specialty?.toLowerCase().contains(query) ?? false) ||
              (doctor.clinicName?.toLowerCase().contains(query) ?? false) ||
              (doctor.qualification?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Apply location-based filtering (client-side)
      if (userLocation != null && radiusKm != null) {
        doctors = doctors.where((doctor) {
          if (doctor.location == null) return false;
          final distance = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            doctor.location!.latitude,
            doctor.location!.longitude,
          );
          return distance <= radiusKm;
        }).toList();

        // Sort by distance
        doctors.sort((a, b) {
          final distanceA = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            a.location!.latitude,
            a.location!.longitude,
          );
          final distanceB = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            b.location!.latitude,
            b.location!.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }

      return doctors;
    } catch (e) {
      throw Exception('Failed to search doctors: $e');
    }
  }

  /// Get doctor by ID
  static Future<DoctorModel?> getDoctorById(String doctorId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();

      if (doc.exists) {
        return DoctorModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get doctor: $e');
    }
  }

  /// Get doctors by specialty
  static Future<List<DoctorModel>> getDoctorsBySpecialty(
    String specialty, {
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('specialty', isEqualTo: specialty)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get doctors by specialty: $e');
    }
  }

  /// Get nearby doctors
  static Future<List<DoctorModel>> getNearbyDoctors({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      // For now, get all doctors and filter client-side
      // In production, use geohash or GeoFlutterFire for better performance
      final querySnapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('isActive', isEqualTo: true)
          .limit(100) // Get more to filter by location
          .get();

      List<DoctorModel> doctors = querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data()))
          .where((doctor) => doctor.location != null)
          .toList();

      // Filter by distance
      doctors = doctors.where((doctor) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          doctor.location!.latitude,
          doctor.location!.longitude,
        );
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      doctors.sort((a, b) {
        final distanceA = _calculateDistance(
          latitude,
          longitude,
          a.location!.latitude,
          a.location!.longitude,
        );
        final distanceB = _calculateDistance(
          latitude,
          longitude,
          b.location!.latitude,
          b.location!.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return doctors.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get nearby doctors: $e');
    }
  }

  /// Get top-rated doctors
  static Future<List<DoctorModel>> getTopRatedDoctors({int limit = 10}) async {
    try {
      // First, get all active doctors ordered by rating
      final querySnapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit * 2) // Get more to filter client-side
          .get();

      // Filter for high-rated doctors (>4.0) and sort by totalReviews
      List<DoctorModel> doctors = querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data()))
          .where((doctor) => (doctor.rating ?? 0.0) > 4.0)
          .toList();

      // Sort by rating first, then by totalReviews
      doctors.sort((a, b) {
        double ratingA = a.rating ?? 0.0;
        double ratingB = b.rating ?? 0.0;
        int ratingComparison = ratingB.compareTo(ratingA);
        if (ratingComparison != 0) return ratingComparison;

        int reviewsA = a.totalReviews ?? 0;
        int reviewsB = b.totalReviews ?? 0;
        return reviewsB.compareTo(reviewsA);
      });

      return doctors.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get top-rated doctors: $e');
    }
  }

  /// Get available doctors for consultation type
  static Future<List<DoctorModel>> getAvailableDoctors({
    required String consultationType,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.doctorsCollection)
          .where('isActive', isEqualTo: true);

      if (consultationType == 'online') {
        query = query.where('isAvailableOnline', isEqualTo: true);
      } else if (consultationType == 'offline') {
        query = query.where('isAvailableOffline', isEqualTo: true);
      }

      final querySnapshot = await query
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get available doctors: $e');
    }
  }

  /// Get all specialties
  static Future<List<String>> getAllSpecialties() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final specialties = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final specialty = data['specialty'] as String?;
        if (specialty != null && specialty.isNotEmpty) {
          specialties.add(specialty);
        }
      }

      final sortedSpecialties = specialties.toList()..sort();
      return sortedSpecialties;
    } catch (e) {
      throw Exception('Failed to get specialties: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Update doctor availability
  static Future<void> updateDoctorAvailability({
    required String doctorId,
    required Map<String, dynamic> availability,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .update({'availability': availability, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Failed to update doctor availability: $e');
    }
  }

  /// Update doctor rating
  static Future<void> updateDoctorRating({
    required String doctorId,
    required double newRating,
    required int totalReviews,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .update({
            'rating': newRating,
            'totalReviews': totalReviews,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to update doctor rating: $e');
    }
  }
}
