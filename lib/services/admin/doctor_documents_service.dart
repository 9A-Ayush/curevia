import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing doctor documents in admin panel
class DoctorDocumentsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all documents for a specific doctor
  static Future<List<String>> getDoctorDocuments(String doctorId) async {
    try {
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (doctorDoc.exists) {
        final data = doctorDoc.data() as Map<String, dynamic>;
        final documentUrls = data['documentUrls'] as List<dynamic>? ?? [];
        return documentUrls.cast<String>();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch doctor documents: $e');
    }
  }

  /// Get doctor profile with documents
  static Future<Map<String, dynamic>?> getDoctorProfile(String doctorId) async {
    try {
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (doctorDoc.exists) {
        return doctorDoc.data() as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to fetch doctor profile: $e');
    }
  }

  /// Get document metadata from Cloudinary URL
  static Map<String, String> getDocumentMetadata(String url, int index) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isNotEmpty) {
        final filename = pathSegments.last;
        final nameWithoutExtension = filename.split('.').first;
        final extension = filename.split('.').last.split('?').first;
        
        String documentName;
        String documentType;
        
        // Determine document type from filename
        if (nameWithoutExtension.contains('license')) {
          documentName = 'Medical License Certificate';
          documentType = 'license';
        } else if (nameWithoutExtension.contains('degree')) {
          documentName = 'Medical Degree Certificate';
          documentType = 'degree';
        } else if (nameWithoutExtension.contains('certificate')) {
          documentName = 'Professional Certificate';
          documentType = 'certificate';
        } else if (nameWithoutExtension.contains('experience')) {
          documentName = 'Experience Letter';
          documentType = 'experience';
        } else if (nameWithoutExtension.contains('profile')) {
          documentName = 'Profile Photo';
          documentType = 'profile';
        } else {
          documentName = 'Document ${index + 1}';
          documentType = 'document';
        }
        
        return {
          'name': documentName,
          'type': documentType,
          'extension': extension,
          'url': url,
        };
      }
    } catch (e) {
      // Fallback if URL parsing fails
    }
    
    return {
      'name': 'Document ${index + 1}',
      'type': 'document',
      'extension': 'unknown',
      'url': url,
    };
  }

  /// Get all pending verifications with document counts
  static Future<List<Map<String, dynamic>>> getPendingVerificationsWithDocuments() async {
    try {
      final verifications = await _firestore
          .collection('doctor_verifications')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      final List<Map<String, dynamic>> result = [];

      for (final doc in verifications.docs) {
        final verificationData = doc.data();
        final doctorId = verificationData['doctorId'] as String;
        
        // Get doctor documents
        final documents = await getDoctorDocuments(doctorId);
        
        result.add({
          'verificationId': doc.id,
          'verificationData': verificationData,
          'documentCount': documents.length,
          'documents': documents,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch pending verifications: $e');
    }
  }

  /// Check if doctor has uploaded required documents
  static Future<bool> hasRequiredDocuments(String doctorId) async {
    try {
      final documents = await getDoctorDocuments(doctorId);
      
      // Check if doctor has at least one document
      // You can customize this logic based on your requirements
      return documents.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get document statistics for admin dashboard
  static Future<Map<String, int>> getDocumentStatistics() async {
    try {
      final doctors = await _firestore
          .collection('doctors')
          .get();

      int totalDoctors = doctors.docs.length;
      int doctorsWithDocuments = 0;
      int totalDocuments = 0;

      for (final doc in doctors.docs) {
        final data = doc.data();
        final documentUrls = data['documentUrls'] as List<dynamic>? ?? [];
        
        if (documentUrls.isNotEmpty) {
          doctorsWithDocuments++;
          totalDocuments += documentUrls.length;
        }
      }

      return {
        'totalDoctors': totalDoctors,
        'doctorsWithDocuments': doctorsWithDocuments,
        'doctorsWithoutDocuments': totalDoctors - doctorsWithDocuments,
        'totalDocuments': totalDocuments,
        'averageDocumentsPerDoctor': totalDoctors > 0 ? (totalDocuments / totalDoctors).round() : 0,
      };
    } catch (e) {
      throw Exception('Failed to get document statistics: $e');
    }
  }
}