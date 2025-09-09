import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase/auth_service.dart';
import '../services/auth/app_lifecycle_biometric_service.dart';

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
          final userModel = await AuthService.getUserDocument(user.uid);
          state = state.copyWith(
            isLoading: false,
            userModel: userModel,
            error: null,
          );
        } catch (e) {
          // If Firestore fails, still allow login with basic user info
          state = state.copyWith(
            isLoading: false,
            firebaseUser: user,
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
      await AuthService.signOut();
      // Reset biometric authentication state
      AppLifecycleBiometricService.reset();
      // State will be updated by auth state listener
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
