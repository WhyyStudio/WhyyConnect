import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  // Lazy initialization of Firebase services
  FirebaseAuth get _firebaseAuth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  GoogleSignIn get _firebaseGoogleSignIn {
    _googleSignIn ??= GoogleSignIn();
    return _googleSignIn!;
  }

  // Check if Firebase is configured
  bool get isFirebaseConfigured {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  User? get currentUser {
    try {
      return _firebaseAuth.currentUser;
    } catch (e) {
      return null;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    try {
      return _firebaseAuth.authStateChanges();
    } catch (e) {
      return Stream.value(null);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    if (!isFirebaseConfigured) {
      throw 'Firebase is not configured. Please set up Firebase first.';
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    if (!isFirebaseConfigured) {
      throw 'Firebase is not configured. Please set up Firebase first.';
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    if (!isFirebaseConfigured) {
      throw 'Firebase is not configured. Please set up Firebase first.';
    }

    try {
      final GoogleSignInAccount? googleUser = await _firebaseGoogleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!isFirebaseConfigured) {
      throw 'Firebase is not configured. Please set up Firebase first.';
    }

    try {
      await _firebaseGoogleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Sign out failed: ${e.toString()}';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    if (!isFirebaseConfigured) {
      throw 'Firebase is not configured. Please set up Firebase first.';
    }

    try {
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
      await _firebaseAuth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw 'Failed to update profile: ${e.toString()}';
    }
  }
}
