# Dark Mode Implementation Guide

This guide explains how to make all components in the Curevia app properly support dark mode so text and UI elements remain visible and accessible.

## ✅ **What's Already Fixed:**

### **Core Components:**
- ✅ **Theme Provider** - Complete theme system with light, dark, and system modes
- ✅ **CustomButton** - All button variants adapt to current theme
- ✅ **CustomTextField** - Input fields with proper dark mode colors
- ✅ **DoctorCard** - Doctor cards with theme-aware backgrounds and shadows
- ✅ **Profile Screens** - All profile-related screens support dark mode
- ✅ **Theme Selection Screen** - Perfect dark mode implementation (as shown in screenshot)

### **Utility Classes:**
- ✅ **ThemeUtils** - Helper class for getting theme-aware colors
- ✅ **ThemeAwareCard** - Pre-built card component that adapts to theme
- ✅ **ThemeAwareText** - Text component with automatic color adaptation
- ✅ **ThemeAwareIcon** - Icon component with theme-aware colors

## 🔧 **How to Fix Remaining Components:**

### **Method 1: Use ThemeUtils (Recommended)**

Replace hardcoded `AppColors` with `ThemeUtils` methods:

```dart
// ❌ OLD (hardcoded colors)
Container(
  color: AppColors.surface,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// ✅ NEW (theme-aware colors)
Container(
  color: ThemeUtils.getSurfaceColor(context),
  child: Text(
    'Hello',
    style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
  ),
)
```

### **Method 2: Use Theme-Aware Components**

Replace standard widgets with theme-aware versions:

```dart
// ❌ OLD
Card(
  color: AppColors.surface,
  child: Text(
    'Content',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// ✅ NEW
ThemeAwareCard(
  child: ThemeAwareText('Content'),
)
```

### **Method 3: Use Theme.of(context)**

For Material Design components, use the theme directly:

```dart
// ✅ GOOD
Container(
  color: Theme.of(context).cardColor,
  child: Text(
    'Content',
    style: Theme.of(context).textTheme.bodyMedium,
  ),
)
```

## 🎯 **Priority Components to Fix:**

### **1. Home Screen Components**
- `lib/widgets/home/home_header.dart`
- `lib/widgets/home/upcoming_appointments.dart`
- `lib/widgets/home/health_tips_carousel.dart`
- `lib/widgets/home/nearby_doctors.dart`

### **2. Doctor-Related Screens**
- `lib/screens/doctor/doctor_search_screen.dart`
- `lib/screens/doctor/nearby_doctors_screen.dart`
- `lib/widgets/doctor/doctor_list_item.dart`

### **3. Appointment Screens**
- `lib/screens/appointment/appointment_booking_screen.dart`
- `lib/screens/appointment/appointments_screen.dart`

### **4. Health Screens**
- `lib/screens/health/symptom_checker_screen.dart`
- `lib/screens/health/medicine_directory_screen.dart`
- `lib/screens/health/home_remedies_screen.dart`

## 📋 **Common Replacements:**

| Old (Hardcoded) | New (Theme-Aware) |
|----------------|-------------------|
| `AppColors.surface` | `ThemeUtils.getSurfaceColor(context)` |
| `AppColors.textPrimary` | `ThemeUtils.getTextPrimaryColor(context)` |
| `AppColors.textSecondary` | `ThemeUtils.getTextSecondaryColor(context)` |
| `AppColors.primary` | `ThemeUtils.getPrimaryColor(context)` |
| `AppColors.shadowLight` | `ThemeUtils.getShadowLightColor(context)` |
| `AppColors.borderLight` | `ThemeUtils.getBorderLightColor(context)` |
| `AppColors.surfaceVariant` | `ThemeUtils.getSurfaceVariantColor(context)` |

## 🚀 **Quick Fix Template:**

For any screen with dark mode issues:

1. **Add import:**
```dart
import '../../utils/theme_utils.dart';
```

2. **Replace hardcoded colors:**
```dart
// Find and replace patterns like:
color: AppColors.surface → color: ThemeUtils.getSurfaceColor(context)
color: AppColors.textPrimary → color: ThemeUtils.getTextPrimaryColor(context)
```

3. **Update Container decorations:**
```dart
decoration: BoxDecoration(
  color: ThemeUtils.getSurfaceColor(context),
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: ThemeUtils.getShadowLightColor(context),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
),
```

## 🎨 **Available ThemeUtils Methods:**

- `ThemeUtils.getPrimaryColor(context)`
- `ThemeUtils.getSurfaceColor(context)`
- `ThemeUtils.getBackgroundColor(context)`
- `ThemeUtils.getTextPrimaryColor(context)`
- `ThemeUtils.getTextSecondaryColor(context)`
- `ThemeUtils.getTextHintColor(context)`
- `ThemeUtils.getBorderLightColor(context)`
- `ThemeUtils.getShadowLightColor(context)`
- `ThemeUtils.getSuccessColor(context)`
- `ThemeUtils.getErrorColor(context)`
- `ThemeUtils.getWarningColor(context)`
- `ThemeUtils.getInfoColor(context)`

## 🔍 **How to Test:**

1. **Switch to dark mode** in the theme settings
2. **Navigate through all screens** to check for:
   - Invisible text (white text on white background)
   - Poor contrast
   - Hardcoded light colors in dark mode
3. **Look for these issues:**
   - Text that disappears
   - Cards that blend into background
   - Icons that become invisible
   - Borders that disappear

## 📱 **Example: Fixing a Screen**

```dart
// Before (problematic in dark mode)
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        color: AppColors.surface,
        child: Column(
          children: [
            Text(
              'Title',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Card(
              color: AppColors.surface,
              child: Text(
                'Content',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// After (works perfectly in both light and dark mode)
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      body: Container(
        color: ThemeUtils.getSurfaceColor(context),
        child: Column(
          children: [
            ThemeAwareText(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ThemeAwareCard(
              child: ThemeAwareText.secondary('Content'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🎯 **Next Steps:**

1. **Start with high-priority screens** (home, doctor search, appointments)
2. **Use find-and-replace** to quickly update hardcoded colors
3. **Test each screen** in both light and dark modes
4. **Use theme-aware components** for new features

The theme system is now fully functional - you just need to replace hardcoded colors with theme-aware alternatives throughout the app!
