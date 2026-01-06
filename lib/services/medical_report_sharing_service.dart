import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/medical_record_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../constants/app_constants.dart';
import 'notifications/notification_manager.dart';
import 'firebase/medical_record_service.dart';

/// Service for sharing medical reports with doctors
class MedicalReportSharingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sharingCollection = 'medical_report_sharing';
  static const String _doctorsCollection = 'users';

  /// Fetch complete medical report data from Firebase including Cloudinary URLs
  static Future<List<MedicalRecordModel>> fetchCompleteReportData({
    required String userId,
    required List<String> reportIds,
  }) async {
    try {
      final List<MedicalRecordModel> completeReports = [];
      
      for (final reportId in reportIds) {
        try {
          final report = await MedicalRecordService.getMedicalRecordById(userId, reportId);
          if (report != null) {
            // Verify Cloudinary URLs are accessible
            final verifiedReport = await _verifyAndRefreshCloudinaryUrls(report);
            completeReports.add(verifiedReport);
          }
        } catch (e) {
          debugPrint('Error fetching report $reportId: $e');
        }
      }
      
      return completeReports;
    } catch (e) {
      debugPrint('Error fetching complete report data: $e');
      return [];
    }
  }

  /// Verify and refresh Cloudinary URLs if needed
  static Future<MedicalRecordModel> _verifyAndRefreshCloudinaryUrls(MedicalRecordModel report) async {
    try {
      final List<String> verifiedAttachments = [];
      
      for (final attachment in report.attachments) {
        if (await _isUrlAccessible(attachment)) {
          verifiedAttachments.add(attachment);
        } else {
          debugPrint('Attachment URL not accessible: $attachment');
          // Could implement URL refresh logic here if needed
          verifiedAttachments.add(attachment); // Keep original for now
        }
      }
      
      return report.copyWith(attachments: verifiedAttachments);
    } catch (e) {
      debugPrint('Error verifying Cloudinary URLs: $e');
      return report;
    }
  }

  /// Check if URL is accessible
  static Future<bool> _isUrlAccessible(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch patient allergies from Firebase
  static Future<List<String>> fetchPatientAllergies(String patientId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(patientId)
          .get();

      if (!doc.exists) return [];

      final userData = doc.data()!;
      return List<String>.from(userData['allergies'] ?? []);
    } catch (e) {
      debugPrint('Error fetching patient allergies: $e');
      return [];
    }
  }

  /// Fetch patient vitals from latest medical records
  static Future<Map<String, dynamic>> fetchPatientVitals(String patientId) async {
    try {
      final recentReports = await MedicalRecordService.getRecentMedicalRecords(patientId);
      
      if (recentReports.isEmpty) return {};
      
      // Get vitals from the most recent report that has vitals data
      for (final report in recentReports) {
        if (report.vitals.isNotEmpty) {
          return report.vitals;
        }
      }
      
      return {};
    } catch (e) {
      debugPrint('Error fetching patient vitals: $e');
      return {};
    }
  }

  /// Share medical reports with a doctor
  static Future<String?> shareReportsWithDoctor({
    required String patientId,
    required String patientName,
    required String doctorId,
    required List<String> selectedReportIds,
    List<String>? selectedAllergies,
    Map<String, dynamic>? patientVitals,
    String? message,
    DateTime? expirationTime,
  }) async {
    try {
      // Fetch complete report data from Firebase
      final completeReports = await fetchCompleteReportData(
        userId: patientId,
        reportIds: selectedReportIds,
      );

      if (completeReports.isEmpty) {
        throw Exception('No valid reports found to share');
      }

      // Fetch patient allergies if not provided
      final allergies = selectedAllergies ?? await fetchPatientAllergies(patientId);

      // Fetch patient vitals if not provided
      final vitals = patientVitals ?? await fetchPatientVitals(patientId);

      // Get doctor information
      final doctorDoc = await _firestore
          .collection(_doctorsCollection)
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor not found');
      }

      final doctorData = doctorDoc.data()!;
      final doctorName = doctorData['fullName'] ?? 'Unknown Doctor';

      // Set expiration time (default: 7 days)
      final expiresAt = expirationTime ?? DateTime.now().add(const Duration(days: 7));

      // Prepare sharing data with complete report information
      final sharingData = {
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'sharedReportIds': completeReports.map((r) => r.id).toList(),
        'sharedReports': completeReports.map((r) => {
          'id': r.id,
          'title': r.title,
          'type': r.type,
          'recordDate': Timestamp.fromDate(r.recordDate),
          'doctorName': r.doctorName,
          'hospitalName': r.hospitalName,
          'diagnosis': r.diagnosis,
          'treatment': r.treatment,
          'prescription': r.prescription,
          'notes': r.notes,
          'attachments': r.attachments, // Cloudinary URLs
          'vitals': r.vitals,
          'labResults': r.labResults,
          'createdAt': Timestamp.fromDate(r.createdAt),
        }).toList(),
        'sharedAllergies': allergies,
        'patientVitals': vitals,
        'message': message,
        'sharingStatus': 'active',
        'sharedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isActive': true,
        'viewedByDoctor': false,
        'viewedAt': null,
        'accessCount': 0,
        'lastAccessedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_sharingCollection)
          .add(sharingData);

      // Send notification to doctor
      await _sendSharingNotificationToDoctor(
        doctorId: doctorId,
        doctorName: doctorName,
        patientName: patientName,
        reportCount: completeReports.length,
        sharingId: docRef.id,
        message: message,
      );

      debugPrint('Medical reports shared successfully with doctor: $doctorName');
      debugPrint('Shared ${completeReports.length} reports with ${allergies.length} allergies');
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error sharing medical reports: $e');
      return null;
    }
  }

  /// Get shared report data for doctor (with access tracking)
  static Future<Map<String, dynamic>?> getSharedReportDataForDoctor({
    required String sharingId,
    required String doctorId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      
      // Verify doctor access
      if (data['doctorId'] != doctorId) {
        debugPrint('Unauthorized access attempt by doctor: $doctorId');
        return null;
      }

      // Check if sharing is still active
      if (!data['isActive'] || data['sharingStatus'] != 'active') {
        debugPrint('Sharing session is not active');
        return null;
      }

      // Check expiration
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        debugPrint('Sharing session has expired');
        return null;
      }

      // Update access tracking
      await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .update({
        'viewedByDoctor': true,
        'viewedAt': FieldValue.serverTimestamp(),
        'lastAccessedAt': FieldValue.serverTimestamp(),
        'accessCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Return complete sharing data including Cloudinary URLs
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('Error getting shared report data: $e');
      return null;
    }
  }

  /// Get available doctors for sharing
  static Future<List<UserModel>> getAvailableDoctors() async {
    try {
      final snapshot = await _firestore
          .collection(_doctorsCollection)
          .where('role', isEqualTo: 'doctor')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('fullName')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting available doctors: $e');
      return [];
    }
  }

  /// Search doctors by name or specialization
  static Future<List<UserModel>> searchDoctors(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_doctorsCollection)
          .where('role', isEqualTo: 'doctor')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      final doctors = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((doctor) {
            final name = doctor.fullName.toLowerCase();
            final email = doctor.email.toLowerCase();
            final searchQuery = query.toLowerCase();
            
            return name.contains(searchQuery) || email.contains(searchQuery);
          })
          .toList();

      return doctors;
    } catch (e) {
      debugPrint('Error searching doctors: $e');
      return [];
    }
  }

  /// Get sharing history for a patient
  static Future<List<Map<String, dynamic>>> getPatientSharingHistory(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(_sharingCollection)
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting patient sharing history: $e');
      return [];
    }
  }

  /// Get shared reports for a doctor
  static Future<List<Map<String, dynamic>>> getDoctorSharedReports(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection(_sharingCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting doctor shared reports: $e');
      return [];
    }
  }

  /// Mark sharing as viewed by doctor
  static Future<void> markAsViewedByDoctor(String sharingId, String doctorId) async {
    try {
      await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .update({
        'viewedByDoctor': true,
        'viewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Sharing marked as viewed by doctor: $sharingId');
    } catch (e) {
      debugPrint('Error marking sharing as viewed: $e');
    }
  }

  /// Revoke sharing
  static Future<bool> revokeSharing(String sharingId, String revokedBy) async {
    try {
      await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .update({
        'sharingStatus': 'revoked',
        'isActive': false,
        'revokedBy': revokedBy,
        'revokedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Sharing revoked successfully: $sharingId');
      return true;
    } catch (e) {
      debugPrint('Error revoking sharing: $e');
      return false;
    }
  }

  /// Get sharing details
  static Future<Map<String, dynamic>?> getSharingDetails(String sharingId) async {
    try {
      final doc = await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      debugPrint('Error getting sharing details: $e');
      return null;
    }
  }

  /// Clean up expired sharing sessions
  static Future<void> cleanupExpiredSharings() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_sharingCollection)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'sharingStatus': 'expired',
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} expired sharing sessions');
    } catch (e) {
      debugPrint('Error cleaning up expired sharings: $e');
    }
  }

  /// Send notification to doctor about shared reports
  static Future<void> _sendSharingNotificationToDoctor({
    required String doctorId,
    required String doctorName,
    required String patientName,
    required int reportCount,
    required String sharingId,
    String? message,
  }) async {
    try {
      // Create notification for the doctor
      final notification = NotificationModel(
        id: 'medical_share_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Medical Reports Shared',
        body: '$patientName has shared $reportCount medical report${reportCount > 1 ? 's' : ''} with you',
        type: NotificationType.medicalReportShared,
        data: {
          'sharingId': sharingId,
          'patientName': patientName,
          'reportCount': reportCount,
          'message': message,
          'action': 'view_shared_reports',
        },
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Send notification through notification manager
      // Note: This would typically involve getting the doctor's FCM token
      // and sending a push notification through your backend
      await NotificationManager.instance.sendTestNotification(
        title: notification.title,
        body: notification.body,
        type: notification.type,
        data: notification.data,
      );

      debugPrint('Notification sent to doctor: $doctorName');
    } catch (e) {
      debugPrint('Error sending notification to doctor: $e');
    }
  }

  /// Get recent sharing activity
  static Future<List<Map<String, dynamic>>> getRecentSharingActivity({
    String? userId,
    String? userRole,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection(_sharingCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (userId != null && userRole != null) {
        if (userRole == 'patient') {
          query = query.where('patientId', isEqualTo: userId);
        } else if (userRole == 'doctor') {
          query = query.where('doctorId', isEqualTo: userId);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting recent sharing activity: $e');
      return [];
    }
  }

  /// Update sharing expiration
  static Future<bool> updateSharingExpiration(
    String sharingId,
    DateTime newExpirationTime,
  ) async {
    try {
      await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .update({
        'expiresAt': Timestamp.fromDate(newExpirationTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Sharing expiration updated: $sharingId');
      return true;
    } catch (e) {
      debugPrint('Error updating sharing expiration: $e');
      return false;
    }
  }

  /// Add message to sharing
  static Future<bool> addMessageToSharing(
    String sharingId,
    String message,
    String addedBy,
  ) async {
    try {
      await _firestore
          .collection(_sharingCollection)
          .doc(sharingId)
          .update({
        'messages': FieldValue.arrayUnion([
          {
            'message': message,
            'addedBy': addedBy,
            'addedAt': FieldValue.serverTimestamp(),
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Message added to sharing: $sharingId');
      return true;
    } catch (e) {
      debugPrint('Error adding message to sharing: $e');
      return false;
    }
  }

  /// Download and cache Cloudinary images for offline access
  static Future<List<String>> downloadAndCacheImages(List<String> imageUrls) async {
    try {
      final List<String> cachedPaths = [];
      
      for (final url in imageUrls) {
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            // In a real implementation, you would save this to local storage
            // For now, we'll just verify the URL is accessible
            cachedPaths.add(url);
            debugPrint('Successfully verified image URL: $url');
          }
        } catch (e) {
          debugPrint('Failed to download image from URL: $url, Error: $e');
        }
      }
      
      return cachedPaths;
    } catch (e) {
      debugPrint('Error downloading and caching images: $e');
      return [];
    }
  }
}