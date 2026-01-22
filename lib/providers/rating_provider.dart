import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curevia/models/rating_model.dart';
import 'package:curevia/models/appointment_model.dart';

/// Provider for managing rating state and operations
class RatingProvider with ChangeNotifier {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Rating submission state
  bool _isSubmittingRating = false;
  String? _submissionError;
  String? _submittedRatingId;

  // Doctor ratings state
  final Map<String, List<RatingModel>> _doctorRatings = {};
  final Map<String, Map<String, dynamic>> _doctorStats = {};
  bool _isLoadingRatings = false;

  // Recent ratings (for admin)
  List<RatingModel> _recentRatings = [];
  bool _isLoadingRecentRatings = false;

  // Analytics (for admin)
  Map<String, dynamic> _analytics = {};
  bool _isLoadingAnalytics = false;

  // Getters
  bool get isSubmittingRating => _isSubmittingRating;
  String? get submissionError => _submissionError;
  String? get submittedRatingId => _submittedRatingId;
  bool get isLoadingRatings => _isLoadingRatings;
  List<RatingModel> get recentRatings => _recentRatings;
  bool get isLoadingRecentRatings => _isLoadingRecentRatings;
  Map<String, dynamic> get analytics => _analytics;
  bool get isLoadingAnalytics => _isLoadingAnalytics;

  /// Get ratings for a specific doctor
  List<RatingModel> getDoctorRatings(String doctorId) {
    return _doctorRatings[doctorId] ?? [];
  }

  /// Get rating statistics for a specific doctor
  Map<String, dynamic> getDoctorStats(String doctorId) {
    return _doctorStats[doctorId] ?? {
      'averageRating': 0.0,
      'totalRatings': 0,
      'totalReviews': 0,
      'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    };
  }

  /// Submit a new rating
  Future<bool> submitRating({
    required String patientId,
    required String doctorId,
    required String appointmentId,
    required int rating,
    String? reviewText,
    required String patientName,
    required String doctorName,
    String? patientProfileImage,
  }) async {
    _isSubmittingRating = true;
    _submissionError = null;
    _submittedRatingId = null;
    notifyListeners();

    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if appointment can be rated
      final canRate = await _canRateAppointment(appointmentId, patientId);
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

      _submittedRatingId = ratingRef.id;
      
      // Refresh doctor ratings and stats
      await loadDoctorRatings(doctorId, refresh: true);
      
      _isSubmittingRating = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _submissionError = e.toString();
      _isSubmittingRating = false;
      notifyListeners();
      return false;
    }
  }

  /// Load ratings for a doctor
  Future<void> loadDoctorRatings(String doctorId, {bool refresh = false}) async {
    if (!refresh && _doctorRatings.containsKey(doctorId)) {
      return; // Already loaded
    }

    _isLoadingRatings = true;
    notifyListeners();

    try {
      // Load ratings and stats in parallel
      final futures = <Future>[
        _getDoctorRatings(doctorId: doctorId),
        _getDoctorRatingStats(doctorId),
      ];
      
      final results = await Future.wait(futures);

      _doctorRatings[doctorId] = results[0] as List<RatingModel>;
      _doctorStats[doctorId] = results[1] as Map<String, dynamic>;

      _isLoadingRatings = false;
      notifyListeners();
    } catch (e) {
      print('Error loading doctor ratings: $e');
      _isLoadingRatings = false;
      notifyListeners();
    }
  }

  /// Check if an appointment can be rated
  Future<bool> canRateAppointment(String appointmentId, String patientId) async {
    try {
      return await _canRateAppointment(appointmentId, patientId);
    } catch (e) {
      print('Error checking if appointment can be rated: $e');
      return false;
    }
  }

  /// Get existing rating for an appointment
  Future<RatingModel?> getRatingForAppointment(String appointmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return RatingModel.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting rating for appointment: $e');
      return null;
    }
  }

  /// Clear submission state
  void clearSubmissionState() {
    _submissionError = null;
    _submittedRatingId = null;
    notifyListeners();
  }

  /// Clear doctor ratings cache
  void clearDoctorRatings(String doctorId) {
    _doctorRatings.remove(doctorId);
    _doctorStats.remove(doctorId);
    notifyListeners();
  }

  /// Clear all cached data
  void clearAllCache() {
    _doctorRatings.clear();
    _doctorStats.clear();
    _recentRatings.clear();
    _analytics.clear();
    notifyListeners();
  }

  /// Validate rating input
  String? validateRating(int? rating) {
    if (rating == null) return 'Please select a rating';
    if (rating < 1 || rating > 5) return 'Rating must be between 1 and 5';
    return null;
  }

  /// Validate review text
  String? validateReviewText(String? text) {
    if (text == null || text.trim().isEmpty) return null; // Review is optional
    if (text.trim().length < 10) return 'Review must be at least 10 characters';
    if (text.trim().length > 500) return 'Review must be less than 500 characters';
    return null;
  }

  // Private helper methods

  /// Check if an appointment can be rated
  Future<bool> _canRateAppointment(String appointmentId, String patientId) async {
    try {
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) return false;

      final data = appointmentDoc.data();
      if (data == null) return false;

      final appointment = AppointmentModel.fromMap(data);

      // Check if appointment belongs to patient, is completed, and not already rated
      return appointment.patientId == patientId &&
             appointment.status == 'completed' &&
             appointment.isRated != true;
    } catch (e) {
      print('Error checking if appointment can be rated: $e');
      return false;
    }
  }

  /// Get all ratings for a doctor
  Future<List<RatingModel>> _getDoctorRatings({
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
          .map((doc) => RatingModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting doctor ratings: $e');
      return [];
    }
  }

  /// Get doctor rating statistics
  Future<Map<String, dynamic>> _getDoctorRatingStats(String doctorId) async {
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
          .map((doc) => RatingModel.fromMap(doc.data() as Map<String, dynamic>))
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
  Future<void> _updateDoctorAverageRating(String doctorId) async {
    try {
      final stats = await _getDoctorRatingStats(doctorId);
      
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
}