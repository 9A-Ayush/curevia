import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prescription_model.dart';
import '../services/prescription_service.dart';

/// State for prescription management
class PrescriptionState {
  final List<PrescriptionModel> prescriptions;
  final bool isLoading;
  final String? error;
  final Map<String, int> stats;

  const PrescriptionState({
    this.prescriptions = const [],
    this.isLoading = false,
    this.error,
    this.stats = const {},
  });

  PrescriptionState copyWith({
    List<PrescriptionModel>? prescriptions,
    bool? isLoading,
    String? error,
    Map<String, int>? stats,
  }) {
    return PrescriptionState(
      prescriptions: prescriptions ?? this.prescriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

/// Provider for managing prescriptions
class PrescriptionNotifier extends StateNotifier<PrescriptionState> {
  PrescriptionNotifier() : super(const PrescriptionState());

  /// Load prescriptions for a doctor
  Future<void> loadDoctorPrescriptions(String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final prescriptions = await PrescriptionService.getDoctorPrescriptions(doctorId);
      final stats = await PrescriptionService.getPrescriptionStats(doctorId);
      
      state = state.copyWith(
        prescriptions: prescriptions,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load today's prescriptions
  Future<void> loadTodayPrescriptions(String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final prescriptions = await PrescriptionService.getTodayPrescriptions(doctorId);
      
      state = state.copyWith(
        prescriptions: prescriptions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load recent prescriptions
  Future<void> loadRecentPrescriptions(String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final prescriptions = await PrescriptionService.getRecentPrescriptions(doctorId);
      
      state = state.copyWith(
        prescriptions: prescriptions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search prescriptions
  Future<void> searchPrescriptions(String doctorId, String query) async {
    if (query.isEmpty) {
      await loadDoctorPrescriptions(doctorId);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final prescriptions = await PrescriptionService.searchPrescriptions(doctorId, query);
      
      state = state.copyWith(
        prescriptions: prescriptions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create a new prescription
  Future<bool> createPrescription(PrescriptionModel prescription) async {
    try {
      await PrescriptionService.createPrescription(prescription);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete a prescription
  Future<bool> deletePrescription(String prescriptionId) async {
    try {
      await PrescriptionService.deletePrescription(prescriptionId);
      
      // Remove from local state
      final updatedPrescriptions = state.prescriptions
          .where((p) => p.id != prescriptionId)
          .toList();
      
      state = state.copyWith(prescriptions: updatedPrescriptions);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const PrescriptionState();
  }
}

/// Provider instance
final prescriptionProvider = StateNotifierProvider<PrescriptionNotifier, PrescriptionState>(
  (ref) => PrescriptionNotifier(),
);

/// Provider for getting most prescribed medicines
final mostPrescribedMedicinesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, doctorId) => PrescriptionService.getMostPrescribedMedicines(doctorId),
);

/// Provider for getting prescription by ID
final prescriptionByIdProvider = FutureProvider.family<PrescriptionModel?, String>(
  (ref, prescriptionId) => PrescriptionService.getPrescriptionById(prescriptionId),
);