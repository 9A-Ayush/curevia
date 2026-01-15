import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for managing secure medical record sharing during appointments
class MedicalRecordSharing {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final List<String> sharedRecordIds;
  final List<String> sharedAllergies;
  final List<String> sharedMedications;
  final Map<String, dynamic> sharedVitals;
  final String sharingStatus; // 'pending', 'active', 'expired', 'revoked'
  final DateTime sharedAt;
  final DateTime? expiresAt;
  final DateTime? accessedAt;
  final DateTime? revokedAt;
  final String? revokedBy;
  final Map<String, dynamic> accessLog;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalRecordSharing({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.sharedRecordIds,
    required this.sharedAllergies,
    required this.sharedMedications,
    required this.sharedVitals,
    required this.sharingStatus,
    required this.sharedAt,
    this.expiresAt,
    this.accessedAt,
    this.revokedAt,
    this.revokedBy,
    required this.accessLog,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory MedicalRecordSharing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecordSharing(
      id: doc.id,
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      sharedRecordIds: List<String>.from(data['sharedRecordIds'] ?? []),
      sharedAllergies: List<String>.from(data['sharedAllergies'] ?? []),
      sharedMedications: List<String>.from(data['sharedMedications'] ?? []),
      sharedVitals: Map<String, dynamic>.from(data['sharedVitals'] ?? {}),
      sharingStatus: data['sharingStatus'] ?? 'pending',
      sharedAt: (data['sharedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      accessedAt: (data['accessedAt'] as Timestamp?)?.toDate(),
      revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
      revokedBy: data['revokedBy'],
      accessLog: Map<String, dynamic>.from(data['accessLog'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'sharedRecordIds': sharedRecordIds,
      'sharedAllergies': sharedAllergies,
      'sharedMedications': sharedMedications,
      'sharedVitals': sharedVitals,
      'sharingStatus': sharingStatus,
      'sharedAt': Timestamp.fromDate(sharedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'accessedAt': accessedAt != null ? Timestamp.fromDate(accessedAt!) : null,
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
      'revokedBy': revokedBy,
      'accessLog': accessLog,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if sharing is currently valid
  bool get isValidForAccess {
    if (!isActive || sharingStatus != 'active') return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Get formatted sharing summary
  String get sharingSummary {
    final items = <String>[];
    if (sharedRecordIds.isNotEmpty) items.add('${sharedRecordIds.length} medical reports');
    if (sharedAllergies.isNotEmpty) items.add('${sharedAllergies.length} allergies');
    if (sharedMedications.isNotEmpty) items.add('${sharedMedications.length} medications');
    if (sharedVitals.isNotEmpty) items.add('vital signs');
    
    return items.isEmpty ? 'No records shared' : items.join(', ');
  }

  /// Copy with updated fields
  MedicalRecordSharing copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? doctorId,
    List<String>? sharedRecordIds,
    List<String>? sharedAllergies,
    List<String>? sharedMedications,
    Map<String, dynamic>? sharedVitals,
    String? sharingStatus,
    DateTime? sharedAt,
    DateTime? expiresAt,
    DateTime? accessedAt,
    DateTime? revokedAt,
    String? revokedBy,
    Map<String, dynamic>? accessLog,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalRecordSharing(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      sharedRecordIds: sharedRecordIds ?? this.sharedRecordIds,
      sharedAllergies: sharedAllergies ?? this.sharedAllergies,
      sharedMedications: sharedMedications ?? this.sharedMedications,
      sharedVitals: sharedVitals ?? this.sharedVitals,
      sharingStatus: sharingStatus ?? this.sharingStatus,
      sharedAt: sharedAt ?? this.sharedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      accessedAt: accessedAt ?? this.accessedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedBy: revokedBy ?? this.revokedBy,
      accessLog: accessLog ?? this.accessLog,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for patient allergies
class PatientAllergy {
  final String id;
  final String patientId;
  final String allergen;
  final String severity; // 'mild', 'moderate', 'severe'
  final String reaction;
  final DateTime? firstOccurrence;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientAllergy({
    required this.id,
    required this.patientId,
    required this.allergen,
    required this.severity,
    required this.reaction,
    this.firstOccurrence,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientAllergy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientAllergy(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      allergen: data['allergen'] ?? '',
      severity: data['severity'] ?? 'mild',
      reaction: data['reaction'] ?? '',
      firstOccurrence: (data['firstOccurrence'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory PatientAllergy.fromMap(Map<String, dynamic> map) {
    return PatientAllergy(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      allergen: map['allergen'] ?? '',
      severity: map['severity'] ?? 'mild',
      reaction: map['reaction'] ?? '',
      firstOccurrence: (map['firstOccurrence'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'allergen': allergen,
      'severity': severity,
      'reaction': reaction,
      'firstOccurrence': firstOccurrence != null ? Timestamp.fromDate(firstOccurrence!) : null,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'allergen': allergen,
      'severity': severity,
      'reaction': reaction,
      'firstOccurrence': firstOccurrence != null ? Timestamp.fromDate(firstOccurrence!) : null,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Model for patient medications
class PatientMedication {
  final String id;
  final String patientId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final String route; // 'oral', 'injection', 'topical', etc.
  final DateTime startDate;
  final DateTime? endDate;
  final String? prescribedBy;
  final String? reason;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientMedication({
    required this.id,
    required this.patientId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.route,
    required this.startDate,
    this.endDate,
    this.prescribedBy,
    this.reason,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientMedication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientMedication(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      route: data['route'] ?? 'oral',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      prescribedBy: data['prescribedBy'],
      reason: data['reason'],
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory PatientMedication.fromMap(Map<String, dynamic> map) {
    return PatientMedication(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      route: map['route'] ?? 'oral',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      prescribedBy: map['prescribedBy'],
      reason: map['reason'],
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'route': route,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'prescribedBy': prescribedBy,
      'reason': reason,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'route': route,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'prescribedBy': prescribedBy,
      'reason': reason,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if medication is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }
}

/// Access log entry for tracking record access
class RecordAccessLog {
  final String id;
  final String sharingId;
  final String accessedBy;
  final String accessType; // 'view', 'download_attempt', 'screenshot_attempt'
  final DateTime accessTime;
  final String? deviceInfo;
  final String? ipAddress;
  final bool wasBlocked;
  final String? blockReason;

  const RecordAccessLog({
    required this.id,
    required this.sharingId,
    required this.accessedBy,
    required this.accessType,
    required this.accessTime,
    this.deviceInfo,
    this.ipAddress,
    required this.wasBlocked,
    this.blockReason,
  });

  factory RecordAccessLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordAccessLog(
      id: doc.id,
      sharingId: data['sharingId'] ?? '',
      accessedBy: data['accessedBy'] ?? '',
      accessType: data['accessType'] ?? 'view',
      accessTime: (data['accessTime'] as Timestamp).toDate(),
      deviceInfo: data['deviceInfo'],
      ipAddress: data['ipAddress'],
      wasBlocked: data['wasBlocked'] ?? false,
      blockReason: data['blockReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sharingId': sharingId,
      'accessedBy': accessedBy,
      'accessType': accessType,
      'accessTime': Timestamp.fromDate(accessTime),
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'wasBlocked': wasBlocked,
      'blockReason': blockReason,
    };
  }
}