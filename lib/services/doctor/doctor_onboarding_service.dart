import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/doctor_model.dart';
import '../image_upload_service.dart';
import '../notifications/role_based_notification_service.dart';

/// Service for handling doctor onboarding operations
class DoctorOnboardingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Initialize doctor document (call this after signup)
  static Future<void> initializeDoctorDocument(
    String doctorId,
    String email,
    String fullName, {
    String? phoneNumber,
  }) async {
    try {
      // Check if document already exists
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      
      if (!doc.exists) {
        // If no phone number provided, try to get it from user document
        if (phoneNumber == null) {
          try {
            final userDoc = await _firestore.collection('users').doc(doctorId).get();
            if (userDoc.exists) {
              phoneNumber = userDoc.data()?['phoneNumber'];
            }
          } catch (e) {
            // Ignore error, phoneNumber will remain null
          }
        }

        // Create initial doctor document
        await _firestore.collection('doctors').doc(doctorId).set({
          'uid': doctorId,
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': 'doctor',
          'profileComplete': false,
          'onboardingCompleted': false,
          'onboardingStep': 0,
          // Don't set verificationStatus until onboarding is complete
          'isActive': true,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // If document exists but doesn't have phone number, try to sync from user document
        final existingData = doc.data();
        if (existingData?['phoneNumber'] == null) {
          try {
            final userDoc = await _firestore.collection('users').doc(doctorId).get();
            if (userDoc.exists) {
              final userPhoneNumber = userDoc.data()?['phoneNumber'];
              if (userPhoneNumber != null) {
                await _firestore.collection('doctors').doc(doctorId).update({
                  'phoneNumber': userPhoneNumber,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            }
          } catch (e) {
            // Ignore error if sync fails
          }
        }
      }
    } catch (e) {
      throw Exception('Error initializing doctor document: $e');
    }
  }

  /// Check if doctor profile is complete
  static Future<bool> checkDoctorProfileComplete(String doctorId) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (!doc.exists) {
        // Initialize document if it doesn't exist
        return false;
      }

      final data = doc.data();
      return data?['profileComplete'] ?? false;
    } catch (e) {
      throw Exception('Error checking profile completion: $e');
    }
  }

  /// Get doctor onboarding status
  static Future<Map<String, dynamic>> getDoctorOnboardingStatus(
    String doctorId,
  ) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (!doc.exists) {
        return {
          'profileComplete': false,
          'onboardingStep': 0,
          'verificationStatus': 'not_submitted',
        };
      }

      final data = doc.data()!;
      return {
        'profileComplete': data['profileComplete'] ?? false,
        'onboardingStep': data['onboardingStep'] ?? 0,
        'verificationStatus': data['verificationStatus'] ?? 'not_submitted',
        'verificationReason': data['verificationReason'],
      };
    } catch (e) {
      throw Exception('Error getting onboarding status: $e');
    }
  }

  /// Save onboarding step progress
  static Future<bool> saveDoctorOnboardingStep(
    String doctorId,
    int step,
    Map<String, dynamic> data,
  ) async {
    try {
      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('doctors').doc(doctorId).set(
        {
          ...data,
          'onboardingStep': step,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      throw Exception('Error saving onboarding step: $e');
    }
  }

  /// Sync phone numbers from user documents to doctor documents (utility method)
  static Future<void> syncPhoneNumbersFromUserDocuments() async {
    try {
      // Get all doctor documents
      final doctorsSnapshot = await _firestore.collection('doctors').get();
      
      for (final doctorDoc in doctorsSnapshot.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;
        
        // If doctor document doesn't have phone number, try to sync from user document
        if (doctorData['phoneNumber'] == null || doctorData['phoneNumber'] == '') {
          try {
            final userDoc = await _firestore.collection('users').doc(doctorId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              final userPhoneNumber = userData?['phoneNumber'];
              
              if (userPhoneNumber != null && userPhoneNumber != '') {
                await _firestore.collection('doctors').doc(doctorId).update({
                  'phoneNumber': userPhoneNumber,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                print('Synced phone number for doctor: $doctorId');
              }
            }
          } catch (e) {
            print('Error syncing phone number for doctor $doctorId: $e');
          }
        }
      }
    } catch (e) {
      print('Error syncing phone numbers: $e');
    }
  }

  /// Upload doctor document (certificate, license, etc.) to Cloudinary
  static Future<String> uploadDoctorDocument(
    String doctorId,
    File file,
    String documentType,
  ) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Convert File to XFile for Cloudinary
      final xFile = XFile(file.path);
      
      // Generate public ID
      final publicId = '${documentType}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Upload to Cloudinary
      final cloudinaryUrl = await ImageUploadService.uploadToCloudinary(
        imageFile: xFile,
        folder: 'curevia/doctors/$doctorId/documents',
        publicId: publicId,
      );

      // Update document URLs in Firestore (create if doesn't exist)
      await _firestore.collection('doctors').doc(doctorId).set(
        {
          'documentUrls': FieldValue.arrayUnion([cloudinaryUrl]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return cloudinaryUrl;
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }

  /// Upload profile photo to Cloudinary
  static Future<String> uploadProfilePhoto(
    String doctorId,
    File file,
  ) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Convert File to XFile for Cloudinary
      final xFile = XFile(file.path);
      
      // Generate public ID
      final publicId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      
      // Upload to Cloudinary
      final cloudinaryUrl = await ImageUploadService.uploadToCloudinary(
        imageFile: xFile,
        folder: 'curevia/doctors/$doctorId/profile',
        publicId: publicId,
      );

      // Update profile image URL in Firestore (create if doesn't exist)
      await _firestore.collection('doctors').doc(doctorId).set(
        {
          'profileImageUrl': cloudinaryUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return cloudinaryUrl;
    } catch (e) {
      throw Exception('Error uploading profile photo: $e');
    }
  }

  /// Submit profile for verification
  static Future<bool> submitForVerification(String doctorId) async {
    try {
      // Get doctor data first
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      final doctorData = doctorDoc.data();
      
      // Update doctor document (use set with merge to ensure it exists)
      await _firestore.collection('doctors').doc(doctorId).set(
        {
          'profileComplete': true,
          'onboardingCompleted': true,
          'verificationStatus': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Create verification request
      await _firestore.collection('doctor_verifications').add({
        'doctorId': doctorId,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'reason': null,
      });

      // Send notification to admins
      try {
        // Get admin FCM tokens
        final adminTokens = await _getAdminFCMTokens();
        
        if (adminTokens.isNotEmpty && doctorData != null) {
          // Send notification using RoleBasedNotificationService
          await RoleBasedNotificationService.instance.sendDoctorVerificationRequestToAdmin(
            adminFCMTokens: adminTokens,
            doctorId: doctorId,
            doctorName: doctorData['fullName'] ?? 'Unknown Doctor',
            email: doctorData['email'] ?? '',
            specialization: doctorData['specialty'] ?? 'General Medicine',
            phoneNumber: doctorData['phoneNumber'] ?? '',
          );
          
          print('✅ Sent verification notification to ${adminTokens.length} admin(s)');
        } else {
          print('⚠️ No admin FCM tokens found or doctor data missing');
        }
      } catch (notificationError) {
        // Don't fail the submission if notification fails
        print('⚠️ Failed to send admin notification: $notificationError');
      }

      return true;
    } catch (e) {
      throw Exception('Error submitting for verification: $e');
    }
  }

  /// Get admin FCM tokens from Firestore
  static Future<List<String>> _getAdminFCMTokens() async {
    try {
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      final tokens = <String>[];
      for (final doc in adminsSnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          tokens.add(fcmToken);
        }
      }
      
      return tokens;
    } catch (e) {
      print('Error getting admin FCM tokens: $e');
      return [];
    }
  }

  /// Get doctor verification status
  static Future<Map<String, dynamic>> getDoctorVerificationStatus(
    String doctorId,
  ) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (!doc.exists) {
        return {'status': 'not_submitted'};
      }

      final data = doc.data()!;
      return {
        'status': data['verificationStatus'] ?? 'not_submitted',
        'reason': data['verificationReason'],
        'profileComplete': data['profileComplete'] ?? false,
      };
    } catch (e) {
      throw Exception('Error getting verification status: $e');
    }
  }

  /// Update doctor profile
  static Future<bool> updateDoctorProfile(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Use set with merge to create document if it doesn't exist
      await _firestore.collection('doctors').doc(doctorId).set(
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      throw Exception('Error updating doctor profile: $e');
    }
  }

  /// Save basic information (Step 1)
  static Future<bool> saveBasicInfo(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    return await saveDoctorOnboardingStep(doctorId, 1, data);
  }

  /// Save professional details (Step 2)
  static Future<bool> saveProfessionalDetails(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Create a copy of data to modify
      final processedData = Map<String, dynamic>.from(data);
      
      // Handle certificate file upload
      if (data['certificateFile'] != null && data['certificateFile'] is File) {
        final certificateFile = data['certificateFile'] as File;
        final xFile = XFile(certificateFile.path);
        
        final certificateUrl = await ImageUploadService.uploadToCloudinary(
          imageFile: xFile,
          folder: 'curevia/doctors/$doctorId/certificates',
          publicId: 'certificate_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        processedData['certificateUrl'] = certificateUrl;
        processedData.remove('certificateFile'); // Remove the File object
      }
      
      // Handle PDF file upload
      if (data['pdfFile'] != null && data['pdfFile'] is File) {
        final pdfFile = data['pdfFile'] as File;
        final xFile = XFile(pdfFile.path);
        
        final pdfUrl = await ImageUploadService.uploadToCloudinary(
          imageFile: xFile,
          folder: 'curevia/doctors/$doctorId/documents',
          publicId: 'document_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        processedData['pdfUrl'] = pdfUrl;
        processedData.remove('pdfFile'); // Remove the File object
      }
      
      // Sync phone number and full name to user document if provided
      if (data['phoneNumber'] != null || data['fullName'] != null) {
        try {
          final updateData = <String, dynamic>{};
          if (data['phoneNumber'] != null && data['phoneNumber'].toString().trim().isNotEmpty) {
            updateData['phoneNumber'] = data['phoneNumber'].toString().trim();
          }
          if (data['fullName'] != null && data['fullName'].toString().trim().isNotEmpty) {
            updateData['fullName'] = data['fullName'].toString().trim();
          }
          
          if (updateData.isNotEmpty) {
            updateData['updatedAt'] = FieldValue.serverTimestamp();
            await _firestore.collection('users').doc(doctorId).update(updateData);
          }
        } catch (e) {
          // Log error but don't fail the entire operation
          print('Warning: Failed to sync data to user document: $e');
        }
      }
      
      return await saveDoctorOnboardingStep(doctorId, 2, processedData);
    } catch (e) {
      throw Exception('Error saving professional details: $e');
    }
  }

  /// Save practice information (Step 3)
  static Future<bool> savePracticeInfo(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    return await saveDoctorOnboardingStep(doctorId, 3, data);
  }

  /// Save availability schedule (Step 4)
  static Future<bool> saveAvailability(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    return await saveDoctorOnboardingStep(doctorId, 4, data);
  }

  /// Save additional information (Step 5)
  static Future<bool> saveAdditionalInfo(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    return await saveDoctorOnboardingStep(doctorId, 5, data);
  }

  /// Save bank details (Step 6) - Should be encrypted
  static Future<bool> saveBankDetails(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    // TODO: Implement encryption for sensitive bank data
    return await saveDoctorOnboardingStep(doctorId, 6, data);
  }

  /// Get doctor profile data
  static Future<DoctorModel?> getDoctorProfile(String doctorId) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (!doc.exists) return null;

      return DoctorModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Error getting doctor profile: $e');
    }
  }

  /// Delete uploaded document
  static Future<bool> deleteDocument(String doctorId, String documentUrl) async {
    try {
      // Delete from storage
      final ref = _storage.refFromURL(documentUrl);
      await ref.delete();

      // Remove from Firestore
      await _firestore.collection('doctors').doc(doctorId).update({
        'documentUrls': FieldValue.arrayRemove([documentUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  /// Resubmit profile after rejection
  static Future<bool> resubmitProfile(String doctorId) async {
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'verificationStatus': 'pending',
        'verificationReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create new verification request
      await _firestore.collection('doctor_verifications').add({
        'doctorId': doctorId,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'reason': null,
      });

      return true;
    } catch (e) {
      throw Exception('Error resubmitting profile: $e');
    }
  }
}
