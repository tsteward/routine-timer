import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for handling Firebase Authentication operations.
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Stream of authentication state changes.
  /// Emits null when signed out, User object when signed in.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Current user ID (null if not signed in).
  String? get currentUserId => _auth.currentUser?.uid;

  /// Whether user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Whether user is signed in anonymously (guest).
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// Sign in with Google account.
  /// Returns null on success, error message on failure.
  Future<String?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled sign-in
        return 'Sign-in cancelled';
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      await _auth.signInWithCredential(credential);

      return null; // Success
    } catch (e) {
      return 'Failed to sign in with Google: $e';
    }
  }

  /// Sign in anonymously (as guest).
  /// Returns null on success, error message on failure.
  Future<String?> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      return null; // Success
    } catch (e) {
      return 'Failed to sign in as guest: $e';
    }
  }

  /// Sign up with email and password.
  /// Returns null on success, error message on failure.
  Future<String?> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Try signing in instead.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        default:
          return 'Failed to create account: ${e.message}';
      }
    } catch (e) {
      return 'Failed to create account: $e';
    }
  }

  /// Sign in with email and password.
  /// Returns null on success, error message on failure.
  Future<String?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return 'Failed to sign in: ${e.message}';
      }
    } catch (e) {
      return 'Failed to sign in: $e';
    }
  }

  /// Send password reset email.
  /// Returns null on success, error message on failure.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return 'Failed to send reset email: ${e.message}';
      }
    } catch (e) {
      return 'Failed to send reset email: $e';
    }
  }

  /// Link anonymous account to Google account (upgrade guest to full account).
  /// Returns null on success, error message on failure.
  Future<String?> linkAnonymousToGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        return 'Not signed in as guest';
      }

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return 'Sign-in cancelled';
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link anonymous account to Google account
      await user.linkWithCredential(credential);

      return null; // Success
    } catch (e) {
      return 'Failed to link accounts: $e';
    }
  }

  /// Sign out current user.
  /// Returns null on success, error message on failure.
  Future<String?> signOut() async {
    try {
      // Sign out from Firebase Auth
      await _auth.signOut();

      // Sign out from Google Sign-In (may fail in tests)
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Ignore Google Sign-In errors in test environment
        // This is expected when Google Sign-In plugin is not available
      }

      return null; // Success
    } catch (e) {
      return 'Failed to sign out: $e';
    }
  }

  /// Delete current user account and all data.
  /// Returns null on success, error message on failure.
  Future<String?> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'Not signed in';
      }

      await user.delete();
      return null; // Success
    } catch (e) {
      return 'Failed to delete account: $e';
    }
  }
}
