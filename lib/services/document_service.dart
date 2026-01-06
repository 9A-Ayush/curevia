import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service for handling document operations like download, share, etc.
class DocumentService {
  static final Dio _dio = Dio();

  /// Check storage permissions based on Android version (without requesting)
  static Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ - Check specific media permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];
        
        final statuses = await Future.wait(
          permissions.map((p) => p.status),
        );
        return statuses.every((status) => status.isGranted);
      } else if (androidInfo.version.sdkInt >= 30) {
        // Android 11-12 - Check manage external storage
        final status = await Permission.manageExternalStorage.status;
        return status.isGranted;
      } else {
        // Android 10 and below - Check traditional storage permissions
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS - Check photos permission
      final status = await Permission.photos.status;
      return status.isGranted;
    }
    
    return true; // For other platforms
  }

  /// Request storage permissions based on Android version
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ - Request specific media permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];
        
        Map<Permission, PermissionStatus> statuses = await permissions.request();
        return statuses.values.every((status) => status.isGranted);
      } else if (androidInfo.version.sdkInt >= 30) {
        // Android 11-12 - Request manage external storage
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        // Android 10 and below - Request traditional storage permissions
        final permissions = [
          Permission.storage,
        ];
        
        Map<Permission, PermissionStatus> statuses = await permissions.request();
        return statuses.values.every((status) => status.isGranted);
      }
    } else if (Platform.isIOS) {
      // iOS - Request photos permission
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    
    return true; // For other platforms
  }

  /// Download a document from URL to device storage
  static Future<String> downloadDocument({
    required String url,
    required String fileName,
    String? customPath,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check if storage permission is already granted
      final hasPermission = await checkStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission is required to download files. Please grant permissions in app settings.');
      }

      // Get download directory
      Directory? downloadDir;
      
      if (customPath != null) {
        downloadDir = Directory(customPath);
      } else if (Platform.isAndroid) {
        // Try to use Downloads folder on Android
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        // Use documents directory on iOS
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) {
        throw Exception('Could not access downloads directory');
      }

      // Ensure directory exists
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Create full file path
      final filePath = '${downloadDir.path}/$fileName';

      // Download the file with proper headers for Firebase Storage
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
        options: Options(
          headers: {
            'User-Agent': 'Curevia Medical App',
            'Accept': '*/*',
            'Cache-Control': 'no-cache',
          },
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );

      return filePath;
    } catch (e) {
      // Provide more specific error messages
      String errorMessage = 'Failed to download document';
      if (e.toString().contains('401')) {
        errorMessage = 'Authentication failed. Please check your permissions.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied. You may not have permission to download this document.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Document not found. It may have been moved or deleted.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Download timeout. Please check your internet connection.';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Share a document from URL
  static Future<void> shareDocument({
    required String url,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    try {
      // Download to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$fileName';

      await _dio.download(
        url, 
        tempFilePath,
        options: Options(
          headers: {
            'User-Agent': 'Curevia Medical App',
            'Accept': '*/*',
            'Cache-Control': 'no-cache',
          },
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(tempFilePath)],
        text: text,
        subject: subject,
      );

      // Clean up temporary file after a delay
      Future.delayed(const Duration(seconds: 30), () {
        try {
          File(tempFilePath).deleteSync();
        } catch (e) {
          print('Failed to clean up temporary file: $e');
        }
      });
    } catch (e) {
      // Provide more specific error messages
      String errorMessage = 'Failed to share document';
      if (e.toString().contains('401')) {
        errorMessage = 'Authentication failed. Please check your permissions.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied. You may not have permission to share this document.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Document not found. It may have been moved or deleted.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Share timeout. Please check your internet connection.';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Get file size from URL
  static Future<int?> getFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      final contentLength = response.headers.value('content-length');
      return contentLength != null ? int.tryParse(contentLength) : null;
    } catch (e) {
      print('Failed to get file size: $e');
      return null;
    }
  }

  /// Format file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Check if file exists at path
  static Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete file at path
  static Future<bool> deleteFile(String path) async {
    try {
      await File(path).delete();
      return true;
    } catch (e) {
      print('Failed to delete file: $e');
      return false;
    }
  }

  /// Get downloads directory path
  static Future<String?> getDownloadsPath() async {
    try {
      Directory? downloadDir;
      
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      return downloadDir?.path;
    } catch (e) {
      print('Failed to get downloads path: $e');
      return null;
    }
  }

  /// Create a unique filename to avoid conflicts
  static String createUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.contains('.') 
        ? originalName.split('.').last 
        : 'jpg';
    final nameWithoutExtension = originalName.contains('.') 
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    
    return '${nameWithoutExtension}_$timestamp.$extension';
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Get file extension from URL
  static String getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.contains('.')) {
        return path.split('.').last.toLowerCase();
      }
      return 'jpg'; // Default to jpg for images
    } catch (e) {
      return 'jpg';
    }
  }

  /// Check if URL points to an image
  static bool isImageUrl(String url) {
    final extension = getFileExtension(url);
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(extension);
  }

  /// Check if URL points to a PDF
  static bool isPdfUrl(String url) {
    final extension = getFileExtension(url);
    return extension == 'pdf';
  }

  /// Check if URL points to a document
  static bool isDocumentUrl(String url) {
    final extension = getFileExtension(url);
    const documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf'];
    return documentExtensions.contains(extension);
  }

  /// Get file type from URL
  static String getFileType(String url) {
    if (isImageUrl(url)) return 'image';
    if (isPdfUrl(url)) return 'pdf';
    if (isDocumentUrl(url)) return 'document';
    return 'unknown';
  }

  /// Generate filename from medical record data
  static String generateMedicalReportFileName({
    required String title,
    required DateTime date,
    required String type,
    int? index,
  }) {
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final indexStr = index != null ? '_${index + 1}' : '';
    
    return 'medical_report_${sanitizedTitle}_${type}_$dateStr$indexStr.jpg';
  }
}