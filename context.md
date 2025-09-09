# Curevia – Your Smart Path to Better Health 🌿💊📱- Context Document

## 📝 Overview
A Flutter-based mobile application that allows patients to easily book doctor appointments (online or offline), consult via video calls, check nearby doctors using GPS, manage medical records, access an AI-powered symptom checker with photo/video uploads, view verified medicine information, and explore home remedies/herbs for common health issues.

---

## 🎯 Target Audience
- Patients of all ages seeking quick and reliable doctor consultations.
- Doctors and clinics wanting to manage appointments and offer telemedicine.
- People looking for verified health info, medicines, and home remedies.

---

## 💎 Core Features

### 1. User Roles
- **Patient**
  - Book online/offline appointments.
  - View medical history.
  - Use AI Symptom Checker.
  - Access medicine & home remedy database.
- **Doctor**
  - Manage schedule & availability.
  - Accept/reject bookings.
  - Conduct video consultations.

### 2. Authentication & Profiles
- Firebase Authentication (Email, Phone OTP, Google).
- Cloudinary for profile photos & document uploads.
- Doctor verification (license proof).

### 3. Doctor Search & Filters
- Search by specialty, location, ratings.
- Filter by fee range, consultation type, language.

### 4. Nearby Doctors (GPS-Based)
- Detect patient’s GPS location.
- Show nearest doctors in map & list view.
- Get directions with Google Maps.

### 5. Real-Time Appointment Booking
- Live availability from Firestore.
- Instant booking confirmation.
- Integrated payments with Stripe.
- Refund flow if canceled.

### 6. Video Consultation (Agora)
- HD in-app video calls.
- Chat for prescription/image sharing.

### 7. Medical Records
- Patients upload prescriptions/reports (Cloudinary).
- Doctors send e-prescriptions as PDFs.

### 8. Reminders & Notifications
- Firebase Cloud Messaging for alerts.
- Appointment & follow-up reminders.

### 9. Ratings & Reviews
- Patients rate doctors after appointments.

---

## 🌿 Health Companion Features

### 10. AI Symptom Checker
- Input symptoms via text.
- Upload photo/video of affected area.
- AI suggests possible causes & specialties.

### 11. In-Built Medicine Directory
- Search medicine details (usage, dosage, side effects, alternatives).
- Powered by OpenFDA API or custom DB.

### 12. Home Remedies & Herbs Guide
- Categorized remedies by symptoms.
- Preparation steps, benefits, cautions.
- Doctor verified.

### 13. Offline Mode
- Common remedies & medicine info stored locally with SQLite.

---

## 💡 Advanced Extras
- Family member profiles for multi-person bookings.
- Emergency Mode to find available doctors instantly.
- Subscription plans for unlimited consultations.
- Multi-language support (Hindi, English, regional).

---

## 🛠 Tech Stack

### Frontend
- Flutter (Material 3 / Cupertino for iOS feel)

### Backend
- Firebase (Auth, Firestore, Functions, FCM)
- Cloudinary (Media Storage)
- Agora SDK (Video Calls)
- Stripe (Payments)

### Packages
- `firebase_auth` → Authentication
- `cloud_firestore` → Database
- `firebase_messaging` → Notifications
- `geolocator` / `geoflutterfire` → GPS location & nearby search
- `google_maps_flutter` → Map view
- `image_picker` → Photo/video capture
- `cloudinary_sdk` → Media uploads
- `video_player` → Media preview
- `stripe_payment` → Payment integration
- `sqflite` → Offline mode data storage

---

## 📅 Development Phases

### Phase 1 (MVP)
- Authentication & profiles
- Doctor search & booking
- Stripe payments
- Video consultation
- GPS-based nearby doctors

### Phase 2
- AI Symptom Checker with photo/video upload
- Medicine directory
- Home remedies/herbs guide
- Offline mode

### Phase 3
- Family profiles
- Emergency mode
- Subscriptions
- Multi-language support

---

## 🚀 Goal
To create India’s first **all-in-one healthcare & wellness app** that merges doctor booking, telemedicine, AI health analysis, verified medical information, and home remedy guidance into one smooth experience.
