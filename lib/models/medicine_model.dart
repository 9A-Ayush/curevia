import 'package:cloud_firestore/cloud_firestore.dart';

/// Medicine model for storing medicine information
class MedicineModel {
  final String id;
  final String name;
  final String chemical;
  final String uses;
  final String dosage;
  final String price;
  final List<String> brands;
  final String categoryName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicineModel({
    required this.id,
    required this.name,
    required this.chemical,
    required this.uses,
    required this.dosage,
    required this.price,
    required this.brands,
    required this.categoryName,
    this.createdAt,
    this.updatedAt,
  });

  /// Create MedicineModel from Firestore document
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      chemical: map['chemical'] ?? '',
      uses: map['uses'] ?? '',
      dosage: map['dosage'] ?? '',
      price: map['price'] ?? '',
      brands: List<String>.from(map['brands'] ?? []),
      categoryName: map['categoryName'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert MedicineModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'chemical': chemical,
      'uses': uses,
      'dosage': dosage,
      'price': price,
      'brands': brands,
      'categoryName': categoryName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  MedicineModel copyWith({
    String? id,
    String? name,
    String? chemical,
    String? uses,
    String? dosage,
    String? price,
    List<String>? brands,
    String? categoryName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      chemical: chemical ?? this.chemical,
      uses: uses ?? this.uses,
      dosage: dosage ?? this.dosage,
      price: price ?? this.price,
      brands: brands ?? this.brands,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicineModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MedicineModel(id: $id, name: $name, chemical: $chemical, categoryName: $categoryName)';
  }
}

/// Medicine category model
class MedicineCategoryModel {
  final String name;
  final List<MedicineModel> medicines;

  const MedicineCategoryModel({
    required this.name,
    required this.medicines,
  });

  /// Create from JSON data
  factory MedicineCategoryModel.fromJson(Map<String, dynamic> json) {
    return MedicineCategoryModel(
      name: json['name'] ?? '',
      medicines: (json['medicines'] as List<dynamic>?)
          ?.map((medicineJson) => MedicineModel(
                id: medicineJson['id'] ?? '',
                name: medicineJson['name'] ?? '',
                chemical: medicineJson['chemical'] ?? '',
                uses: medicineJson['uses'] ?? '',
                dosage: medicineJson['dosage'] ?? '',
                price: medicineJson['price'] ?? '',
                brands: List<String>.from(medicineJson['brands'] ?? []),
                categoryName: json['name'] ?? '',
              ))
          .toList() ?? [],
    );
  }

  @override
  String toString() {
    return 'MedicineCategoryModel(name: $name, medicines: ${medicines.length})';
  }
}