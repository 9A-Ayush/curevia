import 'package:cloud_firestore/cloud_firestore.dart';

/// Medical document model for patient reports and files
class MedicalDocument {
  final String id;
  final String patientId;
  final String fileName;
  final String originalFileName;
  final String fileUrl;
  final String? cloudinaryPublicId; // Cloudinary public ID for file management
  final String fileType;
  final int fileSizeBytes;
  final DocumentType documentType;
  final DocumentCategory category;
  final DateTime uploadedAt;
  final DateTime? reportDate;
  final String? uploadedBy; // Doctor ID or patient ID
  final String? doctorId;
  final String? appointmentId;
  final String? description;
  final String? notes;
  final List<String> tags;
  final DocumentStatus status;
  final Map<String, dynamic>? metadata;
  final bool isSharedWithDoctor;
  final DateTime? lastViewedAt;
  final int viewCount;

  const MedicalDocument({
    required this.id,
    required this.patientId,
    required this.fileName,
    required this.originalFileName,
    required this.fileUrl,
    this.cloudinaryPublicId,
    required this.fileType,
    required this.fileSizeBytes,
    required this.documentType,
    required this.category,
    required this.uploadedAt,
    this.reportDate,
    this.uploadedBy,
    this.doctorId,
    this.appointmentId,
    this.description,
    this.notes,
    this.tags = const [],
    this.status = DocumentStatus.active,
    this.metadata,
    this.isSharedWithDoctor = false,
    this.lastViewedAt,
    this.viewCount = 0,
  });

  /// Create MedicalDocument from Firestore document
  factory MedicalDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalDocument(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      fileName: data['fileName'] ?? '',
      originalFileName: data['originalFileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      cloudinaryPublicId: data['cloudinaryPublicId'],
      fileType: data['fileType'] ?? '',
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      documentType: DocumentType.values.firstWhere(
        (e) => e.toString() == data['documentType'],
        orElse: () => DocumentType.other,
      ),
      category: DocumentCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => DocumentCategory.general,
      ),
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportDate: (data['reportDate'] as Timestamp?)?.toDate(),
      uploadedBy: data['uploadedBy'],
      doctorId: data['doctorId'],
      appointmentId: data['appointmentId'],
      description: data['description'],
      notes: data['notes'],
      tags: List<String>.from(data['tags'] ?? []),
      status: DocumentStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => DocumentStatus.active,
      ),
      metadata: data['metadata'],
      isSharedWithDoctor: data['isSharedWithDoctor'] ?? false,
      lastViewedAt: (data['lastViewedAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] ?? 0,
    );
  }

  /// Convert MedicalDocument to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'fileName': fileName,
      'originalFileName': originalFileName,
      'fileUrl': fileUrl,
      'cloudinaryPublicId': cloudinaryPublicId,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'documentType': documentType.toString(),
      'category': category.toString(),
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'reportDate': reportDate != null ? Timestamp.fromDate(reportDate!) : null,
      'uploadedBy': uploadedBy,
      'doctorId': doctorId,
      'appointmentId': appointmentId,
      'description': description,
      'notes': notes,
      'tags': tags,
      'status': status.toString(),
      'metadata': metadata,
      'isSharedWithDoctor': isSharedWithDoctor,
      'lastViewedAt': lastViewedAt != null ? Timestamp.fromDate(lastViewedAt!) : null,
      'viewCount': viewCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  MedicalDocument copyWith({
    String? id,
    String? patientId,
    String? fileName,
    String? originalFileName,
    String? fileUrl,
    String? cloudinaryPublicId,
    String? fileType,
    int? fileSizeBytes,
    DocumentType? documentType,
    DocumentCategory? category,
    DateTime? uploadedAt,
    DateTime? reportDate,
    String? uploadedBy,
    String? doctorId,
    String? appointmentId,
    String? description,
    String? notes,
    List<String>? tags,
    DocumentStatus? status,
    Map<String, dynamic>? metadata,
    bool? isSharedWithDoctor,
    DateTime? lastViewedAt,
    int? viewCount,
  }) {
    return MedicalDocument(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      fileUrl: fileUrl ?? this.fileUrl,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      documentType: documentType ?? this.documentType,
      category: category ?? this.category,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reportDate: reportDate ?? this.reportDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      doctorId: doctorId ?? this.doctorId,
      appointmentId: appointmentId ?? this.appointmentId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      isSharedWithDoctor: isSharedWithDoctor ?? this.isSharedWithDoctor,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  String toString() {
    return 'MedicalDocument(id: $id, fileName: $fileName, documentType: $documentType, category: $category)';
  }
}

/// Document types for medical files
enum DocumentType {
  pdf,
  image,
  video,
  audio,
  text,
  other,
}

/// Document categories for organization
enum DocumentCategory {
  labReport,
  xray,
  mri,
  ctScan,
  ultrasound,
  prescription,
  discharge,
  consultation,
  insurance,
  vaccination,
  general,
  other,
}

/// Document status
enum DocumentStatus {
  active,
  archived,
  deleted,
  processing,
}

/// Extensions for enums
extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.pdf:
        return 'PDF Document';
      case DocumentType.image:
        return 'Image';
      case DocumentType.video:
        return 'Video';
      case DocumentType.audio:
        return 'Audio';
      case DocumentType.text:
        return 'Text Document';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DocumentType.pdf:
        return '📄';
      case DocumentType.image:
        return '🖼️';
      case DocumentType.video:
        return '🎥';
      case DocumentType.audio:
        return '🎵';
      case DocumentType.text:
        return '📝';
      case DocumentType.other:
        return '📁';
    }
  }

  List<String> get allowedExtensions {
    switch (this) {
      case DocumentType.pdf:
        return ['pdf'];
      case DocumentType.image:
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
      case DocumentType.video:
        return ['mp4', 'avi', 'mov', 'wmv', 'flv'];
      case DocumentType.audio:
        return ['mp3', 'wav', 'aac', 'm4a'];
      case DocumentType.text:
        return ['txt', 'doc', 'docx'];
      case DocumentType.other:
        return [];
    }
  }
}

extension DocumentCategoryExtension on DocumentCategory {
  String get displayName {
    switch (this) {
      case DocumentCategory.labReport:
        return 'Lab Report';
      case DocumentCategory.xray:
        return 'X-Ray';
      case DocumentCategory.mri:
        return 'MRI Scan';
      case DocumentCategory.ctScan:
        return 'CT Scan';
      case DocumentCategory.ultrasound:
        return 'Ultrasound';
      case DocumentCategory.prescription:
        return 'Prescription';
      case DocumentCategory.discharge:
        return 'Discharge Summary';
      case DocumentCategory.consultation:
        return 'Consultation Report';
      case DocumentCategory.insurance:
        return 'Insurance Document';
      case DocumentCategory.vaccination:
        return 'Vaccination Record';
      case DocumentCategory.general:
        return 'General';
      case DocumentCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DocumentCategory.labReport:
        return '🧪';
      case DocumentCategory.xray:
        return '🦴';
      case DocumentCategory.mri:
        return '🧠';
      case DocumentCategory.ctScan:
        return '💀';
      case DocumentCategory.ultrasound:
        return '👶';
      case DocumentCategory.prescription:
        return '💊';
      case DocumentCategory.discharge:
        return '🏥';
      case DocumentCategory.consultation:
        return '👨‍⚕️';
      case DocumentCategory.insurance:
        return '🛡️';
      case DocumentCategory.vaccination:
        return '💉';
      case DocumentCategory.general:
        return '📋';
      case DocumentCategory.other:
        return '📁';
    }
  }
}

/// Document statistics for analytics
class DocumentStatistics {
  final int totalDocuments;
  final int totalSizeBytes;
  final Map<DocumentCategory, int> categoryCount;
  final Map<DocumentType, int> typeCount;
  final DateTime? lastUploadDate;
  final DateTime? oldestDocumentDate;

  const DocumentStatistics({
    required this.totalDocuments,
    required this.totalSizeBytes,
    required this.categoryCount,
    required this.typeCount,
    this.lastUploadDate,
    this.oldestDocumentDate,
  });

  String get totalSizeFormatted {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    if (totalSizeBytes < 1024 * 1024 * 1024) return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}