# Quick FCM Setup - Curevia

## 🚀 Quick Start (5 minutes)

You have the Firebase service account key at:
```
d:\folder\curevia\curevia-f31a8-firebase-adminsdk-fbsvc-1a9966980f.json
```

### Step 1: Copy Service Account Key
```bash
# Copy the key to your email service folder
copy "d:\folder\curevia\curevia-f31a8-firebase-adminsdk-fbsvc-1a9966980f.json" "email-service\serviceAccountKey.json"
```

### Step 2: Install Dependencies
```bash
cd email-service
npm install firebase-admin
```

### Step 3: Run Setup Script
```bash
node setup-fcm.js
```

### Step 4: Test FCM Setup
```bash
node test-fcm-setup.js
```

### Step 5: Start Email Service
```bash
npm start
```

## 🧪 Test FCM Notifications

### From Flutter App:
```dart
// Add this to your debug screen or create a test widget
final success = await FCMDirectService.sendTestNotification(
  fcmToken: 'your_device_fcm_token',
  title: '🧪 Test from Flutter',
  body: 'FCM is working!',
);
print(success ? '✅ Success' : '❌ Failed');
```

### From Command Line:
```bash
curl -X POST http://localhost:3000/test-fcm \
  -H "Content-Type: application/json" \
  -d '{"fcmToken":"YOUR_DEVICE_TOKEN","title":"Test","body":"Hello from backend!"}'
```

## 📱 Get Your FCM Token

Add this to your Flutter app to get your device's FCM token:

```dart
// In your debug screen or main.dart
final fcmToken = await FirebaseMessaging.instance.getToken();
print('FCM Token: $fcmToken');
```

## ✅ Success Checklist

- [ ] Service account key copied to `email-service/serviceAccountKey.json`
- [ ] `firebase-admin` package installed
- [ ] Setup script runs without errors
- [ ] Test script shows "FCM Service: Ready to send notifications"
- [ ] Email service starts successfully
- [ ] Test notification sent successfully

## 🔧 Troubleshooting

### "serviceAccountKey.json not found"
```bash
# Make sure you copied the file correctly
copy "d:\folder\curevia\curevia-f31a8-firebase-adminsdk-fbsvc-1a9966980f.json" "email-service\serviceAccountKey.json"
```

### "firebase-admin not installed"
```bash
cd email-service
npm install firebase-admin
```

### "Port 3000 already in use"
```bash
# Kill the process using port 3000
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F
```

## 🎯 What This Enables

✅ **Real FCM Push Notifications**: Your app can now send actual push notifications
✅ **Appointment Notifications**: Patients and doctors get notified
✅ **Payment Notifications**: Success/failure notifications work
✅ **Admin Notifications**: Verification requests reach admins
✅ **Email + Push Integration**: Both email and push notifications work together

## 📊 Monitoring

Check your FCM service health:
```bash
curl http://localhost:3000/health
```

View the dashboard:
```
http://localhost:3000/dashboard
```

Your FCM setup is now complete and ready to send real push notifications! 🎉