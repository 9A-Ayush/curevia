import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/medical_record_model.dart';
import '../models/medical_record_sharing_model.dart';
import '../constants/app_constants.dart';

/// Service for extracting medical data from uploaded documents and text
class MedicalDataExtractionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Extract medical data from document text and create structured records
  static Future<ExtractedMedicalData> extractMedicalData({
    required String patientId,
    required String documentText,
    required String documentTitle,
    required DateTime documentDate,
    String? doctorName,
    String? hospitalName,
  }) async {
    try {
      final extractedData = ExtractedMedicalData();
      final text = documentText.toLowerCase();

      // Extract vitals
      extractedData.vitals = _extractVitals(text);
      
      // Extract allergies
      extractedData.allergies = _extractAllergies(text, patientId, documentDate);
      
      // Extract medications
      extractedData.medications = _extractMedications(text, patientId, documentDate, doctorName);
      
      // Extract lab results
      extractedData.labResults = _extractLabResults(text);

      return extractedData;
    } catch (e) {
      debugPrint('Error extracting medical data: $e');
      return ExtractedMedicalData();
    }
  }

  /// Save extracted medical data to appropriate collections
  static Future<void> saveExtractedData({
    required String patientId,
    required ExtractedMedicalData extractedData,
    required String sourceDocumentId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Save allergies to user profile (append to existing)
      if (extractedData.allergies.isNotEmpty) {
        final userRef = _firestore.collection(AppConstants.usersCollection).doc(patientId);
        final userDoc = await userRef.get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final existingAllergies = List<String>.from(userData['allergies'] ?? []);
          
          // Add new allergies that don't already exist
          for (final allergy in extractedData.allergies) {
            final allergenName = allergy.allergen.toLowerCase();
            if (!existingAllergies.any((existing) => existing.toLowerCase() == allergenName)) {
              existingAllergies.add(allergy.allergen);
            }
          }
          
          batch.update(userRef, {
            'allergies': existingAllergies,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Save medications to user profile or medical record
      if (extractedData.medications.isNotEmpty) {
        // Add medications info to user profile for quick access
        final userRef = _firestore.collection(AppConstants.usersCollection).doc(patientId);
        final medicationNames = extractedData.medications.map((m) => m.medicationName).toList();
        
        batch.update(userRef, {
          'currentMedications': FieldValue.arrayUnion(medicationNames),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('Extracted medical data saved successfully');
    } catch (e) {
      debugPrint('Error saving extracted medical data: $e');
    }
  }

  /// Extract vitals from text
  static Map<String, dynamic> _extractVitals(String text) {
    final vitals = <String, dynamic>{};

    // Blood pressure patterns
    final bpPatterns = [
      RegExp(r'(?:bp|blood pressure|b\.?p\.?)[:\s]*(\d{2,3})[/\\](\d{2,3})', caseSensitive: false),
      RegExp(r'(\d{2,3})[/\\](\d{2,3})\s*(?:mmhg|mm hg)', caseSensitive: false),
    ];

    for (final pattern in bpPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitals['systolicBP'] = int.tryParse(match.group(1) ?? '');
        vitals['diastolicBP'] = int.tryParse(match.group(2) ?? '');
        vitals['bloodPressure'] = '${match.group(1)}/${match.group(2)}';
        break;
      }
    }

    // Heart rate patterns
    final hrPatterns = [
      RegExp(r'(?:heart rate|hr|pulse)[:\s]*(\d{2,3})\s*(?:bpm|beats)', caseSensitive: false),
      RegExp(r'pulse[:\s]*(\d{2,3})', caseSensitive: false),
    ];

    for (final pattern in hrPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitals['heartRate'] = int.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Temperature patterns
    final tempPatterns = [
      RegExp(r'(?:temperature|temp|fever)[:\s]*(\d{2,3}(?:\.\d)?)\s*(?:°?f|fahrenheit)', caseSensitive: false),
      RegExp(r'(?:temperature|temp|fever)[:\s]*(\d{2}(?:\.\d)?)\s*(?:°?c|celsius)', caseSensitive: false),
      RegExp(r'(\d{2,3}(?:\.\d)?)\s*(?:°f|°c)', caseSensitive: false),
    ];

    for (final pattern in tempPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitals['temperature'] = double.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Weight patterns
    final weightPatterns = [
      RegExp(r'(?:weight|wt)[:\s]*(\d{2,3}(?:\.\d)?)\s*(?:kg|kgs|kilograms)', caseSensitive: false),
      RegExp(r'(?:weight|wt)[:\s]*(\d{2,3})\s*(?:lbs?|pounds)', caseSensitive: false),
    ];

    for (final pattern in weightPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitals['weight'] = double.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Height patterns
    final heightPatterns = [
      RegExp(r'(?:height|ht)[:\s]*(\d{1,3}(?:\.\d)?)\s*(?:cm|centimeters)', caseSensitive: false),
      RegExp(r'(?:height|ht)[:\s]*(\d)\s*(?:ft|feet)\s*(\d{1,2})\s*(?:in|inches)', caseSensitive: false),
    ];

    for (final pattern in heightPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        if (match.groupCount == 1) {
          vitals['height'] = double.tryParse(match.group(1) ?? '');
        } else if (match.groupCount == 2) {
          // Convert feet and inches to cm
          final feet = int.tryParse(match.group(1) ?? '') ?? 0;
          final inches = int.tryParse(match.group(2) ?? '') ?? 0;
          final totalInches = (feet * 12) + inches;
          vitals['height'] = totalInches * 2.54; // Convert to cm
        }
        break;
      }
    }

    // Oxygen saturation patterns
    final spo2Patterns = [
      RegExp(r'(?:spo2|oxygen saturation|o2 sat)[:\s]*(\d{2,3})\s*%?', caseSensitive: false),
      RegExp(r'(\d{2,3})\s*%\s*(?:spo2|oxygen|o2)', caseSensitive: false),
    ];

    for (final pattern in spo2Patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitals['oxygenSaturation'] = double.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Blood sugar patterns
    final glucosePatterns = [
      RegExp(r'(?:blood sugar|glucose|bg)[:\s]*(\d{2,3})\s*(?:mg/dl|mmol)', caseSensitive: false),
      RegExp(r'(?:fasting|random)\s*(?:glucose|sugar)[:\s]*(\d{2,3})', caseSensitive: false),
    ];

    for (final pattern in glucosePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        vitals['bloodSugar'] = double.tryParse(match.group(1) ?? '');
        break;
      }
    }

    return vitals;
  }

  /// Extract allergies from text
  static List<PatientAllergy> _extractAllergies(String text, String patientId, DateTime documentDate) {
    final allergies = <PatientAllergy>[];
    
    // Common allergens to look for
    final allergens = [
      'penicillin', 'amoxicillin', 'sulfa', 'aspirin', 'ibuprofen',
      'peanut', 'tree nut', 'shellfish', 'fish', 'milk', 'egg', 'soy', 'wheat',
      'latex', 'dust mite', 'pollen', 'pet dander', 'mold',
      'iodine', 'contrast dye', 'morphine', 'codeine'
    ];

    // Allergy indication keywords
    final allergyKeywords = ['allergic', 'allergy', 'allergies', 'reaction', 'intolerance', 'sensitive'];
    
    for (final allergen in allergens) {
      // Look for patterns like "allergic to penicillin" or "penicillin allergy"
      final patterns = [
        RegExp('(?:allergic to|allergy to)\\s+$allergen', caseSensitive: false),
        RegExp('$allergen\\s+(?:allergy|allergic|reaction)', caseSensitive: false),
        RegExp('(?:avoid|contraindicated)\\s+$allergen', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        if (pattern.hasMatch(text)) {
          // Determine severity based on context
          String severity = 'mild';
          if (text.contains('severe') || text.contains('anaphylaxis')) {
            severity = 'severe';
          } else if (text.contains('moderate') || text.contains('significant')) {
            severity = 'moderate';
          }

          allergies.add(PatientAllergy(
            id: 'extracted_${allergen.hashCode}_${documentDate.millisecondsSinceEpoch}',
            patientId: patientId,
            allergen: allergen.toUpperCase(),
            severity: severity,
            reaction: 'Mentioned in medical document',
            firstOccurrence: documentDate,
            notes: 'Extracted from medical document',
            isActive: true,
            createdAt: documentDate,
            updatedAt: documentDate,
          ));
          break; // Found this allergen, move to next
        }
      }
    }

    return allergies;
  }

  /// Extract medications from text
  static List<PatientMedication> _extractMedications(String text, String patientId, DateTime documentDate, String? doctorName) {
    final medications = <PatientMedication>[];

    // Common medication patterns
    final medicationPatterns = [
      // Pattern: "Medication name 10mg twice daily"
      RegExp(r'([a-z]{3,})\s+(\d+\s*mg)\s+(.*?(?:daily|twice|once|morning|evening|night|bid|tid|qid))', caseSensitive: false),
      // Pattern: "Take medication 1 tablet daily"
      RegExp(r'(?:take\s+)?([a-z]{3,})\s+(\d+\s*tablet)\s+(.*?(?:daily|twice|once))', caseSensitive: false),
      // Pattern: "Medication 5ml three times"
      RegExp(r'([a-z]{3,})\s+(\d+\s*ml)\s+(.*?(?:times|daily|twice|once))', caseSensitive: false),
    ];

    for (final pattern in medicationPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final medicationName = match.group(1)?.trim() ?? '';
        final dosage = match.group(2)?.trim() ?? '';
        final frequency = match.group(3)?.trim() ?? '';

        // Filter out common non-medication words
        final excludeWords = ['patient', 'doctor', 'hospital', 'clinic', 'report', 'test', 'result'];
        if (medicationName.length > 3 && !excludeWords.contains(medicationName.toLowerCase())) {
          medications.add(PatientMedication(
            id: 'extracted_${medicationName.hashCode}_${documentDate.millisecondsSinceEpoch}',
            patientId: patientId,
            medicationName: medicationName.toUpperCase(),
            dosage: dosage,
            frequency: frequency,
            route: 'oral', // Default assumption
            startDate: documentDate,
            endDate: null, // Assume ongoing unless specified
            prescribedBy: doctorName ?? 'Unknown Doctor',
            reason: 'As prescribed',
            notes: 'Extracted from medical document',
            isActive: true,
            createdAt: documentDate,
            updatedAt: documentDate,
          ));
        }
      }
    }

    // Look for prescription section
    final prescriptionMatch = RegExp(r'(?:prescription|medications?|drugs?):\s*(.*?)(?:\n\n|\n[A-Z]|$)', 
        caseSensitive: false, dotAll: true).firstMatch(text);
    
    if (prescriptionMatch != null) {
      final prescriptionText = prescriptionMatch.group(1) ?? '';
      final lines = prescriptionText.split('\n');
      
      for (final line in lines) {
        if (line.trim().isNotEmpty && line.length > 5) {
          // Simple medication extraction from prescription lines
          final words = line.trim().split(' ');
          if (words.isNotEmpty) {
            final medicationName = words.first;
            if (medicationName.length > 3) {
              medications.add(PatientMedication(
                id: 'prescription_${medicationName.hashCode}_${documentDate.millisecondsSinceEpoch}',
                patientId: patientId,
                medicationName: medicationName.toUpperCase(),
                dosage: 'As prescribed',
                frequency: 'As directed',
                route: 'oral',
                startDate: documentDate,
                endDate: null,
                prescribedBy: doctorName ?? 'Unknown Doctor',
                reason: 'Prescribed medication',
                notes: line.trim(),
                isActive: true,
                createdAt: documentDate,
                updatedAt: documentDate,
              ));
            }
          }
        }
      }
    }

    return medications;
  }

  /// Extract lab results from text
  static Map<String, dynamic> _extractLabResults(String text) {
    final labResults = <String, dynamic>{};

    // Common lab test patterns
    final labPatterns = {
      'hemoglobin': RegExp(r'(?:hemoglobin|hb|hgb)[:\s]*(\d+(?:\.\d)?)', caseSensitive: false),
      'hematocrit': RegExp(r'(?:hematocrit|hct)[:\s]*(\d+(?:\.\d)?)', caseSensitive: false),
      'wbc': RegExp(r'(?:wbc|white blood cell)[:\s]*(\d+(?:\.\d)?)', caseSensitive: false),
      'rbc': RegExp(r'(?:rbc|red blood cell)[:\s]*(\d+(?:\.\d)?)', caseSensitive: false),
      'platelets': RegExp(r'(?:platelets|plt)[:\s]*(\d+)', caseSensitive: false),
      'cholesterol': RegExp(r'(?:cholesterol|chol)[:\s]*(\d+)', caseSensitive: false),
      'hdl': RegExp(r'hdl[:\s]*(\d+)', caseSensitive: false),
      'ldl': RegExp(r'ldl[:\s]*(\d+)', caseSensitive: false),
      'triglycerides': RegExp(r'(?:triglycerides|tg)[:\s]*(\d+)', caseSensitive: false),
      'creatinine': RegExp(r'(?:creatinine|cr)[:\s]*(\d+(?:\.\d)?)', caseSensitive: false),
      'bun': RegExp(r'bun[:\s]*(\d+)', caseSensitive: false),
    };

    for (final entry in labPatterns.entries) {
      final match = entry.value.firstMatch(text);
      if (match != null) {
        labResults[entry.key] = double.tryParse(match.group(1) ?? '') ?? match.group(1);
      }
    }

    return labResults;
  }
}

/// Model for extracted medical data
class ExtractedMedicalData {
  Map<String, dynamic> vitals = {};
  List<PatientAllergy> allergies = [];
  List<PatientMedication> medications = [];
  Map<String, dynamic> labResults = {};

  bool get hasData => 
      vitals.isNotEmpty || 
      allergies.isNotEmpty || 
      medications.isNotEmpty || 
      labResults.isNotEmpty;
}