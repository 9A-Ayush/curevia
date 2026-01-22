import 'package:cloud_firestore/cloud_firestore.dart';

/// Rating model for doctor ratings and reviews
class RatingModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final int rating; // 1-5 stars
  final String? reviewText;
  final DateTime timestamp;
  final String status; // 'active', 'hidden'
  final String patientName; // For display purposes
  final String doctorName; // For display purposes
  final String? patientProfileImage; // Optional patient image

  const RatingModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.rating,
    this.reviewText,
    required this.timestamp,
    this.status = 'active',
    required this.patientName,
    required this.doctorName,
    this.patientProfileImage,
  });

  /// Create RatingModel from Firestore document
  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      rating: map['rating'] ?? 1,
      reviewText: map['reviewText'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      patientName: map['patientName'] ?? '',
      doctorName: map['doctorName'] ?? '',
      patientProfileImage: map['patientProfileImage'],
    );
  }

  /// Convert RatingModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'rating': rating,
      'reviewText': reviewText,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'patientName': patientName,
      'doctorName': doctorName,
      'patientProfileImage': patientProfileImage,
    };
  }

  /// Create a copy of RatingModel with updated fields
  RatingModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? appointmentId,
    int? rating,
    String? reviewText,
    DateTime? timestamp,
    String? status,
    String? patientName,
    String? doctorName,
    String? patientProfileImage,
  }) {
    return RatingModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      patientProfileImage: patientProfileImage ?? this.patientProfileImage,
    );
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 30) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get anonymized patient name for display
  String get anonymizedPatientName {
    if (patientName.isEmpty) return 'Anonymous';
    
    final parts = patientName.split(' ');
    if (parts.length == 1) {
      return '${parts[0][0]}***';
    } else {
      return '${parts[0]} ${parts[1][0]}***';
    }
  }

  /// Check if rating is valid (1-5)
  bool get isValidRating => rating >= 1 && rating <= 5;

  /// Check if rating is active
  bool get isActive => status == 'active';

  /// Check if rating has review text
  bool get hasReview => reviewText != null && reviewText!.trim().isNotEmpty;

  /// Get star display string
  String get starDisplay {
    return '★' * rating + '☆' * (5 - rating);
  }

  @override
  String toString() {
    return 'RatingModel(id: $id, rating: $rating, patientName: $patientName, doctorName: $doctorName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RatingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}