import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/common/theme_aware_card.dart';
import '../../widgets/common/document_viewer_widget.dart';

class DoctorVerificationDetailsScreen extends StatefulWidget {
  final String verificationId;
  final String doctorId;

  const DoctorVerificationDetailsScreen({
    super.key,
    required this.verificationId,
    required this.doctorId,
  });

  @override
  State<DoctorVerificationDetailsScreen> createState() => _DoctorVerificationDetailsScreenState();
}

class _DoctorVerificationDetailsScreenState extends State<DoctorVerificationDetailsScreen> {
  Map<String, dynamic>? _verificationData;
  Map<String, dynamic>? _doctorData;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('doctor_verifications')
            .doc(widget.verificationId)
            .get(),
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .get(),
      ]);

      if (mounted) {
        setState(() {
          _verificationData = futures[0].exists ? futures[0].data() as Map<String, dynamic>? : null;
          _doctorData = futures[1].exists ? futures[1].data() as Map<String, dynamic>? : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        foregroundColor: ThemeUtils.getTextPrimaryColor(context),
        elevation: 0,
        title: Text(
          'Doctor Verification Details',
          style: TextStyle(
            color: ThemeUtils.getTextPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _verificationData == null || _doctorData == null
              ? _buildErrorState()
              : _buildContent(context, isMobile),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load verification details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          _buildStatusHeader(context),
          const SizedBox(height: 24),

          if (isMobile) ...[
            // Mobile: Single column layout
            _buildDoctorProfileCard(context),
            const SizedBox(height: 16),
            _buildVerificationDetailsCard(context),
            const SizedBox(height: 16),
            _buildDocumentsCard(context),
            const SizedBox(height: 16),
            _buildTimelineCard(context),
          ] else ...[
            // Desktop: Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildDoctorProfileCard(context),
                      const SizedBox(height: 16),
                      _buildDocumentsCard(context),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildVerificationDetailsCard(context),
                      const SizedBox(height: 16),
                      _buildTimelineCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          if (_verificationData!['status'] == 'pending')
            _buildActionButtons(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final status = _verificationData!['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(status),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Status',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorProfileCard(BuildContext context) {
    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doctor Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),

          // Profile photo placeholder
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(context).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThemeUtils.getPrimaryColor(context),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Doctor information
          _buildInfoRow(context, 'Full Name', _doctorData!['fullName'] ?? 'N/A'),
          _buildInfoRow(context, 'Email', _doctorData!['email'] ?? 'N/A'),
          _buildInfoRow(context, 'Phone', _doctorData!['phoneNumber'] ?? _doctorData!['phone'] ?? 'N/A'),
          _buildInfoRow(context, 'Specialty', _doctorData!['specialty'] ?? 'N/A'),
          _buildInfoRow(context, 'Experience', '${_doctorData!['experienceYears'] ?? 0} years'),
          _buildInfoRow(context, 'Education', _doctorData!['qualification'] ?? _doctorData!['education'] ?? 'N/A'),
          _buildInfoRow(context, 'License Number', _doctorData!['licenseNumber'] ?? 'N/A'),
          _buildInfoRow(context, 'Hospital/Clinic', _doctorData!['hospitalName'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildVerificationDetailsCard(BuildContext context) {
    final submittedAt = _verificationData!['submittedAt'] as Timestamp?;
    final reviewedAt = _verificationData!['reviewedAt'] as Timestamp?;

    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            context,
            'Submitted Date',
            submittedAt != null
                ? DateFormat('MMM dd, yyyy - hh:mm a').format(submittedAt.toDate())
                : 'N/A',
          ),
          
          if (reviewedAt != null)
            _buildInfoRow(
              context,
              'Reviewed Date',
              DateFormat('MMM dd, yyyy - hh:mm a').format(reviewedAt.toDate()),
            ),

          if (_verificationData!['reason'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rejection Reason',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _verificationData!['reason'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context) {
    // Get documents from doctor's profile instead of verification data
    final doctorDocuments = _doctorData?['documentUrls'] as List<dynamic>? ?? [];
    
    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uploaded Documents',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),

          if (doctorDocuments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeUtils.getSurfaceVariantColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No documents uploaded',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            )
          else
            ...doctorDocuments.asMap().entries.map((entry) {
              final index = entry.key;
              final documentUrl = entry.value as String;
              final documentName = _getDocumentNameFromUrl(documentUrl, index);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DocumentPreviewCard(
                  documentUrl: documentUrl,
                  documentName: documentName,
                  documentType: _getDocumentTypeFromUrl(documentUrl),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  DocumentType _getDocumentTypeFromUrl(String url) {
    final extension = url.toLowerCase().split('.').last.split('?').first; // Remove query params
    switch (extension) {
      case 'pdf':
        return DocumentType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return DocumentType.image;
      default:
        return DocumentType.unknown;
    }
  }

  String _getDocumentNameFromUrl(String url, int index) {
    try {
      // Extract filename from Cloudinary URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isNotEmpty) {
        final filename = pathSegments.last;
        final nameWithoutExtension = filename.split('.').first;
        
        // Try to extract document type from the filename
        if (nameWithoutExtension.contains('license')) {
          return 'Medical License Certificate';
        } else if (nameWithoutExtension.contains('degree')) {
          return 'Medical Degree Certificate';
        } else if (nameWithoutExtension.contains('certificate')) {
          return 'Professional Certificate';
        } else if (nameWithoutExtension.contains('experience')) {
          return 'Experience Letter';
        } else if (nameWithoutExtension.contains('profile')) {
          return 'Profile Photo';
        } else {
          return 'Document ${index + 1}';
        }
      }
    } catch (e) {
      // Fallback if URL parsing fails
    }
    
    return 'Document ${index + 1}';
  }

  Widget _buildTimelineCard(BuildContext context) {
    return ThemeAwareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Timeline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),

          _buildTimelineItem(
            context,
            'Application Submitted',
            _verificationData!['submittedAt'] as Timestamp?,
            Icons.upload_file,
            AppColors.info,
            true,
          ),

          if (_verificationData!['reviewedAt'] != null)
            _buildTimelineItem(
              context,
              _verificationData!['status'] == 'verified' ? 'Approved' : 'Rejected',
              _verificationData!['reviewedAt'] as Timestamp?,
              _verificationData!['status'] == 'verified' ? Icons.check_circle : Icons.cancel,
              _getStatusColor(_verificationData!['status']),
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    Timestamp? timestamp,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate()),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _rejectVerification(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _approveVerification(),
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(_isProcessing ? 'Processing...' : 'Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveVerification() async {
    setState(() => _isProcessing = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('doctor_verifications').doc(widget.verificationId),
        {
          'status': 'verified',
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId),
        {
          'verificationStatus': 'verified',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor verified successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectVerification() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: ThemeUtils.getSurfaceColor(context),
          title: Text(
            'Reject Verification',
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Enter reason...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('doctor_verifications').doc(widget.verificationId),
        {
          'status': 'rejected',
          'reason': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId),
        {
          'verificationStatus': 'rejected',
          'verificationReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification rejected'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'verified':
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return ThemeUtils.getTextSecondaryColor(context);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'verified':
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}