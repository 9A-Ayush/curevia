import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medical_record_model.dart';
import '../services/firebase/medical_record_service.dart';

/// Medical record state
class MedicalRecordState {
  final List<MedicalRecordModel> medicalRecords;
  final bool isLoading;
  final String? error;

  const MedicalRecordState({
    this.medicalRecords = const [],
    this.isLoading = false,
    this.error,
  });

  MedicalRecordState copyWith({
    List<MedicalRecordModel>? medicalRecords,
    bool? isLoading,
    String? error,
  }) {
    return MedicalRecordState(
      medicalRecords: medicalRecords ?? this.medicalRecords,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Medical record provider notifier
class MedicalRecordNotifier extends StateNotifier<MedicalRecordState> {
  MedicalRecordNotifier() : super(const MedicalRecordState());

  /// Load medical records for user
  Future<void> loadMedicalRecords(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final medicalRecords = await MedicalRecordService.getMedicalRecords(userId);

      state = state.copyWith(
        isLoading: false,
        medicalRecords: medicalRecords,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add medical record
  Future<String?> addMedicalRecord({
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

      // Reload medical records to get the updated list
      await loadMedicalRecords(userId);

      return recordId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update medical record
  Future<bool> updateMedicalRecord({
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

      // Reload medical records to get the updated list
      await loadMedicalRecords(userId);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete medical record
  Future<bool> deleteMedicalRecord(String userId, String recordId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await MedicalRecordService.deleteMedicalRecord(userId, recordId);

      // Update local state by removing the deleted record
      final updatedRecords = state.medicalRecords
          .where((record) => record.id != recordId)
          .toList();

      state = state.copyWith(
        isLoading: false,
        medicalRecords: updatedRecords,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get medical record by ID
  MedicalRecordModel? getMedicalRecordById(String recordId) {
    try {
      return state.medicalRecords.firstWhere((record) => record.id == recordId);
    } catch (e) {
      return null;
    }
  }

  /// Get medical records by type
  List<MedicalRecordModel> getMedicalRecordsByType(String type) {
    return state.medicalRecords
        .where((record) => record.type == type)
        .toList();
  }

  /// Get recent medical records (last 30 days)
  List<MedicalRecordModel> getRecentMedicalRecords() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return state.medicalRecords
        .where((record) => record.recordDate.isAfter(thirtyDaysAgo))
        .toList();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Add medical record to local state (for real-time updates)
  void addMedicalRecordToState(MedicalRecordModel record) {
    final updatedRecords = [record, ...state.medicalRecords];
    state = state.copyWith(medicalRecords: updatedRecords);
  }

  /// Update medical record in local state (for real-time updates)
  void updateMedicalRecordInState(MedicalRecordModel updatedRecord) {
    final updatedRecords = state.medicalRecords.map((record) {
      return record.id == updatedRecord.id ? updatedRecord : record;
    }).toList();
    state = state.copyWith(medicalRecords: updatedRecords);
  }
}

/// Medical record provider
final medicalRecordProvider = StateNotifierProvider<MedicalRecordNotifier, MedicalRecordState>((ref) {
  return MedicalRecordNotifier();
});

/// Medical record count provider
final medicalRecordCountProvider = Provider<int>((ref) {
  return ref.watch(medicalRecordProvider).medicalRecords.length;
});

/// Medical records by type provider
final medicalRecordsByTypeProvider = Provider.family<List<MedicalRecordModel>, String>((ref, type) {
  final medicalRecords = ref.watch(medicalRecordProvider).medicalRecords;
  return medicalRecords.where((record) => record.type == type).toList();
});

/// Recent medical records provider
final recentMedicalRecordsProvider = Provider<List<MedicalRecordModel>>((ref) {
  final medicalRecords = ref.watch(medicalRecordProvider).medicalRecords;
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return medicalRecords
      .where((record) => record.recordDate.isAfter(thirtyDaysAgo))
      .toList();
});
