import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Web OAuth Client ID from Firebase Google Sign-In configuration.
  static const String _serverClientId =
      '53107125785-4cdd8pdotslo7p88gfg8fmj8f0eileqa.apps.googleusercontent.com';

  Future<User?> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In with the Web Client ID.
      await _googleSignIn.initialize(
        serverClientId: _serverClientId,
      );

      // Open Google account selection.
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      // Get Google authentication information.
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Create Firebase credential using Google ID token.
      final AuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase using Google credential.
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        'Firebase sign-in failed: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Google sign-in failed: $e',
      );
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();
}