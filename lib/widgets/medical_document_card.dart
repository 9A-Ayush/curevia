import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/medical_record_model.dart';
import '../constants/app_colors.dart';
import '../utils/theme_utils.dart';
import '../screens/patient/medical_document_viewer_screen.dart';
import '../screens/patient/pdf_viewer_screen.dart';
import '../services/document_service.dart';

/// Enhanced Medical Document Card with thumbnail preview and quick actions
class MedicalDocumentCard extends StatelessWidget {
  final MedicalRecordModel medicalRecord;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showThumbnails;

  const MedicalDocumentCard({
    super.key,
    required this.medicalRecord,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.showThumbnails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () => _openDocumentViewer(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicalRecord.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ThemeUtils.getTextPrimaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTypeDisplayName(medicalRecord.type),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showActions)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleAction(context, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Document details
              _buildDetailRow(
                context,
                Icons.calendar_today,
                'Date',
                _formatDate(medicalRecord.recordDate),
              ),
              
              if (medicalRecord.doctorName != null)
                _buildDetailRow(
                  context,
                  Icons.person,
                  'Doctor',
                  medicalRecord.doctorName!,
                ),

              if (medicalRecord.hospitalName != null)
                _buildDetailRow(
                  context,
                  Icons.local_hospital,
                  'Hospital',
                  medicalRecord.hospitalName!,
                ),

              if (medicalRecord.attachments.isNotEmpty)
                _buildDetailRow(
                  context,
                  Icons.attachment,
                  'Attachments',
                  '${medicalRecord.attachments.length} file(s)',
                ),

              // Thumbnails section
              if (showThumbnails && medicalRecord.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildThumbnailsSection(context),
              ],

              // Quick actions
              if (medicalRecord.attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildQuickActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments (${medicalRecord.attachments.length})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: medicalRecord.attachments.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openDocumentViewer(context, initialIndex: index),
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // Check if it's a PDF or image
                        DocumentService.isPdfUrl(medicalRecord.attachments[index])
                            ? Container(
                                color: Colors.red[50],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.red[700],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PDF',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: medicalRecord.attachments[index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                              ),
                        if (medicalRecord.attachments.length > 1)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openDocumentViewer(context),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _openDocumentViewer(BuildContext context, {int initialIndex = 0}) {
    if (medicalRecord.attachments.isNotEmpty) {
      final currentUrl = medicalRecord.attachments[initialIndex];
      final isPdf = DocumentService.isPdfUrl(currentUrl);
      
      if (isPdf) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              medicalRecord: medicalRecord,
              pdfUrl: currentUrl,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicalDocumentViewerScreen(
              medicalRecord: medicalRecord,
              initialIndex: initialIndex,
            ),
          ),
        );
      }
    }
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'view':
        _openDocumentViewer(context);
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  Future<void> _shareDocument(BuildContext context) async {
    if (medicalRecord.attachments.isEmpty) return;

    try {
      final fileName = DocumentService.generateMedicalReportFileName(
        title: medicalRecord.title,
        date: medicalRecord.recordDate,
        type: medicalRecord.type,
      );

      await DocumentService.shareDocument(
        url: medicalRecord.attachments.first,
        fileName: fileName,
        text: 'Medical Report: ${medicalRecord.title}\nDate: ${_formatDate(medicalRecord.recordDate)}',
        subject: 'Medical Report - ${medicalRecord.title}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share document: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _downloadDocument(BuildContext context) async {
    if (medicalRecord.attachments.isEmpty) return;

    try {
      final fileName = DocumentService.generateMedicalReportFileName(
        title: medicalRecord.title,
        date: medicalRecord.recordDate,
        type: medicalRecord.type,
      );

      final filePath = await DocumentService.downloadDocument(
        url: medicalRecord.attachments.first,
        fileName: fileName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document downloaded successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download document: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'lab_test':
        return 'Lab Test';
      case 'consultation':
        return 'Consultation';
      case 'prescription':
        return 'Prescription';
      case 'vaccination':
        return 'Vaccination';
      case 'surgery':
        return 'Surgery';
      case 'checkup':
        return 'Checkup';
      default:
        return type.toUpperCase();
    }
  }
}