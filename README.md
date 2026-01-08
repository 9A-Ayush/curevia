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

### 🧠 **Smart Analysis Features**
- **Text-Based Assessment** --- Describe symptoms in natural language for AI analysis
- **Image Analysis** --- Upload photos of visual symptoms for AI evaluation
- **Multi-Step Process** --- Comprehensive 4-step symptom collection workflow
- **Severity Classification** --- AI determines urgency levels and recommendations
- **Condition Matching** --- Identifies possible conditions with confidence scores
- **Doctor Integration** --- Direct booking with relevant specialists from results

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
- **Google Gemini Integration** --- Advanced AI model for medical analysis
- **Secure API Management** --- Protected API keys and secure data transmission
- **Theme-Aware UI** --- Consistent design across light/dark modes
- **Error Handling** --- Graceful fallbacks and user-friendly error messages
- **Performance Optimized** --- Fast loading and efficient image processing

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

### 🛡️ **Privacy & Compliance**
- **User Control** --- Complete email preference management
- **GDPR Compliant** --- Easy unsubscribe and data protection
- **Secure Processing** --- Protected email service with environment variables
- **Professional Templates** --- Branded email designs with proper formatting

------------------------------------------------------------------------

## 🔔 Advanced Notification System

Curevia features a comprehensive **role-based push notification system** powered by Firebase Cloud Messaging (FCM) with intelligent targeting and sound support.

### 📱 **Patient Notifications**
- **Appointment Confirmations** --- Instant booking confirmations with appointment details
- **Appointment Reminders** --- Smart reminders before scheduled appointments  
- **Payment Success** --- Confirmation notifications for successful payments
- **Health Tips** --- Periodic wellness reminders and health advice
- **Doctor Rescheduling** --- Notifications when doctors reschedule appointments
- **Engagement Messages** --- Motivational check-ins and wellness wishes
- **Fitness Achievements** --- Celebration notifications for completed fitness goals

### 🩺 **Doctor Notifications**  
- **New Bookings** --- Instant alerts for new patient appointments
- **Payment Received** --- Notifications when payments are processed
- **Appointment Changes** --- Updates when patients reschedule or cancel
- **Verification Status** --- Updates on doctor verification approval/rejection

### 🛡️ **Admin Notifications**
- **Verification Requests** --- High-priority alerts for new doctor verification submissions

### 🔊 **Smart Sound System**
- **Priority-Based Sounds** --- Different notification sounds based on urgency and type
- **Multi-State Support** --- Works in foreground, background, and terminated app states
- **Sound Categories** --- Appointment alerts, payment confirmations, and admin notifications

### 🧪 **Developer Tools**
- **Notification Test Center** --- Debug screen for testing all notification types (debug mode only)
- **Comprehensive Testing** --- Built-in tools for testing role-based notifications
- **System Monitoring** --- Real-time status monitoring and diagnostics

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
- ✅ **Production Ready** - Handles all app states (foreground, background, terminated)
- ✅ **Sound Enabled** - Custom sounds for different notification categories
- ✅ **Role Aware** - Intelligent targeting based on user roles
- ✅ **Scalable** - Easy to add new notification types and targeting rules
- ✅ **Testable** - Comprehensive testing tools for development
- ✅ **Monitored** - Real-time system status and diagnostics

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
git clone https://github.com/your-username/Curevia.git
cd Curevia

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 🧪 **Testing Notifications (Debug Mode)**

Access the **Notification Test Center** in debug builds to test all notification types:

1. **Build in debug mode**: `flutter run --debug`
2. **Navigate to**: Debug → Notification Test Screen
3. **Test Features**:
   - Test individual notification types by role
   - Run comprehensive test suites
   - Monitor system status and FCM token
   - Test sound playback and priorities
   - Simulate different app states

### 🔧 **Development Setup**

The notification system automatically initializes when the app starts. Key integration points:

- **Main App**: `lib/main.dart` - System initialization
- **Auth Flow**: `lib/providers/auth_provider.dart` - User-specific setup
- **Debug Tools**: `lib/screens/debug/notification_test_screen.dart` - Testing interface

------------------------------------------------------------------------

## 🆕 Recent Updates

### **v1.2.0 - AI-Powered Health Features & Enhanced UX** (Latest - January 9, 2026)
- 🤖 **AI Symptom Checker** - Google Gemini-powered symptom analysis with image support
- 🏦 **Smart Bank Details** - IFSC.in API integration with dropdown-based bank selection
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

## 👨‍💻 Author

**Ayush Kumar**\
[![GitHub](https://img.shields.io/badge/GitHub-9A--Ayush-black?logo=github)](https://github.com/9A-Ayush)\
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ayush%20Kumar-blue?logo=linkedin)](http://www.linkedin.com/in/ayush-kumar-849a1324b)\
[![Instagram](https://img.shields.io/badge/Instagram-%40ayush__ix__xi-pink?logo=instagram)](https://www.instagram.com/ayush_ix_xi)

------------------------------------------------------------------------

## 📜 License

This project is licensed under the **MIT License**.
------------------------------------------------------------------------

## ☕ Support My Work  

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/9a.ayush)
 

_"Code. Secure. Innovate."_  





