import 'dart:io';

/// Enhanced symptom analysis models for the symptoms checker
class SymptomAnalysisRequest {
  final String textDescription;
  final List<String> selectedSymptoms;
  final int age;
  final String gender;
  final String? duration;
  final int? severityLevel; // 1-10 scale
  final String? bodyPart;
  final List<String>? medicalHistory;
  final List<File>? images;

  const SymptomAnalysisRequest({
    required this.textDescription,
    required this.selectedSymptoms,
    required this.age,
    required this.gender,
    this.duration,
    this.severityLevel,
    this.bodyPart,
    this.medicalHistory,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'textDescription': textDescription,
      'selectedSymptoms': selectedSymptoms,
      'age': age,
      'gender': gender,
      'duration': duration,
      'severityLevel': severityLevel,
      'bodyPart': bodyPart,
      'medicalHistory': medicalHistory,
      // Note: images are handled separately for API calls
    };
  }
}

/// Enhanced symptom analysis result
class SymptomAnalysisResult {
  final List<PossibleCondition> possibleConditions;
  final List<String> recommendations;
  final List<String> urgentSigns;
  final String suggestedSpecialist;
  final String confidence;
  final String disclaimer;
  final SeverityLevel overallSeverity;
  final List<String> nextSteps;
  final String? emergencyAdvice;

  const SymptomAnalysisResult({
    required this.possibleConditions,
    required this.recommendations,
    required this.urgentSigns,
    required this.suggestedSpecialist,
    required this.confidence,
    required this.disclaimer,
    required this.overallSeverity,
    required this.nextSteps,
    this.emergencyAdvice,
  });

  factory SymptomAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysisResult(
      possibleConditions: (json['possibleConditions'] as List<dynamic>?)
              ?.map((e) => PossibleCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
      urgentSigns: List<String>.from(json['urgentSigns'] ?? []),
      suggestedSpecialist: json['suggestedSpecialist'] ?? '',
      confidence: json['confidence'] ?? 'Unknown',
      disclaimer: json['disclaimer'] ?? '',
      overallSeverity: SeverityLevel.values.firstWhere(
        (e) => e.name == json['overallSeverity'],
        orElse: () => SeverityLevel.low,
      ),
      nextSteps: List<String>.from(json['nextSteps'] ?? []),
      emergencyAdvice: json['emergencyAdvice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'possibleConditions': possibleConditions.map((e) => e.toJson()).toList(),
      'recommendations': recommendations,
      'urgentSigns': urgentSigns,
      'suggestedSpecialist': suggestedSpecialist,
      'confidence': confidence,
      'disclaimer': disclaimer,
      'overallSeverity': overallSeverity.name,
      'nextSteps': nextSteps,
      'emergencyAdvice': emergencyAdvice,
    };
  }
}

/// Possible medical condition
class PossibleCondition {
  final String name;
  final String probability;
  final String description;
  final SeverityLevel severity;
  final List<String> symptoms;
  final String? treatment;

  const PossibleCondition({
    required this.name,
    required this.probability,
    required this.description,
    required this.severity,
    required this.symptoms,
    this.treatment,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    return PossibleCondition(
      name: json['name'] ?? '',
      probability: json['probability'] ?? '',
      description: json['description'] ?? '',
      severity: SeverityLevel.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => SeverityLevel.low,
      ),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      treatment: json['treatment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'probability': probability,
      'description': description,
      'severity': severity.name,
      'symptoms': symptoms,
      'treatment': treatment,
    };
  }
}

/// Severity levels for conditions
enum SeverityLevel {
  low,
  moderate,
  high,
  emergency;

  String get displayName {
    switch (this) {
      case SeverityLevel.low:
        return 'Low Concern';
      case SeverityLevel.moderate:
        return 'Moderate Concern';
      case SeverityLevel.high:
        return 'High Concern';
      case SeverityLevel.emergency:
        return 'Emergency';
    }
  }

  String get description {
    switch (this) {
      case SeverityLevel.low:
        return 'Monitor symptoms and consider home care';
      case SeverityLevel.moderate:
        return 'Schedule appointment with healthcare provider';
      case SeverityLevel.high:
        return 'Seek medical attention soon';
      case SeverityLevel.emergency:
        return 'Seek immediate emergency care';
    }
  }
}

/// Symptom category for organized selection
class SymptomCategory {
  final String name;
  final List<String> symptoms;
  final String? icon;

  const SymptomCategory({
    required this.name,
    required this.symptoms,
    this.icon,
  });
}

/// Body part selection for targeted analysis
class BodyPart {
  final String name;
  final String displayName;
  final List<String> commonSymptoms;

  const BodyPart({
    required this.name,
    required this.displayName,
    required this.commonSymptoms,
  });
}

/// Duration options for symptoms
enum SymptomDuration {
  lessThanHour('Less than 1 hour'),
  fewHours('A few hours'),
  oneDay('1 day'),
  fewDays('2-3 days'),
  oneWeek('About a week'),
  fewWeeks('2-3 weeks'),
  oneMonth('About a month'),
  moreThanMonth('More than a month');

  const SymptomDuration(this.displayName);
  final String displayName;
}