import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';
import '../common/theme_aware_card.dart';
import '../common/document_viewer_widget.dart';
import 'document_preview_card.dart' as admin;

class ExpandableVerificationCard extends StatefulWidget {
  final String verificationId;
  final Map<String, dynamic> verificationData;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onViewDetails;

  const ExpandableVerificationCard({
    super.key,
    required this.verificationId,
    required this.verificationData,
    this.onApprove,
    this.onReject,
    this.onViewDetails,
  });

  @override
  State<ExpandableVerificationCard> createState() => _ExpandableVerificationCardState();
}

class _ExpandableVerificationCardState extends State<ExpandableVerificationCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  Map<String, dynamic>? _doctorData;
  bool _isLoadingDoctorData = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorData() async {
    if (_doctorData != null || _isLoadingDoctorData) return;

    setState(() => _isLoadingDoctorData = true);

    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.verificationData['doctorId'])
          .get();

      if (doctorDoc.exists && mounted) {
        setState(() {
          _doctorData = doctorDoc.data();
          _isLoadingDoctorData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDoctorData = false);
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _loadDoctorData();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final status = widget.verificationData['status'] ?? 'pending';
    final submittedAt = widget.verificationData['submittedAt'] as Timestamp?;
    
    return ThemeAwareCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header - Always visible
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Doctor info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _doctorData?['fullName'] ?? 'Doctor ID: ${widget.verificationData['doctorId']}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ThemeUtils.getTextPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: ThemeUtils.getTextSecondaryColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                submittedAt != null
                                    ? 'Submitted ${DateFormat('MMM dd, yyyy').format(submittedAt.toDate())}'
                                    : 'Submission date unknown',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Expand/collapse icon
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Expanded content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: ThemeUtils.getBorderLightColor(context),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildExpandedContent(context, isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, bool isMobile) {
    if (_isLoadingDoctorData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Doctor details
        if (_doctorData != null) ...[
          _buildDoctorInfo(context),
          const SizedBox(height: 16),
        ],
        
        // Verification details
        _buildVerificationInfo(context),
        
        const SizedBox(height: 16),
        
        // Action buttons
        if (widget.verificationData['status'] == 'pending')
          _buildActionButtons(context, isMobile),
      ],
    );
  }

  Widget _buildDoctorInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor Information',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildInfoChip(
              context,
              Icons.person,
              'Name',
              _doctorData?['fullName'] ?? 'N/A',
            ),
            _buildInfoChip(
              context,
              Icons.email,
              'Email',
              _doctorData?['email'] ?? 'N/A',
            ),
            _buildInfoChip(
              context,
              Icons.phone,
              'Phone',
              _doctorData?['phoneNumber'] ?? _doctorData?['phone'] ?? 'N/A',
            ),
            _buildInfoChip(
              context,
              Icons.medical_services,
              'Specialty',
              _doctorData?['specialty'] ?? 'N/A',
            ),
            _buildInfoChip(
              context,
              Icons.work,
              'Experience',
              '${_doctorData?['experienceYears'] ?? 0} years',
            ),
            _buildInfoChip(
              context,
              Icons.school,
              'Education',
              _doctorData?['qualification'] ?? _doctorData?['education'] ?? 'N/A',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Icon(
              Icons.description,
              size: 16,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              'Documents: ${_doctorData?['documentUrls']?.length ?? 0} files',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ],
        ),
        
        // Show document previews if available from doctor's profile
        if (_doctorData != null && _doctorData!['documentUrls'] != null && 
            (_doctorData!['documentUrls'] as List).isNotEmpty) ...[
          const SizedBox(height: 12),
          ...(((_doctorData!['documentUrls'] as List).take(2).toList()).asMap().entries.map((entry) {
            final index = entry.key;
            final documentUrl = entry.value as String;
            final documentName = _getDocumentNameFromUrl(documentUrl, index);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: admin.DocumentPreviewCard(
                documentUrl: documentUrl,
                documentName: documentName,
                documentType: _getDocumentTypeFromUrl(documentUrl),
              ),
            );
          })),
          if ((_doctorData!['documentUrls'] as List).length > 2)
            TextButton(
              onPressed: widget.onViewDetails,
              child: Text(
                'View all ${(_doctorData!['documentUrls'] as List).length} documents',
                style: TextStyle(
                  color: ThemeUtils.getPrimaryColor(context),
                  fontSize: 12,
                ),
              ),
            ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'No documents available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        
        if (widget.verificationData['reason'] != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: _getStatusColor('rejected'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reason: ${widget.verificationData['reason']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getStatusColor('rejected'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: isMobile 
          ? Column(
              children: [
                // First row: View Details (full width)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onViewDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ThemeUtils.getPrimaryColor(context),
                      side: BorderSide(color: ThemeUtils.getPrimaryColor(context)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Second row: Reject and Approve
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: widget.onViewDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ThemeUtils.getPrimaryColor(context),
                      side: BorderSide(color: ThemeUtils.getPrimaryColor(context)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
    );
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
          return 'Medical License';
        } else if (nameWithoutExtension.contains('degree')) {
          return 'Medical Degree';
        } else if (nameWithoutExtension.contains('certificate')) {
          return 'Certificate';
        } else if (nameWithoutExtension.contains('experience')) {
          return 'Experience Letter';
        } else {
          return 'Document ${index + 1}';
        }
      }
    } catch (e) {
      // Fallback if URL parsing fails
    }
    
    return 'Document ${index + 1}';
  }
}