import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // webClientId is required to get idToken for Firebase Authentication
  // This is the client_type: 3 (Web client) from google-services.json
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web Client ID from google-services.json (client_type: 3)
    // This is required for Firebase Authentication to get idToken
    serverClientId:
        '625159457653-i8qo5p6k1lbbhdcd5k31lcq5i9rhi2c2.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Sign Up
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (name != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if user is already signed in
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Check if idToken is null
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // If it's a PlatformException, provide more details
      rethrow;
    }
  }

  // Check if user exists by email
  // This uses fetchSignInMethodsForEmail to check if user exists
  // Works for both email/password and Google-authenticated users
  Future<bool> checkUserExists(String email) async {
    try {
      // Trim email and normalize to lowercase (Firebase emails are case-insensitive)
      final trimmedEmail = email.trim().toLowerCase();

      // Validate email format first
      if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
        return false;
      }

      // Fetch sign-in methods for the email
      // This returns available sign-in methods like ['password', 'google.com', etc.]
      // For email/password users: returns ['password']
      // For Google users: returns ['google.com']
      // For users with both: returns ['password', 'google.com']
      // If empty: user might not exist OR there's a network/API issue
      final signInMethods = await _auth.fetchSignInMethodsForEmail(
        trimmedEmail,
      );

      // If signInMethods is not empty, user definitely exists
      return signInMethods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'invalid-email') {
        // Invalid email format
        return false;
      }
      // For other Firebase errors (like network issues),
      // we can't reliably determine if user exists
      // Return false to prevent sending email to potentially non-existent users
      return false;
    } catch (e) {
      // For other exceptions (network, etc.), return false
      // User can try again when network is available
      return false;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      rethrow;
    }
  }

  // Get error message
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Password is too weak.';
        case 'email-already-in-use':
          return 'User already exist.';
        case 'invalid-email':
          return 'Email is invalid.';
        case 'user-not-found':
          return 'User not found .';
        case 'wrong-password':
          return 'Wrong password.';
        case 'user-disabled':
          return 'User account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'invalid-credential':
          return 'Invalid credential.';
        case 'network-request-failed':
          return 'Check your internet connection.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }

    // Handle PlatformException for Google Sign-In specific errors
    if (error.toString().contains('SIGN_IN_CANCELLED') ||
        error.toString().contains('sign_in_cancelled')) {
      return 'Google sign-in was cancelled.';
    }
    if (error.toString().contains('SIGN_IN_FAILED') ||
        error.toString().contains('sign_in_failed')) {
      return 'Google sign-in failed. Please check your Firebase configuration.';
    }
    if (error.toString().contains('INVALID_ACCOUNT') ||
        error.toString().contains('invalid_account')) {
      return 'Invalid Google account. Please try again.';
    }
    if (error.toString().contains('oauth_client') ||
        error.toString().contains('OAuth')) {
      return 'Google Sign-In not configured. Please add OAuth client in Firebase Console.';
    }

    return error.toString();
  }
}
