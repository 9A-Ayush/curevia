# Notification Sound Fix Documentation

## Problem Summary
Push notification sounds were not working consistently on the mobile app:
- ✅ Sounds worked when phone was connected to laptop via USB
- ❌ Sounds did not play after disconnecting the phone
- ❌ Inconsistent behavior across different app states (foreground/background/killed)

## Root Causes Identified

### 1. **Notification Channel Configuration Issues**
- Channels were created with `Importance.defaultImportance` instead of `Importance.high` or `Importance.max`
- Missing `audioAttributesUsage` parameter which is critical for sound playback
- Channels might have been created without sound on first initialization

### 2. **USB Debugging Audio Focus**
- When connected via USB for debugging, Android may temporarily override audio settings
- This masked the underlying notification sound configuration issues

### 3. **Missing Audio Attributes**
- `AudioAttributesUsage.notification` was not consistently set
- This parameter tells Android to use the notification audio stream

### 4. **Channel Importance Level**
- Low importance channels don't play sound by default on Android 8.0+
- Need `Importance.high` or `Importance.max` for reliable sound playback

## Solutions Implemented

### 1. Enhanced FCM Service (`lib/services/notifications/fcm_service.dart`)

#### Channel Creation Improvements:
```dart
// Before
importance: type.isHighPriority ? Importance.high : Importance.defaultImportance

// After
importance: type.isHighPriority ? Importance.max : Importance.high
audioAttributesUsage: AudioAttributesUsage.notification
```

#### Added Channel Verification:
- Automatically verifies channels after creation
- Logs detailed channel configuration for debugging
- Ensures sound settings are properly applied

#### Enhanced Notification Details:
```dart
AndroidNotificationDetails(
  // ... other params
  audioAttributesUsage: AudioAttributesUsage.notification,
  visibility: NotificationVisibility.public,
  fullScreenIntent: notification.type.isHighPriority,
  category: AndroidNotificationCategory.event,
  onlyAlertOnce: false, // Ensures sound plays every time
)
```

### 2. Diagnostic Service (`lib/services/notifications/notification_diagnostic_service.dart`)

New service to help troubleshoot notification issues:

#### Features:
- **Comprehensive Diagnostics**: Checks FCM, permissions, channels, and sound files
- **Test Notifications**: Send test notifications with different sounds
- **Channel Recreation**: Recreate channels with proper configuration
- **Detailed Reporting**: Generates diagnostic reports for debugging

#### Usage:
```dart
// Run diagnostics
final results = await NotificationDiagnosticService.instance.runDiagnostics();

// Send test notification
await NotificationDiagnosticService.instance.sendTestNotification(
  type: NotificationType.appointmentReminder,
);

// Test all sounds
await NotificationDiagnosticService.instance.testAllNotificationSounds();

// Recreate channels
await NotificationDiagnosticService.instance.recreateNotificationChannels();
```

### 3. Debug Screen (`lib/screens/debug/notification_test_screen.dart`)

User-friendly interface for testing notifications:

#### Features:
- View diagnostic summary
- Test individual notification sounds
- Test all sounds sequentially
- Recreate notification channels
- View channel configuration details
- Troubleshooting tips

#### Access:
Navigate to `NotificationTestScreen` from your app's debug menu or settings.

## Sound Files Configuration

### Android Sound Files Location:
```
android/app/src/main/res/raw/
├── appointment_notification.mp3
├── payment_notification.mp3
└── verification_notification.mp3
```

### Sound File Requirements:
- Format: MP3 or OGG
- Location: `android/app/src/main/res/raw/`
- Naming: lowercase with underscores (no spaces)
- Reference: Without file extension in code

### iOS Sound Files Location:
```
ios/Runner/
├── appointment_notification.mp3
├── payment_notification.mp3
└── verification_notification.mp3
```

## Testing Checklist

### ✅ Pre-Testing Setup:
1. Ensure sound files exist in correct locations
2. Verify AndroidManifest.xml has notification permissions
3. Check that notification channels are created on app start

### ✅ Test Scenarios:

#### 1. **Foreground State**
- [ ] App is open and visible
- [ ] Notification arrives
- [ ] Sound plays
- [ ] Notification appears in status bar

#### 2. **Background State**
- [ ] App is in background (home button pressed)
- [ ] Notification arrives
- [ ] Sound plays
- [ ] Notification appears in status bar

#### 3. **Killed State**
- [ ] App is force-closed
- [ ] Notification arrives
- [ ] Sound plays
- [ ] Notification appears in status bar

#### 4. **USB Connection Test**
- [ ] Test with phone connected to laptop
- [ ] Disconnect phone
- [ ] Test again without USB connection
- [ ] Verify sound plays in both scenarios

#### 5. **Device Settings Test**
- [ ] Normal mode (sound plays)
- [ ] Silent mode (no sound, vibration only)
- [ ] Do Not Disturb mode (follows DND rules)
- [ ] Battery saver mode (sound should still play)

### ✅ Multi-Device Testing:
Test on various Android versions:
- [ ] Android 8.0 (Oreo) - First version with notification channels
- [ ] Android 9.0 (Pie)
- [ ] Android 10
- [ ] Android 11
- [ ] Android 12+

## Common Issues and Solutions

### Issue 1: Sound Not Playing After App Update
**Cause**: Notification channels persist across app updates
**Solution**: 
```dart
// Recreate channels with new configuration
await NotificationDiagnosticService.instance.recreateNotificationChannels();
```
**Note**: Users may need to manually delete old channels from device settings

### Issue 2: Sound Works in Debug but Not Release
**Cause**: USB debugging may affect audio focus
**Solution**: 
- Always test release builds without USB connection
- Use wireless debugging or test on physical device without cable

### Issue 3: Sound Not Playing on Specific Devices
**Cause**: Device-specific battery optimization or manufacturer restrictions
**Solution**:
- Disable battery optimization for the app
- Check manufacturer-specific settings (e.g., Xiaomi, Huawei)
- Ensure app has notification permissions

### Issue 4: Channels Created Without Sound
**Cause**: Initial channel creation may have failed or used wrong settings
**Solution**:
```dart
// User must manually delete channels from device settings:
// Settings > Apps > Curevia > Notifications > [Channel Name] > Delete

// Then recreate channels:
await NotificationDiagnosticService.instance.recreateNotificationChannels();
```

## Device-Specific Considerations

### Xiaomi Devices:
- Go to Settings > Apps > Curevia > Battery saver > No restrictions
- Enable "Autostart"
- Disable "Battery optimization"

### Huawei Devices:
- Go to Settings > Apps > Curevia > Battery > App launch
- Set to "Manage manually"
- Enable all options

### Samsung Devices:
- Go to Settings > Apps > Curevia > Battery
- Set to "Unrestricted"
- Disable "Put app to sleep"

### OnePlus Devices:
- Go to Settings > Apps > Curevia > Battery optimization
- Select "Don't optimize"

## Monitoring and Debugging

### Enable Debug Logging:
The FCM service now includes detailed logging:
```
✅ Created notification channel: patient_appointment_notifications with sound: appointment_notification
✅ Notification shown: Appointment Reminder
   Channel: patient_appointment_notifications
   Sound: appointment_notification
```

### Run Diagnostics:
```dart
final results = await NotificationDiagnosticService.instance.runDiagnostics();
print(NotificationDiagnosticService.instance.getDiagnosticSummary(results));
```

### Check Logs:
Look for these indicators in logs:
- `✅` = Success
- `⚠️` = Warning
- `❌` = Error

## Best Practices

### 1. **Always Set Audio Attributes**
```dart
audioAttributesUsage: AudioAttributesUsage.notification
```

### 2. **Use High Importance for Critical Notifications**
```dart
importance: Importance.max  // For critical notifications
importance: Importance.high // For important notifications
```

### 3. **Test Without USB Connection**
Always perform final testing with phone disconnected from laptop

### 4. **Verify Channel Configuration**
Use the diagnostic service to verify channels are properly configured

### 5. **Handle Channel Updates Carefully**
Remember that channels cannot be deleted programmatically - users must do it manually

## Migration Guide

### For Existing Apps:
1. Update FCM service with new configuration
2. Inform users to clear app data or reinstall (to reset channels)
3. Or guide users to manually delete old channels from device settings

### For New Installations:
Channels will be created correctly from the start with proper sound configuration

## Support and Troubleshooting

### User-Facing Instructions:
If users report sound issues, guide them to:
1. Open the Notification Test Screen (in app settings/debug menu)
2. Run diagnostics
3. Test notification sounds
4. Follow troubleshooting tips displayed in the app

### Developer Debugging:
1. Check logs for channel creation messages
2. Run diagnostic service
3. Verify sound files exist in correct locations
4. Test on multiple devices and Android versions
5. Test with and without USB connection

## Conclusion

The notification sound issue has been comprehensively addressed by:
1. ✅ Fixing channel importance levels
2. ✅ Adding audio attributes usage
3. ✅ Implementing channel verification
4. ✅ Creating diagnostic tools
5. ✅ Adding debug UI for testing
6. ✅ Documenting device-specific considerations

Notification sounds should now work reliably across all conditions, regardless of USB connection status.
