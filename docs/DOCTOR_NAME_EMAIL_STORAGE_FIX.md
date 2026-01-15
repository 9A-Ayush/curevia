# Doctor Name and Email Storage Fix

## Issue Summary
Doctor name and email were not being properly stored in Firebase during the onboarding process, causing issues with email notifications and data display.

## Root Causes Identified

### 1. **Missing Initial Data Loading**
- **File**: `lib/screens/doctor/onboarding/doctor_onboarding_screen.dart`
- **Issue**: The onboarding screen was not loading existing doctor data from Firebase
- **Impact**: Name and email from registration were not pre-populated in onboarding forms

### 2. **Data Overwriting During Onboarding**
- **File**: `lib/screens/doctor/onboarding/professional_details_step.dart`
- **Issue**: Professional details step could overwrite or clear existing name/email data
- **Impact**: Even if data existed, it could be lost during onboarding

### 3. **Editable Email Field**
- **File**: `lib/screens/doctor/onboarding/professional_details_step.dart`
- **Issue**: Email field was editable, allowing users to change their registered email
- **Impact**: Inconsistency between user account email and doctor profile email

## Data Flow Analysis

### Registration Process:
1. **User Registration**: Creates user document with name, email, role
2. **Doctor Initialization**: Creates doctor document with basic info from user document
3. **Onboarding Start**: Should load existing data but was starting with empty form

### Expected vs Actual Behavior:

#### Expected:
```
Registration → User Document (name, email) → Doctor Document (name, email) → Onboarding (pre-filled forms)
```

#### Actual (Before Fix):
```
Registration → User Document (name, email) → Doctor Document (name, email) → Onboarding (empty forms) → Data Loss
```

## Fixes Applied

### 1. **Added Initial Data Loading**
**File**: `lib/screens/doctor/onboarding/doctor_onboarding_screen.dart`

#### Added Method:
```dart
/// Load existing doctor data from Firestore
Future<void> _loadExistingDoctorData() async {
  try {
    final user = ref.read(authProvider).userModel;
    if (user == null) return;

    // Load data from both users and doctors collections
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final doctorDoc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(user.uid)
        .get();

    final Map<String, dynamic> existingData = {};

    // Load basic info from user document
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      existingData['fullName'] = userData['fullName'];
      existingData['email'] = userData['email'];
      existingData['phoneNumber'] = userData['phoneNumber'];
    }

    // Load doctor-specific info from doctor document
    if (doctorDoc.exists) {
      final doctorData = doctorDoc.data()!;
      
      // Merge doctor data, but prioritize user document for basic info
      existingData.addAll(doctorData);
      
      // Ensure basic info from user document takes precedence
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        existingData['fullName'] = userData['fullName'];
        existingData['email'] = userData['email'];
        if (userData['phoneNumber'] != null) {
          existingData['phoneNumber'] = userData['phoneNumber'];
        }
      }
    }

    // Update onboarding data with existing data
    if (existingData.isNotEmpty && mounted) {
      setState(() {
        _onboardingData = existingData;
      });
      
      print('✅ Loaded existing doctor data: ${existingData.keys.toList()}');
    }
  } catch (e) {
    print('⚠️ Error loading existing doctor data: $e');
    // Don't fail the onboarding process if loading existing data fails
  }
}
```

#### Updated initState:
```dart
@override
void initState() {
  super.initState();
  
  // ... existing animation setup ...
  
  // Load existing doctor data
  _loadExistingDoctorData();
  
  // Start initial animations
  _progressAnimationController.forward();
  _slideAnimationController.forward();
  _fadeAnimationController.forward();
}
```

### 2. **Made Email Field Read-Only**
**File**: `lib/screens/doctor/onboarding/professional_details_step.dart`

#### Updated Email Field:
```dart
Widget _buildEmailField() {
  return _buildStyledTextField(
    controller: _emailController,
    label: 'Email Address',
    hint: 'Your registered email address',
    icon: Icons.email,
    keyboardType: TextInputType.emailAddress,
    enabled: false, // Make email read-only since it comes from user account
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Email address is required';
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Please enter a valid email address';
      }
      return null;
    },
  );
}
```

#### Enhanced TextField Builder:
```dart
Widget _buildStyledTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType? keyboardType,
  TextCapitalization? textCapitalization,
  int maxLines = 1,
  String? Function(String?)? validator,
  List<TextInputFormatter>? inputFormatters,
  bool enabled = true, // Add enabled parameter
}) {
  // ... existing implementation with enabled support ...
  
  child: TextFormField(
    controller: controller,
    enabled: enabled, // Add enabled property
    // ... other properties ...
    style: TextStyle(
      color: enabled ? textColor : textColor.withOpacity(0.6),
    ),
    decoration: InputDecoration(
      // ... other decoration properties ...
      filled: true,
      fillColor: enabled ? fillColor : fillColor.withOpacity(0.5),
    ),
  ),
}
```

### 3. **Created Data Sync Utility**
**File**: `lib/utils/doctor_data_sync_helper.dart`

#### Key Methods:
```dart
/// Sync missing name and email data for all doctors
static Future<void> syncAllDoctorData() async {
  // Scans all doctor documents and syncs missing data from user documents
}

/// Fix data for a specific doctor
static Future<bool> syncDoctorData(String doctorId) async {
  // Syncs data for a specific doctor
}

/// Validate doctor data integrity
static Future<Map<String, dynamic>> validateDoctorData(String doctorId) async {
  // Checks for data consistency and missing fields
}

/// Get summary of all doctor data issues
static Future<Map<String, dynamic>> getDoctorDataSummary() async {
  // Provides overview of data issues across all doctors
}
```

## Data Synchronization Strategy

### Priority Order:
1. **User Document**: Source of truth for basic info (name, email, phone)
2. **Doctor Document**: Contains professional details and references user data
3. **Onboarding Forms**: Pre-filled with existing data, updates doctor document

### Sync Rules:
- Name and email always come from user document
- Phone number synced from user to doctor document if missing
- Professional details stored only in doctor document
- Email field is read-only during onboarding

## Testing and Validation

### Manual Testing Steps:
1. **New Doctor Registration**:
   - Register as doctor with name and email
   - Start onboarding process
   - Verify name and email are pre-filled
   - Complete onboarding
   - Check both user and doctor documents have correct data

2. **Existing Doctor Data**:
   - Run data sync utility for existing doctors
   - Verify missing name/email data is populated
   - Check data consistency between collections

### Validation Commands:
```dart
// Check specific doctor data
final validation = await DoctorDataSyncHelper.validateDoctorData('doctor-id');
print('Validation: $validation');

// Get overview of all doctor data issues
final summary = await DoctorDataSyncHelper.getDoctorDataSummary();
print('Summary: $summary');

// Sync all doctor data
await DoctorDataSyncHelper.syncAllDoctorData();

// Sync specific doctor
final success = await DoctorDataSyncHelper.syncDoctorData('doctor-id');
print('Sync successful: $success');
```

## Database Structure

### Users Collection:
```json
{
  "uid": "doctor-id",
  "email": "doctor@example.com",
  "fullName": "Dr. John Smith",
  "phoneNumber": "9876543210",
  "role": "doctor",
  "isActive": true,
  "isVerified": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Doctors Collection:
```json
{
  "uid": "doctor-id",
  "email": "doctor@example.com",        // Synced from users
  "fullName": "Dr. John Smith",         // Synced from users
  "phoneNumber": "9876543210",          // Synced from users
  "role": "doctor",
  "specialty": "Cardiology",            // From onboarding
  "licenseNumber": "MED123456",         // From onboarding
  "profileComplete": false,
  "onboardingCompleted": false,
  "onboardingStep": 2,
  "verificationStatus": "pending",
  "isActive": true,
  "isVerified": false,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Migration for Existing Data

### For Existing Doctors with Missing Data:
```dart
// Run this once to fix existing data
await DoctorDataSyncHelper.syncAllDoctorData();
```

### For Missing Doctor Documents:
```dart
// Create doctor documents for users with doctor role
await DoctorDataSyncHelper.initializeMissingDoctorDocuments();
```

## Error Handling

### Graceful Degradation:
- If loading existing data fails, onboarding continues with empty forms
- Data sync errors are logged but don't break the process
- Email service can still work with partial data

### Logging:
```dart
print('✅ Loaded existing doctor data: ${existingData.keys.toList()}');
print('⚠️ Error loading existing doctor data: $e');
print('📝 Syncing name for doctor $doctorId: ${userData['fullName']}');
```

## Files Modified

1. `lib/screens/doctor/onboarding/doctor_onboarding_screen.dart` - Added data loading
2. `lib/screens/doctor/onboarding/professional_details_step.dart` - Made email read-only
3. `lib/utils/doctor_data_sync_helper.dart` - New sync utility
4. `docs/DOCTOR_NAME_EMAIL_STORAGE_FIX.md` - This documentation

## Expected Results

After applying these fixes:

### ✅ New Doctor Registration:
- Name and email automatically pre-filled in onboarding
- Email field is read-only (prevents accidental changes)
- Data consistency maintained between user and doctor documents

### ✅ Existing Doctor Data:
- Missing name/email data can be synced from user documents
- Data validation tools available for checking integrity
- Bulk sync operations for fixing multiple doctors

### ✅ Email Service:
- Doctor verification emails will have correct name and email
- No more "Doctor not found" errors in email service
- Consistent data for all email templates

## Monitoring and Maintenance

### Regular Checks:
```dart
// Weekly data integrity check
final summary = await DoctorDataSyncHelper.getDoctorDataSummary();
if (summary['missingName'] > 0 || summary['missingEmail'] > 0) {
  await DoctorDataSyncHelper.syncAllDoctorData();
}
```

### Health Monitoring:
- Monitor doctor registration completion rates
- Check for email delivery failures
- Validate data consistency during onboarding

The doctor name and email storage issue has been comprehensively resolved with proper data loading, field validation, and sync utilities for maintaining data integrity.