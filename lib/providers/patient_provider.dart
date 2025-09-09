import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase/patient_service.dart';
import 'auth_provider.dart';

/// Patient state
class PatientState {
  final bool isLoading;
  final String? error;
  final PatientModel? patientModel;

  const PatientState({this.isLoading = false, this.error, this.patientModel});

  PatientState copyWith({
    bool? isLoading,
    String? error,
    PatientModel? patientModel,
  }) {
    return PatientState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      patientModel: patientModel ?? this.patientModel,
    );
  }
}

/// Patient provider notifier
class PatientNotifier extends StateNotifier<PatientState> {
  PatientNotifier() : super(const PatientState());

  /// Load patient data
  Future<void> loadPatientData(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final patientModel = await PatientService.getPatientById(userId);

      state = state.copyWith(isLoading: false, patientModel: patientModel);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update patient data
  Future<void> updatePatientData({
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? medicalHistory,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? city,
    String? patientState,
    String? pincode,
  }) async {
    try {
      if (state.patientModel == null) return;

      state = state.copyWith(isLoading: true, error: null);

      final updatedPatient = PatientModel(
        uid: state.patientModel!.uid,
        email: state.patientModel!.email,
        fullName: state.patientModel!.fullName,
        role: state.patientModel!.role,
        phoneNumber: state.patientModel!.phoneNumber,
        profileImageUrl: state.patientModel!.profileImageUrl,
        createdAt: state.patientModel!.createdAt,
        updatedAt: DateTime.now(),
        isActive: state.patientModel!.isActive,
        isVerified: state.patientModel!.isVerified,
        additionalInfo: state.patientModel!.additionalInfo,
        dateOfBirth: dateOfBirth ?? state.patientModel!.dateOfBirth,
        gender: gender ?? state.patientModel!.gender,
        bloodGroup: bloodGroup ?? state.patientModel!.bloodGroup,
        height: height ?? state.patientModel!.height,
        weight: weight ?? state.patientModel!.weight,
        allergies: allergies ?? state.patientModel!.allergies,
        medicalHistory: medicalHistory ?? state.patientModel!.medicalHistory,
        emergencyContactName:
            emergencyContactName ?? state.patientModel!.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? state.patientModel!.emergencyContactPhone,
        address: address ?? state.patientModel!.address,
        city: city ?? state.patientModel!.city,
        state: patientState ?? state.patientModel!.state,
        pincode: pincode ?? state.patientModel!.pincode,
      );

      await PatientService.updatePatient(updatedPatient);

      state = state.copyWith(isLoading: false, patientModel: updatedPatient);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Patient provider instance
final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((
  ref,
) {
  return PatientNotifier();
});

/// Current patient model provider
final currentPatientModelProvider = Provider<PatientModel?>((ref) {
  final userModel = ref.watch(currentUserModelProvider);
  final patientState = ref.watch(patientProvider);

  // If user is a patient and we have patient data, return it
  if (userModel?.role == 'patient' && patientState.patientModel != null) {
    return patientState.patientModel;
  }

  // If user is a patient but no patient data loaded, try to load it
  if (userModel?.role == 'patient' && !patientState.isLoading) {
    Future.microtask(() {
      ref.read(patientProvider.notifier).loadPatientData(userModel!.uid);
    });
  }

  return null;
});
