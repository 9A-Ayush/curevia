import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model for doctor and remedy reviews
class ReviewModel {
  final String id;
  final String reviewerId; // User ID who wrote the review
  final String reviewerName;
  final String? reviewerImageUrl;
  final String targetId; // Doctor ID, Remedy ID, etc.
  final String targetType; // 'doctor', 'remedy', 'medicine'
  final double rating; // 1-5 stars
  final String? title;
  final String? comment;
  final List<String>? pros;
  final List<String>? cons;
  final String? appointmentId; // If review is for a doctor after appointment
  final bool? isVerifiedPurchase; // For medicine reviews
  final bool? isAnonymous;
  final List<String>? imageUrls; // Review images
  final Map<String, dynamic>? additionalInfo;
  final int? helpfulCount; // How many found this helpful
  final List<String>? helpfulBy; // User IDs who found this helpful
  final bool? isReported;
  final String? reportReason;
  final bool? isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImageUrl,
    required this.targetId,
    required this.targetType,
    required this.rating,
    this.title,
    this.comment,
    this.pros,
    this.cons,
    this.appointmentId,
    this.isVerifiedPurchase,
    this.isAnonymous,
    this.imageUrls,
    this.additionalInfo,
    this.helpfulCount,
    this.helpfulBy,
    this.isReported,
    this.reportReason,
    this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ReviewModel from Firestore document
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      reviewerImageUrl: map['reviewerImageUrl'],
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      title: map['title'],
      comment: map['comment'],
      pros: List<String>.from(map['pros'] ?? []),
      cons: List<String>.from(map['cons'] ?? []),
      appointmentId: map['appointmentId'],
      isVerifiedPurchase: map['isVerifiedPurchase'],
      isAnonymous: map['isAnonymous'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      additionalInfo: map['additionalInfo'],
      helpfulCount: map['helpfulCount'] ?? 0,
      helpfulBy: List<String>.from(map['helpfulBy'] ?? []),
      isReported: map['isReported'],
      reportReason: map['reportReason'],
      isApproved: map['isApproved'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ReviewModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerImageUrl': reviewerImageUrl,
      'targetId': targetId,
      'targetType': targetType,
      'rating': rating,
      'title': title,
      'comment': comment,
      'pros': pros,
      'cons': cons,
      'appointmentId': appointmentId,
      'isVerifiedPurchase': isVerifiedPurchase,
      'isAnonymous': isAnonymous,
      'imageUrls': imageUrls,
      'additionalInfo': additionalInfo,
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'isReported': isReported,
      'reportReason': reportReason,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of ReviewModel with updated fields
  ReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? reviewerName,
    String? reviewerImageUrl,
    String? targetId,
    String? targetType,
    double? rating,
    String? title,
    String? comment,
    List<String>? pros,
    List<String>? cons,
    String? appointmentId,
    bool? isVerifiedPurchase,
    bool? isAnonymous,
    List<String>? imageUrls,
    Map<String, dynamic>? additionalInfo,
    int? helpfulCount,
    List<String>? helpfulBy,
    bool? isReported,
    String? reportReason,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerImageUrl: reviewerImageUrl ?? this.reviewerImageUrl,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      appointmentId: appointmentId ?? this.appointmentId,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      imageUrls: imageUrls ?? this.imageUrls,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulBy: helpfulBy ?? this.helpfulBy,
      isReported: isReported ?? this.isReported,
      reportReason: reportReason ?? this.reportReason,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted rating with stars
  String get ratingWithStars {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    String stars = '★' * fullStars;
    if (hasHalfStar) stars += '☆';
    stars += '☆' * emptyStars;
    
    return '$stars (${rating.toStringAsFixed(1)})';
  }

  /// Get display name (anonymous or actual name)
  String get displayName {
    if (isAnonymous == true) return 'Anonymous User';
    return reviewerName;
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get verification badge text
  String? get verificationBadge {
    if (isVerifiedPurchase == true) return 'Verified Purchase';
    if (appointmentId != null) return 'Verified Appointment';
    return null;
  }

  /// Check if user found this review helpful
  bool isHelpfulBy(String userId) {
    return helpfulBy?.contains(userId) ?? false;
  }

  /// Get rating color based on rating value
  String get ratingColor {
    if (rating >= 4.0) return 'green';
    if (rating >= 3.0) return 'orange';
    return 'red';
  }

  /// Get rating category
  String get ratingCategory {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    return 'Poor';
  }

  /// Check if review has images
  bool get hasImages {
    return imageUrls != null && imageUrls!.isNotEmpty;
  }

  /// Get image count
  int get imageCount {
    return imageUrls?.length ?? 0;
  }

  /// Check if review has pros and cons
  bool get hasProsCons {
    return (pros != null && pros!.isNotEmpty) || (cons != null && cons!.isNotEmpty);
  }

  /// Get total pros and cons count
  int get prosConsCount {
    return (pros?.length ?? 0) + (cons?.length ?? 0);
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, reviewer: $reviewerName, rating: $rating, target: $targetType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
