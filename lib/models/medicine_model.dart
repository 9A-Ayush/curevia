import 'package:cloud_firestore/cloud_firestore.dart';

/// Medicine model for medicine directory
class MedicineModel {
  final String id;
  final String name;
  final String? genericName;
  final String? brandName;
  final String? manufacturer;
  final String? category;
  final String? therapeuticClass;
  final String? composition;
  final String? strength;
  final String? dosageForm; // tablet, capsule, syrup, injection, etc.
  final String? description;
  final String? uses;
  final String? dosage;
  final String? administration; // how to take
  final List<String>? sideEffects;
  final List<String>? contraindications;
  final List<String>? precautions;
  final List<String>? interactions;
  final String? storage;
  final String? pregnancyCategory;
  final bool? isOTC; // Over the counter
  final bool? isPrescriptionRequired;
  final double? price;
  final String? imageUrl;
  final List<String>? alternatives;
  final Map<String, dynamic>? fdaInfo; // FDA approval info
  final bool? isAvailable;
  final DateTime? expiryDate;
  final String? batchNumber;
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicineModel({
    required this.id,
    required this.name,
    this.genericName,
    this.brandName,
    this.manufacturer,
    this.category,
    this.therapeuticClass,
    this.composition,
    this.strength,
    this.dosageForm,
    this.description,
    this.uses,
    this.dosage,
    this.administration,
    this.sideEffects,
    this.contraindications,
    this.precautions,
    this.interactions,
    this.storage,
    this.pregnancyCategory,
    this.isOTC,
    this.isPrescriptionRequired,
    this.price,
    this.imageUrl,
    this.alternatives,
    this.fdaInfo,
    this.isAvailable,
    this.expiryDate,
    this.batchNumber,
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create MedicineModel from Firestore document
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      genericName: map['genericName'],
      brandName: map['brandName'],
      manufacturer: map['manufacturer'],
      category: map['category'],
      therapeuticClass: map['therapeuticClass'],
      composition: map['composition'],
      strength: map['strength'],
      dosageForm: map['dosageForm'],
      description: map['description'],
      uses: map['uses'],
      dosage: map['dosage'],
      administration: map['administration'],
      sideEffects: List<String>.from(map['sideEffects'] ?? []),
      contraindications: List<String>.from(map['contraindications'] ?? []),
      precautions: List<String>.from(map['precautions'] ?? []),
      interactions: List<String>.from(map['interactions'] ?? []),
      storage: map['storage'],
      pregnancyCategory: map['pregnancyCategory'],
      isOTC: map['isOTC'],
      isPrescriptionRequired: map['isPrescriptionRequired'],
      price: map['price']?.toDouble(),
      imageUrl: map['imageUrl'],
      alternatives: List<String>.from(map['alternatives'] ?? []),
      fdaInfo: map['fdaInfo'],
      isAvailable: map['isAvailable'],
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      batchNumber: map['batchNumber'],
      additionalInfo: map['additionalInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert MedicineModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'brandName': brandName,
      'manufacturer': manufacturer,
      'category': category,
      'therapeuticClass': therapeuticClass,
      'composition': composition,
      'strength': strength,
      'dosageForm': dosageForm,
      'description': description,
      'uses': uses,
      'dosage': dosage,
      'administration': administration,
      'sideEffects': sideEffects,
      'contraindications': contraindications,
      'precautions': precautions,
      'interactions': interactions,
      'storage': storage,
      'pregnancyCategory': pregnancyCategory,
      'isOTC': isOTC,
      'isPrescriptionRequired': isPrescriptionRequired,
      'price': price,
      'imageUrl': imageUrl,
      'alternatives': alternatives,
      'fdaInfo': fdaInfo,
      'isAvailable': isAvailable,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'batchNumber': batchNumber,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of MedicineModel with updated fields
  MedicineModel copyWith({
    String? id,
    String? name,
    String? genericName,
    String? brandName,
    String? manufacturer,
    String? category,
    String? therapeuticClass,
    String? composition,
    String? strength,
    String? dosageForm,
    String? description,
    String? uses,
    String? dosage,
    String? administration,
    List<String>? sideEffects,
    List<String>? contraindications,
    List<String>? precautions,
    List<String>? interactions,
    String? storage,
    String? pregnancyCategory,
    bool? isOTC,
    bool? isPrescriptionRequired,
    double? price,
    String? imageUrl,
    List<String>? alternatives,
    Map<String, dynamic>? fdaInfo,
    bool? isAvailable,
    DateTime? expiryDate,
    String? batchNumber,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      brandName: brandName ?? this.brandName,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      therapeuticClass: therapeuticClass ?? this.therapeuticClass,
      composition: composition ?? this.composition,
      strength: strength ?? this.strength,
      dosageForm: dosageForm ?? this.dosageForm,
      description: description ?? this.description,
      uses: uses ?? this.uses,
      dosage: dosage ?? this.dosage,
      administration: administration ?? this.administration,
      sideEffects: sideEffects ?? this.sideEffects,
      contraindications: contraindications ?? this.contraindications,
      precautions: precautions ?? this.precautions,
      interactions: interactions ?? this.interactions,
      storage: storage ?? this.storage,
      pregnancyCategory: pregnancyCategory ?? this.pregnancyCategory,
      isOTC: isOTC ?? this.isOTC,
      isPrescriptionRequired: isPrescriptionRequired ?? this.isPrescriptionRequired,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      alternatives: alternatives ?? this.alternatives,
      fdaInfo: fdaInfo ?? this.fdaInfo,
      isAvailable: isAvailable ?? this.isAvailable,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted price
  String get formattedPrice {
    if (price == null) return 'Price not available';
    return '₹${price!.toStringAsFixed(2)}';
  }

  /// Get display name (brand name or generic name)
  String get displayName {
    return brandName ?? genericName ?? name;
  }

  /// Get full name with strength
  String get fullName {
    final baseName = displayName;
    if (strength != null) {
      return '$baseName ($strength)';
    }
    return baseName;
  }

  /// Check if medicine is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Get days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiryDate!)) return 0;
    return expiryDate!.difference(now).inDays;
  }

  /// Check if medicine is near expiry (within 30 days)
  bool get isNearExpiry {
    final days = daysUntilExpiry;
    return days != null && days <= 30 && days > 0;
  }

  /// Get availability status text
  String get availabilityStatus {
    if (isExpired) return 'Expired';
    if (isAvailable == false) return 'Out of Stock';
    if (isNearExpiry) return 'Near Expiry';
    return 'Available';
  }

  /// Get prescription requirement text
  String get prescriptionText {
    if (isPrescriptionRequired == true) return 'Prescription Required';
    if (isOTC == true) return 'Over the Counter';
    return 'Prescription Status Unknown';
  }

  @override
  String toString() {
    return 'MedicineModel(id: $id, name: $name, manufacturer: $manufacturer)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicineModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
