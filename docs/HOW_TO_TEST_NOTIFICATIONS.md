# How to Test Notification Sounds - Quick Guide

## For Developers

### Step 1: Access Test Screen
1. Open the Curevia app
2. Go to **Profile** tab (bottom navigation)
3. Scroll down to find **"Test Notifications"** option
4. Tap to open the Notification Test Screen

> **Note**: This option is only visible in debug mode

### Step 2: Run Diagnostics
1. The diagnostics run automatically when you open the screen
2. Check the **System Status** card at the top
3. Look for ✅ (all good) or ⚠️ (issues found)

### Step 3: Test Sounds
1. Tap **"Test Appointment Sound"** button
2. You should hear a notification sound immediately
3. Check your notification tray - you should see the test notification
4. Repeat for other sound types if needed

### Step 4: Critical Test - Disconnect USB
1. **Disconnect your phone from the laptop**
2. Wait 5 seconds
3. Tap **"Test Appointment Sound"** again
4. **Verify the sound plays** - this is the critical test!

### Step 5: Test All Sounds
1. Tap **"Test All Sounds"** button
2. You'll hear 3 different notification sounds with 3-second gaps
3. Verify all sounds play correctly

## For End Users (If Reporting Issues)

### Quick Fix Steps:

#### 1. Check Basic Settings
- Ensure phone is not in **Do Not Disturb** mode
- Check phone volume is not muted
- Verify **Silent mode** is off

#### 2. Check App Permissions
1. Go to phone **Settings**
2. Find **Apps** > **Curevia**
3. Tap **Notifications**
4. Ensure notifications are **ON**
5. Check each notification category has **Sound enabled**

#### 3. Disable Battery Optimization
1. Go to phone **Settings**
2. Find **Apps** > **Curevia**
3. Tap **Battery**
4. Select **"Unrestricted"** or **"No restrictions"**

#### 4. Recreate Notification Channels
1. Open Curevia app
2. Go to **Profile** > **Test Notifications**
3. Tap **"Recreate Channels"** button
4. Restart the app
5. Test notifications again

## Device-Specific Instructions

### Xiaomi / MIUI:
1. Settings > Apps > Curevia > **Battery saver** > No restrictions
2. Settings > Apps > Curevia > **Autostart** > Enable
3. Settings > Apps > Curevia > **Battery** > No restrictions

### Huawei / EMUI:
1. Settings > Apps > Curevia > **Battery** > App launch
2. Set to **"Manage manually"**
3. Enable all three options (Auto-launch, Secondary launch, Run in background)

### Samsung / One UI:
1. Settings > Apps > Curevia > **Battery**
2. Set to **"Unrestricted"**
3. Disable **"Put app to sleep"**
4. Settings > Apps > Curevia > **Notifications** > Ensure all ON

### OnePlus / OxygenOS:
1. Settings > Apps > Curevia > **Battery optimization**
2. Select **"Don't optimize"**
3. Settings > Apps > Curevia > **Mobile data** > Enable background data

### Realme / ColorOS:
1. Settings > Apps > Curevia > **App battery usage**
2. Select **"No restrictions"**
3. Enable **"Allow background activity"**

## Common Issues and Solutions

### Issue: "Sound works when connected to laptop but not after disconnecting"
**Solution**: This was the original bug - it should now be fixed. If still occurring:
1. Restart the app
2. Recreate channels from Test Notifications screen
3. Test again without USB connection

### Issue: "No sound at all"
**Solution**:
1. Check phone is not in Silent/DND mode
2. Check app notification settings
3. Disable battery optimization
4. Recreate channels
5. Reinstall app as last resort

### Issue: "Sound works sometimes but not always"
**Solution**:
1. Check if it's related to app state (foreground vs background)
2. Disable battery optimization
3. Check device-specific battery settings
4. Ensure "Unrestricted" battery mode

### Issue: "Sound works for some notification types but not others"
**Solution**:
1. Go to phone Settings > Apps > Curevia > Notifications
2. Check each notification category individually
3. Ensure sound is enabled for each
4. Use "Recreate Channels" button in app

## Testing Checklist

Use this checklist to verify notifications work correctly:

### Basic Tests:
- [ ] Phone not in Silent mode
- [ ] Phone not in Do Not Disturb mode
- [ ] App has notification permissions
- [ ] Battery optimization disabled

### Sound Tests:
- [ ] Test notification sound plays
- [ ] Sound plays with phone disconnected from laptop
- [ ] Sound plays when app is in foreground
- [ ] Sound plays when app is in background
- [ ] Sound plays when app is killed/closed

### Advanced Tests:
- [ ] Sound plays after phone restart
- [ ] Sound plays after app reinstall
- [ ] Sound plays on different notification types
- [ ] Scheduled notifications play sound

## What to Report if Issues Persist

If you've tried everything and sounds still don't work, please report:

1. **Device Information**:
   - Phone model (e.g., Xiaomi Redmi Note 11)
   - Android version (e.g., Android 12)
   - MIUI/One UI/etc. version

2. **Diagnostic Results**:
   - Open Test Notifications screen
   - Take screenshot of System Status
   - Take screenshot of Notification Channels section

3. **What You've Tried**:
   - List all troubleshooting steps attempted
   - Specify which tests pass and which fail

4. **When It Fails**:
   - Always fails or sometimes?
   - Specific app states (foreground/background/killed)?
   - After specific actions (USB disconnect, restart, etc.)?

## Quick Reference Commands

### For Developers (Debug Console):
```dart
// Run diagnostics
await NotificationDiagnosticService.instance.runDiagnostics();

// Test single notification
await NotificationDiagnosticService.instance.sendTestNotification(
  type: NotificationType.appointmentReminder,
);

// Test all sounds
await NotificationDiagnosticService.instance.testAllNotificationSounds();

// Recreate channels
await NotificationDiagnosticService.instance.recreateNotificationChannels();
```

## Success Indicators

You'll know notifications are working correctly when:
- ✅ You hear sound immediately when testing
- ✅ Sound plays with phone disconnected from laptop
- ✅ Sound plays in all app states (foreground/background/killed)
- ✅ Notification appears in notification tray
- ✅ Phone vibrates (if vibration enabled)
- ✅ Notification LED lights up (if device has LED)

## Need More Help?

- Check `NOTIFICATION_SOUND_FIX.md` for technical details
- Check `NOTIFICATION_FIX_SUMMARY.md` for quick overview
- Check `NOTIFICATION_CHANGES_APPLIED.md` for list of changes

---

**Remember**: The most important test is with the phone **disconnected from the laptop**. This is where the original issue occurred.
