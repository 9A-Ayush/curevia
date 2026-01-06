import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for handling PDF URL validation and fallback options
class PdfUrlService {
  
  /// Check if a PDF URL is accessible
  static Future<PdfUrlStatus> checkPdfUrl(String url) async {
    try {
      final dio = Dio();
      
      // Set a short timeout for the check
      final options = Options(
        method: 'HEAD', // Only get headers, not the full file
        headers: {
          'User-Agent': 'Curevia Medical App',
          'Accept': 'application/pdf,*/*',
        },
        followRedirects: true,
        maxRedirects: 3,
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null && status < 500,
      );

      final response = await dio.request(url, options: options);
      
      if (response.statusCode == 200) {
        final contentType = response.headers.value('content-type');
        final contentLength = response.headers.value('content-length');
        
        return PdfUrlStatus(
          isAccessible: true,
          statusCode: response.statusCode!,
          contentType: contentType,
          contentLength: contentLength != null ? int.tryParse(contentLength) : null,
          error: null,
        );
      } else {
        return PdfUrlStatus(
          isAccessible: false,
          statusCode: response.statusCode!,
          error: 'HTTP ${response.statusCode}',
        );
      }
      
    } catch (e) {
      String errorType = 'Unknown error';
      
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            errorType = 'Connection timeout';
            break;
          case DioExceptionType.badResponse:
            errorType = 'HTTP ${e.response?.statusCode ?? 'Error'}';
            break;
          case DioExceptionType.connectionError:
            errorType = 'Connection error';
            break;
          case DioExceptionType.cancel:
            errorType = 'Request cancelled';
            break;
          default:
            errorType = 'Network error';
        }
      }
      
      return PdfUrlStatus(
        isAccessible: false,
        statusCode: null,
        error: errorType,
      );
    }
  }
  
  /// Get PDF URL type (Firebase, Cloudinary, etc.)
  static PdfUrlType getPdfUrlType(String url) {
    if (url.contains('cloudinary.com')) {
      return PdfUrlType.cloudinary;
    } else if (url.contains('firebasestorage.googleapis.com')) {
      return PdfUrlType.firebase;
    } else if (url.contains('drive.google.com')) {
      return PdfUrlType.googleDrive;
    } else if (url.startsWith('http')) {
      return PdfUrlType.web;
    } else {
      return PdfUrlType.unknown;
    }
  }
  
  /// Convert Google Drive sharing URL to direct download URL
  static String? convertGoogleDriveUrl(String url) {
    try {
      // Convert sharing URL to direct download URL
      final regex = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9-_]+)');
      final match = regex.firstMatch(url);
      
      if (match != null) {
        final fileId = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Open PDF in external browser
  static Future<bool> openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      print('Error opening PDF in browser: $e');
      return false;
    }
  }
  
  /// Get user-friendly error message
  static String getUserFriendlyError(String error) {
    if (error.contains('401')) {
      return 'Authentication failed. The document link may have expired.';
    } else if (error.contains('403')) {
      return 'Access denied. You may not have permission to view this document.';
    } else if (error.contains('404')) {
      return 'Document not found. It may have been moved or deleted.';
    } else if (error.contains('timeout')) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.contains('Connection error')) {
      return 'Unable to connect. Please check your internet connection.';
    } else {
      return 'Unable to load document. Please try again later.';
    }
  }
  
  /// Get suggested actions based on error type
  static List<PdfAction> getSuggestedActions(String error, PdfUrlType urlType) {
    final actions = <PdfAction>[];
    
    // Always suggest retry
    actions.add(PdfAction.retry);
    
    // Suggest browser opening for web URLs
    if (urlType != PdfUrlType.unknown) {
      actions.add(PdfAction.openInBrowser);
    }
    
    // Suggest specific actions based on error
    if (error.contains('401') || error.contains('403')) {
      actions.add(PdfAction.refreshAndRetry);
    } else if (error.contains('timeout') || error.contains('Connection')) {
      actions.add(PdfAction.checkConnection);
    }
    
    // Always allow going back
    actions.add(PdfAction.goBack);
    
    return actions;
  }
}

/// PDF URL status information
class PdfUrlStatus {
  final bool isAccessible;
  final int? statusCode;
  final String? contentType;
  final int? contentLength;
  final String? error;
  
  const PdfUrlStatus({
    required this.isAccessible,
    this.statusCode,
    this.contentType,
    this.contentLength,
    this.error,
  });
  
  bool get isPdf => contentType?.contains('pdf') ?? false;
  
  String get formattedSize {
    if (contentLength == null) return 'Unknown size';
    
    final bytes = contentLength!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  @override
  String toString() {
    return 'PdfUrlStatus(accessible: $isAccessible, status: $statusCode, error: $error)';
  }
}

/// Types of PDF URLs
enum PdfUrlType {
  firebase,
  cloudinary,
  googleDrive,
  web,
  unknown,
}

/// Suggested actions for PDF errors
enum PdfAction {
  retry,
  openInBrowser,
  refreshAndRetry,
  checkConnection,
  goBack,
}

extension PdfUrlTypeExtension on PdfUrlType {
  String get displayName {
    switch (this) {
      case PdfUrlType.firebase:
        return 'Firebase Storage';
      case PdfUrlType.cloudinary:
        return 'Cloudinary';
      case PdfUrlType.googleDrive:
        return 'Google Drive';
      case PdfUrlType.web:
        return 'Web URL';
      case PdfUrlType.unknown:
        return 'Unknown';
    }
  }
  
  bool get isReliable {
    switch (this) {
      case PdfUrlType.cloudinary:
        return true; // Cloudinary URLs don't expire
      case PdfUrlType.firebase:
        return false; // Firebase URLs can expire
      case PdfUrlType.googleDrive:
      case PdfUrlType.web:
        return true; // Generally reliable
      case PdfUrlType.unknown:
        return false;
    }
  }
}

extension PdfActionExtension on PdfAction {
  String get displayName {
    switch (this) {
      case PdfAction.retry:
        return 'Retry';
      case PdfAction.openInBrowser:
        return 'Open in Browser';
      case PdfAction.refreshAndRetry:
        return 'Refresh & Retry';
      case PdfAction.checkConnection:
        return 'Check Connection';
      case PdfAction.goBack:
        return 'Go Back';
    }
  }
  
  String get description {
    switch (this) {
      case PdfAction.retry:
        return 'Try loading the document again';
      case PdfAction.openInBrowser:
        return 'Open the document in your web browser';
      case PdfAction.refreshAndRetry:
        return 'Refresh the app and try again';
      case PdfAction.checkConnection:
        return 'Check your internet connection';
      case PdfAction.goBack:
        return 'Return to the previous screen';
    }
  }
}