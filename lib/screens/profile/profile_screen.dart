import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/family_member_provider.dart';
import '../../providers/medical_report_provider.dart';
import '../../models/user_model.dart';
import '../../services/image_upload_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'medical_records_screen.dart';
import 'family_members_screen.dart';
import 'help_support_screen.dart';
import 'theme_selection_screen.dart';
import '../notifications/notifications_screen.dart';
import 'privacy_security_screen.dart';

/// Profile screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Use post frame callback to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final user = ref.read(authProvider).userModel;
    if (user != null) {
      // Notifications are loaded via stream provider automatically
      // No need to manually load

      // Load family members
      ref.read(familyMemberProvider.notifier).loadFamilyMembers(user.uid);

      // Load medical reports
      ref.read(medicalReportProvider.notifier).loadMedicalReports(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(currentUserModelProvider);
    final patientModel = ref.watch(currentPatientModelProvider);
    final isPatient = userModel?.role == 'patient';

    return PopScope(
      canPop: !_isUploadingImage, // Prevent navigation during upload
      child: Scaffold(
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(context),

                  // Profile Content
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ThemeUtils.getBackgroundColor(context),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Profile Picture and Info
                            _buildProfileHeader(context, userModel),

                            const SizedBox(height: 30),

                            // Health Stats (only for patients)
                            if (isPatient) ...[
                              _buildHealthStats(context, patientModel),
                              const SizedBox(height: 30),
                            ],

                            // About Me Section
                            _buildAboutSection(context, userModel),

                            const SizedBox(height: 30),

                            // Family Members Section (only for patients)
                            if (isPatient) ...[
                              _buildFamilyMembersSection(context),
                              const SizedBox(height: 30),
                            ],

                            // Profile Options
                            _buildProfileOptions(context, ref),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Loading overlay during image upload
            if (_isUploadingImage)
              Container(
                color: ThemeUtils.getTextPrimaryColor(
                  context,
                ).withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeUtils.getPrimaryColor(context),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Uploading profile picture...',
                        style: TextStyle(
                          color: ThemeUtils.getTextOnPrimaryColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ThemeUtils.getTextOnPrimaryColor(
                context,
              ).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _isUploadingImage
                  ? null
                  : () {
                      // Check if we can pop (came from another screen)
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // If we're in tab navigation, go back to home tab
                        ref.read(navigationProvider.notifier).goToHome();
                      }
                    },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: ThemeUtils.getTextOnPrimaryColor(context),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: ThemeUtils.getTextOnPrimaryColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: ThemeUtils.getTextOnPrimaryColor(
                context,
              ).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _showLogoutDialog(context, ref),
              icon: Icon(
                Icons.logout,
                color: ThemeUtils.getTextOnPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel? userModel) {
    // Check if fullName is empty and try to fix it
    if (userModel != null && (userModel.fullName.isEmpty)) {
      _fixEmptyUserName(userModel);
    }

    // Use actual user data with fallback to Firebase displayName
    final firebaseUser = ref.read(currentUserProvider);
    final displayName = userModel != null && userModel.fullName.isNotEmpty
        ? userModel.fullName
        : firebaseUser?.displayName?.isNotEmpty == true
        ? firebaseUser!.displayName!
        : 'User';

    final membershipType = userModel?.isVerified == true
        ? 'Verified Member'
        : 'Member';
    final roleDisplay = userModel?.role == 'doctor'
        ? 'Dr. $displayName'
        : displayName;

    return Column(
      children: [
        // Profile Picture with Edit Button
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white,
                  child:
                      userModel?.profileImageUrl != null &&
                          userModel!.profileImageUrl!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: userModel.profileImageUrl!,
                            width: 108,
                            height: 108,
                            fit: BoxFit.cover,
                            // Add cache key to force refresh when image changes
                            cacheKey:
                                '${userModel.profileImageUrl!}_${DateTime.now().millisecondsSinceEpoch ~/ 10000}', // Refresh every 10 seconds
                            placeholder: (context, url) => Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                              child: const CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) {
                              debugPrint('Error loading profile image: $error');
                              debugPrint('Image URL: $url');
                              return Container(
                                width: 108,
                                height: 108,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(
                                    0.1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploadingImage ? null : _changeProfilePicture,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ThemeUtils.getPrimaryColor(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ThemeUtils.getTextOnPrimaryColor(context),
                      width: 2,
                    ),
                  ),
                  child: _isUploadingImage
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeUtils.getTextOnPrimaryColor(context),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.edit,
                          color: ThemeUtils.getTextOnPrimaryColor(context),
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Name and Role - Use actual user data
        Text(
          roleDisplay,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),

        const SizedBox(height: 8),

        // Membership Badge - Use actual user data
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: userModel?.isVerified == true
                  ? [
                      ThemeUtils.getSuccessColor(
                        context,
                      ).withOpacity(0.7),
                      ThemeUtils.getSuccessColor(context),
                    ]
                  : [
                      ThemeUtils.getWarningColor(
                        context,
                      ).withOpacity(0.7),
                      ThemeUtils.getWarningColor(context),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                membershipType.toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getTextOnPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                userModel?.isVerified == true ? '✓' : '👑',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStats(BuildContext context, PatientModel? patientModel) {
    final familyMemberCount = ref.watch(familyMemberCountProvider);
    final medicalRecordCount = ref.watch(medicalReportsCountProvider);
    final user = ref.watch(authProvider).userModel;
    final unreadNotifications = user != null 
        ? ref.watch(unreadNotificationsCountProvider(user.uid))
        : const AsyncValue.data(0);

    // Use actual patient data or show placeholders
    final bloodGroup = patientModel?.bloodGroup ?? 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Family Members - Real-time count
            _buildStatCard(
              context,
              icon: '👨‍👩‍👧‍👦',
              label: 'Family',
              value: '$familyMemberCount',
              color: Colors.blue,
            ),
            const SizedBox(width: 12),

            // Medical Records - Real-time count
            _buildStatCard(
              context,
              icon: '📋',
              label: 'Records',
              value: '$medicalRecordCount',
              color: Colors.green,
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            // Notifications - Real-time count
            _buildStatCard(
              context,
              icon: '🔔',
              label: 'Alerts',
              value: unreadNotifications.when(
                data: (count) => '$count',
                loading: () => '...',
                error: (_, __) => '0',
              ),
              color: unreadNotifications.when(
                data: (count) => count > 0 ? Colors.red : Colors.grey,
                loading: () => Colors.grey,
                error: (_, __) => Colors.grey,
              ),
            ),
            const SizedBox(width: 12),

            // Blood Group - Use actual patient data
            _buildStatCard(
              context,
              icon: '🩸',
              label: 'Blood',
              value: bloodGroup,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceVariantColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, UserModel? userModel) {
    // Use actual user data or show default text
    final aboutText =
        userModel?.additionalInfo?['about'] as String? ??
        'Welcome to my profile! I\'m ${userModel?.fullName ?? 'a user'} and I\'m here to take care of my health with Curevia.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Me',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          aboutText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ThemeUtils.getTextSecondaryColor(context),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyMembersSection(BuildContext context) {
    // For now, show empty state with add button
    // In a real app, this would fetch family members from the database

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Members',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [_buildAddFamilyMember(context)]),
        const SizedBox(height: 8),
        Text(
          'Add family members to manage their health profiles',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFamilyMember(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FamilyMembersScreen()),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
              border: Border.all(
                color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(
              Icons.add,
              color: ThemeUtils.getPrimaryColor(context),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add New',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: ThemeUtils.getPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildProfileOption(
          context,
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
        ),
        _buildProfileOption(
          context,
          icon: Icons.medical_information_outlined,
          title: 'Medical Records',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MedicalRecordsScreen(),
              ),
            );
          },
        ),
        _buildProfileOption(
          context,
          icon: Icons.family_restroom,
          title: 'Family Members',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FamilyMembersScreen(),
              ),
            );
          },
        ),
        _buildProfileOption(
          context,
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        _buildProfileOption(
          context,
          icon: Icons.palette_outlined,
          title: 'Theme',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ThemeSelectionScreen(),
              ),
            );
          },
        ),
        _buildProfileOption(
          context,
          icon: Icons.security,
          title: 'Privacy & Security',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacySecurityScreen(),
              ),
            );
          },
        ),
        _buildProfileOption(
          context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Fix empty user name by updating with Firebase displayName
  Future<void> _fixEmptyUserName(UserModel userModel) async {
    try {
      final firebaseUser = ref.read(currentUserProvider);
      if (firebaseUser?.displayName?.isNotEmpty == true) {
        debugPrint(
          'Fixing empty fullName with Firebase displayName: ${firebaseUser!.displayName}',
        );

        await ref
            .read(authProvider.notifier)
            .updateUserProfile(
              additionalData: {
                'fullName': firebaseUser.displayName!,
                'updatedAt': DateTime.now(),
              },
            );
      }
    } catch (e) {
      print('Error fixing empty user name: $e');
    }
  }

  Future<void> _changeProfilePicture() async {
    print('=== PROFILE PICTURE CHANGE STARTED ===');

    try {
      // Test Cloudinary configuration first
      final configOk = ImageUploadService.testCloudinaryConfig();
      print('Cloudinary config test result: $configOk');

      if (!configOk) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image upload service not properly configured. Using fallback storage.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }

      print('Showing image source dialog...');
      final imageFile = await ImageUploadService.showImageSourceDialog(context);

      if (imageFile == null) {
        print('No image selected by user');
        return;
      }

      print('Image selected: ${imageFile.path}');

      setState(() {
        _isUploadingImage = true;
      });

      final userModel = ref.read(currentUserModelProvider);
      final firebaseUser = ref.read(currentUserProvider);
      final authState = ref.read(authProvider);

      print('Auth Debug:');
      print('Firebase User: ${firebaseUser?.uid ?? "NULL"}');
      print('User Model: ${userModel?.uid ?? "NULL"}');
      print(
        'Auth State: isAuthenticated=${authState.isAuthenticated}, isLoading=${authState.isLoading}',
      );

      if (firebaseUser == null) {
        throw Exception(
          'Firebase user not authenticated. Please log in again.',
        );
      }

      if (userModel == null) {
        // Try to use Firebase user UID as fallback
        print(
          'User model is null, using Firebase user UID: ${firebaseUser.uid}',
        );
      }

      // Upload image - use userModel UID if available, otherwise use Firebase user UID
      final userId = userModel?.uid ?? firebaseUser.uid;
      print('Using user ID for upload: $userId');

      final imageUrl = await ImageUploadService.uploadProfilePicture(
        imageFile: imageFile,
        userId: userId,
      );

      // Update user profile with basic user info to ensure document exists
      print('Updating user profile with image URL: $imageUrl');
      final updateData = {
        'profileImageUrl': imageUrl,
        'uid': userId,
        'email': firebaseUser.email ?? '',
        'displayName': firebaseUser.displayName ?? 'User',
        'updatedAt': DateTime.now(),
      };

      await ref
          .read(authProvider.notifier)
          .updateUserProfile(additionalData: updateData);

      print('Profile update completed successfully');

      // Clear cached network image to force reload
      await CachedNetworkImage.evictFromCache(imageUrl);

      // Force complete refresh of auth state
      ref.invalidate(authProvider);
      ref.invalidate(currentUserModelProvider);
      ref.invalidate(currentUserProvider);

      // Wait for providers to refresh and reload user data
      await Future.delayed(const Duration(milliseconds: 1000));

      // Force the auth provider to reload user data
      await ref.read(authProvider.notifier).refreshUserData();

      // Force UI rebuild
      if (mounted) {
        setState(() {
          // This will trigger a rebuild with the updated user data
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile picture';

        if (e.toString().contains('Cloudinary')) {
          errorMessage =
              'Image upload failed. Please check your internet connection and try again.';
        } else if (e.toString().contains('Firebase')) {
          errorMessage = 'Image storage failed. Please try again later.';
        } else if (e.toString().contains('permission')) {
          errorMessage =
              'Camera/Gallery permission required. Please enable in settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      // Always ensure loading state is cleared, even if widget is unmounted
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      } else {
        // If widget is unmounted, just set the flag directly
        _isUploadingImage = false;
      }
    }
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: ThemeUtils.getTextSecondaryColor(context)),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: Icon(
          Icons.chevron_right,
          color: ThemeUtils.getTextSecondaryColor(context),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(color: ThemeUtils.getErrorColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}
