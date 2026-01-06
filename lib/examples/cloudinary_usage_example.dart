import 'dart:io';
import '../services/cloudinary/medical_document_service.dart';
import '../models/medical_document_model.dart';

/// Example usage of the Cloudinary Medical Document Service
class CloudinaryUsageExample {
  
  /// Example: Upload a PDF document
  static Future<void> uploadPdfExample() async {
    try {
      // Example file (you would get this from file picker)
      final file = File('/path/to/your/document.pdf');
      
      final documentId = await CloudinaryMedicalDocumentService.uploadDocument(
        patientId: 'patient_123',
        file: file,
        category: DocumentCategory.labReport,
        description: 'Blood test results from January 2024',
        doctorId: 'doctor_456',
        reportDate: DateTime.now(),
        tags: ['blood_test', 'routine_checkup'],
      );
      
      print('Document uploaded successfully with ID: $documentId');
    } catch (e) {
      print('Error uploading document: $e');
    }
  }
  
  /// Example: Get documents for a patient
  static Future<void> getDocumentsExample() async {
    try {
      final documents = await CloudinaryMedicalDocumentService.getDocuments(
        patientId: 'patient_123',
        category: DocumentCategory.labReport,
        limit: 10,
      );
      
      print('Found ${documents.length} documents');
      for (final doc in documents) {
        print('- ${doc.originalFileName} (${doc.category.displayName})');
      }
    } catch (e) {
      print('Error getting documents: $e');
    }
  }
  
  /// Example: Get optimized URL for display
  static void getOptimizedUrlExample() {
    const publicId = 'medical_documents/patient_123/document_12345';
    
    // Get thumbnail (200x200)
    final thumbnailUrl = CloudinaryMedicalDocumentService.getOptimizedUrl(
      publicId: publicId,
      width: 200,
      height: 200,
      quality: 'auto',
    );
    
    // Get preview (800x600)
    final previewUrl = CloudinaryMedicalDocumentService.getOptimizedUrl(
      publicId: publicId,
      width: 800,
      height: 600,
      quality: 'auto',
    );
    
    print('Thumbnail URL: $thumbnailUrl');
    print('Preview URL: $previewUrl');
  }
  
  /// Example: Search documents
  static Future<void> searchDocumentsExample() async {
    try {
      final results = await CloudinaryMedicalDocumentService.searchDocuments(
        patientId: 'patient_123',
        searchQuery: 'blood test',
        category: DocumentCategory.labReport,
      );
      
      print('Found ${results.length} matching documents');
      for (final doc in results) {
        print('- ${doc.originalFileName}: ${doc.description}');
      }
    } catch (e) {
      print('Error searching documents: $e');
    }
  }
  
  /// Example: Get document statistics
  static Future<void> getStatisticsExample() async {
    try {
      final stats = await CloudinaryMedicalDocumentService.getDocumentStatistics('patient_123');
      
      print('Document Statistics:');
      print('- Total documents: ${stats.totalDocuments}');
      print('- Total size: ${stats.totalSizeFormatted}');
      print('- Last upload: ${stats.lastUploadDate}');
      
      print('\nBy category:');
      stats.categoryCount.forEach((category, count) {
        print('- ${category.displayName}: $count');
      });
      
      print('\nBy type:');
      stats.typeCount.forEach((type, count) {
        print('- ${type.displayName}: $count');
      });
    } catch (e) {
      print('Error getting statistics: $e');
    }
  }
  
  /// Example: Delete a document
  static Future<void> deleteDocumentExample() async {
    try {
      // Soft delete (marks as deleted but keeps file)
      await CloudinaryMedicalDocumentService.deleteDocument('document_id_123');
      print('Document soft deleted');
      
      // Permanent delete (removes file from Cloudinary)
      await CloudinaryMedicalDocumentService.permanentlyDeleteDocument('document_id_123');
      print('Document permanently deleted');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }
}