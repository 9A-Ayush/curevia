# 📧 Curevia Email Service Integration Guide

This guide shows you how to integrate the email service with your Flutter Curevia app for automated email workflows.

## 🚀 What's Been Added

### 1. Email Service Integration (`lib/services/email_service.dart`)
- **Doctor Verification Emails** - Automatic approval/rejection notifications
- **Promotional Campaigns** - Marketing emails to opted-in users
- **Health Tips Newsletter** - Wellness content distribution
- **User Preferences Management** - Email subscription controls
- **Test Email Functionality** - Development and testing support

### 2. Updated Admin Screens
- **Doctor Verification** - Now sends emails automatically when approving/rejecting doctors
- **Email Campaign Screen** - New admin interface for sending promotional emails
- **Health Tips Admin** - New interface for sending health newsletters

### 3. User Settings
- **Email Preferences Screen** - Users can control their email subscriptions

## 🔧 Integration Steps

### Step 1: Update Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0  # For API calls to email service
  # ... your existing dependencies
```

### Step 2: Deploy Email Service

✅ **Already Deployed!** Your email service is live at:
**Production URL**: `https://curvia-mail-service.onrender.com`

**Note**: Render free tier may spin down after inactivity. The first request might take 30-60 seconds to wake up the service.

**Test Your Deployment**:
```bash
# Health check (may take time to wake up)
curl https://curvia-mail-service.onrender.com/health

# Dashboard
open https://curvia-mail-service.onrender.com/dashboard
```

### Step 3: Add Navigation Routes

Add these routes to your app's routing:

```dart
// In your route configuration
'/email-preferences': (context) => const EmailPreferencesScreen(),
'/admin/email-campaign': (context) => const EmailCampaignScreen(),
'/admin/health-tips': (context) => const HealthTipsAdminScreen(),
```

### Step 4: Add to Settings Menu

Add email preferences to your user settings:

```dart
// In your settings screen
ListTile(
  leading: const Icon(Icons.email_outlined),
  title: const Text('Email Preferences'),
  subtitle: const Text('Manage your email notifications'),
  onTap: () => Navigator.pushNamed(context, '/email-preferences'),
),
```

### Step 5: Add to Admin Panel

Add email management to your admin panel:

```dart
// In your admin dashboard
Card(
  child: ListTile(
    leading: const Icon(Icons.campaign),
    title: const Text('Email Campaign'),
    subtitle: const Text('Send promotional emails'),
    onTap: () => Navigator.pushNamed(context, '/admin/email-campaign'),
  ),
),
Card(
  child: ListTile(
    leading: const Icon(Icons.favorite),
    title: const Text('Health Tips'),
    subtitle: const Text('Send health newsletters'),
    onTap: () => Navigator.pushNamed(context, '/admin/health-tips'),
  ),
),
```

## 🔥 Real-Time Features

The email service includes real-time Firebase integration that automatically:

### 1. Doctor Verification Emails
- **Triggers**: When doctor `verificationStatus` changes to `approved` or `rejected`
- **Recipients**: The specific doctor being verified
- **Content**: Professional approval/rejection notification with next steps

### 2. Welcome Emails
- **Triggers**: When new user registers and `emailVerified` is `true`
- **Recipients**: New verified users
- **Content**: Welcome message with app features and download link

### 3. Scheduled Campaigns
- **Triggers**: When campaign `scheduledAt` time is reached
- **Recipients**: Users with `emailPreferences.promotional = true`
- **Content**: Custom marketing content from admin

### 4. Health Tips Distribution
- **Triggers**: When health tip `status` changes to `pending`
- **Recipients**: Users with `emailPreferences.healthTips = true`
- **Content**: Health advice with actionable tips

## 📊 Monitoring & Analytics

### Real-Time Dashboard
Access at: `https://curvia-mail-service.onrender.com/dashboard`

**Note**: First load may take 30-60 seconds as Render wakes up the service.

Features:
- Live email delivery statistics
- Firebase listener status
- User subscription metrics
- System health monitoring

### API Health Check
```dart
// Check email service status
final health = await EmailService.getServiceHealth();
if (health != null) {
  print('Email service status: ${health['status']}');
  print('Emails sent today: ${health['dailyStats']['emailsSentToday']}');
}
```

## 🛡️ Security & Best Practices

### 1. Environment Configuration
- Email service uses environment variables for sensitive data
- Firebase credentials are properly secured
- No sensitive data in repository

### 2. Error Handling
- Email failures don't break app functionality
- Graceful degradation when service is unavailable
- Comprehensive logging for debugging

### 3. User Privacy
- Users control their email preferences
- Easy unsubscribe functionality
- GDPR-compliant email handling

## 🧪 Testing

### 1. Test Email Functionality
```dart
// Send test email
final success = await EmailService.sendTestEmail('test@example.com');
print('Test email sent: $success');
```

### 2. Test Real-Time Features
```bash
# In email-service directory
npm run test-realtime
```

### 3. Test Admin Functions
1. Go to admin panel
2. Try sending a promotional campaign
3. Try sending a health tip
4. Verify emails are received

## 📱 User Experience Flow

### For Users:
1. **Registration** → Automatic welcome email
2. **Settings** → Control email preferences
3. **Subscriptions** → Receive relevant content
4. **Unsubscribe** → Easy opt-out process

### For Doctors:
1. **Submit Verification** → Automatic status emails
2. **Profile Updates** → Notification emails
3. **Appointment Reminders** → Automated scheduling emails

### For Admins:
1. **Doctor Management** → Automatic verification emails
2. **Marketing Campaigns** → Bulk promotional emails
3. **Health Content** → Newsletter distribution
4. **Analytics** → Real-time email metrics

## 🚨 Troubleshooting

### Common Issues:

1. **Emails not sending**:
   - Check email service deployment status
   - Verify Firebase credentials
   - Check network connectivity

2. **Real-time features not working**:
   - Ensure Firebase listeners are active
   - Check Firestore security rules
   - Verify collection structure

3. **User preferences not saving**:
   - Check user authentication
   - Verify Firestore permissions
   - Test API endpoints

### Debug Commands:
```bash
# Check email service health (may take time to wake up)
curl https://curvia-mail-service.onrender.com/health

# Check real-time stats
curl https://curvia-mail-service.onrender.com/stats/realtime

# View dashboard
open https://curvia-mail-service.onrender.com/dashboard
```

## 📈 Scaling Considerations

### Current Limits:
- **Gmail SMTP**: ~500 emails/day (free tier)
- **Firebase**: Real-time listeners handle concurrent users
- **Vercel**: Generous free tier for API calls

### Upgrade Path:
1. **Higher Email Volume**: Switch to Resend/SendGrid
2. **More Features**: Add email templates, A/B testing
3. **Analytics**: Integrate with email tracking services
4. **Automation**: Add more trigger-based workflows

## 🎯 Next Steps

1. **Deploy email service** to production
2. **Update production URL** in Flutter app
3. **Test all email flows** end-to-end
4. **Monitor real-time dashboard** for issues
5. **Gather user feedback** on email preferences
6. **Optimize email content** based on engagement

---

Your Curevia app now has a complete email automation system! 🚀

The integration provides:
- ✅ Automated doctor verification emails
- ✅ User welcome and preference management
- ✅ Admin marketing campaign tools
- ✅ Health tips newsletter system
- ✅ Real-time Firebase integration
- ✅ Comprehensive monitoring and analytics

Users will receive timely, relevant emails while admins have powerful tools to manage communications and engage with the Curevia community.