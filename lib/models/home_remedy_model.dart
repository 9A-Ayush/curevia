import 'package:cloud_firestore/cloud_firestore.dart';

/// Home remedy model for storing remedy information
class HomeRemedyModel {
  final int id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> preparation;
  final String usage;
  final String ageSuitability;
  final String dosage;
  final String precautions;
  final String contraindications;
  final String imageURL;
  final String preparationTime;
  final String difficulty;
  final List<String> tags;
  final String categoryName;
  final int categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HomeRemedyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.preparation,
    required this.usage,
    required this.ageSuitability,
    required this.dosage,
    required this.precautions,
    required this.contraindications,
    required this.imageURL,
    required this.preparationTime,
    required this.difficulty,
    required this.tags,
    required this.categoryName,
    required this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  /// Create HomeRemedyModel from Firestore document
  factory HomeRemedyModel.fromMap(Map<String, dynamic> map) {
    return HomeRemedyModel(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      preparation: List<String>.from(map['preparation'] ?? []),
      usage: map['usage'] ?? '',
      ageSuitability: map['ageSuitability'] ?? '',
      dosage: map['dosage'] ?? '',
      precautions: map['precautions'] ?? '',
      contraindications: map['contraindications'] ?? '',
      imageURL: map['imageURL'] ?? '',
      preparationTime: map['preparationTime'] ?? '',
      difficulty: map['difficulty'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      categoryName: map['categoryName'] ?? '',
      categoryId: map['categoryId'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert HomeRemedyModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'preparation': preparation,
      'usage': usage,
      'ageSuitability': ageSuitability,
      'dosage': dosage,
      'precautions': precautions,
      'contraindications': contraindications,
      'imageURL': imageURL,
      'preparationTime': preparationTime,
      'difficulty': difficulty,
      'tags': tags,
      'categoryName': categoryName,
      'categoryId': categoryId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  HomeRemedyModel copyWith({
    int? id,
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? preparation,
    String? usage,
    String? ageSuitability,
    String? dosage,
    String? precautions,
    String? contraindications,
    String? imageURL,
    String? preparationTime,
    String? difficulty,
    List<String>? tags,
    String? categoryName,
    int? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeRemedyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      preparation: preparation ?? this.preparation,
      usage: usage ?? this.usage,
      ageSuitability: ageSuitability ?? this.ageSuitability,
      dosage: dosage ?? this.dosage,
      precautions: precautions ?? this.precautions,
      contraindications: contraindications ?? this.contraindications,
      imageURL: imageURL ?? this.imageURL,
      preparationTime: preparationTime ?? this.preparationTime,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeRemedyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HomeRemedyModel(id: $id, title: $title, categoryName: $categoryName)';
  }
}

/// Home remedy category model
class HomeRemedyCategoryModel {
  final int id;
  final String name;
  final List<HomeRemedyModel> remedies;

  const HomeRemedyCategoryModel({
    required this.id,
    required this.name,
    required this.remedies,
  });

  /// Create from JSON data
  factory HomeRemedyCategoryModel.fromJson(Map<String, dynamic> json) {
    return HomeRemedyCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      remedies: (json['remedies'] as List<dynamic>?)
          ?.map((remedyJson) => HomeRemedyModel(
                id: remedyJson['id'] ?? 0,
                title: remedyJson['title'] ?? '',
                description: remedyJson['description'] ?? '',
                ingredients: List<String>.from(remedyJson['ingredients'] ?? []),
                preparation: List<String>.from(remedyJson['preparation'] ?? []),
                usage: remedyJson['usage'] ?? '',
                ageSuitability: remedyJson['ageSuitability'] ?? '',
                dosage: remedyJson['dosage'] ?? '',
                precautions: remedyJson['precautions'] ?? '',
                contraindications: remedyJson['contraindications'] ?? '',
                imageURL: remedyJson['imageURL'] ?? '',
                preparationTime: remedyJson['preparationTime'] ?? '',
                difficulty: remedyJson['difficulty'] ?? '',
                tags: List<String>.from(remedyJson['tags'] ?? []),
                categoryName: json['name'] ?? '',
                categoryId: json['id'] ?? 0,
              ))
          .toList() ?? [],
    );
  }

  @override
  String toString() {
    return 'HomeRemedyCategoryModel(id: $id, name: $name, remedies: ${remedies.length})';
  }
}