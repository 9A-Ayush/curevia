import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/env_config.dart';

/// Service for handling image uploads to Cloudinary and Firebase Storage
class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cloudinary instance
  static final Cloudinary _cloudinary = Cloudinary.signedConfig(
    cloudName: EnvConfig.cloudinaryCloudName,
    apiKey: EnvConfig.cloudinaryApiKey,
    apiSecret: EnvConfig.cloudinaryApiSecret,
  );

  /// Test Cloudinary configuration
  static bool testCloudinaryConfig() {
    final cloudName = EnvConfig.cloudinaryCloudName;
    final apiKey = EnvConfig.cloudinaryApiKey;
    final apiSecret = EnvConfig.cloudinaryApiSecret;

    print('Testing Cloudinary configuration:');
    print('Cloud Name: ${cloudName.isNotEmpty ? "✓ Set" : "✗ Missing"}');
    print('API Key: ${apiKey.isNotEmpty ? "✓ Set" : "✗ Missing"}');
    print('API Secret: ${apiSecret.isNotEmpty ? "✓ Set" : "✗ Missing"}');

    return cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
  }

  /// Pick image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Pick image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to capture image from camera: $e');
    }
  }

  /// Show image source selection dialog
  static Future<XFile?> showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Image Source',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    context,
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      try {
                        final image = await pickImageFromGallery();
                        if (context.mounted) {
                          Navigator.pop(context, image);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to pick image: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    context,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      try {
                        final image = await pickImageFromCamera();
                        if (context.mounted) {
                          Navigator.pop(context, image);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to capture image: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  /// Upload image to Cloudinary
  static Future<String> uploadToCloudinary({
    required XFile imageFile,
    required String folder,
    String? publicId,
  }) async {
    try {
      // Debug: Check if Cloudinary is properly configured
      final cloudName = EnvConfig.cloudinaryCloudName;
      final apiKey = EnvConfig.cloudinaryApiKey;
      final apiSecret = EnvConfig.cloudinaryApiSecret;

      print('Cloudinary Config Check:');
      print('Cloud Name: "$cloudName" (${cloudName.length} chars)');
      print('API Key: "$apiKey" (${apiKey.length} chars)');
      print(
        'API Secret: "${apiSecret.isNotEmpty ? "***" : "EMPTY"}" (${apiSecret.length} chars)',
      );

      if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
        throw Exception(
          'Cloudinary credentials not configured properly. Cloud Name: ${cloudName.isEmpty ? "MISSING" : "OK"}, API Key: ${apiKey.isEmpty ? "MISSING" : "OK"}, API Secret: ${apiSecret.isEmpty ? "MISSING" : "OK"}',
        );
      }

      // Debug: Check if file exists
      final file = File(imageFile.path);
      if (!await file.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      print('Uploading to Cloudinary: ${imageFile.path}');
      print('Folder: $folder, PublicId: $publicId');

      // Try to create a new Cloudinary instance to ensure fresh config
      final cloudinary = Cloudinary.signedConfig(
        cloudName: cloudName,
        apiKey: apiKey,
        apiSecret: apiSecret,
      );

      final response = await cloudinary.upload(
        file: imageFile.path,
        folder: folder,
        publicId: publicId,
        resourceType: CloudinaryResourceType.image,
      );

      print('Cloudinary response: ${response.isSuccessful}');
      if (response.error != null) {
        print('Cloudinary error: ${response.error}');
      }

      if (response.isSuccessful) {
        print('Upload successful: ${response.secureUrl}');
        return response.secureUrl!;
      } else {
        throw Exception('Cloudinary upload failed: ${response.error}');
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw Exception('Failed to upload to Cloudinary: $e');
    }
  }

  /// Upload image to Firebase Storage
  static Future<String> uploadToFirebaseStorage({
    required XFile imageFile,
    required String path,
  }) async {
    try {
      print('Starting Firebase Storage upload...');
      print('Path: $path');

      final file = File(imageFile.path);

      // Verify file exists before upload
      if (!await file.exists()) {
        throw Exception('File does not exist at path: ${imageFile.path}');
      }

      final ref = _storage.ref().child(path);
      print('Firebase Storage reference created: ${ref.fullPath}');

      final uploadTask = ref.putFile(file);
      print('Upload task started...');

      final snapshot = await uploadTask;
      print('Upload completed, getting download URL...');

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Firebase Storage upload error: $e');
      throw Exception('Failed to upload to Firebase Storage: $e');
    }
  }

  /// Upload profile picture
  static Future<String> uploadProfilePicture({
    required XFile imageFile,
    required String userId,
  }) async {
    print('=== PROFILE PICTURE UPLOAD DEBUG ===');
    print('User ID: $userId');
    print('Image file path: ${imageFile.path}');
    print('Image file name: ${imageFile.name}');

    try {
      // Check if file exists and get size
      final file = File(imageFile.path);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;

      print('File exists: $exists');
      print('File size: ${size} bytes');

      if (!exists) {
        throw Exception('Selected image file does not exist');
      }

      if (size == 0) {
        throw Exception('Selected image file is empty');
      }

      if (size > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception(
          'Image file is too large (${(size / 1024 / 1024).toStringAsFixed(1)}MB). Please select a smaller image.',
        );
      }

      print('Starting profile picture upload for user: $userId');

      // Use Cloudinary for profile pictures
      final cloudinaryUrl = await uploadToCloudinary(
        imageFile: imageFile,
        folder: 'curevia/profile_pictures',
        publicId: 'profile_$userId',
      );

      print('Cloudinary upload successful: $cloudinaryUrl');
      return cloudinaryUrl;
    } catch (cloudinaryError) {
      print('Cloudinary upload failed: $cloudinaryError');
      print('Attempting fallback to Firebase Storage...');

      try {
        // Fallback to Firebase Storage
        final firebaseUrl = await uploadToFirebaseStorage(
          imageFile: imageFile,
          path: 'profile_pictures/$userId.jpg',
        );

        print('Firebase Storage upload successful: $firebaseUrl');
        return firebaseUrl;
      } catch (firebaseError) {
        print('Firebase Storage upload also failed: $firebaseError');
        throw Exception(
          'Image upload failed. Cloudinary error: $cloudinaryError. Firebase error: $firebaseError',
        );
      }
    }
  }

  /// Delete image from Cloudinary
  static Future<bool> deleteFromCloudinary(String publicId) async {
    try {
      final response = await _cloudinary.destroy(publicId);
      return response.isSuccessful;
    } catch (e) {
      return false;
    }
  }

  /// Delete image from Firebase Storage
  static Future<bool> deleteFromFirebaseStorage(String path) async {
    try {
      await _storage.ref().child(path).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload medical document
  static Future<String> uploadMedicalDocument({
    required XFile imageFile,
    required String userId,
  }) async {
    try {
      print('Starting medical document upload for user: $userId');

      // Use Cloudinary for medical documents
      final cloudinaryUrl = await uploadToCloudinary(
        imageFile: imageFile,
        folder: 'curevia/medical_documents',
        publicId: 'medical_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      print('Medical document upload successful: $cloudinaryUrl');
      return cloudinaryUrl;
    } catch (cloudinaryError) {
      print('Cloudinary upload failed: $cloudinaryError');
      print('Attempting fallback to Firebase Storage...');

      try {
        // Fallback to Firebase Storage
        final firebaseUrl = await uploadToFirebaseStorage(
          imageFile: imageFile,
          path:
              'medical_documents/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        print('Firebase Storage upload successful: $firebaseUrl');
        return firebaseUrl;
      } catch (firebaseError) {
        print('Firebase Storage upload also failed: $firebaseError');
        throw Exception(
          'Failed to upload medical document. Cloudinary: $cloudinaryError, Firebase: $firebaseError',
        );
      }
    }
  }
}
