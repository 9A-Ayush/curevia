import 'package:cloud_firestore/cloud_firestore.dart';

/// Home remedy model for natural treatments
class RemedyModel {
  final String id;
  final String name;
  final String? category;
  final List<String>? symptoms; // What symptoms it treats
  final List<String>? conditions; // What conditions it helps with
  final String? description;
  final List<String>? ingredients;
  final List<String>? preparation; // Step-by-step preparation
  final String? usage; // How to use/apply
  final String? dosage;
  final String? frequency; // How often to use
  final String? duration; // How long to use
  final List<String>? benefits;
  final List<String>? precautions;
  final List<String>? contraindications;
  final List<String>? sideEffects;
  final String? ageGroup; // 'adults', 'children', 'all'
  final String? difficulty; // 'easy', 'medium', 'hard'
  final int? preparationTime; // in minutes
  final String? imageUrl;
  final List<String>? tags;
  final double? rating;
  final int? totalReviews;
  final bool? isVerified; // Doctor verified
  final String? verifiedBy; // Doctor ID who verified
  final DateTime? verifiedAt;
  final String? source; // Traditional, Ayurvedic, etc.
  final Map<String, dynamic>? nutritionalInfo;
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RemedyModel({
    required this.id,
    required this.name,
    this.category,
    this.symptoms,
    this.conditions,
    this.description,
    this.ingredients,
    this.preparation,
    this.usage,
    this.dosage,
    this.frequency,
    this.duration,
    this.benefits,
    this.precautions,
    this.contraindications,
    this.sideEffects,
    this.ageGroup,
    this.difficulty,
    this.preparationTime,
    this.imageUrl,
    this.tags,
    this.rating,
    this.totalReviews,
    this.isVerified,
    this.verifiedBy,
    this.verifiedAt,
    this.source,
    this.nutritionalInfo,
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create RemedyModel from Firestore document
  factory RemedyModel.fromMap(Map<String, dynamic> map) {
    return RemedyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'],
      symptoms: List<String>.from(map['symptoms'] ?? []),
      conditions: List<String>.from(map['conditions'] ?? []),
      description: map['description'],
      ingredients: List<String>.from(map['ingredients'] ?? []),
      preparation: List<String>.from(map['preparation'] ?? []),
      usage: map['usage'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      duration: map['duration'],
      benefits: List<String>.from(map['benefits'] ?? []),
      precautions: List<String>.from(map['precautions'] ?? []),
      contraindications: List<String>.from(map['contraindications'] ?? []),
      sideEffects: List<String>.from(map['sideEffects'] ?? []),
      ageGroup: map['ageGroup'],
      difficulty: map['difficulty'],
      preparationTime: map['preparationTime'],
      imageUrl: map['imageUrl'],
      tags: List<String>.from(map['tags'] ?? []),
      rating: map['rating']?.toDouble(),
      totalReviews: map['totalReviews'],
      isVerified: map['isVerified'],
      verifiedBy: map['verifiedBy'],
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
      source: map['source'],
      nutritionalInfo: map['nutritionalInfo'],
      additionalInfo: map['additionalInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert RemedyModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'symptoms': symptoms,
      'conditions': conditions,
      'description': description,
      'ingredients': ingredients,
      'preparation': preparation,
      'usage': usage,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'benefits': benefits,
      'precautions': precautions,
      'contraindications': contraindications,
      'sideEffects': sideEffects,
      'ageGroup': ageGroup,
      'difficulty': difficulty,
      'preparationTime': preparationTime,
      'imageUrl': imageUrl,
      'tags': tags,
      'rating': rating,
      'totalReviews': totalReviews,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'source': source,
      'nutritionalInfo': nutritionalInfo,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of RemedyModel with updated fields
  RemedyModel copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? symptoms,
    List<String>? conditions,
    String? description,
    List<String>? ingredients,
    List<String>? preparation,
    String? usage,
    String? dosage,
    String? frequency,
    String? duration,
    List<String>? benefits,
    List<String>? precautions,
    List<String>? contraindications,
    List<String>? sideEffects,
    String? ageGroup,
    String? difficulty,
    int? preparationTime,
    String? imageUrl,
    List<String>? tags,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? source,
    Map<String, dynamic>? nutritionalInfo,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RemedyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      symptoms: symptoms ?? this.symptoms,
      conditions: conditions ?? this.conditions,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      preparation: preparation ?? this.preparation,
      usage: usage ?? this.usage,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      benefits: benefits ?? this.benefits,
      precautions: precautions ?? this.precautions,
      contraindications: contraindications ?? this.contraindications,
      sideEffects: sideEffects ?? this.sideEffects,
      ageGroup: ageGroup ?? this.ageGroup,
      difficulty: difficulty ?? this.difficulty,
      preparationTime: preparationTime ?? this.preparationTime,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      source: source ?? this.source,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted rating text
  String get ratingText {
    if (rating == null) return 'No ratings yet';
    return '${rating!.toStringAsFixed(1)} (${totalReviews ?? 0} reviews)';
  }

  /// Get formatted preparation time
  String get preparationTimeText {
    if (preparationTime == null) return 'Time not specified';
    if (preparationTime! < 60) return '${preparationTime!} minutes';
    final hours = preparationTime! ~/ 60;
    final minutes = preparationTime! % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Get difficulty level with emoji
  String get difficultyWithEmoji {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return '🟢 Easy';
      case 'medium':
        return '🟡 Medium';
      case 'hard':
        return '🔴 Hard';
      default:
        return difficulty ?? 'Not specified';
    }
  }

  /// Get verification status
  String get verificationStatus {
    if (isVerified == true) return 'Doctor Verified ✓';
    return 'Not Verified';
  }

  /// Get ingredients count
  int get ingredientsCount {
    return ingredients?.length ?? 0;
  }

  /// Get preparation steps count
  int get preparationStepsCount {
    return preparation?.length ?? 0;
  }

  /// Check if remedy is suitable for age group
  bool isSuitableForAge(String age) {
    if (ageGroup == null || ageGroup == 'all') return true;
    return ageGroup!.toLowerCase().contains(age.toLowerCase());
  }

  /// Check if remedy treats specific symptom
  bool treatsSymptom(String symptom) {
    if (symptoms == null) return false;
    return symptoms!.any((s) => s.toLowerCase().contains(symptom.toLowerCase()));
  }

  /// Check if remedy helps with specific condition
  bool helpsWithCondition(String condition) {
    if (conditions == null) return false;
    return conditions!.any((c) => c.toLowerCase().contains(condition.toLowerCase()));
  }

  /// Get all treatable symptoms and conditions
  List<String> get allTreatableIssues {
    final issues = <String>[];
    if (symptoms != null) issues.addAll(symptoms!);
    if (conditions != null) issues.addAll(conditions!);
    return issues;
  }

  @override
  String toString() {
    return 'RemedyModel(id: $id, name: $name, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemedyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
