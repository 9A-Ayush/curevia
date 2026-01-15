# Email Service Troubleshooting Guide

## Issue Summary
Emails are not being sent to doctors after admin verification or rejection of their applications.

## Root Causes Identified

### 1. **Missing Email Service Calls in Details Screen**
- **File**: `lib/screens/admin/doctor_verification_details_screen.dart`
- **Issue**: The verification methods in the details screen were not calling the email service
- **Impact**: When admins verify/reject from the details screen, no emails were sent

### 2. **Potential Email Service Configuration Issues**
- **Service URL**: May not be reachable or properly configured
- **Firebase Integration**: Email service may not be able to fetch doctor data
- **SMTP Configuration**: Gmail SMTP may not be properly configured

## Fixes Applied

### 1. **Added Email Service Calls to Details Screen**

**File**: `lib/screens/admin/doctor_verification_details_screen.dart`

#### Import Added:
```dart
import '../../services/email_service.dart';
```

#### Approval Method Updated:
```dart
// Send approval email
try {
  await EmailService.sendDoctorVerificationEmail(
    doctorId: widget.doctorId,
    status: 'approved',
    adminId: 'admin', // Replace with actual admin ID
  );
  debugPrint('✅ Doctor approval email sent successfully');
} catch (emailError) {
  debugPrint('⚠️ Failed to send approval email: $emailError');
  // Don't fail the verification process if email fails
}
```

#### Rejection Method Updated:
```dart
// Send rejection email
try {
  await EmailService.sendDoctorVerificationEmail(
    doctorId: widget.doctorId,
    status: 'rejected',
    adminId: 'admin', // Replace with actual admin ID
  );
  debugPrint('✅ Doctor rejection email sent successfully');
} catch (emailError) {
  debugPrint('⚠️ Failed to send rejection email: $emailError');
  // Don't fail the verification process if email fails
}
```

### 2. **Created Email Service Diagnostic Tool**

**File**: `lib/utils/email_service_diagnostic.dart`

This tool can help identify email service issues:

```dart
// Run comprehensive diagnostics
final results = await EmailServiceDiagnostic.runDiagnostics();

// Test specific doctor verification email
final success = await EmailServiceDiagnostic.testDoctorVerificationEmail(
  doctorId: 'test-doctor-id',
  status: 'approved',
);

// Check if email service is reachable
final isReachable = await EmailServiceDiagnostic.isEmailServiceReachable();
```

## Email Service Architecture

### Flutter App → Email Service Flow:
1. **Admin Action**: Admin approves/rejects doctor in Flutter app
2. **API Call**: Flutter app calls email service endpoint
3. **Doctor Data Fetch**: Email service fetches doctor data from Firebase
4. **Email Generation**: Email service generates HTML email template
5. **SMTP Send**: Email service sends email via Gmail SMTP
6. **Response**: Success/failure response back to Flutter app

### Email Service Endpoints:
- `POST /send-doctor-verification` - Send verification emails
- `GET /health` - Service health check
- `GET /stats/realtime` - Firebase connection status
- `POST /test-email` - Test email functionality

## Troubleshooting Steps

### 1. **Check Email Service Status**
```dart
// Test if email service is reachable
final status = await EmailServiceDiagnostic.getEmailServiceStatus();
print('Email Service Status: $status');
```

### 2. **Run Full Diagnostics**
```dart
// Run comprehensive diagnostics
await EmailServiceDiagnostic.runDiagnostics();
```

### 3. **Check Email Service Logs**
- **Development**: Check console logs in email service terminal
- **Production**: Check Render.com logs for the email service

### 4. **Verify Email Service Configuration**

#### Required Environment Variables:
```env
# Gmail SMTP Configuration
GMAIL_USER=your-gmail@gmail.com
GMAIL_APP_PASSWORD=your-app-password

# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour-Private-Key\n-----END PRIVATE KEY-----\n"

# Email Configuration
FROM_EMAIL=your-email@gmail.com
SUPPORT_EMAIL=your-email@gmail.com
```

### 5. **Test Email Service Manually**

#### Health Check:
```bash
curl https://curvia-mail-service.onrender.com/health
```

#### Test Email:
```bash
curl -X POST https://curvia-mail-service.onrender.com/test-email \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

#### Doctor Verification Test:
```bash
curl -X POST https://curvia-mail-service.onrender.com/send-doctor-verification \
  -H "Content-Type: application/json" \
  -d '{"doctorId":"test-doctor-id","status":"approved"}'
```

## Common Issues and Solutions

### 1. **Email Service Unreachable**
- **Symptoms**: Connection timeout, service unreachable
- **Solutions**: 
  - Check if email service is deployed and running
  - Verify URL configuration in Flutter app
  - Check network connectivity

### 2. **Firebase Connection Issues**
- **Symptoms**: Cannot fetch doctor data, Firebase errors
- **Solutions**:
  - Verify Firebase credentials in email service
  - Check Firebase project permissions
  - Ensure service account has proper roles

### 3. **SMTP Configuration Issues**
- **Symptoms**: Email sending fails, SMTP errors
- **Solutions**:
  - Verify Gmail app password is correct
  - Check Gmail account settings
  - Ensure 2FA is enabled and app password is generated

### 4. **Doctor Data Not Found**
- **Symptoms**: Doctor not found errors
- **Solutions**:
  - Verify doctor exists in Firebase
  - Check doctor document structure
  - Ensure email field is present in doctor document

## Testing Checklist

### Before Testing:
- [ ] Email service is deployed and running
- [ ] Firebase credentials are configured
- [ ] Gmail SMTP is configured
- [ ] Doctor documents have email addresses

### Test Cases:
- [ ] Approve doctor from verification screen
- [ ] Reject doctor from verification screen  
- [ ] Approve doctor from details screen
- [ ] Reject doctor from details screen
- [ ] Check email service logs for success/failure
- [ ] Verify emails are received (check spam folder)

### Expected Results:
- [ ] No errors in Flutter app console
- [ ] Success messages in email service logs
- [ ] Emails received by doctors
- [ ] Email content is properly formatted

## Monitoring and Logging

### Flutter App Logs:
```dart
debugPrint('✅ Doctor approval email sent successfully');
debugPrint('⚠️ Failed to send approval email: $emailError');
```

### Email Service Logs:
```javascript
console.log('✅ Doctor approved email sent to Dr. ${doctorData.name}');
console.error('❌ Email sending failed:', error);
```

### Firebase Logs:
- Check Firestore for doctor document updates
- Verify verification status changes
- Monitor email activity logs

## Files Modified

1. `lib/screens/admin/doctor_verification_details_screen.dart` - Added email service calls
2. `lib/utils/email_service_diagnostic.dart` - New diagnostic tool
3. `docs/EMAIL_SERVICE_TROUBLESHOOTING.md` - This documentation

## Next Steps

1. **Test the fixes** by verifying/rejecting a doctor application
2. **Run diagnostics** to identify any remaining issues
3. **Check email service logs** for success/failure messages
4. **Monitor email delivery** to ensure doctors receive emails
5. **Update admin ID** in email service calls to use actual admin user ID

## Support

If issues persist:
1. Run the diagnostic tool to identify specific problems
2. Check email service dashboard at `/dashboard` endpoint
3. Review email service logs for detailed error messages
4. Verify all configuration settings are correct