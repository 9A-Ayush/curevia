import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';

enum DocumentType { pdf, image, unknown }

class DocumentViewerWidget extends StatefulWidget {
  final String documentUrl;
  final String documentName;
  final DocumentType? documentType;
  final bool showDownloadButton;
  final bool showShareButton;
  final VoidCallback? onClose;

  const DocumentViewerWidget({
    super.key,
    required this.documentUrl,
    required this.documentName,
    this.documentType,
    this.showDownloadButton = true,
    this.showShareButton = true,
    this.onClose,
  });

  @override
  State<DocumentViewerWidget> createState() => _DocumentViewerWidgetState();
}

class _DocumentViewerWidgetState extends State<DocumentViewerWidget>
    with SingleTickerProviderStateMixin {
  late DocumentType _documentType;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isDownloading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _documentType = widget.documentType ?? _detectDocumentType(widget.documentUrl);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadDocument();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  DocumentType _detectDocumentType(String url) {
    final extension = url.toLowerCase().split('.').last;
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

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Simulate loading delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, we'll assume the document loads successfully
      // In a real implementation, you might want to validate the URL
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load document: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: ThemeUtils.getSurfaceColor(context),
      foregroundColor: ThemeUtils.getTextPrimaryColor(context),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.documentName,
            style: TextStyle(
              color: ThemeUtils.getTextPrimaryColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _getDocumentTypeLabel(),
            style: TextStyle(
              color: ThemeUtils.getTextSecondaryColor(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(
          Icons.close,
          color: ThemeUtils.getTextPrimaryColor(context),
        ),
        onPressed: widget.onClose ?? () => Navigator.pop(context),
      ),
      actions: [
        if (widget.showShareButton)
          IconButton(
            icon: Icon(
              Icons.share,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
            onPressed: _shareDocument,
          ),
        if (widget.showDownloadButton)
          _isDownloading
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ThemeUtils.getPrimaryColor(context),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.download,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                  onPressed: _downloadDocument,
                ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
          color: ThemeUtils.getSurfaceColor(context),
          onSelected: (value) {
            switch (value) {
              case 'open_external':
                _openInExternalApp();
                break;
              case 'copy_link':
                _copyLink();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'open_external',
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new,
                    color: ThemeUtils.getTextPrimaryColor(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Open in External App',
                    style: TextStyle(
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'copy_link',
              child: Row(
                children: [
                  Icon(
                    Icons.copy,
                    color: ThemeUtils.getTextPrimaryColor(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Copy Link',
                    style: TextStyle(
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    switch (_documentType) {
      case DocumentType.image:
        return _buildImageViewer();
      case DocumentType.pdf:
        return _buildPdfViewer();
      case DocumentType.unknown:
        return _buildUnsupportedState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ThemeUtils.getPrimaryColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading document...',
            style: TextStyle(
              color: ThemeUtils.getTextSecondaryColor(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Failed to Load Document',
              style: TextStyle(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadDocument,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeUtils.getPrimaryColor(context),
                    side: BorderSide(color: ThemeUtils.getPrimaryColor(context)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _openInExternalApp,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open External'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeUtils.getPrimaryColor(context),
                    foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Unsupported Document Type',
              style: TextStyle(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This document type cannot be previewed in the app.',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openInExternalApp,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in External App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeUtils.getPrimaryColor(context),
                foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return Container(
      color: ThemeUtils.getBackgroundColor(context),
      child: PhotoView(
        imageProvider: CachedNetworkImageProvider(widget.documentUrl),
        backgroundDecoration: BoxDecoration(
          color: ThemeUtils.getBackgroundColor(context),
        ),
        minScale: PhotoViewComputedScale.contained * 0.5,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        initialScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(tag: widget.documentUrl),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            color: ThemeUtils.getPrimaryColor(context),
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
        ),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(
                  color: ThemeUtils.getTextPrimaryColor(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    // For PDF viewing, we'll show a placeholder with options
    // In a real implementation, you'd use a package like flutter_pdfview
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PDF Viewer',
              style: TextStyle(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF viewing requires additional setup.\nFor now, you can download or open externally.',
              style: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _downloadDocument,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeUtils.getPrimaryColor(context),
                    side: BorderSide(color: ThemeUtils.getPrimaryColor(context)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _openInExternalApp,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open External'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeUtils.getPrimaryColor(context),
                    foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentTypeLabel() {
    switch (_documentType) {
      case DocumentType.pdf:
        return 'PDF Document';
      case DocumentType.image:
        return 'Image';
      case DocumentType.unknown:
        return 'Document';
    }
  }

  Future<void> _shareDocument() async {
    try {
      await Share.share(
        widget.documentUrl,
        subject: widget.documentName,
      );
    } catch (e) {
      _showSnackBar('Failed to share document: $e', isError: true);
    }
  }

  Future<void> _downloadDocument() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final response = await http.get(Uri.parse(widget.documentUrl));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${widget.documentName}');
        
        await file.writeAsBytes(bytes);
        
        _showSnackBar('Document downloaded successfully');
      } else {
        throw Exception('Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Failed to download document: $e', isError: true);
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _openInExternalApp() async {
    try {
      final uri = Uri.parse(widget.documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot open URL');
      }
    } catch (e) {
      _showSnackBar('Failed to open document externally: $e', isError: true);
    }
  }

  Future<void> _copyLink() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.documentUrl));
      _showSnackBar('Link copied to clipboard');
    } catch (e) {
      _showSnackBar('Failed to copy link: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? AppColors.error 
            : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Helper widget for opening documents in a modal
class DocumentViewerModal extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final DocumentType? documentType;

  const DocumentViewerModal({
    super.key,
    required this.documentUrl,
    required this.documentName,
    this.documentType,
  });

  static Future<void> show(
    BuildContext context, {
    required String documentUrl,
    required String documentName,
    DocumentType? documentType,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewerModal(
          documentUrl: documentUrl,
          documentName: documentName,
          documentType: documentType,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DocumentViewerWidget(
      documentUrl: documentUrl,
      documentName: documentName,
      documentType: documentType,
    );
  }
}

// Helper widget for inline document preview
class DocumentPreviewCard extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final DocumentType? documentType;
  final VoidCallback? onTap;
  final bool showPreview;

  const DocumentPreviewCard({
    super.key,
    required this.documentUrl,
    required this.documentName,
    this.documentType,
    this.onTap,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final detectedType = documentType ?? _detectDocumentType(documentUrl);
    
    return Card(
      color: ThemeUtils.getSurfaceColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: InkWell(
        onTap: onTap ?? () => DocumentViewerModal.show(
          context,
          documentUrl: documentUrl,
          documentName: documentName,
          documentType: detectedType,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getTypeColor(detectedType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(detectedType),
                  color: _getTypeColor(detectedType),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentName,
                      style: TextStyle(
                        color: ThemeUtils.getTextPrimaryColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeLabel(detectedType),
                      style: TextStyle(
                        color: ThemeUtils.getTextSecondaryColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.visibility,
                color: ThemeUtils.getTextSecondaryColor(context),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  DocumentType _detectDocumentType(String url) {
    final extension = url.toLowerCase().split('.').last;
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

  IconData _getTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
      case DocumentType.image:
        return Icons.image;
      case DocumentType.unknown:
        return Icons.description;
    }
  }

  Color _getTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return AppColors.error;
      case DocumentType.image:
        return AppColors.info;
      case DocumentType.unknown:
        return AppColors.warning;
    }
  }

  String _getTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return 'PDF Document';
      case DocumentType.image:
        return 'Image File';
      case DocumentType.unknown:
        return 'Document';
    }
  }
}