# Phone Number Storage Fix

## Issue Summary
Doctor and patient mobile numbers were not being properly stored to Firebase due to several issues:

1. **Field name mismatch**: Doctor onboarding was saving phone numbers as `'phone'` instead of `'phoneNumber'`
2. **Missing synchronization**: Phone numbers from doctor onboarding weren't being synced to the user document
3. **Inconsistent formatting**: Phone numbers weren't being consistently formatted (digits only)

## Root Causes

### 1. Doctor Onboarding Field Mismatch
- **File**: `lib/screens/doctor/onboarding/professional_details_step.dart`
- **Issue**: Phone number was saved as `'phone'` but models expect `'phoneNumber'`
- **Impact**: Doctor phone numbers weren't accessible in other parts of the app

### 2. Missing User Document Sync
- **File**: `lib/services/doctor/doctor_onboarding_service.dart`
- **Issue**: Phone numbers saved during onboarding weren't synced to the main user document
- **Impact**: Phone numbers only existed in doctor-specific collection, not in the main users collection

### 3. Inconsistent Phone Number Formatting
- **Files**: Multiple registration and profile edit screens
- **Issue**: Phone numbers weren't consistently formatted to digits-only
- **Impact**: Phone numbers could contain spaces, dashes, or other characters

## Fixes Applied

### 1. Fixed Field Name Consistency
**File**: `lib/screens/doctor/onboarding/professional_details_step.dart`

```dart
// Before
final data = {
  'name': _nameController.text.trim(),
  'phone': _phoneController.text.trim(),
  // ...
};

// After
final data = {
  'fullName': _nameController.text.trim(),
  'phoneNumber': ValidationUtils.formatPhoneNumber(_phoneController.text),
  // ...
};
```

### 2. Added Phone Number Synchronization
**File**: `lib/services/doctor/doctor_onboarding_service.dart`

```dart
// Added sync logic to saveProfessionalDetails method
if (data['phoneNumber'] != null || data['fullName'] != null) {
  try {
    final updateData = <String, dynamic>{};
    if (data['phoneNumber'] != null && data['phoneNumber'].toString().trim().isNotEmpty) {
      updateData['phoneNumber'] = data['phoneNumber'].toString().trim();
    }
    if (data['fullName'] != null && data['fullName'].toString().trim().isNotEmpty) {
      updateData['fullName'] = data['fullName'].toString().trim();
    }
    
    if (updateData.isNotEmpty) {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(doctorId).update(updateData);
    }
  } catch (e) {
    print('Warning: Failed to sync data to user document: $e');
  }
}
```

### 3. Enhanced Phone Number Validation and Formatting
**File**: `lib/utils/validation_utils.dart`

```dart
// Added phone number formatting utility
static String? formatPhoneNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  
  // Remove any non-digit characters
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Return null if empty after cleaning, otherwise return cleaned digits
  return digitsOnly.isEmpty ? null : digitsOnly;
}

// Fixed regex pattern
static String? validatePhoneNumber(String? value, {bool isRequired = false}) {
  // ... validation logic with proper 10-digit limit and Indian mobile number pattern
  if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(digitsOnly)) {
    return 'Please enter a valid Indian mobile number';
  }
}
```

### 4. Updated Profile Edit Screens
**Files**: 
- `lib/screens/profile/edit_profile_screen.dart`
- Other profile-related screens

```dart
// Before
'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),

// After
'phoneNumber': ValidationUtils.formatPhoneNumber(_phoneController.text),
```

## Phone Number Validation Rules

The system now enforces these rules for phone numbers:

1. **Exactly 10 digits** (after removing non-digit characters)
2. **Must start with 6, 7, 8, or 9** (Indian mobile number pattern)
3. **Digits only storage** (spaces, dashes, etc. are removed)
4. **Optional field** (can be null/empty)

## Data Migration

A migration helper has been created to fix existing data:

**File**: `lib/utils/phone_number_migration_helper.dart`

### Available Methods:
- `runPhoneNumberMigration()` - Complete migration process
- `checkAndFixUserPhoneNumbers()` - Fix user document phone numbers
- `checkAndFixDoctorPhoneNumbers()` - Fix doctor document phone numbers
- `validateAllPhoneNumbers()` - Validate all existing phone numbers

### To Run Migration:
```dart
import 'package:curevia/utils/phone_number_migration_helper.dart';

// Run complete migration
await PhoneNumberMigrationHelper.runPhoneNumberMigration();

// Or run individual checks
await PhoneNumberMigrationHelper.validateAllPhoneNumbers();
```

## Testing

### Manual Testing Steps:
1. **Doctor Registration**:
   - Complete doctor onboarding with phone number
   - Verify phone number appears in both `users` and `doctors` collections
   - Check phone number is formatted as digits only

2. **Patient Profile Edit**:
   - Edit patient profile and add phone number
   - Verify phone number is saved to `users` collection
   - Test emergency contact phone number

3. **Phone Number Validation**:
   - Test with invalid formats (less than 10 digits, starting with 1-5)
   - Test with valid formats (10 digits starting with 6-9)
   - Test with spaces, dashes (should be cleaned)

### Expected Behavior:
- ✅ Phone numbers stored as 10-digit strings (e.g., "9876543210")
- ✅ Phone numbers synced between user and doctor collections
- ✅ Validation prevents invalid phone numbers
- ✅ Existing data can be migrated and fixed

## Files Modified

1. `lib/screens/doctor/onboarding/professional_details_step.dart` - Fixed field names
2. `lib/services/doctor/doctor_onboarding_service.dart` - Added sync logic
3. `lib/utils/validation_utils.dart` - Enhanced validation and formatting
4. `lib/screens/profile/edit_profile_screen.dart` - Updated to use formatting
5. `lib/utils/phone_number_migration_helper.dart` - New migration utility
6. `docs/PHONE_NUMBER_STORAGE_FIX.md` - This documentation

## Summary

The phone number storage issue has been resolved by:
- Fixing field name inconsistencies
- Adding proper synchronization between collections
- Implementing consistent formatting and validation
- Providing migration tools for existing data

Phone numbers are now properly stored in Firebase with 10-digit validation and consistent formatting across the entire application.