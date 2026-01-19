import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration utility for managing API keys and secrets
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// Initialize environment configuration
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  // Firebase Configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAuthDomain =>
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // FCM Configuration
  static String? get fcmServerKey => dotenv.env['FCM_SERVER_KEY'];

  // Google Maps API
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Cloudinary Configuration
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret =>
      dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // Agora Configuration
  static String get agoraAppId => dotenv.env['AGORA_APP_ID'] ?? '';
  static String get agoraAppCertificate =>
      dotenv.env['AGORA_APP_CERTIFICATE'] ?? '';

  // Razorpay Configuration
  static String get razorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  static String get razorpayKeySecret => dotenv.env['RAZORPAY_KEY_SECRET'] ?? '';
  static String get razorpayPlanId => dotenv.env['RAZORPAY_PLAN_ID'] ?? '';

  // AI API Configuration
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get aiApiBaseUrl =>
      dotenv.env['AI_API_BASE_URL'] ?? 'https://api.openai.com/v1';

  // Google Cloud Configuration
  static String get googleCloudServiceAccount =>
      dotenv.env['GOOGLE_CLOUD_SERVICE_ACCOUNT'] ?? '';
  static String get googleCloudProjectId =>
      dotenv.env['GOOGLE_CLOUD_PROJECT_ID'] ?? '';

  // OpenFDA API
  static String get openFdaApiKey => dotenv.env['OPENFDA_API_KEY'] ?? '';

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Curevia';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  /// Validate that all required environment variables are set
  static bool validateConfig() {
    final requiredKeys = [
      'FIREBASE_API_KEY',
      'FIREBASE_PROJECT_ID',
      'GOOGLE_MAPS_API_KEY',
      'CLOUDINARY_CLOUD_NAME',
      'AGORA_APP_ID',
      'RAZORPAY_KEY_ID',
      'OPENAI_API_KEY',
    ];

    for (final key in requiredKeys) {
      if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
        print('Warning: Required environment variable $key is not set');
        return false;
      }
    }
    return true;
  }

  /// Get environment variables for production use
  static Map<String, String> getAppInfo() {
    return {
      'APP_NAME': appName,
      'APP_VERSION': appVersion,
    };
  }
}
