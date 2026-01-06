import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;

/// Service for managing file uploads to Cloudinary
class CloudinaryService {
  static Cloudinary? _cloudinary;
  
  /// Initialize Cloudinary with environment variables
  static void initialize() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
    final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];
    
    if (cloudName == null || apiKey == null || apiSecret == null) {
      throw Exception('Cloudinary configuration missing in .env file');
    }
    
    _cloudinary = Cloudinary.signedConfig(
      cloudName: cloudName,
      apiKey: apiKey,
      apiSecret: apiSecret,
    );
  }
  
  /// Get Cloudinary instance
  static Cloudinary get instance {
    if (_cloudinary == null) {
      initialize();
    }
    return _cloudinary!;
  }
  
  /// Upload file to Cloudinary
  static Future<CloudinaryUploadResult> uploadFile({
    required File file,
    required String folder,
    String? publicId,
    Map<String, String>? tags,
    bool? overwrite,
    String? resourceType,
  }) async {
    try {
      final fileName = path.basenameWithoutExtension(file.path);
      final fileExtension = path.extension(file.path).toLowerCase().replaceAll('.', '');
      
      // Generate unique public ID if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniquePublicId = publicId ?? '${fileName}_$timestamp';
      
      // Determine resource type based on file extension
      final type = _getCloudinaryResourceType(fileExtension);
      
      final response = await instance.upload(
        file: file.path,
        resourceType: type,
        folder: folder,
        fileName: uniquePublicId,
        optParams: {
          if (tags != null) 'tags': tags.values.join(','),
          if (overwrite != null) 'overwrite': overwrite.toString(),
          'quality': 'auto',
          'fetch_format': 'auto',
        },
      );
      
      if (response.isSuccessful) {
        return CloudinaryUploadResult(
          success: true,
          publicId: response.publicId!,
          secureUrl: response.secureUrl!,
          url: response.url!,
          format: response.format!,
          resourceType: response.resourceType!,
          bytes: response.bytes!,
          width: response.width,
          height: response.height,
          createdAt: DateTime.now(), // Use current time since API doesn't provide it
          version: response.version!,
        );
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return CloudinaryUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Upload file from bytes
  static Future<CloudinaryUploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    String? publicId,
    Map<String, String>? tags,
    bool? overwrite,
    String? resourceType,
  }) async {
    try {
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      
      // Generate unique public ID if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniquePublicId = publicId ?? '${path.basenameWithoutExtension(fileName)}_$timestamp';
      
      // Determine resource type based on file extension
      final type = _getCloudinaryResourceType(fileExtension);
      
      final response = await instance.upload(
        fileBytes: bytes,
        resourceType: type,
        folder: folder,
        fileName: uniquePublicId,
        optParams: {
          if (tags != null) 'tags': tags.values.join(','),
          if (overwrite != null) 'overwrite': overwrite.toString(),
          'quality': 'auto',
          'fetch_format': 'auto',
        },
      );
      
      if (response.isSuccessful) {
        return CloudinaryUploadResult(
          success: true,
          publicId: response.publicId!,
          secureUrl: response.secureUrl!,
          url: response.url!,
          format: response.format!,
          resourceType: response.resourceType!,
          bytes: response.bytes!,
          width: response.width,
          height: response.height,
          createdAt: DateTime.now(),
          version: response.version!,
        );
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      print('Error uploading bytes to Cloudinary: $e');
      return CloudinaryUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Delete file from Cloudinary
  static Future<bool> deleteFile({
    required String publicId,
    String resourceType = 'image',
  }) async {
    try {
      final type = _getCloudinaryResourceType(resourceType);
      final response = await instance.destroy(
        publicId,
        resourceType: type,
      );
      
      return response.isSuccessful ?? false;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }
  
  /// Generate optimized URL for display
  static String getOptimizedUrl({
    required String publicId,
    int? width,
    int? height,
    String? quality,
    String? format,
    String? crop,
    String? gravity,
  }) {
    try {
      // For the current cloudinary package, we'll build the URL manually
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      if (cloudName == null) return publicId;
      
      final baseUrl = 'https://res.cloudinary.com/$cloudName/image/upload';
      final transformations = <String>[];
      
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (quality != null) transformations.add('q_$quality');
      if (format != null) transformations.add('f_$format');
      if (crop != null) transformations.add('c_$crop');
      if (gravity != null) transformations.add('g_$gravity');
      
      final transformationString = transformations.isNotEmpty ? '${transformations.join(',')}/' : '';
      return '$baseUrl/$transformationString$publicId';
    } catch (e) {
      print('Error generating optimized URL: $e');
      return publicId; // Return original if transformation fails
    }
  }
  
  /// Get Cloudinary resource type based on file extension
  static CloudinaryResourceType _getCloudinaryResourceType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return CloudinaryResourceType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
      case 'ogg':
        return CloudinaryResourceType.video;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      default:
        return CloudinaryResourceType.raw;
    }
  }
  
  /// Generate secure URL with expiration
  static String generateSecureUrl({
    required String publicId,
    int? expirationTimestamp,
    Map<String, dynamic>? transformation,
  }) {
    try {
      // For basic implementation, return the public URL
      // In production, you might want to implement signed URLs
      return getOptimizedUrl(publicId: publicId);
    } catch (e) {
      print('Error generating secure URL: $e');
      return publicId;
    }
  }
}

/// Result class for Cloudinary upload operations
class CloudinaryUploadResult {
  final bool success;
  final String? publicId;
  final String? secureUrl;
  final String? url;
  final String? format;
  final String? resourceType;
  final int? bytes;
  final int? width;
  final int? height;
  final DateTime? createdAt;
  final int? version;
  final String? error;
  
  const CloudinaryUploadResult({
    required this.success,
    this.publicId,
    this.secureUrl,
    this.url,
    this.format,
    this.resourceType,
    this.bytes,
    this.width,
    this.height,
    this.createdAt,
    this.version,
    this.error,
  });
  
  @override
  String toString() {
    if (success) {
      return 'CloudinaryUploadResult(success: $success, publicId: $publicId, secureUrl: $secureUrl)';
    } else {
      return 'CloudinaryUploadResult(success: $success, error: $error)';
    }
  }
}