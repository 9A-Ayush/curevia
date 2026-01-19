import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/symptom_checker_models.dart';
import '../../config/ai_config.dart';

/// Custom exception for Gemini API errors
class GeminiAPIException implements Exception {
  final int statusCode;
  final String message;
  
  GeminiAPIException({required this.statusCode, required this.message});
  
  @override
  String toString() {
    if (statusCode == 503) {
      return 'The AI service is currently overloaded. Please try again in a few moments.';
    } else if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    } else if (statusCode == 403) {
      return 'API access denied. Please check your API key configuration.';
    } else if (statusCode == 400) {
      return 'Invalid request. Please check your input and try again.';
    }
    return 'AI service error (Code: $statusCode). Please try again later.';
  }
}

/// Service for AI-powered symptom analysis using Gemini
class SymptomAnalysisService {
  /// Analyze symptoms using Gemini AI
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
      print('=== ANALYZING SYMPTOMS WITH GEMINI ===');
      print('Symptoms: ${symptoms.join(", ")}');
      print('Age: $age, Gender: $gender');
      print('Duration: $duration, Severity: $severity');
      
      // Prepare the prompt for AI analysis
      final prompt = _buildAnalysisPrompt(
        symptoms: symptoms,
        description: description,
        age: age,
        gender: gender,
        duration: duration,
        severity: severity,
      );

      // Call Gemini API with retry logic
      final response = await _callGeminiAPI(prompt);
      
      // Parse the response
      return _parseAnalysisResponse(response, symptoms);
    } on GeminiAPIException catch (e) {
      print('Gemini API Exception: $e');
      // Return user-friendly error in the result
      throw Exception(e.toString());
    } catch (e) {
      print('Error analyzing symptoms: $e');
      // Instead of returning fallback result, throw the error to inform user
      throw Exception('AI analysis failed: ${e.toString()}. Please try again or consult with a healthcare professional.');
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
You are a medical AI assistant. Analyze the following symptoms and provide a preliminary assessment in JSON format.

Patient Information:
- Age: $age years
- Gender: $gender
${duration != null ? '- Duration: $duration' : ''}
${severity != null ? '- Severity: $severity' : ''}

Symptoms: ${symptoms.join(', ')}

Additional Description: $description

Please provide your analysis in the following JSON format:
{
  "possibleConditions": [
    {
      "name": "Condition Name",
      "probability": "High/Medium/Low",
      "description": "Brief description"
    }
  ],
  "recommendations": [
    "Recommendation 1",
    "Recommendation 2"
  ],
  "urgentSigns": [
    "Sign 1 that requires immediate care",
    "Sign 2 that requires immediate care"
  ],
  "suggestedSpecialist": "Type of specialist",
  "confidence": "High/Medium/Low"
}

Important: 
- Provide 2-4 possible conditions ranked by probability
- Give 3-5 practical recommendations
- List 3-5 urgent warning signs
- Suggest the most appropriate specialist
- This is for preliminary assessment only and should not replace professional medical advice
- Be specific and practical in your recommendations
- Consider the patient's age and gender in your analysis
''';
  }

  /// Call Gemini API with retry logic
  static Future<String> _callGeminiAPI(String prompt, {int retryCount = 0}) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    try {
      final url = Uri.parse(
        '${AIConfig.geminiBaseUrl}/models/${AIConfig.geminiModel}:generateContent?key=${AIConfig.geminiApiKey}',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': AIConfig.temperature,
          'topK': AIConfig.topK,
          'topP': AIConfig.topP,
          'maxOutputTokens': AIConfig.maxOutputTokens,
        },
        'safetySettings': AIConfig.safetySettings.entries.map((entry) {
          return {
            'category': entry.key,
            'threshold': entry.value,
          };
        }).toList(),
      };

      print('Calling Gemini API (attempt ${retryCount + 1}/$maxRetries)...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('Gemini API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        print('Gemini Response received: ${text.substring(0, text.length > 200 ? 200 : text.length)}...');
        return text;
      } else if (response.statusCode == 503 && retryCount < maxRetries - 1) {
        // Model overloaded - retry after delay
        print('Model overloaded (503), retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        return _callGeminiAPI(prompt, retryCount: retryCount + 1);
      } else if (response.statusCode == 429 && retryCount < maxRetries - 1) {
        // Rate limit - retry after longer delay
        print('Rate limited (429), retrying in ${retryDelay.inSeconds * 2} seconds...');
        await Future.delayed(retryDelay * 2);
        return _callGeminiAPI(prompt, retryCount: retryCount + 1);
      } else {
        print('Gemini API Error: ${response.body}');
        throw GeminiAPIException(
          statusCode: response.statusCode,
          message: response.body,
        );
      }
    } catch (e) {
      if (e is GeminiAPIException) {
        rethrow;
      }
      print('Error calling Gemini API: $e');
      
      // Retry on network errors
      if (retryCount < maxRetries - 1) {
        print('Network error, retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
        return _callGeminiAPI(prompt, retryCount: retryCount + 1);
      }
      
      throw Exception('Failed to connect to Gemini API after $maxRetries attempts: $e');
    }
  }

  /// Parse AI response
  static SymptomAnalysisResult _parseAnalysisResponse(
    String response,
    List<String> symptoms,
  ) {
    try {
      // Extract JSON from response (Gemini might wrap it in markdown)
      String jsonStr = response.trim();
      
      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      print('Parsing JSON response...');
      final data = json.decode(jsonStr);

      // Parse possible conditions
      final List<PossibleCondition> conditions = [];
      if (data['possibleConditions'] != null) {
        for (final condition in data['possibleConditions']) {
          conditions.add(PossibleCondition(
            name: condition['name'] ?? 'Unknown Condition',
            probability: condition['probability'] ?? 'Medium',
            description: condition['description'] ?? '',
          ));
        }
      }

      // Validate that we have meaningful results
      if (conditions.isEmpty) {
        throw Exception('AI analysis did not return any conditions. Please try again.');
      }

      // Parse recommendations
      final List<String> recommendations = [];
      if (data['recommendations'] != null) {
        for (final rec in data['recommendations']) {
          recommendations.add(rec.toString());
        }
      }

      if (recommendations.isEmpty) {
        throw Exception('AI analysis did not return recommendations. Please try again.');
      }

      // Parse urgent signs
      final List<String> urgentSigns = [];
      if (data['urgentSigns'] != null) {
        for (final sign in data['urgentSigns']) {
          urgentSigns.add(sign.toString());
        }
      }

      print('Successfully parsed analysis result');
      return SymptomAnalysisResult(
        possibleConditions: conditions,
        recommendations: recommendations,
        urgentSigns: urgentSigns,
        suggestedSpecialist: data['suggestedSpecialist']?.toString() ?? 'General Practitioner',
        confidence: data['confidence']?.toString() ?? 'Medium',
        disclaimer:
            'This is a preliminary assessment based on AI analysis. Please consult with a healthcare professional for proper diagnosis and treatment.',
      );
    } catch (e) {
      print('Error parsing Gemini response: $e');
      print('Response was: $response');
      // Instead of returning fallback, throw error to inform user
      throw Exception('Failed to parse AI response. Please try again.');
    }
  }

  /// Get default conditions as fallback - REMOVED
  /// No longer providing hardcoded conditions
  static List<PossibleCondition> _getDefaultConditions(List<String> symptoms) {
    throw Exception('Unable to analyze symptoms. Please try again.');
  }

  /// Get default recommendations as fallback - REMOVED
  /// No longer providing hardcoded recommendations
  static List<String> _getDefaultRecommendations() {
    throw Exception('Unable to generate recommendations. Please try again.');
  }

  /// Get default urgent signs as fallback - REMOVED
  /// No longer providing hardcoded urgent signs
  static List<String> _getDefaultUrgentSigns() {
    throw Exception('Unable to generate urgent signs. Please try again.');
  }

  /// Get fallback result when parsing fails - REMOVED
  /// Instead of returning hardcoded results, we now throw an error to inform the user
  static SymptomAnalysisResult _getFallbackResult(List<String> symptoms) {
    throw Exception('AI analysis failed. Please try again or consult with a healthcare professional directly.');
  }

  /// Upload and analyze images (to be implemented)
  static Future<String> analyzeSymptomImages(List<File> images) async {
    // TODO: Implement image analysis using Gemini Vision API
    return 'Image analysis not yet implemented';
  }
}
