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
        'Dehydration',
        'Malaise',
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
        'Phlegm/Mucus',
        'Hoarse voice',
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
        'Blood in stool',
        'Acid reflux',
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
        'Shoulder pain',
        'Knee pain',
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
        'Hives',
        'Acne',
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
        'Tremors',
        'Fainting',
      ],
    ),
    const SymptomCategory(
      name: 'Women\'s Health',
      symptoms: [
        'Irregular periods',
        'Heavy bleeding',
        'Painful periods',
        'Missed period',
        'Vaginal discharge',
        'Pelvic pain',
        'Breast pain',
        'Breast lumps',
        'Hot flashes',
        'Mood swings',
        'Vaginal itching',
        'Painful intercourse',
      ],
    ),
    const SymptomCategory(
      name: 'Injuries & Wounds',
      symptoms: [
        'Cut/Laceration',
        'Bruise',
        'Burn',
        'Sprain',
        'Fracture/Broken bone',
        'Bleeding',
        'Swelling from injury',
        'Wound infection',
        'Animal bite',
        'Insect bite',
        'Scrape/Abrasion',
        'Puncture wound',
      ],
    ),
    const SymptomCategory(
      name: 'Eye & Ear',
      symptoms: [
        'Eye pain',
        'Blurred vision',
        'Red eyes',
        'Eye discharge',
        'Ear pain',
        'Hearing loss',
        'Ringing in ears',
        'Ear discharge',
        'Itchy eyes',
        'Sensitivity to light',
        'Double vision',
        'Ear pressure',
      ],
    ),
    const SymptomCategory(
      name: 'Urinary',
      symptoms: [
        'Painful urination',
        'Frequent urination',
        'Blood in urine',
        'Difficulty urinating',
        'Urgent need to urinate',
        'Incontinence',
        'Dark urine',
        'Cloudy urine',
        'Lower back pain',
        'Kidney pain',
      ],
    ),
    const SymptomCategory(
      name: 'Mental Health',
      symptoms: [
        'Anxiety',
        'Depression',
        'Stress',
        'Insomnia',
        'Panic attacks',
        'Mood changes',
        'Irritability',
        'Loss of interest',
        'Difficulty concentrating',
        'Restlessness',
        'Excessive worry',
        'Fatigue (mental)',
      ],
    ),
    const SymptomCategory(
      name: 'Cardiovascular',
      symptoms: [
        'Chest pain',
        'Rapid heartbeat',
        'Irregular heartbeat',
        'Shortness of breath',
        'Swelling in legs',
        'Lightheadedness',
        'Fainting',
        'Cold hands/feet',
        'High blood pressure',
        'Palpitations',
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