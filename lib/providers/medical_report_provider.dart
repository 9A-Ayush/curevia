import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medical_record_model.dart';
import '../services/firebase/medical_record_service.dart';
import '../services/ai/google_vision_service.dart';
import '../services/image_upload_service.dart';

/// Medical report state
class MedicalReportState {
  final List<MedicalRecordModel> reports;
  final bool isLoading;
  final bool isUploading;
  final bool isProcessing;
  final String? error;
  final MedicalReportData? extractedData;
  final double uploadProgress;

  const MedicalReportState({
    this.reports = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.isProcessing = false,
    this.error,
    this.extractedData,
    this.uploadProgress = 0.0,
  });

  MedicalReportState copyWith({
    List<MedicalRecordModel>? reports,
    bool? isLoading,
    bool? isUploading,
    bool? isProcessing,
    String? error,
    MedicalReportData? extractedData,
    double? uploadProgress,
  }) {
    return MedicalReportState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      extractedData: extractedData ?? this.extractedData,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

/// Medical report provider notifier
class MedicalReportNotifier extends StateNotifier<MedicalReportState> {
  MedicalReportNotifier() : super(const MedicalReportState());

  /// Load medical reports for user
  Future<void> loadMedicalReports(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final reports = await MedicalRecordService.getMedicalRecords(userId);

      state = state.copyWith(isLoading: false, reports: reports);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Upload and process medical report image
  Future<String?> uploadMedicalReport({
    required String userId,
    required File imageFile,
    String? title,
    String? type,
  }) async {
    try {
      state = state.copyWith(
        isUploading: true,
        isProcessing: false,
        error: null,
        uploadProgress: 0.0,
      );

      // Step 1: Upload image to cloud storage
      state = state.copyWith(uploadProgress: 0.2);
      final xFile = XFile(imageFile.path);
      final imageUrl = await ImageUploadService.uploadMedicalDocument(
        imageFile: xFile,
        userId: userId,
      );

      // Step 2: Process image with Google Vision API
      state = state.copyWith(
        isUploading: false,
        isProcessing: true,
        uploadProgress: 0.5,
      );

      final extractedData = await GoogleVisionService.extractMedicalReportData(
        imageFile,
      );

      state = state.copyWith(extractedData: extractedData, uploadProgress: 0.8);

      // Step 3: Save to Firestore
      final recordId = await MedicalRecordService.addMedicalRecord(
        userId: userId,
        title: title ?? extractedData.diagnosis ?? 'Medical Report',
        type: type ?? 'lab_test',
        recordDate: extractedData.reportDate,
        doctorName: extractedData.doctorName,
        hospitalName: extractedData.hospitalName,
        diagnosis: extractedData.diagnosis,
        treatment: extractedData.treatment,
        prescription: extractedData.prescription,
        notes: extractedData.notes,
        attachments: [imageUrl],
        vitals: extractedData.vitals.map((k, v) => MapEntry(k, v)),
        labResults: extractedData.labResults.map((k, v) => MapEntry(k, v)),
      );

      state = state.copyWith(isProcessing: false, uploadProgress: 1.0);

      // Reload reports to get the updated list
      await loadMedicalReports(userId);

      return recordId;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        isProcessing: false,
        error: e.toString(),
        uploadProgress: 0.0,
      );
      return null;
    }
  }

  /// Add manual medical report
  Future<String?> addManualMedicalReport({
    required String userId,
    required String title,
    required String type,
    required DateTime recordDate,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? vitals,
    Map<String, dynamic>? labResults,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final recordId = await MedicalRecordService.addMedicalRecord(
        userId: userId,
        title: title,
        type: type,
        recordDate: recordDate,
        doctorName: doctorName,
        hospitalName: hospitalName,
        diagnosis: diagnosis,
        treatment: treatment,
        prescription: prescription,
        notes: notes,
        attachments: attachments,
        vitals: vitals,
        labResults: labResults,
      );

      // Reload reports to get the updated list
      await loadMedicalReports(userId);

      return recordId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update medical report
  Future<bool> updateMedicalReport({
    required String userId,
    required String recordId,
    String? title,
    String? type,
    DateTime? recordDate,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? vitals,
    Map<String, dynamic>? labResults,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await MedicalRecordService.updateMedicalRecord(
        userId: userId,
        recordId: recordId,
        title: title,
        type: type,
        recordDate: recordDate,
        doctorName: doctorName,
        hospitalName: hospitalName,
        diagnosis: diagnosis,
        treatment: treatment,
        prescription: prescription,
        notes: notes,
        attachments: attachments,
        vitals: vitals,
        labResults: labResults,
      );

      // Reload reports to get the updated list
      await loadMedicalReports(userId);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete medical report
  Future<bool> deleteMedicalReport(String userId, String recordId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await MedicalRecordService.deleteMedicalRecord(userId, recordId);

      // Update local state by removing the deleted report
      final updatedReports = state.reports
          .where((report) => report.id != recordId)
          .toList();

      state = state.copyWith(isLoading: false, reports: updatedReports);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get medical report by ID
  MedicalRecordModel? getMedicalReportById(String recordId) {
    try {
      return state.reports.firstWhere((report) => report.id == recordId);
    } catch (e) {
      return null;
    }
  }

  /// Clear extracted data
  void clearExtractedData() {
    state = state.copyWith(extractedData: null);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset upload progress
  void resetProgress() {
    state = state.copyWith(
      isUploading: false,
      isProcessing: false,
      uploadProgress: 0.0,
    );
  }

  /// Get reports by type
  List<MedicalRecordModel> getReportsByType(String type) {
    return state.reports.where((report) => report.type == type).toList();
  }

  /// Get recent reports (last 30 days)
  List<MedicalRecordModel> getRecentReports() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return state.reports
        .where((report) => report.recordDate.isAfter(thirtyDaysAgo))
        .toList();
  }

  /// Search reports
  List<MedicalRecordModel> searchReports(String query) {
    if (query.isEmpty) return state.reports;

    final lowercaseQuery = query.toLowerCase();
    return state.reports.where((report) {
      return report.title.toLowerCase().contains(lowercaseQuery) ||
          (report.diagnosis?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (report.doctorName?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          (report.hospitalName?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }
}

/// Medical report provider
final medicalReportProvider =
    StateNotifierProvider<MedicalReportNotifier, MedicalReportState>((ref) {
      return MedicalReportNotifier();
    });

/// Medical reports count provider
final medicalReportsCountProvider = Provider<int>((ref) {
  return ref.watch(medicalReportProvider).reports.length;
});

/// Medical reports by type provider
final medicalReportsByTypeProvider =
    Provider.family<List<MedicalRecordModel>, String>((ref, type) {
      final reports = ref.watch(medicalReportProvider).reports;
      return reports.where((report) => report.type == type).toList();
    });

/// Recent medical reports provider
final recentMedicalReportsProvider = Provider<List<MedicalRecordModel>>((ref) {
  final reports = ref.watch(medicalReportProvider).reports;
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return reports
      .where((report) => report.recordDate.isAfter(thirtyDaysAgo))
      .toList();
});
