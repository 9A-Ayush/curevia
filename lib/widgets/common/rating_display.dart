import 'package:flutter/material.dart';
import 'package:curevia/models/rating_model.dart';
import 'package:curevia/constants/app_colors.dart';

/// Widget for displaying doctor ratings and reviews
class RatingDisplay extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final int totalReviews;
  final Map<int, int>? ratingDistribution;
  final bool showDetails;
  final bool compact;
  final VoidCallback? onTap;

  const RatingDisplay({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    this.totalReviews = 0,
    this.ratingDistribution,
    this.showDetails = false,
    this.compact = false,
    this.onTap,
  });

  /// Factory constructor for compact display
  const RatingDisplay.compact({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    this.onTap,
  }) : totalReviews = 0,
       ratingDistribution = null,
       showDetails = false,
       compact = true;

  /// Factory constructor with full details
  const RatingDisplay.detailed({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    required this.totalReviews,
    required this.ratingDistribution,
    this.onTap,
  }) : showDetails = true,
       compact = false;

  @override
  Widget build(BuildContext context) {
    if (totalRatings == 0) {
      return _buildNoRatings();
    }

    if (compact) {
      return _buildCompactRating();
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainRating(),
          if (showDetails) ...[
            const SizedBox(height: 16),
            _buildRatingDistribution(),
          ],
        ],
      ),
    );
  }

  Widget _buildNoRatings() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 16,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 4),
          Text(
            'No ratings yet',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRating() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getRatingColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 14,
              color: _getRatingColor(),
            ),
            const SizedBox(width: 2),
            Text(
              averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getRatingColor(),
              ),
            ),
            if (totalRatings > 0) ...[
              const SizedBox(width: 2),
              Text(
                '($totalRatings)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainRating() {
    return Row(
      children: [
        // Star rating display
        _buildStarDisplay(),
        const SizedBox(width: 12),
        
        // Rating number and count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'out of 5',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _getRatingText(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Tap indicator
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey[400],
          ),
      ],
    );
  }

  Widget _buildStarDisplay() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= averageRating;
        final isHalfFilled = !isFilled && starIndex - 0.5 <= averageRating;

        return Icon(
          isHalfFilled
              ? Icons.star_half_rounded
              : isFilled
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
          size: 20,
          color: isFilled || isHalfFilled
              ? _getRatingColor()
              : Colors.grey[300],
        );
      }),
    );
  }

  Widget _buildRatingDistribution() {
    if (ratingDistribution == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(5, (index) {
          final rating = 5 - index; // Show 5 stars first
          final count = ratingDistribution![rating] ?? 0;
          final percentage = totalRatings > 0 ? count / totalRatings : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '$rating',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: Colors.amber[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRatingColor(),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getRatingColor() {
    if (averageRating >= 4.5) return Colors.green[600]!;
    if (averageRating >= 4.0) return Colors.lightGreen[600]!;
    if (averageRating >= 3.5) return Colors.amber[600]!;
    if (averageRating >= 3.0) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  String _getRatingText() {
    final reviewText = totalReviews > 0 
        ? '$totalReviews review${totalReviews == 1 ? '' : 's'}'
        : 'No reviews';
    
    return '$totalRatings rating${totalRatings == 1 ? '' : 's'} • $reviewText';
  }
}

/// Widget for displaying individual rating/review cards
class RatingCard extends StatelessWidget {
  final RatingModel rating;
  final bool showDoctorName;
  final bool showPatientName;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RatingCard({
    super.key,
    required this.rating,
    this.showDoctorName = false,
    this.showPatientName = true,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and rating
              Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: rating.patientProfileImage != null
                        ? NetworkImage(rating.patientProfileImage!)
                        : null,
                    child: rating.patientProfileImage == null
                        ? Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // User name and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showPatientName 
                              ? rating.anonymizedPatientName
                              : showDoctorName 
                                  ? 'Dr. ${rating.doctorName}'
                                  : rating.anonymizedPatientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          rating.formattedTimestamp,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Star rating
                  _buildStarRating(),
                  
                  // Trailing widget
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              
              // Review text
              if (rating.hasReview) ...[
                const SizedBox(height: 12),
                Text(
                  rating.reviewText!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRatingColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 14,
            color: _getRatingColor(),
          ),
          const SizedBox(width: 2),
          Text(
            rating.rating.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getRatingColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor() {
    switch (rating.rating) {
      case 5:
        return Colors.green[600]!;
      case 4:
        return Colors.lightGreen[600]!;
      case 3:
        return Colors.amber[600]!;
      case 2:
        return Colors.orange[600]!;
      case 1:
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

/// Widget for displaying a list of ratings with loading and empty states
class RatingsList extends StatelessWidget {
  final List<RatingModel> ratings;
  final bool isLoading;
  final bool showDoctorName;
  final bool showPatientName;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final String emptyMessage;

  const RatingsList({
    super.key,
    required this.ratings,
    this.isLoading = false,
    this.showDoctorName = false,
    this.showPatientName = true,
    this.onLoadMore,
    this.hasMore = false,
    this.emptyMessage = 'No ratings yet',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && ratings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (ratings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.star_outline_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ratings.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == ratings.length) {
          // Load more button
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: onLoadMore,
                      child: const Text('Load More'),
                    ),
            ),
          );
        }

        return RatingCard(
          rating: ratings[index],
          showDoctorName: showDoctorName,
          showPatientName: showPatientName,
        );
      },
    );
  }
}