import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:jihc_volunteers_app/services/firestore_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirestoreService? firestoreService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _firestoreService = firestoreService ?? FirestoreService();

  static Future<void>? _googleInitialization;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;

  User? get currentUser {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return _auth.currentUser;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    _guardReady();
    _ensureOfficialEmail(email);
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await _firestoreService.ensureUserDocument(credential.user);
    return credential;
  }

  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    _guardReady();
    _ensureOfficialEmail(email);
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
    await credential.user?.updateDisplayName(fullName.trim());
    await credential.user?.reload();
    await _firestoreService.ensureUserDocument(_auth.currentUser);
    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    _guardReady();
    await _ensureGoogleInitialized();
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In did not return a valid ID token.');
    }
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    final String email = userCredential.user?.email ?? '';
    if (!_isOfficialEmail(email)) {
      await _auth.signOut();
      await _googleSignIn.signOut();
      throw FormatException(
        'Access denied. Use your official JIHC email.',
      );
    }
    await _firestoreService.ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<void> resetPassword(String email) async {
    _guardReady();
    _ensureOfficialEmail(email);
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut(BuildContext context) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    await _auth.signOut();
    if (_googleInitialization != null) {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    }
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _guardReady() {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured yet.');
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  void _ensureOfficialEmail(String email) {
    if (!_isOfficialEmail(email)) {
      throw FormatException('Access denied. Use your official JIHC email.');
    }
  }

  bool _isOfficialEmail(String email) {
    return email.trim().toLowerCase().endsWith(
      AppConstants.officialEmailDomain,
    );
  }
}
