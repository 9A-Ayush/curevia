/// Model for home remedies and natural treatments
class HomeRemedyModel {
  final String id;
  final String name;
  final String category;
  final String condition;
  final String description;
  final List<String> symptoms;
  final List<Ingredient> ingredients;
  final List<PreparationStep> preparationSteps;
  final String usage;
  final String dosage;
  final List<String> benefits;
  final List<String> precautions;
  final List<String> contraindications;
  final String? imageUrl;
  final int preparationTime; // in minutes
  final String difficulty; // Easy, Medium, Hard
  final double effectiveness; // 1-5 rating
  final bool isVerified; // Doctor verified
  final String? scientificEvidence;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HomeRemedyModel({
    required this.id,
    required this.name,
    required this.category,
    required this.condition,
    required this.description,
    required this.symptoms,
    required this.ingredients,
    required this.preparationSteps,
    required this.usage,
    required this.dosage,
    required this.benefits,
    required this.precautions,
    required this.contraindications,
    this.imageUrl,
    required this.preparationTime,
    required this.difficulty,
    required this.effectiveness,
    this.isVerified = false,
    this.scientificEvidence,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeRemedyModel.fromJson(Map<String, dynamic> json) {
    return HomeRemedyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preparationSteps: (json['preparationSteps'] as List<dynamic>?)
              ?.map((e) => PreparationStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usage: json['usage'] ?? '',
      dosage: json['dosage'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      precautions: List<String>.from(json['precautions'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      imageUrl: json['imageUrl'],
      preparationTime: json['preparationTime'] ?? 0,
      difficulty: json['difficulty'] ?? 'Easy',
      effectiveness: json['effectiveness']?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] ?? false,
      scientificEvidence: json['scientificEvidence'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'condition': condition,
      'description': description,
      'symptoms': symptoms,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'preparationSteps': preparationSteps.map((e) => e.toJson()).toList(),
      'usage': usage,
      'dosage': dosage,
      'benefits': benefits,
      'precautions': precautions,
      'contraindications': contraindications,
      'imageUrl': imageUrl,
      'preparationTime': preparationTime,
      'difficulty': difficulty,
      'effectiveness': effectiveness,
      'isVerified': isVerified,
      'scientificEvidence': scientificEvidence,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  HomeRemedyModel copyWith({
    String? id,
    String? name,
    String? category,
    String? condition,
    String? description,
    List<String>? symptoms,
    List<Ingredient>? ingredients,
    List<PreparationStep>? preparationSteps,
    String? usage,
    String? dosage,
    List<String>? benefits,
    List<String>? precautions,
    List<String>? contraindications,
    String? imageUrl,
    int? preparationTime,
    String? difficulty,
    double? effectiveness,
    bool? isVerified,
    String? scientificEvidence,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeRemedyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      symptoms: symptoms ?? this.symptoms,
      ingredients: ingredients ?? this.ingredients,
      preparationSteps: preparationSteps ?? this.preparationSteps,
      usage: usage ?? this.usage,
      dosage: dosage ?? this.dosage,
      benefits: benefits ?? this.benefits,
      precautions: precautions ?? this.precautions,
      contraindications: contraindications ?? this.contraindications,
      imageUrl: imageUrl ?? this.imageUrl,
      preparationTime: preparationTime ?? this.preparationTime,
      difficulty: difficulty ?? this.difficulty,
      effectiveness: effectiveness ?? this.effectiveness,
      isVerified: isVerified ?? this.isVerified,
      scientificEvidence: scientificEvidence ?? this.scientificEvidence,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted preparation time
  String get formattedPreparationTime {
    if (preparationTime < 60) {
      return '$preparationTime min';
    } else {
      final hours = preparationTime ~/ 60;
      final minutes = preparationTime % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  /// Get difficulty color
  String get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'success';
      case 'medium':
        return 'warning';
      case 'hard':
        return 'error';
      default:
        return 'info';
    }
  }
}

/// Model for remedy ingredients
class Ingredient {
  final String name;
  final String quantity;
  final String? unit;
  final bool isOptional;
  final String? notes;

  const Ingredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.isOptional = false,
    this.notes,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      unit: json['unit'],
      isOptional: json['isOptional'] ?? false,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isOptional': isOptional,
      'notes': notes,
    };
  }

  /// Get formatted ingredient text
  String get formattedText {
    String text = '$quantity';
    if (unit != null) text += ' $unit';
    text += ' $name';
    if (isOptional) text += ' (optional)';
    return text;
  }
}

/// Model for preparation steps
class PreparationStep {
  final int stepNumber;
  final String instruction;
  final String? tip;
  final int? duration; // in minutes
  final String? imageUrl;

  const PreparationStep({
    required this.stepNumber,
    required this.instruction,
    this.tip,
    this.duration,
    this.imageUrl,
  });

  factory PreparationStep.fromJson(Map<String, dynamic> json) {
    return PreparationStep(
      stepNumber: json['stepNumber'] ?? 0,
      instruction: json['instruction'] ?? '',
      tip: json['tip'],
      duration: json['duration'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'tip': tip,
      'duration': duration,
      'imageUrl': imageUrl,
    };
  }
}

/// Model for remedy categories
class RemedyCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String color;
  final int remedyCount;

  const RemedyCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    this.remedyCount = 0,
  });

  factory RemedyCategory.fromJson(Map<String, dynamic> json) {
    return RemedyCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? '',
      color: json['color'] ?? '',
      remedyCount: json['remedyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'color': color,
      'remedyCount': remedyCount,
    };
  }
}

/// Model for herbs information
class HerbModel {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final List<String> commonNames;
  final List<String> properties;
  final List<String> uses;
  final List<String> benefits;
  final List<String> sideEffects;
  final List<String> contraindications;
  final String? imageUrl;
  final String origin;
  final String availability;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HerbModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.commonNames,
    required this.properties,
    required this.uses,
    required this.benefits,
    required this.sideEffects,
    required this.contraindications,
    this.imageUrl,
    required this.origin,
    required this.availability,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HerbModel.fromJson(Map<String, dynamic> json) {
    return HerbModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientificName'] ?? '',
      description: json['description'] ?? '',
      commonNames: List<String>.from(json['commonNames'] ?? []),
      properties: List<String>.from(json['properties'] ?? []),
      uses: List<String>.from(json['uses'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      sideEffects: List<String>.from(json['sideEffects'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      imageUrl: json['imageUrl'],
      origin: json['origin'] ?? '',
      availability: json['availability'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'commonNames': commonNames,
      'properties': properties,
      'uses': uses,
      'benefits': benefits,
      'sideEffects': sideEffects,
      'contraindications': contraindications,
      'imageUrl': imageUrl,
      'origin': origin,
      'availability': availability,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
