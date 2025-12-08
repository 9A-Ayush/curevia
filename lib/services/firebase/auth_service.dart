import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import '../../constants/app_constants.dart';
import '../doctor/doctor_onboarding_service.dart';

/// Firebase Authentication Service
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Create user with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(fullName);

        // Create user document in Firestore
        try {
          await _createUserDocument(
            uid: credential.user!.uid,
            email: email,
            fullName: fullName,
            role: role,
          );
          
          // If user is a doctor, initialize doctor onboarding document
          if (role == AppConstants.doctorRole) {
            await DoctorOnboardingService.initializeDoctorDocument(
              credential.user!.uid,
              email,
              fullName,
            );
          }
        } catch (firestoreError) {
          // If Firestore fails, log but don't fail the entire signup
          print('Firestore error during user creation: $firestoreError');
          // User account is still created successfully
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle({
    bool forceAccountSelection = false,
  }) async {
    try {
      // If forceAccountSelection is true, sign out first to show account picker
      if (forceAccountSelection) {
        await _googleSignIn.signOut();
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user and create user document
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        try {
          await _createUserDocument(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email!,
            fullName: userCredential.user!.displayName ?? 'Google User',
            role: AppConstants.patientRole, // Default role for Google sign-in
          );
        } catch (firestoreError) {
          // If Firestore fails, log but don't fail the entire signup
          print('Firestore error during Google user creation: $firestoreError');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  /// Get user document from Firestore
  static Future<UserModel?> getUserDocument(String uid) async {
    try {
      print('Attempting to fetch user document for uid: $uid');
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        print('User document found in Firestore');
        return UserModel.fromMap(doc.data()!);
      }
      print('User document does not exist in Firestore');
      return null;
    } catch (e) {
      // If Firestore API is not enabled, return null instead of throwing
      print('Error fetching user document: $e');
      if (e.toString().contains('Cloud Firestore API has not been used') ||
          e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('not found')) {
        print('Firestore API not enabled or permission denied, returning null user document');
        return null;
      }
      throw Exception('Failed to get user document: $e');
    }
  }

  /// Update user document in Firestore (creates if doesn't exist)
  static Future<void> updateUserDocument({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Use set with merge to create document if it doesn't exist
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  /// Create user document in Firestore
  static Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String fullName,
    required String role,
  }) async {
    try {
      final userModel = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isVerified: false,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  /// Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .delete();

        // Delete user account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  static String? get currentUserEmail => _auth.currentUser?.email;
}
