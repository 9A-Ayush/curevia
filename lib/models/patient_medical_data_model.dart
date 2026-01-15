import 'package:cloud_firestore/cloud_firestore.dart';
import 'medical_record_model.dart';
import 'medical_record_sharing_model.dart';

/// Comprehensive patient medical data model for secure doctor viewing
class PatientMedicalData {
  final String patientId;
  final String patientName;
  final String? profileImageUrl;
  final PatientBasicInfo basicInfo;
  final List<MedicalRecordModel> medicalRecords;
  final List<PatientAllergy> allergies;
  final List<PatientMedication> currentMedications;
  final PatientVitals? latestVitals;
  final List<PatientVitals> vitalsHistory;
  final DateTime lastUpdated;

  const PatientMedicalData({
    required this.patientId,
    required this.patientName,
    this.profileImageUrl,
    required this.basicInfo,
    required this.medicalRecords,
    required this.allergies,
    required this.currentMedications,
    this.latestVitals,
    required this.vitalsHistory,
    required this.lastUpdated,
  });

  /// Create from Firestore data
  factory PatientMedicalData.fromFirestore(Map<String, dynamic> data) {
    return PatientMedicalData(
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      basicInfo: PatientBasicInfo.fromMap(data['basicInfo'] ?? {}),
      medicalRecords: (data['medicalRecords'] as List<dynamic>? ?? [])
          .map((record) => MedicalRecordModel.fromMap(record, record['id'] ?? ''))
          .toList(),
      allergies: (data['allergies'] as List<dynamic>? ?? [])
          .map((allergy) => PatientAllergy.fromMap(allergy))
          .toList(),
      currentMedications: (data['currentMedications'] as List<dynamic>? ?? [])
          .map((medication) => PatientMedication.fromMap(medication))
          .toList(),
      latestVitals: data['latestVitals'] != null 
          ? PatientVitals.fromMap(data['latestVitals'])
          : null,
      vitalsHistory: (data['vitalsHistory'] as List<dynamic>? ?? [])
          .map((vitals) => PatientVitals.fromMap(vitals))
          .toList(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'profileImageUrl': profileImageUrl,
      'basicInfo': basicInfo.toMap(),
      'medicalRecords': medicalRecords.map((record) => record.toMap()).toList(),
      'allergies': allergies.map((allergy) => allergy.toMap()).toList(),
      'currentMedications': currentMedications.map((medication) => medication.toMap()).toList(),
      'latestVitals': latestVitals?.toMap(),
      'vitalsHistory': vitalsHistory.map((vitals) => vitals.toMap()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Get medical summary
  String get medicalSummary {
    final parts = <String>[];
    if (allergies.isNotEmpty) {
      parts.add('${allergies.length} known allergies');
    }
    if (currentMedications.isNotEmpty) {
      parts.add('${currentMedications.length} current medications');
    }
    if (medicalRecords.isNotEmpty) {
      parts.add('${medicalRecords.length} medical records');
    }
    return parts.isEmpty ? 'No medical data available' : parts.join(' • ');
  }

  /// Get critical alerts
  List<String> get criticalAlerts {
    final alerts = <String>[];
    
    // Check for severe allergies
    final severeAllergies = allergies.where((a) => a.severity == 'severe').toList();
    if (severeAllergies.isNotEmpty) {
      alerts.add('SEVERE ALLERGIES: ${severeAllergies.map((a) => a.allergen).join(', ')}');
    }
    
    // Check for critical medications
    final criticalMeds = currentMedications.where((m) => 
        m.medicationName.toLowerCase().contains('warfarin') ||
        m.medicationName.toLowerCase().contains('insulin') ||
        m.medicationName.toLowerCase().contains('digoxin')
    ).toList();
    if (criticalMeds.isNotEmpty) {
      alerts.add('CRITICAL MEDICATIONS: ${criticalMeds.map((m) => m.medicationName).join(', ')}');
    }
    
    // Check for abnormal vitals
    if (latestVitals != null) {
      final vitals = latestVitals!;
      if (vitals.systolicBP != null && (vitals.systolicBP! > 180 || vitals.systolicBP! < 90)) {
        alerts.add('ABNORMAL BP: ${vitals.bloodPressure}');
      }
      if (vitals.heartRate != null && (vitals.heartRate! > 100 || vitals.heartRate! < 60)) {
        alerts.add('ABNORMAL HR: ${vitals.heartRate} bpm');
      }
    }
    
    return alerts;
  }
}

/// Patient basic information model
class PatientBasicInfo {
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final double? height; // in cm
  final double? weight; // in kg
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final List<String> medicalHistory;

  const PatientBasicInfo({
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.height,
    this.weight,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.medicalHistory,
  });

  factory PatientBasicInfo.fromMap(Map<String, dynamic> map) {
    return PatientBasicInfo(
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: map['gender'],
      bloodGroup: map['bloodGroup'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      emergencyContactName: map['emergencyContactName'],
      emergencyContactPhone: map['emergencyContactPhone'],
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'height': height,
      'weight': weight,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'medicalHistory': medicalHistory,
    };
  }

  /// Calculate age
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

/// Enhanced patient vitals model
class PatientVitals {
  final String id;
  final String patientId;
  final double? systolicBP;
  final double? diastolicBP;
  final int? heartRate;
  final double? temperature; // in Celsius
  final double? weight; // in kg
  final double? height; // in cm
  final int? respiratoryRate;
  final double? oxygenSaturation;
  final double? bloodSugar; // in mg/dL
  final String? notes;
  final String? recordedBy; // Doctor/Nurse ID
  final DateTime recordedAt;
  final DateTime createdAt;

  const PatientVitals({
    required this.id,
    required this.patientId,
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.bloodSugar,
    this.notes,
    this.recordedBy,
    required this.recordedAt,
    required this.createdAt,
  });

  factory PatientVitals.fromMap(Map<String, dynamic> map) {
    return PatientVitals(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      systolicBP: map['systolicBP']?.toDouble(),
      diastolicBP: map['diastolicBP']?.toDouble(),
      heartRate: map['heartRate'],
      temperature: map['temperature']?.toDouble(),
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      respiratoryRate: map['respiratoryRate'],
      oxygenSaturation: map['oxygenSaturation']?.toDouble(),
      bloodSugar: map['bloodSugar']?.toDouble(),
      notes: map['notes'],
      recordedBy: map['recordedBy'],
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'temperature': temperature,
      'weight': weight,
      'height': height,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'bloodSugar': bloodSugar,
      'notes': notes,
      'recordedBy': recordedBy,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get blood pressure string
  String? get bloodPressure {
    if (systolicBP == null || diastolicBP == null) return null;
    return '${systolicBP!.toInt()}/${diastolicBP!.toInt()}';
  }

  /// Get temperature in Fahrenheit
  double? get temperatureFahrenheit {
    if (temperature == null) return null;
    return (temperature! * 9/5) + 32;
  }

  /// Check if vitals are normal
  bool get areVitalsNormal {
    // Basic normal ranges
    if (systolicBP != null && (systolicBP! < 90 || systolicBP! > 140)) return false;
    if (diastolicBP != null && (diastolicBP! < 60 || diastolicBP! > 90)) return false;
    if (heartRate != null && (heartRate! < 60 || heartRate! > 100)) return false;
    if (temperature != null && (temperature! < 36.1 || temperature! > 37.2)) return false;
    if (oxygenSaturation != null && oxygenSaturation! < 95) return false;
    return true;
  }

  /// Get formatted date
  String get formattedDate {
    return '${recordedAt.day}/${recordedAt.month}/${recordedAt.year} ${recordedAt.hour}:${recordedAt.minute.toString().padLeft(2, '0')}';
  }
}