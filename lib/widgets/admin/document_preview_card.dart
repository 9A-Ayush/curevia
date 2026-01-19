import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../common/document_viewer_widget.dart';

class DocumentPreviewCard extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final DocumentType documentType;

  const DocumentPreviewCard({
    super.key,
    required this.documentUrl,
    required this.documentName,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Row(
        children: [
          // Document type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getDocumentTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getDocumentTypeIcon(),
              color: _getDocumentTypeColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Document info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getDocumentTypeLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          
          // View button
          IconButton(
            onPressed: () => _viewDocument(context),
            icon: Icon(
              Icons.visibility_outlined,
              color: ThemeUtils.getPrimaryColor(context),
            ),
            tooltip: 'View Document',
          ),
        ],
      ),
    );
  }

  Color _getDocumentTypeColor() {
    switch (documentType) {
      case DocumentType.pdf:
        return AppColors.error;
      case DocumentType.image:
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  IconData _getDocumentTypeIcon() {
    switch (documentType) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
      case DocumentType.image:
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeLabel() {
    switch (documentType) {
      case DocumentType.pdf:
        return 'PDF Document';
      case DocumentType.image:
        return 'Image File';
      default:
        return 'Unknown Format';
    }
  }

  void _viewDocument(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              documentName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: DocumentViewerWidget(
            documentUrl: documentUrl,
            documentName: documentName,
            documentType: documentType,
            showDownloadButton: true,
            showShareButton: false,
          ),
        ),
      ),
    );
  }
}