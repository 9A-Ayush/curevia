/// Model for symptom analysis results
class SymptomAnalysisResult {
  final List<PossibleCondition> possibleConditions;
  final List<String> recommendations;
  final List<String> urgentSigns;
  final String suggestedSpecialist;
  final String confidence;
  final String disclaimer;

  const SymptomAnalysisResult({
    required this.possibleConditions,
    required this.recommendations,
    required this.urgentSigns,
    required this.suggestedSpecialist,
    required this.confidence,
    required this.disclaimer,
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
    };
  }
}

/// Model for possible medical conditions
class PossibleCondition {
  final String name;
  final String probability;
  final String description;

  const PossibleCondition({
    required this.name,
    required this.probability,
    required this.description,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    return PossibleCondition(
      name: json['name'] ?? '',
      probability: json['probability'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'probability': probability,
      'description': description,
    };
  }
}

/// Model for symptom input data
class SymptomInput {
  final List<String> symptoms;
  final String description;
  final int age;
  final String gender;
  final String? duration;
  final String? severity;
  final List<String>? imageUrls;

  const SymptomInput({
    required this.symptoms,
    required this.description,
    required this.age,
    required this.gender,
    this.duration,
    this.severity,
    this.imageUrls,
  });

  factory SymptomInput.fromJson(Map<String, dynamic> json) {
    return SymptomInput(
      symptoms: List<String>.from(json['symptoms'] ?? []),
      description: json['description'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      duration: json['duration'],
      severity: json['severity'],
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symptoms': symptoms,
      'description': description,
      'age': age,
      'gender': gender,
      'duration': duration,
      'severity': severity,
      'imageUrls': imageUrls,
    };
  }
}

/// Model for symptom category
class SymptomCategory {
  final String name;
  final List<String> symptoms;
  final String? icon;
  final String? color;

  const SymptomCategory({
    required this.name,
    required this.symptoms,
    this.icon,
    this.color,
  });

  factory SymptomCategory.fromJson(Map<String, dynamic> json) {
    return SymptomCategory(
      name: json['name'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symptoms': symptoms,
      'icon': icon,
      'color': color,
    };
  }
}
