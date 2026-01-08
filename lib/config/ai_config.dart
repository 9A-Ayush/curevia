/// Configuration for AI services
class AIConfig {
  // Gemini API configuration
  static const String _geminiApiKey = 'AIzaSyC_8jN6_ukjm2CidF_fprVluJcY-hMJW04';
  
  /// Get Gemini API key
  static String get geminiApiKey => _geminiApiKey;
  
  /// Check if Gemini is configured
  static bool get isGeminiConfigured => true;
  
  /// Gemini model configurations
  static const String geminiModel = 'gemini-2.5-flash';
  static const String geminiVisionModel = 'gemini-2.5-flash';
  
  /// API endpoints
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  /// Generation parameters
  static const double temperature = 0.3;
  static const int topK = 40;
  static const double topP = 0.95;
  static const int maxOutputTokens = 2048;
  
  /// Safety settings
  static const Map<String, String> safetySettings = {
    'HARM_CATEGORY_MEDICAL': 'BLOCK_NONE',
    'HARM_CATEGORY_HARASSMENT': 'BLOCK_MEDIUM_AND_ABOVE',
    'HARM_CATEGORY_HATE_SPEECH': 'BLOCK_MEDIUM_AND_ABOVE',
    'HARM_CATEGORY_SEXUALLY_EXPLICIT': 'BLOCK_MEDIUM_AND_ABOVE',
    'HARM_CATEGORY_DANGEROUS_CONTENT': 'BLOCK_MEDIUM_AND_ABOVE',
  };
}