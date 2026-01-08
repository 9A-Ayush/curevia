import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom_checker_models.dart';
import '../services/ai/gemini_service.dart';

/// Symptom checker state
class SymptomCheckerState {
  final bool isLoading;
  final String? error;
  final SymptomAnalysisResult? analysisResult;
  final int currentStep;
  final SymptomAnalysisRequest? currentRequest;
  final bool hasAcceptedDisclaimer;

  const SymptomCheckerState({
    this.isLoading = false,
    this.error,
    this.analysisResult,
    this.currentStep = 0,
    this.currentRequest,
    this.hasAcceptedDisclaimer = false,
  });

  SymptomCheckerState copyWith({
    bool? isLoading,
    String? error,
    SymptomAnalysisResult? analysisResult,
    int? currentStep,
    SymptomAnalysisRequest? currentRequest,
    bool? hasAcceptedDisclaimer,
  }) {
    return SymptomCheckerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      analysisResult: analysisResult ?? this.analysisResult,
      currentStep: currentStep ?? this.currentStep,
      currentRequest: currentRequest ?? this.currentRequest,
      hasAcceptedDisclaimer: hasAcceptedDisclaimer ?? this.hasAcceptedDisclaimer,
    );
  }
}

/// Symptom checker notifier
class SymptomCheckerNotifier extends StateNotifier<SymptomCheckerState> {
  SymptomCheckerNotifier() : super(const SymptomCheckerState());

  /// Accept disclaimer and proceed
  void acceptDisclaimer() {
    state = state.copyWith(hasAcceptedDisclaimer: true);
  }

  /// Reset to initial state
  void reset() {
    state = const SymptomCheckerState();
  }

  /// Set current step
  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  /// Go to next step
  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  /// Go to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Analyze symptoms
  Future<void> analyzeSymptoms(SymptomAnalysisRequest request) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentRequest: request,
    );

    try {
      final result = await GeminiService.analyzeSymptoms(request);
      
      state = state.copyWith(
        isLoading: false,
        analysisResult: result,
        currentStep: 4, // Move to results step
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Save analysis result (for future reference)
  Future<void> saveAnalysisResult() async {
    // TODO: Implement saving to local storage or Firebase
    // This could be used for medical history tracking
  }
}

/// Symptom checker provider
final symptomCheckerProvider = StateNotifierProvider<SymptomCheckerNotifier, SymptomCheckerState>((ref) {
  return SymptomCheckerNotifier();
});

/// Current step provider
final currentStepProvider = Provider<int>((ref) {
  return ref.watch(symptomCheckerProvider).currentStep;
});

/// Is loading provider
final isAnalyzingProvider = Provider<bool>((ref) {
  return ref.watch(symptomCheckerProvider).isLoading;
});

/// Analysis result provider
final analysisResultProvider = Provider<SymptomAnalysisResult?>((ref) {
  return ref.watch(symptomCheckerProvider).analysisResult;
});

/// Error provider
final symptomCheckerErrorProvider = Provider<String?>((ref) {
  return ref.watch(symptomCheckerProvider).error;
});

/// Has accepted disclaimer provider
final hasAcceptedDisclaimerProvider = Provider<bool>((ref) {
  return ref.watch(symptomCheckerProvider).hasAcceptedDisclaimer;
});

/// Symptom categories data provider
final symptomCategoriesProvider = Provider<List<SymptomCategory>>((ref) {
  return [
    const SymptomCategory(
      name: 'General',
      symptoms: [
        'Fever',
        'Fatigue',
        'Headache',
        'Nausea',
        'Dizziness',
        'Loss of appetite',
        'Weakness',
        'Chills',
        'Sweating',
        'Weight loss',
      ],
    ),
    const SymptomCategory(
      name: 'Respiratory',
      symptoms: [
        'Cough',
        'Shortness of breath',
        'Chest pain',
        'Sore throat',
        'Runny nose',
        'Congestion',
        'Wheezing',
        'Sneezing',
        'Difficulty breathing',
        'Chest tightness',
      ],
    ),
    const SymptomCategory(
      name: 'Digestive',
      symptoms: [
        'Stomach pain',
        'Diarrhea',
        'Constipation',
        'Vomiting',
        'Heartburn',
        'Bloating',
        'Gas',
        'Indigestion',
        'Loss of appetite',
        'Abdominal cramps',
      ],
    ),
    const SymptomCategory(
      name: 'Musculoskeletal',
      symptoms: [
        'Joint pain',
        'Muscle pain',
        'Back pain',
        'Neck pain',
        'Stiffness',
        'Swelling',
        'Muscle cramps',
        'Joint swelling',
        'Limited mobility',
        'Muscle weakness',
      ],
    ),
    const SymptomCategory(
      name: 'Skin',
      symptoms: [
        'Rash',
        'Itching',
        'Dry skin',
        'Swelling',
        'Bruising',
        'Redness',
        'Bumps',
        'Blisters',
        'Discoloration',
        'Burning sensation',
      ],
    ),
    const SymptomCategory(
      name: 'Neurological',
      symptoms: [
        'Headache',
        'Dizziness',
        'Confusion',
        'Memory problems',
        'Numbness',
        'Tingling',
        'Vision changes',
        'Balance problems',
        'Seizures',
        'Coordination issues',
      ],
    ),
  ];
});

/// Body parts data provider
final bodyPartsProvider = Provider<List<BodyPart>>((ref) {
  return [
    const BodyPart(
      name: 'head',
      displayName: 'Head',
      commonSymptoms: ['Headache', 'Dizziness', 'Vision changes'],
    ),
    const BodyPart(
      name: 'chest',
      displayName: 'Chest',
      commonSymptoms: ['Chest pain', 'Shortness of breath', 'Cough'],
    ),
    const BodyPart(
      name: 'abdomen',
      displayName: 'Abdomen',
      commonSymptoms: ['Stomach pain', 'Nausea', 'Bloating'],
    ),
    const BodyPart(
      name: 'back',
      displayName: 'Back',
      commonSymptoms: ['Back pain', 'Stiffness', 'Muscle pain'],
    ),
    const BodyPart(
      name: 'arms',
      displayName: 'Arms',
      commonSymptoms: ['Joint pain', 'Numbness', 'Weakness'],
    ),
    const BodyPart(
      name: 'legs',
      displayName: 'Legs',
      commonSymptoms: ['Joint pain', 'Swelling', 'Cramps'],
    ),
    const BodyPart(
      name: 'skin',
      displayName: 'Skin',
      commonSymptoms: ['Rash', 'Itching', 'Redness'],
    ),
  ];
});