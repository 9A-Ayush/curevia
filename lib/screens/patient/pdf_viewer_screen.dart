import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../models/medical_record_model.dart';
import '../../utils/theme_utils.dart';
import '../../services/document_service.dart';
import '../../services/cloudinary/medical_document_service.dart';

/// PDF Viewer Screen for viewing and sharing PDF medical reports
class PdfViewerScreen extends ConsumerStatefulWidget {
  final MedicalRecordModel medicalRecord;
  final String pdfUrl;

  const PdfViewerScreen({
    super.key,
    required this.medicalRecord,
    required this.pdfUrl,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _hasError = false;
  String? _localFilePath;
  PDFViewController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadPdfForViewing();
  }

  Future<void> _downloadPdfForViewing() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      String downloadUrl = widget.pdfUrl;
      
      // Handle different URL types
      if (widget.pdfUrl.contains('cloudinary.com')) {
        // Cloudinary URLs don't expire, use directly
        downloadUrl = widget.pdfUrl;
      } else if (widget.pdfUrl.contains('firebasestorage.googleapis.com')) {
        // This is a Firebase Storage URL - try to get a fresh one
        try {
          // If we have a document ID, try to get fresh URL from Cloudinary service
          // For now, we'll try the original URL and handle errors gracefully
          downloadUrl = widget.pdfUrl;
        } catch (e) {
          print('Could not refresh Firebase URL: $e');
        }
      }

      final dio = Dio();
      
      // Different headers based on URL type
      Map<String, String> headers = {
        'User-Agent': 'Curevia Medical App',
        'Accept': 'application/pdf,*/*',
      };
      
      // For Firebase Storage URLs, don't add authentication headers that might cause issues
      if (!widget.pdfUrl.contains('firebasestorage.googleapis.com')) {
        headers['Cache-Control'] = 'no-cache';
      }
      
      final options = Options(
        headers: headers,
        followRedirects: true,
        maxRedirects: 5,
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 3),
        validateStatus: (status) {
          // Accept any status code less than 500
          return status != null && status < 500;
        },
      );

      final response = await dio.download(
        downloadUrl, 
        filePath,
        options: options,
      );

      // Check if download was successful
      final file = File(filePath);
      if (await file.exists() && await file.length() > 0) {
        if (mounted) {
          setState(() {
            _localFilePath = filePath;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Downloaded file is empty or corrupted');
      }
      
    } catch (e) {
      print('PDF download error: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        
        // Show fallback options
        _showPdfErrorDialog(e);
      }
    }
  }

  /// Show error dialog with fallback options
  void _showPdfErrorDialog(dynamic error) {
    String errorMessage = 'Failed to load PDF';
    String suggestion = 'Please try again or contact support.';
    
    if (error.toString().contains('401') || error.toString().contains('403')) {
      errorMessage = 'Authentication failed';
      suggestion = 'The document link may have expired. Please refresh and try again.';
    } else if (error.toString().contains('404')) {
      errorMessage = 'Document not found';
      suggestion = 'The document may have been moved or deleted.';
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Connection timeout';
      suggestion = 'Please check your internet connection and try again.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Load PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: 8),
            Text(
              suggestion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openInBrowser();
            },
            child: const Text('Open in Browser'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _retryDownload();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Retry downloading the PDF
  void _retryDownload() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _localFilePath = null;
    });
    _downloadPdfForViewing();
  }

  /// Open PDF in browser as fallback
  void _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open PDF in browser'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.medicalRecord.title,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_localFilePath != null) ...[
            IconButton(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              tooltip: 'Share PDF',
            ),
          ],
          IconButton(
            onPressed: _showDocumentInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Document Info',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _totalPages > 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "prev",
                  mini: true,
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  backgroundColor: _currentPage > 0
                      ? ThemeUtils.getPrimaryColor(context)
                      : ThemeUtils.getTextSecondaryColor(context),
                  child: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  heroTag: "next",
                  mini: true,
                  onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                  backgroundColor: _currentPage < _totalPages - 1
                      ? ThemeUtils.getPrimaryColor(context)
                      : ThemeUtils.getTextSecondaryColor(context),
                  child: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ThemeUtils.getPrimaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeUtils.getErrorColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retryDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeUtils.getPrimaryColor(context),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openInBrowser,
              style: TextButton.styleFrom(
                foregroundColor: ThemeUtils.getPrimaryColor(context),
              ),
              child: const Text('Open in Browser'),
            ),
          ],
        ),
      );
    }

    if (_localFilePath != null) {
      return Column(
        children: [
          // Page indicator
          if (_totalPages > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: ThemeUtils.getSurfaceColor(context),
              child: Text(
                'Page ${_currentPage + 1} of $_totalPages',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: ThemeUtils.getTextPrimaryColor(context),
                ),
              ),
            ),
          // PDF View
          Expanded(
            child: Container(
              color: ThemeUtils.getSurfaceColor(context),
              child: PDFView(
                filePath: _localFilePath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: true,
                pageSnap: true,
                defaultPage: 0,
                fitPolicy: FitPolicy.BOTH,
                preventLinkNavigation: false,
                onRender: (pages) {
                  setState(() {
                    _totalPages = pages ?? 0;
                  });
                },
                onViewCreated: (PDFViewController pdfViewController) {
                  _pdfController = pdfViewController;
                },
                onPageChanged: (int? page, int? total) {
                  setState(() {
                    _currentPage = page ?? 0;
                    _totalPages = total ?? 0;
                  });
                },
                onError: (error) {
                  _showErrorSnackBar('Error loading PDF: $error');
                },
                onPageError: (page, error) {
                  _showErrorSnackBar('Error loading page $page: $error');
                },
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        'No PDF to display',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: ThemeUtils.getTextSecondaryColor(context),
        ),
      ),
    );
  }

  void _previousPage() {
    if (_pdfController != null && _currentPage > 0) {
      _pdfController!.setPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_pdfController != null && _currentPage < _totalPages - 1) {
      _pdfController!.setPage(_currentPage + 1);
    }
  }

  void _showDocumentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        title: Text(
          'Document Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ThemeUtils.getTextPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 8),
            if (_totalPages > 0)
              _buildInfoRow('Pages', '$_totalPages'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ThemeUtils.getPrimaryColor(context),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
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

  String _getTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'consultation':
        return 'Consultation';
      case 'lab_test':
        return 'Lab Test';
      case 'prescription':
        return 'Prescription';
      case 'vaccination':
        return 'Vaccination';
      case 'surgery':
        return 'Surgery';
      case 'checkup':
        return 'Checkup';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _sharePdf() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Get a fresh download URL
      String downloadUrl = widget.pdfUrl;
      // For Cloudinary URLs, use them directly
      if (widget.pdfUrl.contains('cloudinary.com')) {
        downloadUrl = widget.pdfUrl;
      } else {
        downloadUrl = widget.pdfUrl;
      }

      final fileName = DocumentService.generateMedicalReportFileName(
        title: widget.medicalRecord.title,
        date: widget.medicalRecord.recordDate,
        type: widget.medicalRecord.type,
      );

      await DocumentService.shareDocument(
        url: downloadUrl,
        fileName: fileName,
        text: 'Medical Report: ${widget.medicalRecord.title}\nDate: ${_formatDate(widget.medicalRecord.recordDate)}',
        subject: 'Medical Report - ${widget.medicalRecord.title}',
      );

      setState(() {
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showErrorSnackBar('Failed to share document: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeUtils.getErrorColor(context),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeUtils.getSuccessColor(context),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up temporary file
    if (_localFilePath != null) {
      try {
        File(_localFilePath!).deleteSync();
      } catch (e) {
        print('Error deleting temp file: $e');
      }
    }
    super.dispose();
  }
}