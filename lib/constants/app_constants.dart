/// App-wide constants for Curevia
class AppConstants {
  // App Information
  static const String appName = 'Curevia';
  static const String appTagline = 'Your Smart Path to Better Health';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.curevia.com';
  static const String openFdaBaseUrl = 'https://api.fda.gov';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String doctorsCollection = 'doctors';
  static const String patientsCollection = 'patients';
  static const String appointmentsCollection = 'appointments';
  static const String medicinesCollection = 'medicines';
  static const String remediesCollection = 'remedies';
  static const String reviewsCollection = 'reviews';
  static const String consultationsCollection = 'consultations';
  static const String prescriptionsCollection = 'prescriptions';
  static const String notificationsCollection = 'notifications';
  static const String familyMembersCollection = 'family_members';
  static const String medicalRecordsCollection = 'medical_records';

  // User Roles
  static const String patientRole = 'patient';
  static const String doctorRole = 'doctor';
  static const String adminRole = 'admin';

  // Appointment Status
  static const String appointmentPending = 'pending';
  static const String appointmentConfirmed = 'confirmed';
  static const String appointmentCompleted = 'completed';
  static const String appointmentCancelled = 'cancelled';
  static const String appointmentRescheduled = 'rescheduled';

  // Consultation Types
  static const String onlineConsultation = 'online';
  static const String offlineConsultation = 'offline';
  static const String videoConsultation = 'video';
  static const String chatConsultation = 'chat';

  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';

  // Doctor Specialties
  static const List<String> doctorSpecialties = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
    'Gynecology',
    'Orthopedics',
    'Neurology',
    'Psychiatry',
    'Ophthalmology',
    'ENT',
    'Dentistry',
    'Urology',
    'Gastroenterology',
    'Endocrinology',
    'Pulmonology',
    'Nephrology',
    'Oncology',
    'Rheumatology',
    'Anesthesiology',
    'Emergency Medicine',
  ];

  // Languages
  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Gujarati',
    'Urdu',
    'Kannada',
    'Malayalam',
  ];

  // Time Slots
  static const List<String> timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
  ];

  // File Upload Limits
  static const int maxImageSizeMB = 5;
  static const int maxVideoSizeMB = 50;
  static const int maxDocumentSizeMB = 10;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration shortCacheExpiry = Duration(minutes: 30);

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Nearby Search Radius (in kilometers)
  static const double nearbySearchRadius = 10.0;
  static const double maxSearchRadius = 50.0;

  // Rating Limits
  static const double minRating = 1.0;
  static const double maxRating = 5.0;

  // Emergency Contact
  static const String emergencyNumber = '108';
  static const String supportEmail = 'support@curevia.com';
  static const String supportPhone = '+91-9876543210';
}
