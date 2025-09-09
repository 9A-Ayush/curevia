import 'package:cloud_firestore/cloud_firestore.dart';

/// Family member model
class FamilyMemberModel {
  final String id;
  final String name;
  final String relationship;
  final String? phoneNumber;
  final String? email;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? gender;
  final List<String> allergies;
  final List<String> medicalConditions;
  final String? emergencyContact;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.phoneNumber,
    this.email,
    this.dateOfBirth,
    this.bloodGroup,
    this.gender,
    required this.allergies,
    required this.medicalConditions,
    this.emergencyContact,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create FamilyMemberModel from Firestore document
  factory FamilyMemberModel.fromMap(Map<String, dynamic> map, String id) {
    return FamilyMemberModel(
      id: id,
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? (map['dateOfBirth'] as Timestamp).toDate() 
          : null,
      bloodGroup: map['bloodGroup'],
      gender: map['gender'],
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      emergencyContact: map['emergencyContact'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert FamilyMemberModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
      'email': email,
      'dateOfBirth': dateOfBirth != null 
          ? Timestamp.fromDate(dateOfBirth!) 
          : null,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'emergencyContact': emergencyContact,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of FamilyMemberModel with updated fields
  FamilyMemberModel copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phoneNumber,
    String? email,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? gender,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? emergencyContact,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gender: gender ?? this.gender,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Get formatted age string
  String get ageString {
    final calculatedAge = age;
    if (calculatedAge == null) return 'Age not set';
    return '$calculatedAge years old';
  }

  /// Get relationship icon
  String get relationshipIcon {
    switch (relationship.toLowerCase()) {
      case 'father':
      case 'dad':
        return 'man';
      case 'mother':
      case 'mom':
        return 'woman';
      case 'son':
        return 'boy';
      case 'daughter':
        return 'girl';
      case 'brother':
        return 'man';
      case 'sister':
        return 'woman';
      case 'husband':
        return 'man';
      case 'wife':
        return 'woman';
      case 'grandfather':
      case 'grandpa':
        return 'elderly_man';
      case 'grandmother':
      case 'grandma':
        return 'elderly_woman';
      default:
        return 'person';
    }
  }

  /// Check if has medical conditions
  bool get hasMedicalConditions => medicalConditions.isNotEmpty;

  /// Check if has allergies
  bool get hasAllergies => allergies.isNotEmpty;

  /// Get formatted medical info
  String get medicalInfo {
    final info = <String>[];
    if (bloodGroup != null) info.add('Blood: $bloodGroup');
    if (hasAllergies) info.add('Allergies: ${allergies.join(', ')}');
    if (hasMedicalConditions) {
      info.add('Conditions: ${medicalConditions.join(', ')}');
    }
    return info.isEmpty ? 'No medical info' : info.join(' • ');
  }

  @override
  String toString() {
    return 'FamilyMemberModel(id: $id, name: $name, relationship: $relationship)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyMemberModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
