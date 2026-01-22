import 'package:flutter/foundation.dart';
import 'package:curevia/models/rating_model.dart';
import 'package:curevia/services/rating_service.dart';

/// Provider for managing rating state and operations
class RatingProvider with ChangeNotifier {
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
      final ratingId = await RatingService.submitRating(
        patientId: patientId,
        doctorId: doctorId,
        appointmentId: appointmentId,
        rating: rating,
        reviewText: reviewText,
        patientName: patientName,
        doctorName: doctorName,
        patientProfileImage: patientProfileImage,
      );

      _submittedRatingId = ratingId;
      
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
        RatingService.getDoctorRatings(doctorId: doctorId),
        RatingService.getDoctorRatingStats(doctorId),
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

  /// Load more ratings for a doctor (pagination)
  Future<void> loadMoreDoctorRatings(String doctorId) async {
    try {
      final currentRatings = _doctorRatings[doctorId] ?? [];
      if (currentRatings.isEmpty) return;

      // Get the last document for pagination
      // Note: This would require storing DocumentSnapshot references
      // For now, we'll implement a simple offset-based approach
      final moreRatings = await RatingService.getDoctorRatings(
        doctorId: doctorId,
        limit: 20,
        // startAfter: lastDocument, // Would need to implement this
      );

      if (moreRatings.isNotEmpty) {
        _doctorRatings[doctorId] = [...currentRatings, ...moreRatings];
        notifyListeners();
      }
    } catch (e) {
      print('Error loading more doctor ratings: $e');
    }
  }

  /// Check if an appointment can be rated
  Future<bool> canRateAppointment(String appointmentId, String patientId) async {
    try {
      return await RatingService.canRateAppointment(appointmentId, patientId);
    } catch (e) {
      print('Error checking if appointment can be rated: $e');
      return false;
    }
  }

  /// Get existing rating for an appointment
  Future<RatingModel?> getRatingForAppointment(String appointmentId) async {
    try {
      return await RatingService.getRatingForAppointment(appointmentId);
    } catch (e) {
      print('Error getting rating for appointment: $e');
      return null;
    }
  }

  /// Load recent ratings (admin function)
  Future<void> loadRecentRatings({String? status, int limit = 50}) async {
    _isLoadingRecentRatings = true;
    notifyListeners();

    try {
      _recentRatings = await RatingService.getRecentRatings(
        limit: limit,
        status: status,
      );

      _isLoadingRecentRatings = false;
      notifyListeners();
    } catch (e) {
      print('Error loading recent ratings: $e');
      _isLoadingRecentRatings = false;
      notifyListeners();
    }
  }

  /// Moderate a rating (admin function)
  Future<bool> moderateRating(String ratingId, String status) async {
    try {
      await RatingService.moderateRating(ratingId, status);
      
      // Update the rating in local state
      _updateRatingInLists(ratingId, status);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error moderating rating: $e');
      return false;
    }
  }

  /// Delete a rating (admin function)
  Future<bool> deleteRating(String ratingId) async {
    try {
      await RatingService.deleteRating(ratingId);
      
      // Remove the rating from local state
      _removeRatingFromLists(ratingId);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting rating: $e');
      return false;
    }
  }

  /// Load rating analytics (admin function)
  Future<void> loadAnalytics() async {
    _isLoadingAnalytics = true;
    notifyListeners();

    try {
      _analytics = await RatingService.getRatingAnalytics();
      _isLoadingAnalytics = false;
      notifyListeners();
    } catch (e) {
      print('Error loading rating analytics: $e');
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  /// Search ratings
  Future<List<RatingModel>> searchRatings(String searchTerm) async {
    try {
      return await RatingService.searchRatings(searchTerm: searchTerm);
    } catch (e) {
      print('Error searching ratings: $e');
      return [];
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

  /// Update rating status in local lists
  void _updateRatingInLists(String ratingId, String status) {
    // Update in doctor ratings
    for (final ratings in _doctorRatings.values) {
      final index = ratings.indexWhere((r) => r.id == ratingId);
      if (index != -1) {
        ratings[index] = ratings[index].copyWith(status: status);
        break;
      }
    }

    // Update in recent ratings
    final recentIndex = _recentRatings.indexWhere((r) => r.id == ratingId);
    if (recentIndex != -1) {
      _recentRatings[recentIndex] = _recentRatings[recentIndex].copyWith(status: status);
    }
  }

  /// Remove rating from local lists
  void _removeRatingFromLists(String ratingId) {
    // Remove from doctor ratings
    for (final ratings in _doctorRatings.values) {
      ratings.removeWhere((r) => r.id == ratingId);
    }

    // Remove from recent ratings
    _recentRatings.removeWhere((r) => r.id == ratingId);
  }

  /// Get formatted rating display
  String getFormattedRating(double rating) {
    if (rating == 0) return 'No ratings';
    return '${rating.toStringAsFixed(1)} ★';
  }

  /// Get rating color based on value
  String getRatingColorClass(double rating) {
    if (rating >= 4.5) return 'excellent';
    if (rating >= 4.0) return 'very-good';
    if (rating >= 3.5) return 'good';
    if (rating >= 3.0) return 'average';
    return 'poor';
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
}