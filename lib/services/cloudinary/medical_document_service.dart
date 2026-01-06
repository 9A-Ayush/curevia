import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import '../../models/medical_document_model.dart';
import '../cloudinary_service.dart';

/// Service for managing medical documents with Cloudinary storage
class CloudinaryMedicalDocumentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'medical_documents';
  static const String _cloudinaryFolder = 'medical_documents';

  /// Upload a medical document to Cloudinary
  static Future<String> uploadDocument({
    required String patientId,
    required File file,
    required DocumentCategory category,
    String? description,
    String? doctorId,
    String? appointmentId,
    DateTime? reportDate,
    List<String> tags = const [],
  }) async {
    try {
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      final documentType = _getDocumentTypeFromExtension(fileExtension);
      final fileSizeBytes = await file.length();

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${patientId}_${timestamp}_${path.basenameWithoutExtension(fileName)}';
      final folderPath = '$_cloudinaryFolder/$patientId';

      // Upload file to Cloudinary
      print('Uploading document to Cloudinary...');
      final uploadResult = await CloudinaryService.uploadFile(
        file: file,
        folder: folderPath,
        publicId: uniqueFileName,
        tags: {
          'patient_id': patientId,
          'category': category.toString(),
          'document_type': documentType.toString(),
          if (doctorId != null) 'doctor_id': doctorId,
          if (appointmentId != null) 'appointment_id': appointmentId,
          ...tags.asMap().map((index, tag) => MapEntry('tag_$index', tag)),
        },
      );

      if (!uploadResult.success) {
        throw Exception('Failed to upload to Cloudinary: ${uploadResult.error}');
      }

      print('Upload successful. Public ID: ${uploadResult.publicId}');

      // Create document record
      final document = MedicalDocument(
        id: '', // Will be set by Firestore
        patientId: patientId,
        fileName: uniqueFileName,
        originalFileName: fileName,
        fileUrl: uploadResult.secureUrl!,
        cloudinaryPublicId: uploadResult.publicId!,
        fileType: fileExtension,
        fileSizeBytes: uploadResult.bytes ?? fileSizeBytes,
        documentType: documentType,
        category: category,
        uploadedAt: DateTime.now(),
        reportDate: reportDate,
        uploadedBy: patientId, // Assuming patient uploads their own documents
        doctorId: doctorId,
        appointmentId: appointmentId,
        description: description,
        tags: tags,
        status: DocumentStatus.active,
        isSharedWithDoctor: doctorId != null,
        viewCount: 0,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(_collection)
          .add(document.toFirestore());

      print('Document uploaded successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Get documents stream for real-time updates
  static Stream<List<MedicalDocument>> getDocumentsStream({
    required String patientId,
    DocumentCategory? category,
    DocumentType? documentType,
    DocumentStatus status = DocumentStatus.active,
    int? limit,
  }) {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: status.toString())
          .orderBy('uploadedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString());
      }

      if (documentType != null) {
        query = query.where('documentType', isEqualTo: documentType.toString());
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => MedicalDocument.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error getting documents stream: $e');
      return Stream.value([]);
    }
  }

  /// Get documents for a specific date range
  static Future<List<MedicalDocument>> getDocuments({
    required String patientId,
    DocumentCategory? category,
    DocumentType? documentType,
    DocumentStatus status = DocumentStatus.active,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: status.toString())
          .orderBy('uploadedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString());
      }

      if (documentType != null) {
        query = query.where('documentType', isEqualTo: documentType.toString());
      }

      if (startDate != null) {
        query = query.where('uploadedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('uploadedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => MedicalDocument.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting documents: $e');
      return [];
    }
  }

  /// Get document by ID
  static Future<MedicalDocument?> getDocumentById(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      if (doc.exists) {
        return MedicalDocument.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting document by ID: $e');
      return null;
    }
  }

  /// Update document metadata
  static Future<void> updateDocument({
    required String documentId,
    String? description,
    String? notes,
    List<String>? tags,
    DocumentCategory? category,
    DateTime? reportDate,
    bool? isSharedWithDoctor,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (description != null) updateData['description'] = description;
      if (notes != null) updateData['notes'] = notes;
      if (tags != null) updateData['tags'] = tags;
      if (category != null) updateData['category'] = category.toString();
      if (reportDate != null) updateData['reportDate'] = Timestamp.fromDate(reportDate);
      if (isSharedWithDoctor != null) updateData['isSharedWithDoctor'] = isSharedWithDoctor;

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(documentId).update(updateData);
      print('Document updated: $documentId');
    } catch (e) {
      print('Error updating document: $e');
      throw Exception('Failed to update document: $e');
    }
  }

  /// Record document view
  static Future<void> recordDocumentView(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'lastViewedAt': FieldValue.serverTimestamp(),
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error recording document view: $e');
    }
  }

  /// Delete document (soft delete)
  static Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'status': DocumentStatus.deleted.toString(),
        'deletedAt': FieldValue.serverTimestamp(),
      });
      print('Document deleted: $documentId');
    } catch (e) {
      print('Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Permanently delete document and file from Cloudinary
  static Future<void> permanentlyDeleteDocument(String documentId) async {
    try {
      final document = await getDocumentById(documentId);
      if (document != null && document.cloudinaryPublicId != null) {
        // Delete file from Cloudinary
        try {
          final resourceType = _getCloudinaryResourceType(document.documentType);
          final deleted = await CloudinaryService.deleteFile(
            publicId: document.cloudinaryPublicId!,
            resourceType: resourceType,
          );
          
          if (!deleted) {
            print('Warning: Failed to delete file from Cloudinary');
          }
        } catch (storageError) {
          print('Error deleting file from Cloudinary: $storageError');
        }

        // Delete document record
        await _firestore.collection(_collection).doc(documentId).delete();
        print('Document permanently deleted: $documentId');
      }
    } catch (e) {
      print('Error permanently deleting document: $e');
      throw Exception('Failed to permanently delete document: $e');
    }
  }

  /// Get document statistics
  static Future<DocumentStatistics> getDocumentStatistics(String patientId) async {
    try {
      final documents = await getDocuments(patientId: patientId);
      
      final categoryCount = <DocumentCategory, int>{};
      final typeCount = <DocumentType, int>{};
      int totalSize = 0;
      DateTime? lastUpload;
      DateTime? oldestDocument;

      for (final doc in documents) {
        // Count by category
        categoryCount[doc.category] = (categoryCount[doc.category] ?? 0) + 1;
        
        // Count by type
        typeCount[doc.documentType] = (typeCount[doc.documentType] ?? 0) + 1;
        
        // Total size
        totalSize += doc.fileSizeBytes;
        
        // Last upload date
        if (lastUpload == null || doc.uploadedAt.isAfter(lastUpload)) {
          lastUpload = doc.uploadedAt;
        }
        
        // Oldest document
        if (oldestDocument == null || doc.uploadedAt.isBefore(oldestDocument)) {
          oldestDocument = doc.uploadedAt;
        }
      }

      return DocumentStatistics(
        totalDocuments: documents.length,
        totalSizeBytes: totalSize,
        categoryCount: categoryCount,
        typeCount: typeCount,
        lastUploadDate: lastUpload,
        oldestDocumentDate: oldestDocument,
      );
    } catch (e) {
      print('Error getting document statistics: $e');
      return const DocumentStatistics(
        totalDocuments: 0,
        totalSizeBytes: 0,
        categoryCount: {},
        typeCount: {},
      );
    }
  }

  /// Search documents
  static Future<List<MedicalDocument>> searchDocuments({
    required String patientId,
    required String searchQuery,
    DocumentCategory? category,
    DocumentType? documentType,
  }) async {
    try {
      final documents = await getDocuments(
        patientId: patientId,
        category: category,
        documentType: documentType,
      );

      final query = searchQuery.toLowerCase();
      return documents.where((doc) {
        return doc.originalFileName.toLowerCase().contains(query) ||
               (doc.description?.toLowerCase().contains(query) ?? false) ||
               (doc.notes?.toLowerCase().contains(query) ?? false) ||
               doc.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    } catch (e) {
      print('Error searching documents: $e');
      return [];
    }
  }

  /// Get documents by appointment
  static Future<List<MedicalDocument>> getDocumentsByAppointment(String appointmentId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('appointmentId', isEqualTo: appointmentId)
          .where('status', isEqualTo: DocumentStatus.active.toString())
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => MedicalDocument.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting documents by appointment: $e');
      return [];
    }
  }

  /// Get shared documents with doctor
  static Future<List<MedicalDocument>> getSharedDocuments({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId)
          .where('doctorId', isEqualTo: doctorId)
          .where('isSharedWithDoctor', isEqualTo: true)
          .where('status', isEqualTo: DocumentStatus.active.toString())
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => MedicalDocument.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting shared documents: $e');
      return [];
    }
  }

  /// Get download URL for a document (Cloudinary URL with optimizations)
  static Future<String> getDownloadUrl(String documentId, {
    int? width,
    int? height,
    String? quality,
  }) async {
    try {
      final document = await getDocumentById(documentId);
      if (document != null) {
        // Record the view
        await recordDocumentView(documentId);
        
        // Return optimized Cloudinary URL if public ID is available
        if (document.cloudinaryPublicId != null) {
          return CloudinaryService.getOptimizedUrl(
            publicId: document.cloudinaryPublicId!,
            width: width,
            height: height,
            quality: quality,
          );
        }
        
        // Fallback to original URL
        return document.fileUrl;
      }
      throw Exception('Document not found');
    } catch (e) {
      print('Error getting download URL: $e');
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// Get optimized URL for display (thumbnail, preview, etc.)
  static String getOptimizedUrl({
    required String publicId,
    int? width,
    int? height,
    String? quality,
    String? format,
  }) {
    return CloudinaryService.getOptimizedUrl(
      publicId: publicId,
      width: width,
      height: height,
      quality: quality,
      format: format,
    );
  }

  /// Helper method to determine document type from file extension
  static DocumentType _getDocumentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return DocumentType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return DocumentType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
        return DocumentType.video;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
        return DocumentType.audio;
      case 'txt':
      case 'doc':
      case 'docx':
        return DocumentType.text;
      default:
        return DocumentType.other;
    }
  }

  /// Helper method to get Cloudinary resource type from document type
  static String _getCloudinaryResourceType(DocumentType documentType) {
    switch (documentType) {
      case DocumentType.image:
        return 'image';
      case DocumentType.video:
      case DocumentType.audio:
        return 'video';
      case DocumentType.pdf:
      case DocumentType.text:
      case DocumentType.other:
        return 'raw';
    }
  }
}