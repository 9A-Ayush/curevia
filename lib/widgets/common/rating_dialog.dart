import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curevia/providers/rating_provider.dart';
import 'package:curevia/constants/app_colors.dart';

/// Dialog for submitting doctor ratings
class RatingDialog extends StatefulWidget {
  final String patientId;
  final String doctorId;
  final String appointmentId;
  final String patientName;
  final String doctorName;
  final String? patientProfileImage;
  final VoidCallback? onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.patientName,
    required this.doctorName,
    this.patientProfileImage,
    this.onRatingSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> with TickerProviderStateMixin {
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RatingProvider>(
      builder: (context, ratingProvider, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Star Rating
                  _buildStarRating(),
                  const SizedBox(height: 8),
                  
                  // Rating Description
                  _buildRatingDescription(),
                  const SizedBox(height: 24),
                  
                  // Review Text Field
                  _buildReviewTextField(),
                  const SizedBox(height: 24),
                  
                  // Error Message
                  if (ratingProvider.submissionError != null)
                    _buildErrorMessage(ratingProvider.submissionError!),
                  
                  // Action Buttons
                  _buildActionButtons(ratingProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.star_rate_rounded,
          size: 48,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Rate Dr. ${widget.doctorName}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'How was your appointment experience?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = starIndex;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            child: Icon(
              starIndex <= _selectedRating
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 40,
              color: starIndex <= _selectedRating
                  ? _getStarColor(starIndex)
                  : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }

  Color _getStarColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.red[400]!;
      case 3:
        return Colors.orange[400]!;
      case 4:
        return Colors.amber[400]!;
      case 5:
        return Colors.green[400]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Widget _buildRatingDescription() {
    if (_selectedRating == 0) return const SizedBox.shrink();

    final descriptions = {
      1: 'Poor - Very unsatisfied',
      2: 'Fair - Somewhat unsatisfied',
      3: 'Good - Neutral experience',
      4: 'Very Good - Satisfied',
      5: 'Excellent - Highly satisfied',
    };

    return AnimatedOpacity(
      opacity: _selectedRating > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Text(
        descriptions[_selectedRating] ?? '',
        style: TextStyle(
          fontSize: 14,
          color: _getStarColor(_selectedRating),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReviewTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write a review (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Share your experience with other patients...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RatingProvider ratingProvider) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: ratingProvider.isSubmittingRating
                ? null
                : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _selectedRating > 0 && !ratingProvider.isSubmittingRating
                ? () => _submitRating(ratingProvider)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: ratingProvider.isSubmittingRating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRating(RatingProvider ratingProvider) async {
    // Clear any previous errors
    ratingProvider.clearSubmissionState();

    // Validate inputs
    final ratingError = ratingProvider.validateRating(_selectedRating);
    final reviewError = ratingProvider.validateReviewText(_reviewController.text);

    if (ratingError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ratingError)),
      );
      return;
    }

    if (reviewError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reviewError)),
      );
      return;
    }

    // Submit rating
    final success = await ratingProvider.submitRating(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      appointmentId: widget.appointmentId,
      rating: _selectedRating,
      reviewText: _reviewController.text.trim().isEmpty 
          ? null 
          : _reviewController.text.trim(),
      patientName: widget.patientName,
      doctorName: widget.doctorName,
      patientProfileImage: widget.patientProfileImage,
    );

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Rating submitted successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Close dialog
      Navigator.of(context).pop();

      // Callback
      widget.onRatingSubmitted?.call();
    }
  }
}

/// Helper function to show rating dialog
Future<void> showRatingDialog({
  required BuildContext context,
  required String patientId,
  required String doctorId,
  required String appointmentId,
  required String patientName,
  required String doctorName,
  String? patientProfileImage,
  VoidCallback? onRatingSubmitted,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RatingDialog(
      patientId: patientId,
      doctorId: doctorId,
      appointmentId: appointmentId,
      patientName: patientName,
      doctorName: doctorName,
      patientProfileImage: patientProfileImage,
      onRatingSubmitted: onRatingSubmitted,
    ),
  );
}