import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for Curevia app
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'patient', 'doctor', 'admin'
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isVerified;
  final Map<String, dynamic>? additionalInfo;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isVerified,
    this.additionalInfo,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'patient',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      additionalInfo: map['additionalInfo'],
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isVerified': isVerified,
      'additionalInfo': additionalInfo,
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? role,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? additionalInfo,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// Patient-specific model extending UserModel
class PatientModel extends UserModel {
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final double? height; // in cm
  final double? weight; // in kg
  final List<String>? allergies;
  final List<String>? medicalHistory;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;

  const PatientModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.role,
    super.phoneNumber,
    super.profileImageUrl,
    required super.createdAt,
    required super.updatedAt,
    required super.isActive,
    required super.isVerified,
    super.additionalInfo,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.height,
    this.weight,
    this.allergies,
    this.medicalHistory,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.address,
    this.city,
    this.state,
    this.pincode,
  });

  /// Create PatientModel from UserModel and additional data
  factory PatientModel.fromUserModel(
    UserModel user,
    Map<String, dynamic> patientData,
  ) {
    return PatientModel(
      uid: user.uid,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isActive: user.isActive,
      isVerified: user.isVerified,
      additionalInfo: user.additionalInfo,
      dateOfBirth: (patientData['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: patientData['gender'],
      bloodGroup: patientData['bloodGroup'],
      height: patientData['height']?.toDouble(),
      weight: patientData['weight']?.toDouble(),
      allergies: List<String>.from(patientData['allergies'] ?? []),
      medicalHistory: List<String>.from(patientData['medicalHistory'] ?? []),
      emergencyContactName: patientData['emergencyContactName'],
      emergencyContactPhone: patientData['emergencyContactPhone'],
      address: patientData['address'],
      city: patientData['city'],
      state: patientData['state'],
      pincode: patientData['pincode'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
    });
    return map;
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

  /// Calculate BMI
  double? get bmi {
    if (height == null || weight == null || height == 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
}
