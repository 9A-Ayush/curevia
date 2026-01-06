import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medical_document_model.dart';
import '../services/cloudinary/medical_document_service.dart';

/// Medical document management state
class MedicalDocumentState {
  final List<MedicalDocument> documents;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? error;
  final String? successMessage;
  final DocumentStatistics? statistics;
  final List<MedicalDocument> searchResults;
  final String searchQuery;
  final DocumentCategory? selectedCategory;
  final DocumentType? selectedType;

  const MedicalDocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
    this.successMessage,
    this.statistics,
    this.searchResults = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedType,
  });

  MedicalDocumentState copyWith({
    List<MedicalDocument>? documents,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    String? successMessage,
    DocumentStatistics? statistics,
    List<MedicalDocument>? searchResults,
    String? searchQuery,
    DocumentCategory? selectedCategory,
    DocumentType? selectedType,
  }) {
    return MedicalDocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
      successMessage: successMessage,
      statistics: statistics ?? this.statistics,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

/// Medical document provider
class MedicalDocumentNotifier extends StateNotifier<MedicalDocumentState> {
  MedicalDocumentNotifier() : super(const MedicalDocumentState());

  /// Upload a new document
  Future<String?> uploadDocument({
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
      state = state.copyWith(
        isUploading: true,
        uploadProgress: 0.0,
        error: null,
      );

      final documentId = await CloudinaryMedicalDocumentService.uploadDocument(
        patientId: patientId,
        file: file,
        category: category,
        description: description,
        doctorId: doctorId,
        appointmentId: appointmentId,
        reportDate: reportDate,
        tags: tags,
      );

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        successMessage: 'Document uploaded successfully!',
      );

      // Refresh documents list
      await loadDocuments(patientId: patientId);
      await loadStatistics(patientId: patientId);

      return documentId;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Load documents for a patient
  Future<void> loadDocuments({
    required String patientId,
    DocumentCategory? category,
    DocumentType? documentType,
    DocumentStatus status = DocumentStatus.active,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final documents = await CloudinaryMedicalDocumentService.getDocuments(
        patientId: patientId,
        category: category,
        documentType: documentType,
        status: status,
      );

      state = state.copyWith(
        isLoading: false,
        documents: documents,
        selectedCategory: category,
        selectedType: documentType,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load document statistics
  Future<void> loadStatistics({required String patientId}) async {
    try {
      final statistics = await CloudinaryMedicalDocumentService.getDocumentStatistics(patientId);
      state = state.copyWith(statistics: statistics);
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  /// Search documents
  Future<void> searchDocuments({
    required String patientId,
    required String query,
    DocumentCategory? category,
    DocumentType? documentType,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        searchQuery: query,
        error: null,
      );

      final results = await CloudinaryMedicalDocumentService.searchDocuments(
        patientId: patientId,
        searchQuery: query,
        category: category,
        documentType: documentType,
      );

      state = state.copyWith(
        isLoading: false,
        searchResults: results,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update document metadata
  Future<void> updateDocument({
    required String documentId,
    required String patientId,
    String? description,
    String? notes,
    List<String>? tags,
    DocumentCategory? category,
    DateTime? reportDate,
    bool? isSharedWithDoctor,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await CloudinaryMedicalDocumentService.updateDocument(
        documentId: documentId,
        description: description,
        notes: notes,
        tags: tags,
        category: category,
        reportDate: reportDate,
        isSharedWithDoctor: isSharedWithDoctor,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Document updated successfully!',
      );

      // Refresh documents
      await loadDocuments(patientId: patientId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Delete document
  Future<void> deleteDocument({
    required String documentId,
    required String patientId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await CloudinaryMedicalDocumentService.deleteDocument(documentId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Document deleted successfully!',
      );

      // Refresh documents and statistics
      await loadDocuments(patientId: patientId);
      await loadStatistics(patientId: patientId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Record document view
  Future<void> recordView(String documentId) async {
    try {
      await CloudinaryMedicalDocumentService.recordDocumentView(documentId);
    } catch (e) {
      print('Error recording view: $e');
    }
  }

  /// Filter documents by category
  void filterByCategory(DocumentCategory? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Filter documents by type
  void filterByType(DocumentType? documentType) {
    state = state.copyWith(selectedType: documentType);
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(
      searchResults: [],
      searchQuery: '',
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear state
  void clearState() {
    state = const MedicalDocumentState();
  }
}

/// Provider instances
final medicalDocumentProvider = StateNotifierProvider.autoDispose<MedicalDocumentNotifier, MedicalDocumentState>((ref) {
  return MedicalDocumentNotifier();
});

/// Real-time documents stream provider
final documentsStreamProvider = StreamProvider.family.autoDispose<List<MedicalDocument>, Map<String, dynamic>>((ref, params) {
  return CloudinaryMedicalDocumentService.getDocumentsStream(
    patientId: params['patientId'] as String,
    category: params['category'] as DocumentCategory?,
    documentType: params['documentType'] as DocumentType?,
    status: params['status'] as DocumentStatus? ?? DocumentStatus.active,
    limit: params['limit'] as int?,
  );
});

/// Document statistics provider
final documentStatisticsProvider = FutureProvider.family.autoDispose<DocumentStatistics, String>((ref, patientId) async {
  return await CloudinaryMedicalDocumentService.getDocumentStatistics(patientId);
});

/// Individual document provider
final documentProvider = FutureProvider.family<MedicalDocument?, String>((ref, documentId) async {
  return await CloudinaryMedicalDocumentService.getDocumentById(documentId);
});

/// Documents by appointment provider
final documentsByAppointmentProvider = FutureProvider.family<List<MedicalDocument>, String>((ref, appointmentId) async {
  return await CloudinaryMedicalDocumentService.getDocumentsByAppointment(appointmentId);
});

/// Shared documents provider
final sharedDocumentsProvider = FutureProvider.family<List<MedicalDocument>, Map<String, String>>((ref, params) async {
  return await CloudinaryMedicalDocumentService.getSharedDocuments(
    patientId: params['patientId']!,
    doctorId: params['doctorId']!,
  );
});