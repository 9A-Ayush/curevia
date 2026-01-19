# 💖 Curevia --- Smart Health & Wellness App (Under Dev)

> 🩺 **Curevia** is a next-generation **health & wellness super app**
> that connects **patients, doctors, fitness, and lifestyle** under one
> digital platform.\
> It offers **doctor booking, video consultations, medicine info, home
> remedies, fitness tracking, meditation sounds, weather & air quality
> alerts** --- ensuring **health, convenience, and holistic care**.

<p align="center">
  <a href="https://curevia-download.vercel.app" download>
    <img src="https://img.shields.io/badge/⬇_Download_Curevia_BETA_APK-blue?style=for-the-badge&logo=android" alt="Download Curevia APK">
  </a>
</p>

------------------------------------------------------------------------

## ✨ Core Features

-   🏥 **Doctor Booking** --- Search nearby doctors via GPS, view
    profiles, and book instantly.\
-   📹 **Video & Voice Consultations** --- Agora-powered real-time calls
    with doctors.\
-   💳 **Payments** --- Razorpay integration with support for multiple
    payment methods including UPI, cards, net banking, and digital
    wallets.\
-   💊 **Medicine Info** --- OpenFDA API for dosage, side effects,
    usage.\
-   🌿 **Home Remedies** --- Verified herbal & natural treatments with
    safety notes.\
-   📂 **Health Records** --- Upload & access medical reports securely.\
-   🏃 **Fitness Tracker** --- Steps, calories, workouts, sleep sync
    (Google Fit/Apple Health).\
-   🎧 **Meditation Sounds** --- Relaxation, focus, and sleep audio
    tracks.\
-   🌦 **Weather & AQI Alerts** --- OpenWeatherMap/Open-Meteo with health
    tips.\
-   🔔 **Smart Notifications** --- Role-based push notifications with sound support for patients, doctors, and admins.\
-   🛡️ **Admin Panel** --- Complete administrative control with doctor verification, user management, and analytics.\
-   🤖 **AI Symptom Checker** --- Google Gemini-powered symptom analysis with text and image support.\
-   📧 **Email Automation** --- Automated email workflows for verification, campaigns, and health tips.

------------------------------------------------------------------------

## 🤖 AI-Powered Symptom Checker

Curevia features an advanced **AI-powered symptom checker** using Google Gemini AI for preliminary health assessments.

### 🤖 **Smart Analysis Features**
- **Text-Based Assessment** --- Describe symptoms in natural language for real-time AI analysis using Google Gemini
- **Image Analysis** --- Upload photos of visual symptoms for AI evaluation using Google Cloud Vision
- **Multi-Step Process** --- Comprehensive 4-step symptom collection workflow with progressive disclosure
- **Severity Classification** --- AI determines urgency levels and provides personalized recommendations
- **Condition Matching** --- Identifies possible conditions with confidence scores and medical context
- **Doctor Integration** --- Direct booking with relevant specialists from results
- **Real-Time Processing** --- Live AI analysis replacing mock data for accurate, contextual assessments

### 🛡️ **Medical Safety & Compliance**
- **Comprehensive Disclaimers** --- Clear limitations and medical advice requirements
- **Emergency Guidance** --- Immediate emergency contact information for urgent symptoms
- **Professional Recommendations** --- Always encourages professional medical consultation
- **Privacy Protection** --- No permanent storage of health data, secure AI processing
- **User Consent** --- Required acknowledgment before symptom analysis

### 🎯 **User Experience Flow**
1. **Welcome Screen** --- Feature overview and privacy information
2. **Medical Disclaimer** --- Legal disclaimers and user acknowledgment
3. **Symptom Input** --- 4-step comprehensive symptom collection:
   - Basic information (age, gender, description)
   - Symptom category selection
   - Additional details (duration, severity, body part)
   - Optional image upload for visual symptoms
4. **AI Processing** --- Secure analysis with progress indicators
5. **Results Display** --- Comprehensive analysis with actionable recommendations

### 🔧 **Technical Implementation**
- **Google Gemini Integration** --- Advanced AI model for real-time medical analysis with structured JSON responses
- **Google Cloud Vision API** --- Professional image analysis for visual symptoms and medical conditions
- **Secure API Management** --- Protected API keys and secure data transmission with comprehensive error handling
- **Theme-Aware UI** --- Consistent design across light/dark modes with smooth animations
- **Error Handling** --- Graceful fallbacks and user-friendly error messages with diagnostic capabilities
- **Performance Optimized** --- Fast loading, efficient image processing, and real-time AI responses

------------------------------------------------------------------------

## 🏦 Smart Banking Integration

Enhanced doctor onboarding with intelligent **IFSC.in API integration** for seamless bank details collection.

### 💳 **Automated Bank Details**
- **Smart Dropdowns** --- Replace manual input with dropdown-based selection
- **Progressive Selection** --- Bank → State → District → Branch workflow
- **Auto-Fetch Details** --- Automatic IFSC, MICR, and address population
- **Real-Time Validation** --- Instant verification of bank information
- **Error Prevention** --- Eliminates manual entry errors and typos

### 🔄 **Enhanced User Flow**
- **Bank Selection** → Loads available states for selected bank
- **State Selection** → Loads districts available in that state
- **District Selection** → Loads branches in that district
- **Branch Selection** → Auto-fills IFSC, MICR, address, and bank code
- **Account Details** → Manual entry with validation for account numbers and UPI

### 🛡️ **Security & Validation**
- **Secure API Integration** --- Protected API keys and encrypted data transmission
- **Comprehensive Validation** --- Account number format and confirmation matching
- **Data Protection** --- Secure storage of sensitive banking information
- **Error Handling** --- Graceful API failure handling with user feedback

------------------------------------------------------------------------

## 📧 Email Automation System

Comprehensive **email service integration** with real-time Firebase triggers for automated communication workflows.

### 🔄 **Automated Email Workflows**
- **Doctor Verification** --- Automatic approval/rejection notifications
- **Welcome Emails** --- New user onboarding with app features
- **Promotional Campaigns** --- Marketing emails to opted-in users
- **Health Tips Newsletter** --- Wellness content distribution
- **Appointment Reminders** --- Automated scheduling notifications

### 🎯 **Real-Time Firebase Integration**
- **Live Triggers** --- Automatic email sending based on Firestore changes
- **User Preferences** --- Subscription management and opt-out controls
- **Admin Tools** --- Campaign management and health tips distribution
- **Analytics Dashboard** --- Real-time email delivery statistics
- **Live Service** --- [Email Service Dashboard](https://curvia-mail-service.onrender.com)
- **Source Code** --- [Email Service Repository](https://github.com/9A-Ayush/curvia-mail-service/tree/main)

### 🛡️ **Privacy & Compliance**
- **User Control** --- Complete email preference management
- **GDPR Compliant** --- Easy unsubscribe and data protection
- **Secure Processing** --- Protected email service with environment variables
- **Professional Templates** --- Branded email designs with proper formatting

------------------------------------------------------------------------

## 🔔 Advanced Notification System

Curevia features a comprehensive **role-based push notification system** powered by Firebase Cloud Messaging (FCM) with intelligent targeting, reliable sound support, and production-ready diagnostics.

### 📱 **Patient Notifications**
- **Appointment Confirmations** --- Instant booking confirmations with appointment details and custom sounds
- **Appointment Reminders** --- Smart reminders before scheduled appointments with priority-based audio
- **Payment Success** --- Confirmation notifications for successful payments with celebration sounds
- **Health Tips** --- Periodic wellness reminders and health advice with gentle notification tones
- **Doctor Rescheduling** --- Notifications when doctors reschedule appointments with appropriate urgency
- **Engagement Messages** --- Motivational check-ins and wellness wishes with uplifting sounds
- **Fitness Achievements** --- Celebration notifications for completed fitness goals with achievement audio

### 🩺 **Doctor Notifications**  
- **New Bookings** --- Instant alerts for new patient appointments with professional notification sounds
- **Payment Received** --- Notifications when payments are processed with confirmation audio
- **Appointment Changes** --- Updates when patients reschedule or cancel with appropriate sound priority
- **Verification Status** --- Updates on doctor verification approval/rejection with status-specific sounds

### 🛡️ **Admin Notifications**
- **Verification Requests** --- High-priority alerts for new doctor verification submissions with urgent sounds

### 🔊 **Production-Ready Sound System**
- **Priority-Based Sounds** --- Different notification sounds based on urgency and type (appointment, payment, verification)
- **Multi-State Support** --- Works reliably in foreground, background, and terminated app states
- **Device Independence** --- Consistent sound playback whether connected to development tools or standalone
- **Sound Categories** --- Appointment alerts, payment confirmations, and admin notifications with distinct audio
- **Diagnostic Tools** --- Built-in testing and troubleshooting capabilities for development and production

### 🧪 **Developer & Production Tools**
- **Notification Test Center** --- Comprehensive debug screen for testing all notification types (debug mode only)
- **Diagnostic Service** --- Real-time system monitoring, channel verification, and troubleshooting tools
- **System Monitoring** --- Live status monitoring, FCM token management, and performance analytics
- **Production Reliability** --- Enhanced error handling, fallback mechanisms, and user-friendly diagnostics

------------------------------------------------------------------------

## 🏗️ Notification System Architecture

### **Service Layer Structure**
```
lib/services/notifications/
├── notification_integration_service.dart    # Main integration interface
├── role_based_notification_service.dart     # Role-specific notifications
├── notification_initialization_service.dart # System setup & lifecycle
├── notification_testing_service.dart        # Development & testing tools
├── notification_manager.dart               # Core notification management
├── fcm_service.dart                        # Firebase Cloud Messaging
├── notification_handler.dart              # Navigation & UI handling
└── notification_scheduler.dart            # Scheduled notifications
```

### **Notification Types & Targeting**
- **15+ Notification Types** covering all user interactions
- **Role-Based Targeting** using FCM topics and device tokens
- **Priority Levels** with appropriate sound and UI treatment
- **Cross-Platform Support** for Android and iOS with native sounds

### **Key Features**
- ✅ **Production Ready** - Handles all app states (foreground, background, terminated) with reliable sound playback
- ✅ **Sound Enabled** - Custom sounds for different notification categories with device-independent playback
- ✅ **Role Aware** - Intelligent targeting based on user roles with appropriate sound priorities
- ✅ **Scalable** - Easy to add new notification types and targeting rules with comprehensive testing
- ✅ **Testable** - Comprehensive testing tools for development with diagnostic capabilities
- ✅ **Monitored** - Real-time system status, diagnostics, and production troubleshooting tools
- ✅ **Reliable** - Enhanced error handling, fallback mechanisms, and consistent cross-device performance

### **Usage Example**
```dart
// Send appointment confirmation to patient
await RoleBasedNotificationService.instance.sendAppointmentBookingConfirmation(
  patientId: 'patient_123',
  patientFCMToken: 'fcm_token_here',
  doctorName: 'Dr. Smith',
  appointmentId: 'apt_456',
  appointmentTime: DateTime.now().add(Duration(days: 1)),
  appointmentType: 'Consultation',
);

// Test notifications in debug mode
await NotificationTestingService.instance.testAllPatientNotifications();
```

------------------------------------------------------------------------

## 🛠️ Tech Stack

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Category                                       Technology
  ---------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------
  🎨 **Frontend**                                ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)

  🗄 **Backend**                                  ![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

  🔐 **Auth**                                    ![Google](https://img.shields.io/badge/Auth-Google%20Sign--In-red?style=for-the-badge&logo=google)

  💳 **Payments**                                ![Razorpay](https://img.shields.io/badge/Razorpay-02042B?style=for-the-badge&logo=razorpay&logoColor=white)

  ☁ **Media**                                    ![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)

  📡 **Real-Time Calls**                         ![Agora](https://img.shields.io/badge/Agora-099DFD?style=for-the-badge&logo=agora&logoColor=white)

  🌦 **Weather API**                              ![OpenWeatherMap](https://img.shields.io/badge/OpenWeatherMap-FF7E00?style=for-the-badge&logo=openstreetmap&logoColor=white)

  💊 **Medicine API**                             ![openFDA](https://img.shields.io/badge/openFDA-003366?style=for-the-badge)

  🔔 **Notifications**                           ![FCM](https://img.shields.io/badge/Firebase%20Cloud%20Messaging-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

  🎵 **Audio**                                   ![Flutter Local Notifications](https://img.shields.io/badge/Local%20Notifications-02569B?style=for-the-badge&logo=flutter&logoColor=white)

  🤖 **AI Services**                             ![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)

  🏦 **Banking API**                             ![IFSC.in](https://img.shields.io/badge/IFSC.in-FF6B35?style=for-the-badge)

  📧 **Email Service**                           ![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 📸 Screenshots & Layout Structure



------------------------------------------------------------------------

## 🚀 Getting Started

``` bash
# Clone the repository
git clone https://github.com/9A-Ayush/curevia.git
cd curevia

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 🔐 **Important Security Setup**

**⚠️ CRITICAL: Never commit sensitive files to GitHub**

Before running the app, you need to set up the following files that are **NOT included in the repository** for security reasons:

#### **Required Environment Files:**
1. **`.env`** (Root directory) - Contains API keys and sensitive configuration
2. **`lib/config/ai_config.dart`** - Google Gemini API configuration (copy from template)
3. **`lib/firebase_options.dart`** - Firebase configuration (copy from template)
4. **`android/app/google-services.json`** - Firebase Android configuration
5. **`ios/Runner/GoogleService-Info.plist`** - Firebase iOS configuration
6. **`curevia-f31a8-firebase-adminsdk-fbsvc-*.json`** - Firebase Admin SDK key
7. **`email-service/.env`** - Email service configuration
8. **`email-service/serviceAccountKey.json`** - Firebase service account

#### **Setup Instructions:**
1. **Create `.env` file** in root directory with your API keys:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   RAZORPAY_KEY_ID=your_razorpay_key_id
   RAZORPAY_KEY_SECRET=your_razorpay_secret
   CLOUDINARY_CLOUD_NAME=your_cloudinary_name
   CLOUDINARY_API_KEY=your_cloudinary_key
   CLOUDINARY_API_SECRET=your_cloudinary_secret
   ```

2. **Configure AI Services**:
   ```bash
   # Copy template and add your Gemini API key
   cp lib/config/ai_config.dart.template lib/config/ai_config.dart
   # Edit lib/config/ai_config.dart and replace YOUR_GEMINI_API_KEY_HERE
   ```

3. **Configure Firebase**:
   ```bash
   # Copy template and add your Firebase config
   cp lib/firebase_options.dart.template lib/firebase_options.dart
   # Edit lib/firebase_options.dart with your Firebase project details
   ```

4. **Download Firebase Configuration Files** from Firebase Console:
   - `android/app/google-services.json` (Android)
   - `ios/Runner/GoogleService-Info.plist` (iOS)

5. **Email Service Setup** - Configure email service environment variables in `email-service/.env`

#### **Security Notes:**
- ✅ All sensitive files are already in `.gitignore`
- ✅ Never share API keys in public repositories
- ✅ Use environment variables for production deployment
- ✅ Rotate API keys regularly for security

### 🧪 **Testing Notifications (Debug Mode)**

Access the **Notification Test Center** in debug builds to test all notification types and diagnose issues:

1. **Build in debug mode**: `flutter run --debug`
2. **Navigate to**: Profile → Test Notifications (debug mode only)
3. **Test Features**:
   - Test individual notification types by role with real sounds
   - Run comprehensive test suites for all notification categories
   - Monitor system status, FCM token, and channel configuration
   - Test sound playback, priorities, and device independence
   - Simulate different app states (foreground, background, terminated)
   - Run diagnostic checks for troubleshooting production issues
   - Verify notification channel configuration and sound settings

### 🔧 **Development Setup**

The notification system automatically initializes when the app starts with enhanced reliability and diagnostics. Key integration points:

- **Main App**: `lib/main.dart` - System initialization with error handling
- **Auth Flow**: `lib/providers/auth_provider.dart` - User-specific setup and token management
- **Debug Tools**: `lib/screens/profile/profile_screen.dart` - Testing interface (debug mode only)
- **Diagnostic Service**: `lib/services/notifications/notification_diagnostic_service.dart` - Production troubleshooting
- **Sound Management**: Enhanced audio handling for reliable cross-device playback

------------------------------------------------------------------------

## 🆕 Recent Updates

### **v1.4.0 - Enhanced Security & Documentation** (Latest - January 19, 2026)
- � **Documentation Update** - Comprehensive README refresh with latest features and security guidelines
- �️ **Security Best Practices** - Added critical security notes for API keys and environment files
- 🔐 **Environment Protection** - Enhanced .gitignore and security documentation for sensitive data
- 📝 **Developer Guidelines** - Clear instructions for secure development and deployment practices
- � **Repository Sync** - Updated GitHub repository with latest codebase improvements

### **v1.3.0 - Production Ready & Enhanced Reliability** (January 16, 2026)
- 🔧 **Compilation Fixes** - Resolved all build errors, app now compiles successfully
- 🔔 **Notification Sound Fix** - Fixed push notification sounds working reliably across all device states
- 🧹 **Codebase Cleanup** - Removed unused test files, debug screens, and example code for cleaner production build
- 🤖 **Real AI Integration** - Symptom checker now uses live Google Gemini AI instead of mock data
- 🎯 **Enhanced Diagnostics** - Added comprehensive notification testing and diagnostic tools
- 📱 **Production Stability** - Improved error handling, loading states, and user experience
- 🛡️ **Security Hardening** - Enhanced data validation and secure API integrations

### **v1.2.0 - AI-Powered Health Features & Enhanced UX** (January 9, 2026)
- 🤖 **AI Symptom Checker** - Google Gemini-powered symptom analysis with image support and real-time processing
- 🏦 **Smart Bank Details** - IFSC.in API integration with dropdown-based bank selection and auto-fetch
- 🎨 **Theme Responsiveness** - Complete dark/light mode support across all doctor onboarding screens
- 📧 **Email Service Integration** - Automated email workflows for verification, campaigns, and health tips
- 🔧 **Enhanced Doctor Onboarding** - Improved file upload, validation, and user experience
- 📱 **UI/UX Improvements** - Better form validation, loading states, and error handling
- 🛡️ **Security Enhancements** - Improved data validation and secure API integrations

### **v1.1.0 - Advanced Features**
- 📧 **Email Automation System** - Complete email service with real-time Firebase integration
- 🏥 **Enhanced Admin Panel** - Email campaign management and health tips distribution
- 🔔 **Notification System** - Comprehensive role-based push notifications with FCM
- 🎯 **User Preferences** - Email subscription management and personalized settings

### **v1.0.0 - Core Platform**
- 🏥 **Admin Panel** - Complete administrative control with doctor verification and analytics
- 📹 **Video Consultations** - Agora-powered real-time video and voice calls
- 💳 **Payment Integration** - Razorpay support with multiple payment methods
- 🏃 **Fitness Tracking** - Comprehensive health and fitness monitoring
- 🎧 **Meditation Sounds** - Relaxation and wellness audio features

------------------------------------------------------------------------

## � Security & Privacy

### **Data Protection**
- �️ **API Key Security** - All sensitive API keys are stored in environment files (not in repository)
- 🔒 **Firebase Security** - Comprehensive Firestore rules and authentication
- 📱 **Local Storage** - Secure local data storage with encryption
- 🌐 **HTTPS Only** - All API communications use secure HTTPS protocols

### **Files NOT in Repository (Security)**
The following files contain sensitive information and are **excluded from GitHub**:
- `.env` - API keys and configuration
- `lib/config/ai_config.dart` - Google Gemini API configuration
- `lib/firebase_options.dart` - Firebase project configuration
- `android/app/google-services.json` - Firebase Android config
- `ios/Runner/GoogleService-Info.plist` - Firebase iOS config
- `curevia-f31a8-firebase-adminsdk-*.json` - Firebase Admin SDK
- `email-service/` - Complete email service folder (separate repository)
- `email-service/.env` - Email service secrets
- `email-service/serviceAccountKey.json` - Service account key

**Template files are provided** for easy setup:
- `lib/config/ai_config.dart.template` → Copy to `ai_config.dart`
- `lib/firebase_options.dart.template` → Copy to `firebase_options.dart`

### **Privacy Compliance**
- 📋 **User Consent** - Clear privacy policies and user agreements
- 🗑️ **Data Deletion** - Users can delete their accounts and data
- 📧 **Email Preferences** - Complete control over email subscriptions
- 🔍 **Transparent Processing** - Clear information about data usage

------------------------------------------------------------------------

## 👨‍💻 Author

**Ayush Kumar**\
[![GitHub](https://img.shields.io/badge/GitHub-9A--Ayush-black?logo=github)](https://github.com/9A-Ayush)\
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ayush%20Kumar-blue?logo=linkedin)](http://www.linkedin.com/in/ayush-kumar-849a1324b)\
[![Instagram](https://img.shields.io/badge/Instagram-%40ayush__ix__xi-pink?logo=instagram)](https://www.instagram.com/ayush_ix_xi)

**Repository**: [https://github.com/9A-Ayush/curevia.git](https://github.com/9A-Ayush/curevia.git)

------------------------------------------------------------------------

## 📜 License

This project is licensed under the **MIT License**.
------------------------------------------------------------------------

## ☕ Support My Work  

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/9a.ayush)
 

_"Code. Secure. Innovate."_  





