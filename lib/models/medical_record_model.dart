import 'package:cloud_firestore/cloud_firestore.dart';

/// Medical record model
class MedicalRecordModel {
  final String id;
  final String title;
  final String type; // 'consultation', 'lab_test', 'prescription', 'vaccination', 'surgery', 'checkup'
  final DateTime recordDate;
  final String? doctorName;
  final String? hospitalName;
  final String? diagnosis;
  final String? treatment;
  final String? prescription;
  final String? notes;
  final List<String> attachments;
  final Map<String, dynamic> vitals; // blood pressure, heart rate, temperature, etc.
  final Map<String, dynamic> labResults; // test results
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalRecordModel({
    required this.id,
    required this.title,
    required this.type,
    required this.recordDate,
    this.doctorName,
    this.hospitalName,
    this.diagnosis,
    this.treatment,
    this.prescription,
    this.notes,
    required this.attachments,
    required this.vitals,
    required this.labResults,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create MedicalRecordModel from Firestore document
  factory MedicalRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicalRecordModel(
      id: id,
      title: map['title'] ?? '',
      type: map['type'] ?? 'consultation',
      recordDate: (map['recordDate'] as Timestamp).toDate(),
      doctorName: map['doctorName'],
      hospitalName: map['hospitalName'],
      diagnosis: map['diagnosis'],
      treatment: map['treatment'],
      prescription: map['prescription'],
      notes: map['notes'],
      attachments: List<String>.from(map['attachments'] ?? []),
      vitals: Map<String, dynamic>.from(map['vitals'] ?? {}),
      labResults: Map<String, dynamic>.from(map['labResults'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert MedicalRecordModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'recordDate': Timestamp.fromDate(recordDate),
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'notes': notes,
      'attachments': attachments,
      'vitals': vitals,
      'labResults': labResults,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of MedicalRecordModel with updated fields
  MedicalRecordModel copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? recordDate,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    List<String>? attachments,
    Map<String, dynamic>? vitals,
    Map<String, dynamic>? labResults,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalRecordModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      recordDate: recordDate ?? this.recordDate,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      vitals: vitals ?? this.vitals,
      labResults: labResults ?? this.labResults,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted date string
  String get formattedDate {
    return '${recordDate.day}/${recordDate.month}/${recordDate.year}';
  }

  /// Get type display name
  String get typeDisplayName {
    switch (type) {
      case 'consultation':
        return 'Consultation';
      case 'lab_test':
        return 'Lab Test';
      case 'prescription':
        return 'Prescription';
      case 'vaccination':
        return 'Vaccination';
      case 'surgery':
        return 'Surgery';
      case 'checkup':
        return 'Checkup';
      case 'emergency':
        return 'Emergency';
      case 'follow_up':
        return 'Follow-up';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case 'consultation':
        return 'medical_services';
      case 'lab_test':
        return 'biotech';
      case 'prescription':
        return 'medication';
      case 'vaccination':
        return 'vaccines';
      case 'surgery':
        return 'healing';
      case 'checkup':
        return 'health_and_safety';
      case 'emergency':
        return 'emergency';
      case 'follow_up':
        return 'follow_the_signs';
      default:
        return 'medical_information';
    }
  }

  /// Check if has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if has vitals
  bool get hasVitals => vitals.isNotEmpty;

  /// Check if has lab results
  bool get hasLabResults => labResults.isNotEmpty;

  /// Get summary text
  String get summary {
    final parts = <String>[];
    if (diagnosis != null && diagnosis!.isNotEmpty) {
      parts.add('Diagnosis: $diagnosis');
    }
    if (treatment != null && treatment!.isNotEmpty) {
      parts.add('Treatment: $treatment');
    }
    if (prescription != null && prescription!.isNotEmpty) {
      parts.add('Prescription: $prescription');
    }
    return parts.isEmpty ? 'No summary available' : parts.join(' • ');
  }

  /// Get vital signs summary
  String get vitalsSummary {
    if (!hasVitals) return 'No vitals recorded';
    
    final parts = <String>[];
    if (vitals['bloodPressure'] != null) {
      parts.add('BP: ${vitals['bloodPressure']}');
    }
    if (vitals['heartRate'] != null) {
      parts.add('HR: ${vitals['heartRate']} bpm');
    }
    if (vitals['temperature'] != null) {
      parts.add('Temp: ${vitals['temperature']}°F');
    }
    if (vitals['weight'] != null) {
      parts.add('Weight: ${vitals['weight']} kg');
    }
    
    return parts.isEmpty ? 'No vitals recorded' : parts.join(' • ');
  }

  @override
  String toString() {
    return 'MedicalRecordModel(id: $id, title: $title, type: $type, date: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicalRecordModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
