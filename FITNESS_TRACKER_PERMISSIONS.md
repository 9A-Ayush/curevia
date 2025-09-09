# 🏃‍♀️ Fitness Tracker Permissions Guide

## Overview

The Curevia fitness tracker requires several permissions to provide accurate health and fitness monitoring. This guide explains what permissions are needed and why.

## 📱 Required Permissions

### 🚶‍♂️ **Activity Recognition**
- **Permission**: `ACTIVITY_RECOGNITION`
- **Purpose**: Detect when you're walking, running, or stationary
- **Why needed**: Essential for step counting and activity classification
- **User benefit**: Automatic workout detection and accurate step tracking

### 📊 **Device Sensors**
- **Permissions**: 
  - `BODY_SENSORS`
  - `HIGH_SAMPLING_RATE_SENSORS`
- **Purpose**: Access accelerometer, gyroscope, and step counter sensors
- **Why needed**: Real-time movement detection and step counting
- **User benefit**: Precise activity tracking and calorie estimation

### ❤️ **Health Data Access**
- **Permissions**:
  - `health.READ_STEPS` / `health.WRITE_STEPS`
  - `health.READ_DISTANCE` / `health.WRITE_DISTANCE`
  - `health.READ_ACTIVE_CALORIES_BURNED` / `health.WRITE_ACTIVE_CALORIES_BURNED`
  - `health.READ_HEART_RATE`
  - `health.READ_EXERCISE` / `health.WRITE_EXERCISE`
- **Purpose**: Sync with system health data and other fitness apps
- **Why needed**: Comprehensive health tracking and data consistency
- **User benefit**: Unified health data across all your apps

## 🔧 Hardware Features

### 📱 **Sensors**
- **Accelerometer**: Movement detection and step counting
- **Gyroscope**: Orientation and rotation tracking
- **Step Counter**: Dedicated step counting hardware
- **Step Detector**: Real-time step detection
- **Heart Rate**: Heart rate monitoring (if available)

## 🛡️ Privacy & Security

### 🔒 **Data Protection**
- ✅ All fitness data stays on your device
- ✅ No data is shared without explicit consent
- ✅ You can revoke permissions at any time
- ✅ Data is encrypted and securely stored

### 📍 **What We DON'T Access**
- ❌ Your exact location (only movement patterns)
- ❌ Personal health records
- ❌ Data from other apps without permission
- ❌ Any data when the app is not in use

## 🎯 Features Enabled by Permissions

### ✅ **With Full Permissions**
- 📊 Real-time step counting
- 🔥 Accurate calorie tracking
- 📏 Distance measurement
- 🏃‍♂️ Automatic workout detection
- 📈 Progress tracking and goals
- 📱 Health app synchronization
- ⏱️ Activity duration tracking
- 🎯 Personalized fitness insights

### ⚠️ **With Limited Permissions**
- 👁️ Visual-only fitness interface
- 📝 Manual activity logging
- 🎯 Goal setting (without tracking)
- 📊 Basic progress visualization

## 📋 Permission Setup Process

### 1. **Initial Setup**
```
App Launch → Fitness Tracker → Permission Request Dialog
```

### 2. **Permission Dialog**
- Clear explanation of each permission
- Benefits of granting access
- Option to proceed or cancel

### 3. **System Permissions**
- Android system permission dialogs
- Health app authorization (if available)
- Sensor access confirmation

### 4. **Verification**
- Permission status check
- Feature availability confirmation
- Fallback options if denied

## 🔄 Managing Permissions

### ✅ **Grant Permissions**
1. Open Curevia app
2. Go to Fitness Tracker
3. Tap "Grant Permissions" when prompted
4. Follow system dialogs
5. Confirm in app settings

### ❌ **Revoke Permissions**
1. Go to device Settings
2. Apps → Curevia → Permissions
3. Toggle off specific permissions
4. Or use in-app settings menu

### 🔄 **Re-enable Permissions**
1. In Fitness Tracker, tap Settings (⚙️)
2. Select "Permissions"
3. Tap "Open Settings"
4. Re-enable required permissions

## 🚨 Troubleshooting

### **Step Counter Not Working**
- ✅ Check Activity Recognition permission
- ✅ Ensure device has step counter sensor
- ✅ Restart app after granting permissions
- ✅ Check if other fitness apps are interfering

### **No Health Data Sync**
- ✅ Grant Health Data permissions
- ✅ Check Google Fit / Apple Health settings
- ✅ Ensure health apps are updated
- ✅ Restart device if needed

### **Inaccurate Tracking**
- ✅ Calibrate by walking known distance
- ✅ Check sensor permissions
- ✅ Ensure phone is carried properly
- ✅ Update app to latest version

## 📱 Device Compatibility

### ✅ **Fully Supported**
- Android 6.0+ with step counter
- Devices with accelerometer/gyroscope
- Google Fit compatible devices
- Wear OS smartwatches

### ⚠️ **Limited Support**
- Older Android versions (manual tracking only)
- Devices without step counter sensor
- Tablets (limited sensor accuracy)

## 🎯 Best Practices

### 📱 **For Optimal Tracking**
1. **Carry your phone**: Keep device with you during activities
2. **Grant all permissions**: Enable full feature set
3. **Regular sync**: Open app daily for data sync
4. **Battery optimization**: Exclude app from battery optimization
5. **Update regularly**: Keep app updated for best performance

### 🔋 **Battery Optimization**
- Fitness tracking uses minimal battery
- Background activity is optimized
- Sensors are accessed efficiently
- No unnecessary location tracking

## 📞 Support

### 🆘 **Need Help?**
- In-app settings → Help & Support
- Check permission status in app
- Review this guide for troubleshooting
- Contact support for technical issues

### 🔄 **Reset Fitness Data**
- Settings → Fitness Settings → Reset Data
- This will clear all stored fitness data
- Permissions will need to be re-granted
- Goals and preferences will be reset

---

**Remember**: Your privacy is our priority. All fitness data remains on your device and is never shared without your explicit consent. You have full control over your data and permissions at all times.
