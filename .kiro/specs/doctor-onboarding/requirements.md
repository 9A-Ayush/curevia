# Requirements Document: Doctor Onboarding Flow

## Introduction

The Doctor Onboarding Flow is a critical feature that ensures all doctors complete their professional profile before accessing the platform. This multi-step process collects essential information including professional credentials, practice details, availability, and banking information for payment processing. The system must validate doctor credentials through admin verification before granting full platform access.

## Glossary

- **Doctor**: A medical professional registering to provide consultation services on the Curevia platform
- **Onboarding System**: The multi-step registration process that collects and validates doctor information
- **Profile Completion**: The state where all mandatory doctor information has been provided
- **Verification Status**: The current state of admin review (pending/verified/rejected)
- **Admin**: Platform administrator responsible for verifying doctor credentials
- **Time Slot**: A specific period when a doctor is available for consultations
- **Consultation Type**: The mode of consultation (online video call or in-person visit)
- **Medical Registration Number**: Official registration number issued by medical council
- **Draft Mode**: Temporary storage of incomplete onboarding data

## Requirements

### Requirement 1: Profile Completion Check

**User Story:** As a doctor, I want the system to check my profile completion status when I log in, so that I am guided to complete my profile if needed.

#### Acceptance Criteria

1. WHEN a doctor logs into the system THEN the Onboarding System SHALL check the profileComplete field in the doctor's Firestore document
2. WHEN the profileComplete field is false THEN the Onboarding System SHALL redirect the Doctor to the onboarding flow
3. WHEN the profileComplete field is true THEN the Onboarding System SHALL check the verificationStatus field
4. WHEN the verificationStatus is pending THEN the Onboarding System SHALL display the verification pending screen
5. WHEN the verificationStatus is rejected THEN the Onboarding System SHALL display the rejection reason and allow profile editing
6. WHEN the verificationStatus is verified THEN the Onboarding System SHALL grant access to the doctor dashboard

### Requirement 2: Multi-Step Onboarding Process

**User Story:** As a doctor, I want to complete my profile through a guided multi-step process, so that I can provide all necessary information without feeling overwhelmed.

#### Acceptance Criteria

1. THE Onboarding System SHALL present exactly seven sequential steps to the Doctor
2. WHEN the Doctor completes a step THEN the Onboarding System SHALL save the data as a draft to Firestore
3. WHEN the Doctor navigates between steps THEN the Onboarding System SHALL preserve previously entered data
4. THE Onboarding System SHALL display a progress indicator showing current step number out of total steps
5. WHEN the Doctor attempts to proceed to the next step THEN the Onboarding System SHALL validate all required fields in the current step
6. WHEN validation fails THEN the Onboarding System SHALL display specific error messages for each invalid field
7. THE Onboarding System SHALL allow the Doctor to navigate backward to previous steps without data loss

### Requirement 3: Basic Information Collection

**User Story:** As a doctor, I want to provide my basic personal information, so that the platform knows my identity and contact details.

#### Acceptance Criteria

1. THE Onboarding System SHALL collect the Doctor's full name
2. THE Onboarding System SHALL allow the Doctor to upload a profile photo
3. THE Onboarding System SHALL collect the Doctor's date of birth
4. THE Onboarding System SHALL collect the Doctor's gender
5. THE Onboarding System SHALL pre-fill the Doctor's email address from the authentication system
6. THE Onboarding System SHALL pre-fill the Doctor's contact number from the authentication system
7. WHEN the Doctor uploads a profile photo THEN the Onboarding System SHALL validate the file type is an image
8. WHEN the Doctor uploads a profile photo THEN the Onboarding System SHALL validate the file size is less than 5MB

### Requirement 4: Professional Details Collection

**User Story:** As a doctor, I want to provide my professional credentials, so that patients can trust my qualifications.

#### Acceptance Criteria

1. THE Onboarding System SHALL collect the Doctor's medical registration number
2. THE Onboarding System SHALL validate the medical registration number format
3. THE Onboarding System SHALL allow the Doctor to select one or more specializations from a predefined list
4. THE Onboarding System SHALL collect the Doctor's years of experience as a positive integer
5. THE Onboarding System SHALL collect the Doctor's medical degree and qualifications
6. THE Onboarding System SHALL allow the Doctor to upload a registration certificate
7. WHEN the Doctor uploads a certificate THEN the Onboarding System SHALL validate the file type is PDF or image
8. WHEN the Doctor uploads a certificate THEN the Onboarding System SHALL validate the file size is less than 10MB

### Requirement 5: Practice Information Collection

**User Story:** As a doctor, I want to provide my practice details, so that patients know where I practice and my consultation fees.

#### Acceptance Criteria

1. THE Onboarding System SHALL collect the clinic or hospital name
2. THE Onboarding System SHALL collect the complete practice address including street, city, state, and pincode
3. THE Onboarding System SHALL validate the pincode format is exactly 6 digits
4. THE Onboarding System SHALL collect the online consultation fee as a positive number
5. THE Onboarding System SHALL collect the offline consultation fee as a positive number
6. THE Onboarding System SHALL allow the Doctor to select multiple languages spoken from a predefined list
7. THE Onboarding System SHALL require at least one language to be selected

### Requirement 6: Availability Schedule Configuration

**User Story:** As a doctor, I want to set my working hours and availability, so that patients can book appointments during my available times.

#### Acceptance Criteria

1. THE Onboarding System SHALL allow the Doctor to select working days from Monday through Sunday
2. WHEN a working day is selected THEN the Onboarding System SHALL allow the Doctor to set start time and end time for that day
3. THE Onboarding System SHALL validate that end time is after start time for each working day
4. THE Onboarding System SHALL allow the Doctor to select consultation duration from options: 15, 30, 45, or 60 minutes
5. THE Onboarding System SHALL allow the Doctor to specify break times within working hours
6. THE Onboarding System SHALL validate that break times fall within working hours
7. THE Onboarding System SHALL require at least one working day to be selected

### Requirement 7: Additional Information Collection

**User Story:** As a doctor, I want to provide additional information about my practice, so that patients can learn more about my services.

#### Acceptance Criteria

1. THE Onboarding System SHALL collect a professional bio or about section with minimum 50 characters
2. THE Onboarding System SHALL allow the Doctor to list services offered as free text
3. THE Onboarding System SHALL allow the Doctor to list conditions treated as free text
4. THE Onboarding System SHALL allow the Doctor to optionally add awards and recognitions
5. THE Onboarding System SHALL allow the Doctor to optionally add professional memberships
6. THE Onboarding System SHALL limit the bio to maximum 500 characters

### Requirement 8: Banking Details Collection

**User Story:** As a doctor, I want to provide my banking information, so that I can receive payments for consultations.

#### Acceptance Criteria

1. THE Onboarding System SHALL collect the bank account number
2. THE Onboarding System SHALL collect the IFSC code
3. THE Onboarding System SHALL validate the IFSC code format is 11 characters
4. THE Onboarding System SHALL collect the account holder name
5. THE Onboarding System SHALL allow the Doctor to optionally provide a UPI ID
6. WHEN UPI ID is provided THEN the Onboarding System SHALL validate the UPI ID format
7. THE Onboarding System SHALL encrypt banking details before storing in Firestore
8. THE Onboarding System SHALL display a security notice about data encryption

### Requirement 9: Review and Submission

**User Story:** As a doctor, I want to review all my information before submission, so that I can ensure accuracy.

#### Acceptance Criteria

1. THE Onboarding System SHALL display a comprehensive summary of all entered information
2. THE Onboarding System SHALL organize the summary by sections matching the onboarding steps
3. THE Onboarding System SHALL allow the Doctor to navigate back to any step to edit information
4. THE Onboarding System SHALL display terms and conditions for platform usage
5. THE Onboarding System SHALL require the Doctor to accept terms and conditions before submission
6. WHEN the Doctor submits THEN the Onboarding System SHALL set profileComplete to true in Firestore
7. WHEN the Doctor submits THEN the Onboarding System SHALL set verificationStatus to pending in Firestore
8. WHEN the Doctor submits THEN the Onboarding System SHALL send a notification to Admin for verification

### Requirement 10: Verification Pending State

**User Story:** As a doctor, I want to see my verification status after submission, so that I know when I can start using the platform.

#### Acceptance Criteria

1. WHEN verification is pending THEN the Onboarding System SHALL display a verification pending screen
2. THE Onboarding System SHALL display an estimated verification time of 24-48 hours
3. THE Onboarding System SHALL allow the Doctor to view their submitted profile information
4. THE Onboarding System SHALL prevent editing of critical fields during pending verification
5. THE Onboarding System SHALL provide a contact support button for verification inquiries
6. WHEN Admin approves the profile THEN the Onboarding System SHALL send a push notification to the Doctor
7. WHEN Admin rejects the profile THEN the Onboarding System SHALL send a push notification with rejection reason

### Requirement 11: Profile Rejection Handling

**User Story:** As a doctor, I want to understand why my profile was rejected and be able to resubmit, so that I can correct issues and get verified.

#### Acceptance Criteria

1. WHEN verification is rejected THEN the Onboarding System SHALL display the rejection reason provided by Admin
2. THE Onboarding System SHALL allow the Doctor to edit their profile information
3. THE Onboarding System SHALL highlight the sections that need correction based on rejection reason
4. WHEN the Doctor resubmits THEN the Onboarding System SHALL reset verificationStatus to pending
5. THE Onboarding System SHALL maintain a history of submission attempts in Firestore
6. THE Onboarding System SHALL limit resubmissions to maximum 3 attempts before requiring manual review

### Requirement 12: Draft Mode and Data Persistence

**User Story:** As a doctor, I want my progress to be saved automatically, so that I don't lose data if I exit the onboarding process.

#### Acceptance Criteria

1. WHEN the Doctor completes any step THEN the Onboarding System SHALL save the data to Firestore immediately
2. THE Onboarding System SHALL store the current onboardingStep number in Firestore
3. WHEN the Doctor returns to onboarding THEN the Onboarding System SHALL resume from the last completed step
4. THE Onboarding System SHALL preserve all previously entered data across app sessions
5. WHEN the Doctor logs out during onboarding THEN the Onboarding System SHALL retain draft data
6. THE Onboarding System SHALL allow the Doctor to exit onboarding and return later without data loss

### Requirement 13: Document Upload and Validation

**User Story:** As a doctor, I want to upload my credentials securely, so that the admin can verify my qualifications.

#### Acceptance Criteria

1. THE Onboarding System SHALL support image file formats: JPG, JPEG, PNG
2. THE Onboarding System SHALL support PDF file format for documents
3. WHEN a file is selected THEN the Onboarding System SHALL validate the file type
4. WHEN a file is selected THEN the Onboarding System SHALL validate the file size
5. WHEN validation fails THEN the Onboarding System SHALL display a specific error message
6. THE Onboarding System SHALL upload documents to Firebase Storage
7. THE Onboarding System SHALL store document URLs in Firestore
8. THE Onboarding System SHALL display upload progress during file upload
9. WHEN upload fails THEN the Onboarding System SHALL allow retry without losing other form data

### Requirement 14: Navigation and User Experience

**User Story:** As a doctor, I want intuitive navigation through the onboarding process, so that I can complete it efficiently.

#### Acceptance Criteria

1. THE Onboarding System SHALL display a "Next" button to proceed to the next step
2. THE Onboarding System SHALL display a "Back" button to return to the previous step
3. THE Onboarding System SHALL disable the "Next" button when required fields are incomplete
4. THE Onboarding System SHALL display a "Save Draft" button on each step
5. WHEN "Save Draft" is clicked THEN the Onboarding System SHALL save current data and show confirmation
6. THE Onboarding System SHALL display field-level validation errors in real-time
7. THE Onboarding System SHALL scroll to the first error when validation fails
8. THE Onboarding System SHALL use consistent visual design across all steps

### Requirement 15: Admin Verification Integration

**User Story:** As an admin, I want to receive notifications when doctors submit profiles, so that I can verify them promptly.

#### Acceptance Criteria

1. WHEN a Doctor submits their profile THEN the Onboarding System SHALL create a notification for Admin
2. THE Onboarding System SHALL include doctor name and submission timestamp in the notification
3. THE Onboarding System SHALL provide a direct link to the doctor's profile in the admin panel
4. WHEN Admin approves a profile THEN the Onboarding System SHALL update verificationStatus to verified
5. WHEN Admin rejects a profile THEN the Onboarding System SHALL update verificationStatus to rejected
6. WHEN Admin rejects a profile THEN the Onboarding System SHALL store the rejection reason
7. THE Onboarding System SHALL send push notifications to the Doctor for both approval and rejection

## Non-Functional Requirements

### Security
- All banking information must be encrypted using AES-256 before storage
- Document uploads must be scanned for malware
- Personal data must comply with data protection regulations
- API calls must be authenticated and authorized

### Performance
- Each step should load within 2 seconds
- File uploads should show progress indicators
- Form validation should be instantaneous (< 100ms)
- Draft saves should complete within 1 second

### Usability
- The interface must be intuitive for users with basic smartphone literacy
- Error messages must be clear and actionable
- The process should be completable in under 15 minutes
- The design must be consistent with the rest of the application

### Accessibility
- All form fields must have proper labels
- Color contrast must meet WCAG 2.1 AA standards
- The interface must support screen readers
- Touch targets must be at least 44x44 pixels

### Reliability
- Draft data must not be lost due to network issues
- The system must handle concurrent submissions gracefully
- Failed uploads must be retryable without data loss
- The system must recover gracefully from errors
