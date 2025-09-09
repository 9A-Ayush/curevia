import 'dart:convert';
import 'dart:io';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import '../../utils/env_config.dart';

/// Service for Google Cloud Vision API integration
class GoogleVisionService {
  static vision.VisionApi? _visionApi;
  static AutoRefreshingAuthClient? _authClient;

  /// Initialize Google Cloud Vision API
  static Future<void> initialize() async {
    try {
      // Create service account credentials from environment
      final serviceAccountJson = EnvConfig.googleCloudServiceAccount;
      if (serviceAccountJson.isEmpty) {
        throw Exception(
          'Google Cloud service account credentials not configured',
        );
      }

      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(serviceAccountJson),
      );

      _authClient = await clientViaServiceAccount(credentials, [
        vision.VisionApi.cloudPlatformScope,
      ]);

      _visionApi = vision.VisionApi(_authClient!);
    } catch (e) {
      throw Exception('Failed to initialize Google Vision API: $e');
    }
  }

  /// Extract text from medical report image
  static Future<MedicalReportData> extractMedicalReportData(
    File imageFile,
  ) async {
    try {
      if (_visionApi == null) {
        await initialize();
      }

      // Read image file
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Create vision request
      final request = vision.BatchAnnotateImagesRequest()
        ..requests = [
          vision.AnnotateImageRequest()
            ..image = (vision.Image()..content = base64Image)
            ..features = [
              vision.Feature()..type = 'TEXT_DETECTION',
              vision.Feature()..type = 'DOCUMENT_TEXT_DETECTION',
            ],
        ];

      // Call Vision API
      final response = await _visionApi!.images.annotate(request);

      if (response.responses == null || response.responses!.isEmpty) {
        throw Exception('No response from Vision API');
      }

      final annotation = response.responses!.first;

      if (annotation.error != null) {
        throw Exception('Vision API error: ${annotation.error!.message}');
      }

      // Extract text
      final extractedText = annotation.fullTextAnnotation?.text ?? '';

      if (extractedText.isEmpty) {
        throw Exception('No text found in the image');
      }

      // Parse medical report data
      return _parseMedicalReportText(extractedText);
    } catch (e) {
      throw Exception('Failed to extract medical report data: $e');
    }
  }

  /// Parse extracted text into structured medical report data
  static MedicalReportData _parseMedicalReportText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? patientName;
    String? doctorName;
    String? hospitalName;
    DateTime? reportDate;
    String? diagnosis;
    String? treatment;
    String? prescription;
    Map<String, String> labResults = {};
    Map<String, String> vitals = {};
    List<String> medications = [];
    String? notes;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      final originalLine = lines[i];

      // Extract patient name
      if (line.contains('patient') && line.contains('name')) {
        patientName =
            _extractValueAfterColon(originalLine) ??
            (i + 1 < lines.length ? lines[i + 1] : null);
      }

      // Extract doctor name
      if (line.contains('doctor') ||
          line.contains('physician') ||
          line.contains('dr.')) {
        doctorName = _extractValueAfterColon(originalLine) ?? originalLine;
      }

      // Extract hospital/clinic name
      if (line.contains('hospital') ||
          line.contains('clinic') ||
          line.contains('medical center')) {
        hospitalName = originalLine;
      }

      // Extract date
      if (line.contains('date') && !line.contains('birth')) {
        final dateStr = _extractValueAfterColon(originalLine);
        if (dateStr != null) {
          reportDate = _parseDate(dateStr);
        }
      }

      // Extract diagnosis
      if (line.contains('diagnosis') || line.contains('impression')) {
        diagnosis =
            _extractValueAfterColon(originalLine) ??
            (i + 1 < lines.length ? lines[i + 1] : null);
      }

      // Extract treatment
      if (line.contains('treatment') || line.contains('plan')) {
        treatment =
            _extractValueAfterColon(originalLine) ??
            (i + 1 < lines.length ? lines[i + 1] : null);
      }

      // Extract prescription
      if (line.contains('prescription') || line.contains('medication')) {
        prescription = _extractValueAfterColon(originalLine);
        if (prescription == null && i + 1 < lines.length) {
          // Look for medications in following lines
          for (int j = i + 1; j < lines.length && j < i + 5; j++) {
            if (lines[j].toLowerCase().contains('mg') ||
                lines[j].toLowerCase().contains('tablet') ||
                lines[j].toLowerCase().contains('capsule')) {
              medications.add(lines[j]);
            }
          }
        }
      }

      // Extract vital signs
      if (line.contains('blood pressure') || line.contains('bp')) {
        final value =
            _extractValueAfterColon(originalLine) ??
            _extractNumbers(originalLine);
        if (value != null) vitals['blood_pressure'] = value;
      }
      if (line.contains('heart rate') || line.contains('pulse')) {
        final value =
            _extractValueAfterColon(originalLine) ??
            _extractNumbers(originalLine);
        if (value != null) vitals['heart_rate'] = value;
      }
      if (line.contains('temperature')) {
        final value =
            _extractValueAfterColon(originalLine) ??
            _extractNumbers(originalLine);
        if (value != null) vitals['temperature'] = value;
      }
      if (line.contains('weight')) {
        final value =
            _extractValueAfterColon(originalLine) ??
            _extractNumbers(originalLine);
        if (value != null) vitals['weight'] = value;
      }

      // Extract lab results
      if (line.contains('hemoglobin') || line.contains('hb')) {
        final value = _extractNumbers(originalLine);
        if (value != null) labResults['hemoglobin'] = value;
      }
      if (line.contains('glucose') || line.contains('sugar')) {
        final value = _extractNumbers(originalLine);
        if (value != null) labResults['glucose'] = value;
      }
      if (line.contains('cholesterol')) {
        final value = _extractNumbers(originalLine);
        if (value != null) labResults['cholesterol'] = value;
      }
    }

    return MedicalReportData(
      patientName: patientName,
      doctorName: doctorName,
      hospitalName: hospitalName,
      reportDate: reportDate ?? DateTime.now(),
      diagnosis: diagnosis,
      treatment: treatment,
      prescription: prescription,
      medications: medications,
      labResults: labResults,
      vitals: vitals,
      extractedText: text,
      notes: notes,
    );
  }

  /// Extract value after colon in a line
  static String? _extractValueAfterColon(String line) {
    final colonIndex = line.indexOf(':');
    if (colonIndex != -1 && colonIndex < line.length - 1) {
      return line.substring(colonIndex + 1).trim();
    }
    return null;
  }

  /// Extract numbers from a line
  static String? _extractNumbers(String line) {
    final regex = RegExp(r'[\d.]+');
    final match = regex.firstMatch(line);
    return match?.group(0);
  }

  /// Parse date from string
  static DateTime? _parseDate(String dateStr) {
    try {
      // Try different date formats
      final formats = [
        RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
        RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),
        RegExp(
          r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})',
        ),
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateStr);
        if (match != null) {
          if (format == formats[0]) {
            // DD/MM/YYYY or DD-MM-YYYY
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
            );
          } else if (format == formats[1]) {
            // YYYY/MM/DD or YYYY-MM-DD
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            );
          }
        }
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }

  /// Dispose resources
  static void dispose() {
    _authClient?.close();
    _authClient = null;
    _visionApi = null;
  }
}

/// Medical report data extracted from image
class MedicalReportData {
  final String? patientName;
  final String? doctorName;
  final String? hospitalName;
  final DateTime reportDate;
  final String? diagnosis;
  final String? treatment;
  final String? prescription;
  final List<String> medications;
  final Map<String, String> labResults;
  final Map<String, String> vitals;
  final String extractedText;
  final String? notes;

  const MedicalReportData({
    this.patientName,
    this.doctorName,
    this.hospitalName,
    required this.reportDate,
    this.diagnosis,
    this.treatment,
    this.prescription,
    this.medications = const [],
    this.labResults = const {},
    this.vitals = const {},
    required this.extractedText,
    this.notes,
  });

  /// Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'reportDate': reportDate.toIso8601String(),
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'medications': medications,
      'labResults': labResults,
      'vitals': vitals,
      'extractedText': extractedText,
      'notes': notes,
    };
  }
}
