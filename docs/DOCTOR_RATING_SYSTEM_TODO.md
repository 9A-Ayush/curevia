# 📝 Doctor Rating System - Implementation TODO

## 🎯 Overview
Implement a comprehensive doctor rating and review system that allows patients to rate doctors after completing appointments. The system will store ratings in Firebase and dynamically update doctor profiles with calculated averages.

## 🔧 Core Implementation Tasks

### 1. Data Models & Structure

#### 1.1 Create Rating Model
- [ ] Create `lib/models/rating_model.dart`
  - [ ] Rating ID
  - [ ] Patient ID
  - [ ] Doctor ID
  - [ ] Appointment ID
  - [ ] Rating value (1-5)
  - [ ] Review text (optional)
  - [ ] Timestamp
  - [ ] Status (active/hidden)

#### 1.2 Update Doctor Model
- [ ] Modify `lib/models/doctor_model.dart`
  - [ ] Add `averageRating` field
  - [ ] Add `totalRatings` field
  - [ ] Add `totalReviews` field

#### 1.3 Update Appointment Model
- [ ] Modify `lib/models/appointment_model.dart`
  - [ ] Add `isRated` boolean field
  - [ ] Add `ratingId` reference field

### 2. Firebase Structure Design

#### 2.1 Firestore Collections
```
appointments/{appointmentId}
├── isRated: boolean
└── ratingId: string (optional)

doctors/{doctorId}
├── averageRating: double
├── totalRatings: int
└── totalReviews: int

ratings/{ratingId}
├── patientId: string
├── doctorId: string
├── appointmentId: string
├── rating: int (1-5)
├── reviewText: string (optional)
├── timestamp: Timestamp
└── status: string (active/hidden)
```

#### 2.2 Firestore Security Rules
- [ ] Update `firestore.rules`
  - [ ] Only patients can create ratings for their completed appointments
  - [ ] One rating per appointment enforcement
  - [ ] Read permissions for ratings
  - [ ] Admin permissions for moderation

### 3. Services Implementation

#### 3.1 Rating Service
- [ ] Create `lib/services/rating_service.dart`
  - [ ] `submitRating()` - Submit new rating
  - [ ] `canRateAppointment()` - Check if rating is allowed
  - [ ] `getRatingForAppointment()` - Get existing rating
  - [ ] `getDoctorRatings()` - Get all ratings for a doctor
  - [ ] `updateDoctorAverageRating()` - Recalculate doctor's average
  - [ ] `hideRating()` - Admin function to hide inappropriate ratings

#### 3.2 Update Appointment Service
- [ ] Modify `lib/services/appointment_booking_service.dart`
  - [ ] Add rating trigger when appointment status changes to 'completed'
  - [ ] Update appointment with rating status

### 4. UI Components

#### 4.1 Rating Dialog Widget
- [ ] Create `lib/widgets/common/rating_dialog.dart`
  - [ ] Star rating component (1-5 stars)
  - [ ] Optional text review input
  - [ ] Submit and cancel buttons
  - [ ] Loading states
  - [ ] Error handling
  - [ ] Theme-responsive design

#### 4.2 Rating Display Widget
- [ ] Create `lib/widgets/common/rating_display.dart`
  - [ ] Star display (filled/empty)
  - [ ] Average rating number
  - [ ] Total ratings count
  - [ ] Compact and expanded views

#### 4.3 Review List Widget
- [ ] Create `lib/widgets/common/review_list.dart`
  - [ ] Individual review cards
  - [ ] Patient name (anonymized)
  - [ ] Rating stars
  - [ ] Review text
  - [ ] Timestamp
  - [ ] Pagination support

### 5. Screen Updates

#### 5.1 Appointment Details Screen
- [ ] Update appointment details to show rating button
  - [ ] Only show for completed appointments
  - [ ] Hide if already rated
  - [ ] Show existing rating if available

#### 5.2 Doctor Profile Screen
- [ ] Update doctor profile to display ratings
  - [ ] Average rating with stars
  - [ ] Total ratings count
  - [ ] "View Reviews" button
  - [ ] Recent reviews preview

#### 5.3 Doctor Reviews Screen
- [ ] Create `lib/screens/doctor/doctor_reviews_screen.dart`
  - [ ] Full list of reviews
  - [ ] Filter options (newest, highest rated)
  - [ ] Search functionality
  - [ ] Pagination

### 6. Provider Updates

#### 6.1 Rating Provider
- [ ] Create `lib/providers/rating_provider.dart`
  - [ ] Rating submission state management
  - [ ] Rating validation
  - [ ] Error handling
  - [ ] Loading states

#### 6.2 Update Doctor Provider
- [ ] Modify `lib/providers/doctor_provider.dart`
  - [ ] Include rating data in doctor fetching
  - [ ] Real-time rating updates
  - [ ] Rating calculation methods

### 7. Admin Features

#### 7.1 Admin Rating Management
- [ ] Update `lib/screens/admin/admin_dashboard_screen.dart`
  - [ ] Rating statistics overview
  - [ ] Recent ratings list
  - [ ] Flagged reviews section

#### 7.2 Rating Moderation Screen
- [ ] Create `lib/screens/admin/rating_moderation_screen.dart`
  - [ ] List all ratings
  - [ ] Hide/show inappropriate reviews
  - [ ] Rating analytics
  - [ ] Doctor rating trends

### 8. Notification System (Optional)

#### 8.1 Rating Notifications
- [ ] Update notification service
  - [ ] Notify doctor when rated
  - [ ] Rate limiting to prevent spam
  - [ ] Notification preferences

### 9. Validation & Security

#### 9.1 Client-Side Validation
- [ ] Appointment completion check
- [ ] Single rating per appointment
- [ ] Rating value validation (1-5)
- [ ] Review text length limits

#### 9.2 Server-Side Security
- [ ] Firebase Cloud Functions (if needed)
  - [ ] Rating submission validation
  - [ ] Automatic average calculation
  - [ ] Spam prevention

### 10. Testing

#### 10.1 Unit Tests
- [ ] Rating model tests
- [ ] Rating service tests
- [ ] Validation logic tests
- [ ] Calculation accuracy tests

#### 10.2 Integration Tests
- [ ] End-to-end rating flow
- [ ] Firebase integration tests
- [ ] UI interaction tests

#### 10.3 Manual Testing Scenarios
- [ ] Complete appointment → rate doctor flow
- [ ] Multiple ratings calculation
- [ ] Edge cases (first rating, no ratings)
- [ ] Admin moderation workflow
- [ ] Real-time updates verification

## 🚀 Implementation Priority

### Phase 1 (Core Functionality)
1. Data models and Firebase structure
2. Basic rating service
3. Rating dialog UI
4. Post-appointment rating trigger

### Phase 2 (Display & Integration)
1. Rating display components
2. Doctor profile integration
3. Rating provider
4. Security rules

### Phase 3 (Advanced Features)
1. Review list and detailed screens
2. Admin moderation
3. Notifications
4. Analytics

### Phase 4 (Polish & Testing)
1. Comprehensive testing
2. Performance optimization
3. UI/UX refinements
4. Documentation

## 📋 Acceptance Criteria

- [ ] Patients can only rate after appointment completion
- [ ] One rating per appointment enforced
- [ ] Real-time doctor rating updates
- [ ] Secure Firebase implementation
- [ ] Responsive UI across all themes
- [ ] Admin moderation capabilities
- [ ] Proper error handling and validation
- [ ] Performance optimized for large datasets

## 🔍 Technical Considerations

### Performance
- Implement pagination for large review lists
- Cache frequently accessed rating data
- Optimize Firestore queries with proper indexing

### Security
- Validate all inputs client and server-side
- Implement proper Firebase security rules
- Prevent rating manipulation

### User Experience
- Smooth animations for rating interactions
- Clear feedback for all user actions
- Intuitive rating interface
- Proper loading states

### Scalability
- Design for high volume of ratings
- Efficient data structure for quick calculations
- Consider batch operations for bulk updates

---

**Estimated Timeline:** 2-3 weeks for full implementation
**Priority Level:** High
**Dependencies:** Firebase, existing appointment system