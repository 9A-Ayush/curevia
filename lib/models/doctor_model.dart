import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Doctor model extending UserModel
class DoctorModel extends UserModel {
  final String? medicalLicenseNumber;
  final String? specialty;
  final List<String>? subSpecialties;
  final String? qualification;
  final List<String>? degrees;
  final int? experienceYears;
  final String? clinicName;
  final String? clinicAddress;
  final String? city;
  final String? state;
  final String? pincode;
  final GeoPoint? location; // For nearby search
  final double? consultationFee;
  final double? rating;
  final int? totalReviews;
  final List<String>? languages;
  final Map<String, dynamic>? availability; // Day-wise time slots
  final bool? isAvailableOnline;
  final bool? isAvailableOffline;
  final String? about;
  final List<String>? services;
  final List<String>? awards;
  final List<String>? certifications;
  final String? registrationNumber;
  final DateTime? licenseExpiryDate;
  final String? verificationStatus; // 'pending', 'verified', 'rejected'
  final List<String>? documentUrls; // License, certificates, etc.

  const DoctorModel({
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
    this.medicalLicenseNumber,
    this.specialty,
    this.subSpecialties,
    this.qualification,
    this.degrees,
    this.experienceYears,
    this.clinicName,
    this.clinicAddress,
    this.city,
    this.state,
    this.pincode,
    this.location,
    this.consultationFee,
    this.rating,
    this.totalReviews,
    this.languages,
    this.availability,
    this.isAvailableOnline,
    this.isAvailableOffline,
    this.about,
    this.services,
    this.awards,
    this.certifications,
    this.registrationNumber,
    this.licenseExpiryDate,
    this.verificationStatus,
    this.documentUrls,
  });

  /// Create DoctorModel from UserModel and additional data
  factory DoctorModel.fromUserModel(
    UserModel user,
    Map<String, dynamic> doctorData,
  ) {
    return DoctorModel(
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
      medicalLicenseNumber: doctorData['medicalLicenseNumber'],
      specialty: doctorData['specialty'],
      subSpecialties: List<String>.from(doctorData['subSpecialties'] ?? []),
      qualification: doctorData['qualification'],
      degrees: List<String>.from(doctorData['degrees'] ?? []),
      experienceYears: doctorData['experienceYears'],
      clinicName: doctorData['clinicName'],
      clinicAddress: doctorData['clinicAddress'],
      city: doctorData['city'],
      state: doctorData['state'],
      pincode: doctorData['pincode'],
      location: doctorData['location'],
      consultationFee: doctorData['consultationFee']?.toDouble(),
      rating: doctorData['rating']?.toDouble(),
      totalReviews: doctorData['totalReviews'],
      languages: List<String>.from(doctorData['languages'] ?? []),
      availability: doctorData['availability'],
      isAvailableOnline: doctorData['isAvailableOnline'],
      isAvailableOffline: doctorData['isAvailableOffline'],
      about: doctorData['about'],
      services: List<String>.from(doctorData['services'] ?? []),
      awards: List<String>.from(doctorData['awards'] ?? []),
      certifications: List<String>.from(doctorData['certifications'] ?? []),
      registrationNumber: doctorData['registrationNumber'],
      licenseExpiryDate: (doctorData['licenseExpiryDate'] as Timestamp?)
          ?.toDate(),
      verificationStatus: doctorData['verificationStatus'],
      documentUrls: List<String>.from(doctorData['documentUrls'] ?? []),
    );
  }

  /// Create DoctorModel from Firestore document
  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'doctor',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      isVerified: map['isVerified'] ?? false,
      additionalInfo: map['additionalInfo'],
      medicalLicenseNumber: map['medicalLicenseNumber'],
      specialty: map['specialty'],
      subSpecialties: List<String>.from(map['subSpecialties'] ?? []),
      qualification: map['qualification'],
      degrees: List<String>.from(map['degrees'] ?? []),
      experienceYears: map['experienceYears'],
      clinicName: map['clinicName'],
      clinicAddress: map['clinicAddress'],
      city: map['city'],
      state: map['state'],
      pincode: map['pincode'],
      location: map['location'],
      consultationFee: map['consultationFee']?.toDouble(),
      rating: map['rating']?.toDouble(),
      totalReviews: map['totalReviews'],
      languages: List<String>.from(map['languages'] ?? []),
      availability: map['availability'],
      isAvailableOnline: map['isAvailableOnline'],
      isAvailableOffline: map['isAvailableOffline'],
      about: map['about'],
      services: List<String>.from(map['services'] ?? []),
      awards: List<String>.from(map['awards'] ?? []),
      certifications: List<String>.from(map['certifications'] ?? []),
      registrationNumber: map['registrationNumber'],
      licenseExpiryDate: (map['licenseExpiryDate'] as Timestamp?)?.toDate(),
      verificationStatus: map['verificationStatus'],
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'medicalLicenseNumber': medicalLicenseNumber,
      'specialty': specialty,
      'subSpecialties': subSpecialties,
      'qualification': qualification,
      'degrees': degrees,
      'experienceYears': experienceYears,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'location': location,
      'consultationFee': consultationFee,
      'rating': rating,
      'totalReviews': totalReviews,
      'languages': languages,
      'availability': availability,
      'isAvailableOnline': isAvailableOnline,
      'isAvailableOffline': isAvailableOffline,
      'about': about,
      'services': services,
      'awards': awards,
      'certifications': certifications,
      'registrationNumber': registrationNumber,
      'licenseExpiryDate': licenseExpiryDate != null
          ? Timestamp.fromDate(licenseExpiryDate!)
          : null,
      'verificationStatus': verificationStatus,
      'documentUrls': documentUrls,
    });
    return map;
  }

  /// Get formatted experience text
  String get experienceText {
    if (experienceYears == null) return 'Experience not specified';
    if (experienceYears! == 1) return '1 year experience';
    return '$experienceYears years experience';
  }

  /// Get formatted rating text
  String get ratingText {
    if (rating == null) return 'No ratings yet';
    return '${rating!.toStringAsFixed(1)} (${totalReviews ?? 0} reviews)';
  }

  /// Get formatted consultation fee
  String get consultationFeeText {
    if (consultationFee == null) return 'Fee not specified';
    return '₹${consultationFee!.toStringAsFixed(0)}';
  }

  /// Get full address
  String get fullAddress {
    final parts = <String>[];
    if (clinicAddress != null) parts.add(clinicAddress!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (pincode != null) parts.add(pincode!);
    return parts.join(', ');
  }

  /// Check if doctor is available for consultation type
  bool isAvailableFor(String consultationType) {
    switch (consultationType.toLowerCase()) {
      case 'online':
        return isAvailableOnline ?? false;
      case 'offline':
        return isAvailableOffline ?? false;
      default:
        return false;
    }
  }

  /// Get availability for a specific day
  Map<String, dynamic>? getAvailabilityForDay(String day) {
    if (availability == null) return null;
    return availability![day.toLowerCase()];
  }

  /// Check if doctor is available at a specific time
  bool isAvailableAt(String day, String time) {
    final dayAvailability = getAvailabilityForDay(day);
    if (dayAvailability == null || dayAvailability['isAvailable'] != true) {
      return false;
    }

    final slots = dayAvailability['slots'] as List<dynamic>?;
    if (slots == null) return false;

    return slots.contains(time);
  }
}
