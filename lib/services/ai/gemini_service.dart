import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/symptom_checker_models.dart';
import '../../config/ai_config.dart';

/// Service for Google Gemini AI integration
class GeminiService {
  /// Analyze symptoms using Gemini AI
  static Future<SymptomAnalysisResult> analyzeSymptoms(
    SymptomAnalysisRequest request,
  ) async {
    try {
      final prompt = _buildMedicalPrompt(request);
      
      // For text-only analysis
      if (request.images == null || request.images!.isEmpty) {
        return await _analyzeTextOnly(prompt);
      } else {
        // For multimodal analysis (text + images)
        return await _analyzeWithImages(prompt, request.images!);
      }
    } catch (e) {
      throw Exception('Failed to analyze symptoms: $e');
    }
  }

  /// Build comprehensive medical analysis prompt
  static String _buildMedicalPrompt(SymptomAnalysisRequest request) {
    return '''
You are a medical AI assistant providing preliminary symptom analysis. Analyze the following information and provide a structured assessment.

PATIENT INFORMATION:
- Age: ${request.age}
- Gender: ${request.gender}
- Duration of symptoms: ${request.duration ?? 'Not specified'}
- Severity level (1-10): ${request.severityLevel ?? 'Not specified'}
- Body part affected: ${request.bodyPart ?? 'Not specified'}
- Medical history: ${request.medicalHistory?.join(', ') ?? 'None provided'}

SYMPTOMS:
Selected symptoms: ${request.selectedSymptoms.join(', ')}
Description: ${request.textDescription}

ANALYSIS REQUIREMENTS:
Please provide a JSON response with the following structure:
{
  "possibleConditions": [
    {
      "name": "Condition name",
      "probability": "High/Medium/Low",
      "description": "Brief description",
      "severity": "low/moderate/high/emergency",
      "symptoms": ["matching symptoms"],
      "treatment": "Basic treatment info"
    }
  ],
  "recommendations": ["List of recommendations"],
  "urgentSigns": ["Signs requiring immediate attention"],
  "suggestedSpecialist": "Type of specialist to consult",
  "confidence": "High/Medium/Low",
  "overallSeverity": "low/moderate/high/emergency",
  "nextSteps": ["Immediate next steps"],
  "emergencyAdvice": "Emergency advice if applicable",
  "disclaimer": "Medical disclaimer"
}

IMPORTANT GUIDELINES:
1. Always include comprehensive medical disclaimers
2. Prioritize patient safety - err on the side of caution
3. Clearly indicate when emergency care is needed
4. Provide 2-4 most likely conditions based on symptoms
5. Include both immediate and follow-up recommendations
6. Suggest appropriate medical specialists
7. Use clear, patient-friendly language
8. Never provide definitive diagnoses - only preliminary assessments

EMERGENCY INDICATORS:
If symptoms suggest emergency conditions (chest pain, difficulty breathing, severe bleeding, etc.), set overallSeverity to "emergency" and provide clear emergency advice.

Please analyze and respond with valid JSON only.
''';
  }

  /// Analyze text-only symptoms
  static Future<SymptomAnalysisResult> _analyzeTextOnly(String prompt) async {
    final url = '${AIConfig.geminiBaseUrl}/models/${AIConfig.geminiModel}:generateContent?key=${AIConfig.geminiApiKey}';
    
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
      'safetySettings': AIConfig.safetySettings.entries.map((entry) => {
        'category': entry.key,
        'threshold': entry.value,
      }).toList(),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'];
      
      // Parse JSON response from Gemini
      try {
        // Remove markdown code blocks if present
        String cleanContent = content;
        if (content.startsWith('```json')) {
          cleanContent = content.replaceFirst('```json', '').replaceFirst('```', '').trim();
        } else if (content.startsWith('```')) {
          cleanContent = content.replaceFirst('```', '').replaceFirst('```', '').trim();
        }
        
        final jsonResponse = json.decode(cleanContent);
        return SymptomAnalysisResult.fromJson(jsonResponse);
      } catch (e) {
        // If JSON parsing fails, create a fallback response
        return _createFallbackResponse(content);
      }
    } else {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Analyze symptoms with images (multimodal)
  static Future<SymptomAnalysisResult> _analyzeWithImages(
    String prompt,
    List<File> images,
  ) async {
    final url = '${AIConfig.geminiBaseUrl}/models/${AIConfig.geminiVisionModel}:generateContent?key=${AIConfig.geminiApiKey}';
    
    // Prepare image parts
    final List<Map<String, dynamic>> parts = [
      {'text': prompt}
    ];

    // Add images to the request
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Image
        }
      });
    }

    final requestBody = {
      'contents': [
        {
          'parts': parts
        }
      ],
      'generationConfig': {
        'temperature': AIConfig.temperature,
        'topK': AIConfig.topK,
        'topP': AIConfig.topP,
        'maxOutputTokens': AIConfig.maxOutputTokens,
      },
      'safetySettings': AIConfig.safetySettings.entries.map((entry) => {
        'category': entry.key,
        'threshold': entry.value,
      }).toList(),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'];
      
      try {
        // Remove markdown code blocks if present
        String cleanContent = content;
        if (content.startsWith('```json')) {
          cleanContent = content.replaceFirst('```json', '').replaceFirst('```', '').trim();
        } else if (content.startsWith('```')) {
          cleanContent = content.replaceFirst('```', '').replaceFirst('```', '').trim();
        }
        
        final jsonResponse = json.decode(cleanContent);
        return SymptomAnalysisResult.fromJson(jsonResponse);
      } catch (e) {
        return _createFallbackResponse(content);
      }
    } else {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Create fallback response when JSON parsing fails
  static SymptomAnalysisResult _createFallbackResponse(String content) {
    return SymptomAnalysisResult(
      possibleConditions: [
        PossibleCondition(
          name: 'Analysis Available',
          probability: 'Medium',
          description: 'Please consult with a healthcare professional for proper diagnosis.',
          severity: SeverityLevel.moderate,
          symptoms: [],
        ),
      ],
      recommendations: [
        'Consult with a healthcare professional',
        'Monitor your symptoms',
        'Seek medical attention if symptoms worsen',
      ],
      urgentSigns: [
        'Severe pain',
        'Difficulty breathing',
        'High fever',
        'Persistent symptoms',
      ],
      suggestedSpecialist: 'General Practitioner',
      confidence: 'Medium',
      disclaimer: 'This analysis is for informational purposes only and should not replace professional medical advice. Always consult with a qualified healthcare provider for proper diagnosis and treatment.',
      overallSeverity: SeverityLevel.moderate,
      nextSteps: [
        'Schedule an appointment with your doctor',
        'Keep track of your symptoms',
        'Follow general health guidelines',
      ],
      emergencyAdvice: 'If you experience severe symptoms, seek immediate medical attention or call emergency services.',
    );
  }

  /// Test API connection
  static Future<bool> testConnection() async {
    try {
      final url = '${AIConfig.geminiBaseUrl}/models/${AIConfig.geminiModel}:generateContent?key=${AIConfig.geminiApiKey}';
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'Hello, this is a test. Please respond with "API connection successful".'}
            ]
          }
        ],
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}