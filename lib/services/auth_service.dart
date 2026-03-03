
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Extension to get current user
  User? get currentUser => _auth.currentUser;

  // Sign Up with Email & Password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (result.user != null) {
        await _saveUserToFirestore(result.user!, firstName, lastName);
        await result.user!.updateDisplayName("$firstName $lastName");
      }

      return result;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Login with Email & Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential result = await _auth.signInWithCredential(credential);

      // Save user to Firestore if new
      if (result.user != null) {
        // Check if user doc exists by uid
        final docRef = _firestore.collection('users').doc(result.user!.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          // If no doc by uid, check for existing doc by email to avoid duplicates
          final email = result.user!.email;
          if (email != null && email.isNotEmpty) {
            final query = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
            if (query.docs.isNotEmpty) {
              // Merge existing doc into new uid document to avoid duplicate user records
              final existing = query.docs.first;
              final existingData = existing.data();
              final merged = {
                ...existingData,
                'uid': result.user!.uid,
                'photoURL': result.user!.photoURL ?? existingData['photoURL'],
                'displayName': result.user!.displayName ?? existingData['displayName'],
                'mergedFrom': existing.id,
                'lastLogin': FieldValue.serverTimestamp(),
              };
              await docRef.set(merged, SetOptions(merge: true));
            } else {
              String firstName = '';
              String lastName = '';
              if (result.user!.displayName != null) {
                final names = result.user!.displayName!.split(' ');
                firstName = names.first;
                if (names.length > 1) lastName = names.sublist(1).join(' ');
              }
              await _saveUserToFirestore(result.user!, firstName, lastName);
            }
          }
        }
      }

      return result;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint("Attempting to send reset email to: $email");
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("Reset email sent successfully to: $email");
    } catch (e) {
      debugPrint("Error sending reset email: $e");
      throw _handleError(e);
    }
  }

  // Change password with optional current password for reauthentication
  Future<void> changePassword({required String newPassword, String? currentPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw FirebaseAuthException(code: 'no-current-user', message: 'No authenticated user.');

      // If the user signed in with email/password and provided currentPassword, try reauth
      if (currentPassword != null && user.email != null) {
        final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(cred);
      }

      await user.updatePassword(newPassword);

      // Update Firestore metadata about password change
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'lastPasswordChange': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to update Firestore password metadata: $e');
      }
    } on FirebaseAuthException catch (e) {
      // Re-throw with friendlier message handled by UI
      throw _handleError(e);
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Helper to save user data
  Future<void> _saveUserToFirestore(User user, String firstName, String lastName) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': user.displayName ?? "$firstName $lastName",
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get User Details
  Future<Map<String, dynamic>?> getUserDetails() async {
    if (_auth.currentUser == null) return null;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint("Error fetching user details: $e");
      return null;
    }
  }

  String _handleError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The email is already in use.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'The password is too weak.';
        default:
          return e.message ?? 'An unknown error occurred.';
      }
    }
    return e.toString();
  }
}
