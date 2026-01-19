import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase/auth_service.dart';
import '../services/auth/app_lifecycle_biometric_service.dart';
import '../services/notifications/notification_integration_service.dart';
import '../services/notifications/fcm_service.dart';
import '../services/data_initialization_service.dart';

/// Authentication state
class AuthState {
  final bool isLoading;
  final User? firebaseUser;
  final UserModel? userModel;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.firebaseUser,
    this.userModel,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    User? firebaseUser,
    UserModel? userModel,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userModel: userModel ?? this.userModel,
      error: error,
    );
  }

  bool get isAuthenticated => firebaseUser != null;
  bool get hasUserData => userModel != null;
}

/// Authentication provider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  /// Initialize notification system and app data for the logged-in user
  Future<void> _initializeNotifications(UserModel userModel) async {
    try {
      // Ensure notification system is fully initialized first
      final notificationService = NotificationIntegrationService.instance;
      
      // Initialize with retry logic
      bool initialized = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔔 Initializing notifications (attempt $attempt/3)...');
          initialized = await notificationService.initialize();
          if (initialized && notificationService.isReady) {
            print('✅ Notification service ready');
            break;
          } else {
            print('⚠️ Notification service not ready, retrying...');
            await Future.delayed(Duration(seconds: 2));
          }
        } catch (e) {
          print('❌ Notification initialization attempt $attempt failed: $e');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }
      
      if (initialized && notificationService.isReady) {
        // Setup user notifications
        await notificationService.setupUserNotifications(
          user: userModel,
          specializations: userModel.role == 'doctor' ? ['General Medicine'] : null,
          location: null, // Can be added later from user preferences
        );
        print('✅ Notifications initialized for user: ${userModel.fullName} (${userModel.role})');
      } else {
        print('⚠️ Notification service not ready, will retry later');
        // Schedule a retry after a delay
        Future.delayed(Duration(seconds: 5), () async {
          try {
            await notificationService.setupUserNotifications(
              user: userModel,
              specializations: userModel.role == 'doctor' ? ['General Medicine'] : null,
              location: null,
            );
            print('✅ Delayed notification setup successful');
          } catch (e) {
            print('❌ Delayed notification setup failed: $e');
          }
        });
      }
      
      // Initialize app data (medicines and home remedies) after authentication
      await DataInitializationService.initializeAfterAuth();
      print('✅ App data initialized for authenticated user');
    } catch (e) {
      print('❌ Error initializing notifications and data: $e');
    }
  }

  void _init() {
    // Listen to auth state changes
    AuthService.authStateChanges.listen((user) async {
      if (user != null) {
        // User is signed in, fetch user data
        try {
          state = state.copyWith(
            isLoading: true,
            firebaseUser: user,
            error: null,
          );
          
          // Wait a bit for Firestore to sync after registration
          await Future.delayed(const Duration(milliseconds: 500));
          
          final userModel = await AuthService.getUserDocument(user.uid);
          
          // If userModel is null, wait and retry once more
          if (userModel == null) {
            await Future.delayed(const Duration(milliseconds: 1000));
            final retryUserModel = await AuthService.getUserDocument(user.uid);
            
            if (retryUserModel != null) {
              state = state.copyWith(
                isLoading: false,
                userModel: retryUserModel,
                error: null,
              );
              
              // Initialize notifications after successful login
              await _initializeNotifications(retryUserModel);
              return;
            }
            
            // Still null, create fallback but DON'T save to Firestore
            // This prevents overwriting the actual role
            final fallbackUserModel = UserModel(
              uid: user.uid,
              email: user.email ?? '',
              fullName: user.displayName ?? 'User',
              role: 'patient', // Temporary fallback
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              isVerified: user.emailVerified,
              profileImageUrl: user.photoURL,
            );
            
            state = state.copyWith(
              isLoading: false,
              userModel: fallbackUserModel,
              error: null,
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              userModel: userModel,
              error: null,
            );
            
            // Initialize notifications after successful login
            await _initializeNotifications(userModel);
          }
        } catch (e) {
          // If Firestore fails, create fallback user model from Firebase Auth
          print('Firestore error, creating fallback user model: $e');
          final fallbackUserModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            fullName: user.displayName ?? 'User',
            role: 'patient', // Default role
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
            isVerified: user.emailVerified,
            profileImageUrl: user.photoURL,
          );
          
          state = state.copyWith(
            isLoading: false,
            firebaseUser: user,
            userModel: fallbackUserModel,
            error: null, // Don't show error for Firestore issues
          );
        }
      } else {
        // User is signed out
        state = const AuthState();
      }
    });
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // State will be updated by auth state listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create user with email and password
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await AuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      // State will be updated by auth state listener
    } catch (e) {
      // Check if it's a Firestore error but auth succeeded
      if (e.toString().contains('Cloud Firestore API has not been used')) {
        // Don't set error state, let auth state listener handle it
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle({bool forceAccountSelection = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await AuthService.signInWithGoogle(
        forceAccountSelection: forceAccountSelection,
      );

      if (result == null) {
        // User cancelled the sign-in
        state = state.copyWith(isLoading: false);
      }
      // State will be updated by auth state listener if successful
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Start Firebase signout immediately (don't wait for cleanup)
      final signOutFuture = AuthService.signOut();
      
      // Run cleanup in parallel (fire and forget)
      if (state.userModel != null) {
        // Don't await - let it run in background
        _cleanupInBackground(
          userId: state.userModel!.uid,
          userRole: state.userModel!.role,
        );
      }
      
      // Wait only for Firebase signout
      await signOutFuture;
      
      // Reset biometric authentication state
      AppLifecycleBiometricService.reset();
      
      // State will be updated by auth state listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Background cleanup (fire and forget)
  void _cleanupInBackground({
    required String userId,
    required String userRole,
  }) {
    // Run cleanup without blocking logout with timeout
    NotificationIntegrationService.instance.cleanupUserNotifications(
      userId: userId,
      userRole: userRole,
      specializations: userRole == 'doctor' ? ['General Medicine'] : null,
      location: null,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => print('Background cleanup timeout - continuing anyway'),
    ).catchError((error) {
      // Log error but don't block logout
      print('Background cleanup error: $error');
    });
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await AuthService.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Update Firebase Auth profile
      await AuthService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Update Firestore document if additional data provided
      if (additionalData != null && state.firebaseUser != null) {
        await AuthService.updateUserDocument(
          uid: state.firebaseUser!.uid,
          data: {...additionalData, 'updatedAt': DateTime.now()},
        );

        // Refresh user data
        final updatedUserModel = await AuthService.getUserDocument(
          state.firebaseUser!.uid,
        );
        state = state.copyWith(
          isLoading: false,
          userModel: updatedUserModel,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update user role
  Future<void> updateUserRole(String role) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (state.firebaseUser != null) {
        // Update role in Firestore
        await AuthService.updateUserDocument(
          uid: state.firebaseUser!.uid,
          data: {
            'role': role,
            'updatedAt': DateTime.now(),
          },
        );

        // Refresh user data to get updated role
        final updatedUserModel = await AuthService.getUserDocument(
          state.firebaseUser!.uid,
        );
        
        state = state.copyWith(
          isLoading: false,
          userModel: updatedUserModel,
          error: null,
        );

        // Update FCM token with new role
        if (updatedUserModel != null) {
          await FCMService.instance.sendTokenToServer(
            state.firebaseUser!.uid,
            role,
          );
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh user data from Firestore
  Future<void> refreshUserData() async {
    if (state.firebaseUser != null) {
      try {
        state = state.copyWith(isLoading: true);
        final userModel = await AuthService.getUserDocument(
          state.firebaseUser!.uid,
        );
        state = state.copyWith(
          isLoading: false,
          userModel: userModel,
          error: null,
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to refresh user data: $e',
        );
      }
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await AuthService.deleteAccount();
      // State will be updated by auth state listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Auth provider instance
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).firebaseUser;
});

/// Current user model provider
final currentUserModelProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).userModel;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Is loading provider
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Auth error provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
