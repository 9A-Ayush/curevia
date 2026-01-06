import 'package:dio/dio.dart';
import '../services/pdf_url_service.dart';

/// Utility class for troubleshooting PDF issues
class PdfTroubleshooter {
  
  /// Test a PDF URL and provide detailed diagnostics
  static Future<PdfDiagnostics> diagnosePdfUrl(String url) async {
    final diagnostics = PdfDiagnostics(url: url);
    
    try {
      // Step 1: Basic URL validation
      diagnostics.isValidUrl = _isValidUrl(url);
      if (!diagnostics.isValidUrl) {
        diagnostics.issues.add('Invalid URL format');
        return diagnostics;
      }
      
      // Step 2: Identify URL type
      diagnostics.urlType = PdfUrlService.getPdfUrlType(url);
      
      // Step 3: Check URL accessibility
      final status = await PdfUrlService.checkPdfUrl(url);
      diagnostics.isAccessible = status.isAccessible;
      diagnostics.statusCode = status.statusCode;
      diagnostics.contentType = status.contentType;
      diagnostics.contentLength = status.contentLength;
      diagnostics.error = status.error;
      
      // Step 4: Analyze issues
      _analyzeIssues(diagnostics);
      
      // Step 5: Generate recommendations
      _generateRecommendations(diagnostics);
      
    } catch (e) {
      diagnostics.error = e.toString();
      diagnostics.issues.add('Failed to diagnose URL: $e');
    }
    
    return diagnostics;
  }
  
  /// Check if URL format is valid
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// Analyze potential issues with the PDF URL
  static void _analyzeIssues(PdfDiagnostics diagnostics) {
    // Check for common Firebase Storage issues
    if (diagnostics.urlType == PdfUrlType.firebase) {
      if (diagnostics.statusCode == 401 || diagnostics.statusCode == 403) {
        diagnostics.issues.add('Firebase Storage authentication failed - URL may have expired');
      }
      diagnostics.issues.add('Firebase Storage URLs can expire - consider migrating to Cloudinary');
    }
    
    // Check for network issues
    if (diagnostics.error?.contains('timeout') == true) {
      diagnostics.issues.add('Connection timeout - check internet connection');
    }
    
    // Check for missing content
    if (diagnostics.statusCode == 404) {
      diagnostics.issues.add('Document not found - file may have been moved or deleted');
    }
    
    // Check content type
    if (diagnostics.contentType != null && !diagnostics.contentType!.contains('pdf')) {
      diagnostics.issues.add('Content type is not PDF: ${diagnostics.contentType}');
    }
    
    // Check file size
    if (diagnostics.contentLength != null) {
      if (diagnostics.contentLength! == 0) {
        diagnostics.issues.add('File appears to be empty');
      } else if (diagnostics.contentLength! > 50 * 1024 * 1024) { // 50MB
        diagnostics.issues.add('Large file size may cause loading issues: ${_formatBytes(diagnostics.contentLength!)}');
      }
    }
  }
  
  /// Generate recommendations based on diagnostics
  static void _generateRecommendations(PdfDiagnostics diagnostics) {
    if (!diagnostics.isAccessible) {
      if (diagnostics.urlType == PdfUrlType.firebase) {
        diagnostics.recommendations.add('Try refreshing the app to get a new authentication token');
        diagnostics.recommendations.add('Consider migrating to Cloudinary for more reliable URLs');
      }
      
      if (diagnostics.error?.contains('timeout') == true) {
        diagnostics.recommendations.add('Check your internet connection');
        diagnostics.recommendations.add('Try switching between WiFi and mobile data');
      }
      
      if (diagnostics.statusCode == 404) {
        diagnostics.recommendations.add('Verify the document still exists');
        diagnostics.recommendations.add('Contact support if the document should be available');
      }
      
      diagnostics.recommendations.add('Try opening the PDF in a web browser as a fallback');
    }
    
    if (diagnostics.urlType == PdfUrlType.firebase) {
      diagnostics.recommendations.add('For better reliability, migrate to Cloudinary storage');
    }
    
    if (diagnostics.contentLength != null && diagnostics.contentLength! > 10 * 1024 * 1024) {
      diagnostics.recommendations.add('Large files may load slowly - consider compressing the PDF');
    }
  }
  
  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Quick test for common PDF issues
  static Future<String> quickDiagnosis(String url) async {
    try {
      final diagnostics = await diagnosePdfUrl(url);
      
      if (diagnostics.isAccessible) {
        return '✅ PDF is accessible and should load properly';
      } else {
        final mainIssue = diagnostics.issues.isNotEmpty 
            ? diagnostics.issues.first 
            : 'Unknown issue';
        final mainRecommendation = diagnostics.recommendations.isNotEmpty 
            ? diagnostics.recommendations.first 
            : 'Try again later';
        return '❌ Issue: $mainIssue\n💡 Suggestion: $mainRecommendation';
      }
    } catch (e) {
      return '❌ Failed to diagnose PDF: $e';
    }
  }
  
  /// Test multiple PDF URLs at once
  static Future<Map<String, PdfDiagnostics>> diagnoseMultipleUrls(List<String> urls) async {
    final results = <String, PdfDiagnostics>{};
    
    for (final url in urls) {
      try {
        results[url] = await diagnosePdfUrl(url);
      } catch (e) {
        results[url] = PdfDiagnostics(url: url)
          ..error = e.toString()
          ..issues.add('Failed to diagnose: $e');
      }
    }
    
    return results;
  }
}

/// Detailed diagnostics for a PDF URL
class PdfDiagnostics {
  final String url;
  bool isValidUrl = false;
  bool isAccessible = false;
  PdfUrlType urlType = PdfUrlType.unknown;
  int? statusCode;
  String? contentType;
  int? contentLength;
  String? error;
  List<String> issues = [];
  List<String> recommendations = [];
  
  PdfDiagnostics({required this.url});
  
  /// Get a summary of the diagnostics
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('PDF Diagnostics for: $url');
    buffer.writeln('URL Type: ${urlType.displayName}');
    buffer.writeln('Accessible: ${isAccessible ? "Yes" : "No"}');
    
    if (statusCode != null) {
      buffer.writeln('Status Code: $statusCode');
    }
    
    if (contentType != null) {
      buffer.writeln('Content Type: $contentType');
    }
    
    if (contentLength != null) {
      buffer.writeln('File Size: ${_formatBytes(contentLength!)}');
    }
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    if (issues.isNotEmpty) {
      buffer.writeln('\nIssues:');
      for (final issue in issues) {
        buffer.writeln('• $issue');
      }
    }
    
    if (recommendations.isNotEmpty) {
      buffer.writeln('\nRecommendations:');
      for (final recommendation in recommendations) {
        buffer.writeln('• $recommendation');
      }
    }
    
    return buffer.toString();
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  @override
  String toString() => summary;
}