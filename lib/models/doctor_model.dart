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
  final double? averageRating; // New field for calculated average
  final int? totalRatings; // New field for total number of ratings
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
  final String? verificationReason; // Reason for rejection
  final List<String>? documentUrls; // License, certificates, etc.
  final bool profileComplete; // Profile setup completed
  final int onboardingStep; // Current onboarding step (0-7)
  final DateTime? dateOfBirth;
  final String? gender;
  final double? offlineConsultationFee;
  final int? consultationDuration; // in minutes
  final String? medicalCouncil;
  final List<String>? conditionsTreated;
  final List<String>? memberships;
  final Map<String, dynamic>? bankDetails; // Encrypted bank info

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
    this.averageRating,
    this.totalRatings,
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
    this.verificationReason,
    this.documentUrls,
    this.profileComplete = false,
    this.onboardingStep = 0,
    this.dateOfBirth,
    this.gender,
    this.offlineConsultationFee,
    this.consultationDuration,
    this.medicalCouncil,
    this.conditionsTreated,
    this.memberships,
    this.bankDetails,
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
      averageRating: doctorData['averageRating']?.toDouble(),
      totalRatings: doctorData['totalRatings'],
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
      verificationReason: doctorData['verificationReason'],
      documentUrls: List<String>.from(doctorData['documentUrls'] ?? []),
      profileComplete: doctorData['profileComplete'] ?? false,
      onboardingStep: doctorData['onboardingStep'] ?? 0,
      dateOfBirth: (doctorData['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: doctorData['gender'],
      offlineConsultationFee: doctorData['offlineConsultationFee']?.toDouble(),
      consultationDuration: doctorData['consultationDuration'],
      medicalCouncil: doctorData['medicalCouncil'],
      conditionsTreated:
          List<String>.from(doctorData['conditionsTreated'] ?? []),
      memberships: List<String>.from(doctorData['memberships'] ?? []),
      bankDetails: doctorData['bankDetails'],
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
      averageRating: map['averageRating']?.toDouble(),
      totalRatings: map['totalRatings'],
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
      verificationReason: map['verificationReason'],
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
      profileComplete: map['profileComplete'] ?? false,
      onboardingStep: map['onboardingStep'] ?? 0,
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: map['gender'],
      offlineConsultationFee: map['offlineConsultationFee']?.toDouble(),
      consultationDuration: map['consultationDuration'],
      medicalCouncil: map['medicalCouncil'],
      conditionsTreated: List<String>.from(map['conditionsTreated'] ?? []),
      memberships: List<String>.from(map['memberships'] ?? []),
      bankDetails: map['bankDetails'],
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
      'averageRating': averageRating,
      'totalRatings': totalRatings,
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
      'verificationReason': verificationReason,
      'documentUrls': documentUrls,
      'profileComplete': profileComplete,
      'onboardingStep': onboardingStep,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'offlineConsultationFee': offlineConsultationFee,
      'consultationDuration': consultationDuration,
      'medicalCouncil': medicalCouncil,
      'conditionsTreated': conditionsTreated,
      'memberships': memberships,
      'bankDetails': bankDetails,
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
    final displayRating = averageRating ?? rating;
    final displayCount = totalRatings ?? totalReviews ?? 0;
    
    if (displayRating == null) return 'No ratings yet';
    return '${displayRating.toStringAsFixed(1)} (${displayCount} rating${displayCount == 1 ? '' : 's'})';
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

  /// Get profile completion percentage
  int get profileCompletionPercentage {
    int completed = 0;
    const int totalFields = 20;

    if (fullName.isNotEmpty) completed++;
    if (profileImageUrl != null) completed++;
    if (dateOfBirth != null) completed++;
    if (gender != null) completed++;
    if (phoneNumber != null) completed++;
    if (medicalLicenseNumber != null) completed++;
    if (specialty != null) completed++;
    if (experienceYears != null) completed++;
    if (qualification != null) completed++;
    if (clinicName != null) completed++;
    if (clinicAddress != null) completed++;
    if (city != null) completed++;
    if (consultationFee != null) completed++;
    if (offlineConsultationFee != null) completed++;
    if (languages != null && languages!.isNotEmpty) completed++;
    if (availability != null && availability!.isNotEmpty) completed++;
    if (about != null) completed++;
    if (services != null && services!.isNotEmpty) completed++;
    if (registrationNumber != null) completed++;
    if (bankDetails != null) completed++;

    return ((completed / totalFields) * 100).round();
  }

  /// Check if basic info is complete
  bool get isBasicInfoComplete {
    return fullName.isNotEmpty &&
        phoneNumber != null &&
        dateOfBirth != null &&
        gender != null;
  }

  /// Check if professional details are complete
  bool get isProfessionalDetailsComplete {
    return medicalLicenseNumber != null &&
        specialty != null &&
        experienceYears != null &&
        qualification != null &&
        registrationNumber != null;
  }

  /// Check if practice info is complete
  bool get isPracticeInfoComplete {
    return clinicName != null &&
        clinicAddress != null &&
        city != null &&
        state != null &&
        consultationFee != null;
  }

  /// Check if availability is set
  bool get isAvailabilitySet {
    return availability != null && availability!.isNotEmpty;
  }

  /// Check if bank details are provided
  bool get isBankDetailsProvided {
    return bankDetails != null && bankDetails!.isNotEmpty;
  }

  /// Get verification status display text
  String get verificationStatusText {
    switch (verificationStatus?.toLowerCase()) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending Verification';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'Not Submitted';
    }
  }

  /// Check if doctor can access full features
  bool get canAccessFullFeatures {
    return profileComplete && verificationStatus == 'verified';
  }

  /// Copy with method for updating doctor model
  DoctorModel copyWith({
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
    String? medicalLicenseNumber,
    String? specialty,
    List<String>? subSpecialties,
    String? qualification,
    List<String>? degrees,
    int? experienceYears,
    String? clinicName,
    String? clinicAddress,
    String? city,
    String? state,
    String? pincode,
    GeoPoint? location,
    double? consultationFee,
    double? rating,
    int? totalReviews,
    double? averageRating,
    int? totalRatings,
    List<String>? languages,
    Map<String, dynamic>? availability,
    bool? isAvailableOnline,
    bool? isAvailableOffline,
    String? about,
    List<String>? services,
    List<String>? awards,
    List<String>? certifications,
    String? registrationNumber,
    DateTime? licenseExpiryDate,
    String? verificationStatus,
    String? verificationReason,
    List<String>? documentUrls,
    bool? profileComplete,
    int? onboardingStep,
    DateTime? dateOfBirth,
    String? gender,
    double? offlineConsultationFee,
    int? consultationDuration,
    String? medicalCouncil,
    List<String>? conditionsTreated,
    List<String>? memberships,
    Map<String, dynamic>? bankDetails,
  }) {
    return DoctorModel(
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
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      specialty: specialty ?? this.specialty,
      subSpecialties: subSpecialties ?? this.subSpecialties,
      qualification: qualification ?? this.qualification,
      degrees: degrees ?? this.degrees,
      experienceYears: experienceYears ?? this.experienceYears,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      location: location ?? this.location,
      consultationFee: consultationFee ?? this.consultationFee,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      languages: languages ?? this.languages,
      availability: availability ?? this.availability,
      isAvailableOnline: isAvailableOnline ?? this.isAvailableOnline,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
      about: about ?? this.about,
      services: services ?? this.services,
      awards: awards ?? this.awards,
      certifications: certifications ?? this.certifications,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationReason: verificationReason ?? this.verificationReason,
      documentUrls: documentUrls ?? this.documentUrls,
      profileComplete: profileComplete ?? this.profileComplete,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      offlineConsultationFee:
          offlineConsultationFee ?? this.offlineConsultationFee,
      consultationDuration: consultationDuration ?? this.consultationDuration,
      medicalCouncil: medicalCouncil ?? this.medicalCouncil,
      conditionsTreated: conditionsTreated ?? this.conditionsTreated,
      memberships: memberships ?? this.memberships,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}
