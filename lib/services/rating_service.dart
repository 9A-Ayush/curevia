import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curevia/models/rating_model.dart';
import 'package:curevia/models/appointment_model.dart';
import 'package:curevia/models/doctor_model.dart';

/// Service for managing doctor ratings and reviews
class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a new rating for a doctor
  static Future<String?> submitRating({
    required String patientId,
    required String doctorId,
    required String appointmentId,
    required int rating,
    String? reviewText,
    required String patientName,
    required String doctorName,
    String? patientProfileImage,
  }) async {
    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if appointment can be rated
      final canRate = await canRateAppointment(appointmentId, patientId);
      if (!canRate) {
        throw Exception('This appointment cannot be rated');
      }

      // Create rating document
      final ratingRef = _firestore.collection('ratings').doc();
      final ratingModel = RatingModel(
        id: ratingRef.id,
        patientId: patientId,
        doctorId: doctorId,
        appointmentId: appointmentId,
        rating: rating,
        reviewText: reviewText?.trim(),
        timestamp: DateTime.now(),
        status: 'active',
        patientName: patientName,
        doctorName: doctorName,
        patientProfileImage: patientProfileImage,
      );

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Add rating document
      batch.set(ratingRef, ratingModel.toMap());

      // Update appointment with rating info
      final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
      batch.update(appointmentRef, {
        'isRated': true,
        'ratingId': ratingRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      // Update doctor's average rating (separate transaction for performance)
      await _updateDoctorAverageRating(doctorId);

      return ratingRef.id;
    } catch (e) {
      print('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Check if an appointment can be rated
  static Future<bool> canRateAppointment(String appointmentId, String patientId) async {
    try {
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) return false;

      final appointment = AppointmentModel.fromMap(appointmentDoc.data()!);

      // Check if appointment belongs to patient, is completed, and not already rated
      return appointment.patientId == patientId &&
             appointment.status == 'completed' &&
             appointment.isRated != true;
    } catch (e) {
      print('Error checking if appointment can be rated: $e');
      return false;
    }
  }

  /// Get existing rating for an appointment
  static Future<RatingModel?> getRatingForAppointment(String appointmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return RatingModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      print('Error getting rating for appointment: $e');
      return null;
    }
  }

  /// Get all ratings for a doctor
  static Future<List<RatingModel>> getDoctorRatings({
    required String doctorId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String orderBy = 'timestamp',
    bool descending = true,
  }) async {
    try {
      Query query = _firestore
          .collection('ratings')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .orderBy(orderBy, descending: descending)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting doctor ratings: $e');
      return [];
    }
  }

  /// Get doctor rating statistics
  static Future<Map<String, dynamic>> getDoctorRatingStats(String doctorId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: 'active')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final ratings = ratingsSnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();

      final totalRatings = ratings.length;
      final totalReviews = ratings.where((r) => r.hasReview).length;
      final sumRatings = ratings.fold<int>(0, (sum, rating) => sum + rating.rating);
      final averageRating = sumRatings / totalRatings;

      // Calculate rating distribution
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
      }

      return {
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'totalRatings': totalRatings,
        'totalReviews': totalReviews,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      print('Error getting doctor rating stats: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'totalReviews': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }

  /// Update doctor's average rating in their profile
  static Future<void> _updateDoctorAverageRating(String doctorId) async {
    try {
      final stats = await getDoctorRatingStats(doctorId);
      
      await _firestore.collection('doctors').doc(doctorId).update({
        'averageRating': stats['averageRating'],
        'totalRatings': stats['totalRatings'],
        'totalReviews': stats['totalReviews'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Updated doctor $doctorId rating stats: ${stats['averageRating']} (${stats['totalRatings']} ratings)');
    } catch (e) {
      print('Error updating doctor average rating: $e');
      // Don't rethrow - this is a background operation
    }
  }

  /// Hide/unhide a rating (admin function)
  static Future<void> moderateRating(String ratingId, String status) async {
    try {
      if (!['active', 'hidden'].contains(status)) {
        throw Exception('Invalid status. Must be "active" or "hidden"');
      }

      // Get the rating to find the doctor ID
      final ratingDoc = await _firestore.collection('ratings').doc(ratingId).get();
      if (!ratingDoc.exists) {
        throw Exception('Rating not found');
      }

      final rating = RatingModel.fromMap(ratingDoc.data()!);

      // Update rating status
      await _firestore.collection('ratings').doc(ratingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculate doctor's average rating
      await _updateDoctorAverageRating(rating.doctorId);

      print('✅ Rating $ratingId status updated to: $status');
    } catch (e) {
      print('Error moderating rating: $e');
      rethrow;
    }
  }

  /// Delete a rating (admin function)
  static Future<void> deleteRating(String ratingId) async {
    try {
      // Get the rating to find the doctor ID and appointment ID
      final ratingDoc = await _firestore.collection('ratings').doc(ratingId).get();
      if (!ratingDoc.exists) {
        throw Exception('Rating not found');
      }

      final rating = RatingModel.fromMap(ratingDoc.data()!);

      // Use batch for atomicity
      final batch = _firestore.batch();

      // Delete rating
      batch.delete(_firestore.collection('ratings').doc(ratingId));

      // Update appointment to allow re-rating
      batch.update(
        _firestore.collection('appointments').doc(rating.appointmentId),
        {
          'isRated': false,
          'ratingId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      // Recalculate doctor's average rating
      await _updateDoctorAverageRating(rating.doctorId);

      print('✅ Rating $ratingId deleted successfully');
    } catch (e) {
      print('Error deleting rating: $e');
      rethrow;
    }
  }

  /// Get recent ratings across all doctors (admin function)
  static Future<List<RatingModel>> getRecentRatings({
    int limit = 50,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('ratings')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting recent ratings: $e');
      return [];
    }
  }

  /// Get ratings that need moderation (admin function)
  static Future<List<RatingModel>> getRatingsForModeration({
    int limit = 20,
  }) async {
    try {
      // Get ratings with potentially inappropriate content
      // This is a simple implementation - you might want to add more sophisticated filtering
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      final ratings = querySnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .where((rating) => rating.hasReview) // Only ratings with reviews
          .take(limit)
          .toList();

      return ratings;
    } catch (e) {
      print('Error getting ratings for moderation: $e');
      return [];
    }
  }

  /// Search ratings by patient or doctor name
  static Future<List<RatingModel>> searchRatings({
    required String searchTerm,
    int limit = 20,
  }) async {
    try {
      final searchTermLower = searchTerm.toLowerCase();
      
      // Get all ratings and filter client-side (Firestore doesn't support case-insensitive search)
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(100) // Get a reasonable batch to search through
          .get();

      final filteredRatings = querySnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .where((rating) =>
              rating.patientName.toLowerCase().contains(searchTermLower) ||
              rating.doctorName.toLowerCase().contains(searchTermLower) ||
              (rating.reviewText?.toLowerCase().contains(searchTermLower) ?? false))
          .take(limit)
          .toList();

      return filteredRatings;
    } catch (e) {
      print('Error searching ratings: $e');
      return [];
    }
  }

  /// Get rating analytics for admin dashboard
  static Future<Map<String, dynamic>> getRatingAnalytics() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Get all active ratings
      final allRatingsSnapshot = await _firestore
          .collection('ratings')
          .where('status', isEqualTo: 'active')
          .get();

      final allRatings = allRatingsSnapshot.docs
          .map((doc) => RatingModel.fromMap(doc.data()))
          .toList();

      // Filter by time periods
      final last30Days = allRatings
          .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
          .toList();
      final last7Days = allRatings
          .where((r) => r.timestamp.isAfter(sevenDaysAgo))
          .toList();

      // Calculate statistics
      final totalRatings = allRatings.length;
      final totalReviews = allRatings.where((r) => r.hasReview).length;
      final averageRating = totalRatings > 0
          ? allRatings.fold<double>(0, (sum, r) => sum + r.rating) / totalRatings
          : 0.0;

      // Rating distribution
      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in allRatings) {
        distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
      }

      return {
        'totalRatings': totalRatings,
        'totalReviews': totalReviews,
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'ratingsLast30Days': last30Days.length,
        'ratingsLast7Days': last7Days.length,
        'ratingDistribution': distribution,
        'reviewPercentage': totalRatings > 0 
            ? double.parse((totalReviews / totalRatings * 100).toStringAsFixed(1))
            : 0.0,
      };
    } catch (e) {
      print('Error getting rating analytics: $e');
      return {
        'totalRatings': 0,
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingsLast30Days': 0,
        'ratingsLast7Days': 0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'reviewPercentage': 0.0,
      };
    }
  }