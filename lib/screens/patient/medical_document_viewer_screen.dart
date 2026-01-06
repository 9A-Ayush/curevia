import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../models/medical_record_model.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/document_service.dart';
import 'pdf_viewer_screen.dart';

/// Medical Document Viewer Screen for viewing and sharing medical reports
class MedicalDocumentViewerScreen extends ConsumerStatefulWidget {
  final MedicalRecordModel medicalRecord;
  final int initialIndex;

  const MedicalDocumentViewerScreen({
    super.key,
    required this.medicalRecord,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MedicalDocumentViewerScreen> createState() =>
      _MedicalDocumentViewerScreenState();
}

class _MedicalDocumentViewerScreenState
    extends ConsumerState<MedicalDocumentViewerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.medicalRecord.attachments;

    if (attachments.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('No Documents'),
          backgroundColor: ThemeUtils.getPrimaryColor(context),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No documents available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if current attachment is a PDF
    final currentUrl = attachments[_currentIndex];
    final isPdf = DocumentService.isPdfUrl(currentUrl);

    // If it's a PDF, navigate to PDF viewer
    if (isPdf) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              medicalRecord: widget.medicalRecord,
              pdfUrl: currentUrl,
            ),
          ),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                '${_currentIndex + 1} of ${attachments.length}',
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showDocumentInfo,
                  tooltip: 'Document Info',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareDocument,
                  tooltip: 'Share',
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 20),
                          SizedBox(width: 8),
                          Text('Details'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // Photo Gallery
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(attachments[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.5,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                heroAttributes: PhotoViewHeroAttributes(tag: attachments[index]),
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onTapUp: (context, details, controllerValue) {
                  setState(() {
                    _showAppBar = !_showAppBar;
                  });
                },
              );
            },
            itemCount: attachments.length,
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls (when app bar is hidden)
          if (!_showAppBar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomButton(
                        icon: Icons.info_outline,
                        label: 'Info',
                        onPressed: _showDocumentInfo,
                      ),
                      _buildBottomButton(
                        icon: Icons.share,
                        label: 'Share',
                        onPressed: _shareDocument,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Page indicator
          if (attachments.length > 1)
            Positioned(
              bottom: _showAppBar ? 20 : 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${attachments.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareDocument();
        break;
      case 'info':
        _showDocumentInfo();
        break;
    }
  }

  void _showDocumentInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Title', widget.medicalRecord.title),
                  _buildInfoRow('Type', _getTypeDisplayName(widget.medicalRecord.type)),
                  _buildInfoRow('Date', _formatDate(widget.medicalRecord.recordDate)),
                  if (widget.medicalRecord.doctorName != null)
                    _buildInfoRow('Doctor', widget.medicalRecord.doctorName!),
                  if (widget.medicalRecord.hospitalName != null)
                    _buildInfoRow('Hospital', widget.medicalRecord.hospitalName!),
                  if (widget.medicalRecord.diagnosis != null)
                    _buildInfoRow('Diagnosis', widget.medicalRecord.diagnosis!),
                  if (widget.medicalRecord.treatment != null)
                    _buildInfoRow('Treatment', widget.medicalRecord.treatment!),
                  _buildInfoRow('Total Images', '${widget.medicalRecord.attachments.length}'),
                  _buildInfoRow('Current Image', '${_currentIndex + 1}'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Close',
                      onPressed: () => Navigator.pop(context),
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareDocument() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentImageUrl = widget.medicalRecord.attachments[_currentIndex];
      
      // Download the image temporarily for sharing
      final tempDir = await getTemporaryDirectory();
      final fileName = 'medical_report_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(currentImageUrl, filePath);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Medical Report: ${widget.medicalRecord.title}\nDate: ${_formatDate(widget.medicalRecord.recordDate)}',
        subject: 'Medical Report - ${widget.medicalRecord.title}',
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to share document: $e');
    }
  }

  Future<void> _downloadDocument() async {
    try {
      // Check if storage permission is already granted
      final hasPermission = await DocumentService.checkStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('Storage permission is required to download files. Please grant permissions in app settings.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final currentImageUrl = widget.medicalRecord.attachments[_currentIndex];
      
      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }

      // Create filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'medical_report_${widget.medicalRecord.title.replaceAll(' ', '_')}_$timestamp.jpg';
      final filePath = '${downloadsDir.path}/$fileName';

      // Download the file
      final dio = Dio();
      await dio.download(
        currentImageUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('Document downloaded to: ${downloadsDir.path}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to download document: $e');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}