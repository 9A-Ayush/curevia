# FCM Setup Guide for Admin Notifications

## Overview
This guide explains how to set up Firebase Cloud Messaging (FCM) for admin notifications in the Curevia app.

## Prerequisites
- Firebase project with FCM enabled
- Admin access to Firebase Console

## Setup Methods

### Method 1: FCM Server Key (Legacy) - Recommended for Quick Setup

#### 1. Get FCM Server Key
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (`curevia-f31a8`)
3. Go to Project Settings (gear icon)
4. Navigate to "Cloud Messaging" tab
5. Copy the "Server key" (legacy) - it looks like: `AAAAxxxxxxx:APA91bH...`

#### 2. Add Server Key to Environment
Add the FCM server key to your `.env` file:
```
FCM_SERVER_KEY=AAAAxxxxxxx:APA91bH...your_server_key_here
```

### Method 2: Service Account (More Secure) - Using Your JSON File

Since you have the service account JSON file, I'll update the implementation to support this method as well.

#### 1. Add Service Account Path to Environment
Add to your `.env` file:
```
FIREBASE_SERVICE_ACCOUNT_PATH=curevia-f31a8-firebase-adminsdk-fbsvc-1a9966980f.json
```

## Test Configuration
Use the debug service to test FCM setup:
```dart
final results = await AdminNotificationDebugService.testAdminNotifications();
print('FCM Config Valid: ${results['fcmConfigurationValid']}');
```

## Features Implemented
- ✅ Direct FCM message sending (no backend required)
- ✅ Support for both Server Key and Service Account methods
- ✅ Admin notification system
- ✅ Batch notification sending
- ✅ Configuration testing
- ✅ Error handling and fallbacks

## Usage
Admin notifications will now be sent automatically when:
- Doctors submit verification requests
- Other admin-relevant events occur

The system gracefully handles FCM failures and continues to work locally.

## Troubleshooting
- If using Server Key: Make sure it starts with `AAAA` and is from the Cloud Messaging tab
- If using Service Account: Ensure the JSON file is in the project root
- Check Firebase Console for any project configuration issues