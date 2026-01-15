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

  /// Get verified doctors
  static Future<List<DoctorModel>> getVerifiedDoctors({int limit = 50}) async {
    try {
      // Simple query without composite index requirement
      final querySnapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('isActive', isEqualTo: true)
          .limit(100) // Get more to filter client-side
          .get();

      // If no documents found, return empty list instead of throwing error
      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Filter and sort client-side
      List<DoctorModel> doctors = querySnapshot.docs
          .map((doc) {
            try {
              return DoctorModel.fromMap(doc.data());
            } catch (e) {
              // Skip invalid documents
              return null;
            }
          })
          .where((doctor) => doctor != null)
          .cast<DoctorModel>()
          .where((doctor) {
            // FIXED: More lenient filtering - show doctors if they have either verification method
            final status = doctor.verificationStatus;
            final isVerified = doctor.isVerified ?? false;
            
            // Show if either condition is met (not both required)
            return (status == 'verified' || status == 'approved') || isVerified;
          })
          .toList();

      // Sort by rating
      doctors.sort((a, b) {
        final ratingA = a.rating ?? 0.0;
        final ratingB = b.rating ?? 0.0;
        return ratingB.compareTo(ratingA);
      });

      return doctors.take(limit).toList();
    } catch (e) {
      // Return empty list instead of throwing error for better UX
      return [];
    }
  }

  /// Create sample doctors for testing (development only)
  static Future<void> createSampleDoctors() async {
    try {
      final sampleDoctors = [
        {
          'uid': 'doctor_1',
          'fullName': 'Dr. Sarah Johnson',
          'email': 'sarah.johnson@example.com',
          'specialty': 'Cardiology',
          'qualification': 'MD, FACC',
          'experienceYears': 12,
          'consultationFee': 150.0,
          'rating': 4.8,
          'totalReviews': 245,
          'isActive': true,
          'isVerified': true,
          'verificationStatus': 'verified',
          'isAvailableOnline': true,
          'isAvailableOffline': true,
          'clinicName': 'Heart Care Center',
          'city': 'New York',
          'about': 'Experienced cardiologist specializing in heart disease prevention and treatment.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'doctor_2',
          'fullName': 'Dr. Michael Chen',
          'email': 'michael.chen@example.com',
          'specialty': 'General Medicine',
          'qualification': 'MBBS, MD',
          'experienceYears': 8,
          'consultationFee': 100.0,
          'rating': 4.6,
          'totalReviews': 189,
          'isActive': true,
          'isVerified': true,
          'verificationStatus': 'verified',
          'isAvailableOnline': true,
          'isAvailableOffline': true,
          'clinicName': 'City Medical Center',
          'city': 'Los Angeles',
          'about': 'General practitioner with expertise in family medicine and preventive care.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'doctor_3',
          'fullName': 'Dr. Emily Rodriguez',
          'email': 'emily.rodriguez@example.com',
          'specialty': 'Dermatology',
          'qualification': 'MD, Dermatology',
          'experienceYears': 10,
          'consultationFee': 120.0,
          'rating': 4.9,
          'totalReviews': 156,
          'isActive': true,
          'isVerified': true,
          'verificationStatus': 'verified',
          'isAvailableOnline': true,
          'isAvailableOffline': false,
          'clinicName': 'Skin Health Clinic',
          'city': 'Chicago',
          'about': 'Dermatologist specializing in skin conditions and cosmetic procedures.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'doctor_4',
          'fullName': 'Dr. James Wilson',
          'email': 'james.wilson@example.com',
          'specialty': 'Pediatrics',
          'qualification': 'MD, Pediatrics',
          'experienceYears': 15,
          'consultationFee': 110.0,
          'rating': 4.7,
          'totalReviews': 203,
          'isActive': true,
          'isVerified': true,
          'verificationStatus': 'verified',
          'isAvailableOnline': true,
          'isAvailableOffline': true,
          'clinicName': 'Children\'s Health Center',
          'city': 'Houston',
          'about': 'Pediatrician with extensive experience in child healthcare and development.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'uid': 'doctor_5',
          'fullName': 'Dr. Lisa Thompson',
          'email': 'lisa.thompson@example.com',
          'specialty': 'Orthopedics',
          'qualification': 'MD, Orthopedic Surgery',
          'experienceYears': 18,
          'consultationFee': 180.0,
          'rating': 4.5,
          'totalReviews': 134,
          'isActive': true,
          'isVerified': true,
          'verificationStatus': 'verified',
          'isAvailableOnline': false,
          'isAvailableOffline': true,
          'clinicName': 'Bone & Joint Clinic',
          'city': 'Phoenix',
          'about': 'Orthopedic surgeon specializing in joint replacement and sports injuries.',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Check if doctors already exist
      final existingDoctors = await _firestore
          .collection(AppConstants.doctorsCollection)
          .limit(1)
          .get();

      if (existingDoctors.docs.isNotEmpty) {
        print('Sample doctors already exist, skipping creation');
        return;
      }

      // Add sample doctors
      for (final doctorData in sampleDoctors) {
        await _firestore
            .collection(AppConstants.doctorsCollection)
            .doc(doctorData['uid'] as String)
            .set(doctorData);
      }

      print('Successfully created ${sampleDoctors.length} sample doctors');
    } catch (e) {
      print('Error creating sample doctors: $e');
    }
  }

  /// Get doctor profile by ID
  static Future<Map<String, dynamic>?> getDoctorProfile(String doctorId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get doctor profile: $e');
    }
  }

  /// Update doctor profile
  static Future<void> updateDoctorProfile({
    required String doctorId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .update({
        ...profileData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update doctor profile: $e');
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

  /// Verify a doctor (admin function)
  static Future<void> verifyDoctor(String doctorId) async {
    try {
      await _firestore
          .collection(AppConstants.doctorsCollection)
          .doc(doctorId)
          .update({
            'verificationStatus': 'verified',
            'isVerified': true,
            'verifiedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });

      // Update verification request
      final verificationQuery = await _firestore
          .collection('doctor_verifications')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in verificationQuery.docs) {
        await doc.reference.update({
          'status': 'approved',
          'reviewedAt': Timestamp.now(),
          'reviewedBy': 'admin', // In real app, use actual admin ID
        });
      }
    } catch (e) {
      throw Exception('Failed to verify doctor: $e');
    }
  }

  /// Fix verification status inconsistencies (development helper)
  static Future<int> fixVerificationInconsistencies() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      int fixedCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['verificationStatus'];
        final isVerified = data['isVerified'];
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Fix doctors that have verificationStatus = 'verified' but isVerified != true
        if (status == 'verified' && isVerified != true) {
          updates['isVerified'] = true;
          needsUpdate = true;
        }
        
        // Fix doctors that have isVerified = true but wrong status
        if (isVerified == true && (status != 'verified' && status != 'approved')) {
          updates['verificationStatus'] = 'verified';
          needsUpdate = true;
        }

        if (needsUpdate) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await doc.reference.update(updates);
          fixedCount++;
        }
      }

      return fixedCount;
    } catch (e) {
      throw Exception('Failed to fix verification inconsistencies: $e');
    }
  }

  /// Get all pending doctors for verification (admin function)
  static Future<List<DoctorModel>> getPendingDoctors() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.doctorsCollection)
          .where('verificationStatus', isEqualTo: 'pending')
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            try {
              return DoctorModel.fromMap(doc.data());
            } catch (e) {
              return null;
            }
          })
          .where((doctor) => doctor != null)
          .cast<DoctorModel>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
