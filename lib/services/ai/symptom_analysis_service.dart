import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/symptom_analysis_model.dart';

/// Service for AI-powered symptom analysis
class SymptomAnalysisService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey =
      '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'; // TODO: Move to environment variables

  /// Analyze symptoms using AI
  static Future<SymptomAnalysisResult> analyzeSymptoms({
    required List<String> symptoms,
    required String description,
    required int age,
    required String gender,
    List<File>? images,
    String? duration,
    String? severity,
  }) async {
    try {
      // Prepare the prompt for AI analysis
      final prompt = _buildAnalysisPrompt(
        symptoms: symptoms,
        description: description,
        age: age,
        gender: gender,
        duration: duration,
        severity: severity,
      );

      // For now, return mock data since we need to set up OpenAI API properly
      return _getMockAnalysisResult(symptoms);

      // TODO: Implement actual OpenAI API call
      // final response = await _callOpenAI(prompt, images);
      // return _parseAnalysisResponse(response);
    } catch (e) {
      throw Exception('Failed to analyze symptoms: $e');
    }
  }

  /// Build the analysis prompt for AI
  static String _buildAnalysisPrompt({
    required List<String> symptoms,
    required String description,
    required int age,
    required String gender,
    String? duration,
    String? severity,
  }) {
    return '''
You are a medical AI assistant. Analyze the following symptoms and provide a preliminary assessment.

Patient Information:
- Age: $age
- Gender: $gender

Symptoms: ${symptoms.join(', ')}

Description: $description

${duration != null ? 'Duration: $duration' : ''}
${severity != null ? 'Severity: $severity' : ''}

Please provide:
1. Possible conditions (with probability levels)
2. Recommended actions
3. When to seek immediate medical care
4. Suggested specialist type if needed

Important: This is for preliminary assessment only and should not replace professional medical advice.
''';
  }

  /// Mock analysis result for development
  static SymptomAnalysisResult _getMockAnalysisResult(List<String> symptoms) {
    // Generate mock results based on symptoms
    List<PossibleCondition> conditions = [];
    List<String> recommendations = [];
    List<String> urgentSigns = [];
    String? suggestedSpecialist;

    // Basic logic for common symptoms
    if (symptoms.contains('Fever') || symptoms.contains('Headache')) {
      conditions.addAll([
        PossibleCondition(
          name: 'Viral Infection',
          probability: 'High',
          description:
              'Common viral infection causing fever and general symptoms',
        ),
        PossibleCondition(
          name: 'Bacterial Infection',
          probability: 'Medium',
          description:
              'Possible bacterial infection requiring medical evaluation',
        ),
      ]);
      recommendations.addAll([
        'Rest and stay hydrated',
        'Monitor temperature regularly',
        'Take over-the-counter fever reducers if needed',
      ]);
      urgentSigns.addAll([
        'Fever above 103°F (39.4°C)',
        'Severe headache with neck stiffness',
        'Difficulty breathing',
      ]);
      suggestedSpecialist = 'General Practitioner';
    }

    if (symptoms.contains('Cough') ||
        symptoms.contains('Shortness of breath')) {
      conditions.add(
        PossibleCondition(
          name: 'Respiratory Infection',
          probability: 'High',
          description: 'Upper or lower respiratory tract infection',
        ),
      );
      recommendations.addAll([
        'Stay hydrated and rest',
        'Use a humidifier',
        'Avoid irritants like smoke',
      ]);
      urgentSigns.addAll([
        'Severe difficulty breathing',
        'Chest pain',
        'Coughing up blood',
      ]);
      suggestedSpecialist = 'Pulmonologist';
    }

    if (symptoms.contains('Stomach pain') || symptoms.contains('Nausea')) {
      conditions.add(
        PossibleCondition(
          name: 'Gastroenteritis',
          probability: 'Medium',
          description: 'Inflammation of the stomach and intestines',
        ),
      );
      recommendations.addAll([
        'Stay hydrated with clear fluids',
        'Follow BRAT diet (Bananas, Rice, Applesauce, Toast)',
        'Avoid dairy and fatty foods',
      ]);
      urgentSigns.addAll([
        'Severe dehydration',
        'Blood in vomit or stool',
        'Severe abdominal pain',
      ]);
      suggestedSpecialist = 'Gastroenterologist';
    }

    // Default recommendations if none specific
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Monitor symptoms closely',
        'Rest and maintain good hydration',
        'Consider consulting a healthcare provider',
      ]);
    }

    // Default urgent signs
    if (urgentSigns.isEmpty) {
      urgentSigns.addAll([
        'Symptoms rapidly worsening',
        'High fever (>101.3°F)',
        'Severe pain',
        'Difficulty breathing',
      ]);
    }

    return SymptomAnalysisResult(
      possibleConditions: conditions,
      recommendations: recommendations,
      urgentSigns: urgentSigns,
      suggestedSpecialist: suggestedSpecialist ?? 'General Practitioner',
      confidence: 'Medium',
      disclaimer:
          'This is a preliminary assessment based on AI analysis. Please consult with a healthcare professional for proper diagnosis and treatment.',
    );
  }

  /// Call OpenAI API (to be implemented)
  static Future<Map<String, dynamic>> _callOpenAI(
    String prompt,
    List<File>? images,
  ) async {
    // TODO: Implement OpenAI API integration
    throw UnimplementedError('OpenAI API integration not yet implemented');
  }

  /// Parse AI response (to be implemented)
  static SymptomAnalysisResult _parseAnalysisResponse(
    Map<String, dynamic> response,
  ) {
    // TODO: Parse OpenAI response and create SymptomAnalysisResult
    throw UnimplementedError('Response parsing not yet implemented');
  }

  /// Upload and analyze images (to be implemented)
  static Future<String> analyzeSymptomImages(List<File> images) async {
    // TODO: Implement image analysis using OpenAI Vision API
    return 'Image analysis not yet implemented';
  }

  /// Get health tips based on symptoms
  static List<String> getHealthTips(List<String> symptoms) {
    List<String> tips = [];

    if (symptoms.contains('Fever')) {
      tips.addAll([
        'Drink plenty of fluids to prevent dehydration',
        'Rest in a cool, comfortable environment',
        'Use light clothing and bedding',
      ]);
    }

    if (symptoms.contains('Cough')) {
      tips.addAll([
        'Stay hydrated to thin mucus',
        'Use honey to soothe throat (not for children under 1 year)',
        'Avoid smoking and secondhand smoke',
      ]);
    }

    if (symptoms.contains('Headache')) {
      tips.addAll([
        'Apply cold or warm compress to head or neck',
        'Practice relaxation techniques',
        'Ensure adequate sleep',
      ]);
    }

    if (tips.isEmpty) {
      tips.addAll([
        'Maintain good hygiene practices',
        'Get adequate rest and sleep',
        'Stay hydrated throughout the day',
        'Eat a balanced, nutritious diet',
      ]);
    }

    return tips;
  }
}
