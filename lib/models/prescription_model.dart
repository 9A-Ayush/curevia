import 'package:cloud_firestore/cloud_firestore.dart';

/// Prescription model for e-prescriptions
class PrescriptionModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime prescriptionDate;
  final String? diagnosis;
  final String? symptoms;
  final List<PrescribedMedicine> medicines;
  final List<String>? instructions;
  final List<String>? precautions;
  final String? followUpInstructions;
  final DateTime? followUpDate;
  final List<String>? tests; // Recommended tests
  final String? notes;
  final String? pdfUrl; // Generated PDF URL
  final bool? isDigitallySigned;
  final String? digitalSignature;
  final Map<String, dynamic>? additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrescriptionModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.prescriptionDate,
    this.diagnosis,
    this.symptoms,
    required this.medicines,
    this.instructions,
    this.precautions,
    this.followUpInstructions,
    this.followUpDate,
    this.tests,
    this.notes,
    this.pdfUrl,
    this.isDigitallySigned,
    this.digitalSignature,
    this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create PrescriptionModel from Firestore document
  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorSpecialty: map['doctorSpecialty'] ?? '',
      prescriptionDate: (map['prescriptionDate'] as Timestamp).toDate(),
      diagnosis: map['diagnosis'],
      symptoms: map['symptoms'],
      medicines: (map['medicines'] as List<dynamic>?)
              ?.map((m) => PrescribedMedicine.fromMap(m))
              .toList() ??
          [],
      instructions: List<String>.from(map['instructions'] ?? []),
      precautions: List<String>.from(map['precautions'] ?? []),
      followUpInstructions: map['followUpInstructions'],
      followUpDate: (map['followUpDate'] as Timestamp?)?.toDate(),
      tests: List<String>.from(map['tests'] ?? []),
      notes: map['notes'],
      pdfUrl: map['pdfUrl'],
      isDigitallySigned: map['isDigitallySigned'],
      digitalSignature: map['digitalSignature'],
      additionalInfo: map['additionalInfo'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert PrescriptionModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'patientName': patientName,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'prescriptionDate': Timestamp.fromDate(prescriptionDate),
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'instructions': instructions,
      'precautions': precautions,
      'followUpInstructions': followUpInstructions,
      'followUpDate': followUpDate != null ? Timestamp.fromDate(followUpDate!) : null,
      'tests': tests,
      'notes': notes,
      'pdfUrl': pdfUrl,
      'isDigitallySigned': isDigitallySigned,
      'digitalSignature': digitalSignature,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get formatted prescription date
  String get formattedDate {
    final date = prescriptionDate;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Get total number of medicines
  int get medicineCount {
    return medicines.length;
  }

  /// Check if prescription has follow-up
  bool get hasFollowUp {
    return followUpDate != null || followUpInstructions != null;
  }

  /// Check if prescription has tests
  bool get hasTests {
    return tests != null && tests!.isNotEmpty;
  }

  /// Get formatted follow-up date
  String? get formattedFollowUpDate {
    if (followUpDate == null) return null;
    final date = followUpDate!;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  String toString() {
    return 'PrescriptionModel(id: $id, patient: $patientName, doctor: $doctorName, date: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrescriptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Prescribed medicine model
class PrescribedMedicine {
  final String medicineId;
  final String medicineName;
  final String? brandName;
  final String? genericName;
  final String? strength;
  final String? dosageForm;
  final String dosage; // e.g., "1 tablet"
  final String frequency; // e.g., "twice daily"
  final String? timing; // e.g., "after meals"
  final int duration; // in days
  final String? instructions;
  final int? quantity; // total quantity to purchase
  final bool? isSubstitutable;

  const PrescribedMedicine({
    required this.medicineId,
    required this.medicineName,
    this.brandName,
    this.genericName,
    this.strength,
    this.dosageForm,
    required this.dosage,
    required this.frequency,
    this.timing,
    required this.duration,
    this.instructions,
    this.quantity,
    this.isSubstitutable,
  });

  /// Create PrescribedMedicine from Map
  factory PrescribedMedicine.fromMap(Map<String, dynamic> map) {
    return PrescribedMedicine(
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      brandName: map['brandName'],
      genericName: map['genericName'],
      strength: map['strength'],
      dosageForm: map['dosageForm'],
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      timing: map['timing'],
      duration: map['duration'] ?? 0,
      instructions: map['instructions'],
      quantity: map['quantity'],
      isSubstitutable: map['isSubstitutable'],
    );
  }

  /// Convert PrescribedMedicine to Map
  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'brandName': brandName,
      'genericName': genericName,
      'strength': strength,
      'dosageForm': dosageForm,
      'dosage': dosage,
      'frequency': frequency,
      'timing': timing,
      'duration': duration,
      'instructions': instructions,
      'quantity': quantity,
      'isSubstitutable': isSubstitutable,
    };
  }

  /// Get full medicine name with strength
  String get fullName {
    final name = brandName ?? genericName ?? medicineName;
    if (strength != null) {
      return '$name ($strength)';
    }
    return name;
  }

  /// Get complete dosage instruction
  String get completeInstruction {
    final parts = <String>[dosage, frequency];
    if (timing != null) parts.add(timing!);
    if (duration > 0) parts.add('for $duration days');
    return parts.join(' ');
  }

  /// Get formatted duration
  String get formattedDuration {
    if (duration <= 0) return 'As needed';
    if (duration == 1) return '1 day';
    if (duration < 7) return '$duration days';
    if (duration == 7) return '1 week';
    if (duration < 30) {
      final weeks = (duration / 7).floor();
      final remainingDays = duration % 7;
      if (remainingDays == 0) return '${weeks} weeks';
      return '${weeks} weeks ${remainingDays} days';
    }
    if (duration == 30) return '1 month';
    final months = (duration / 30).floor();
    final remainingDays = duration % 30;
    if (remainingDays == 0) return '${months} months';
    return '${months} months ${remainingDays} days';
  }

  @override
  String toString() {
    return 'PrescribedMedicine(name: $medicineName, dosage: $dosage, frequency: $frequency, duration: $duration days)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrescribedMedicine && 
           other.medicineId == medicineId &&
           other.dosage == dosage &&
           other.frequency == frequency &&
           other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(medicineId, dosage, frequency, duration);
}
