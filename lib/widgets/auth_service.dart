import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthService {
  static const String _pendingEmailKey = 'pending_email_link_sign_in';
  static const String _emailLinkContinueUrl =
      'https://orientaamobileapp.firebaseapp.com/__/auth/links';
  static const String _androidPackageName = 'com.orientaa_mobile_app';
  static const String _iosBundleId = 'com.orientaaMobileApp';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Send email verification
    await credential.user!.sendEmailVerification();

    // Sign out so user must verify before logging in
    await _auth.signOut();

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  ActionCodeSettings _emailLinkActionCodeSettings() {
    return ActionCodeSettings(
      url: _emailLinkContinueUrl,
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: _iosBundleId,
    );
  }

  Future<void> sendSignInLinkToEmail(String email) async {
    final normalizedEmail = email.trim();
    await _auth.sendSignInLinkToEmail(
      email: normalizedEmail,
      actionCodeSettings: _emailLinkActionCodeSettings(),
    );
    await _savePendingEmailForLinkSignIn(normalizedEmail);
  }

  bool isSignInWithEmailLink(String emailLink) {
    return _auth.isSignInWithEmailLink(emailLink);
  }

  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    return _auth.signInWithEmailLink(
      email: email.trim(),
      emailLink: emailLink,
    );
  }

  Future<void> _savePendingEmailForLinkSignIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email);
  }

  Future<String?> getPendingEmailForLinkSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingEmailKey);
  }

  Future<void> clearPendingEmailForLinkSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google_sign_in_cancelled',
        message: 'Google sign-in was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Sends the Firebase ID token to the Django backend to authenticate the session.
  /// Returns the profile data if successful, or null if the backend is unavailable.
  Future<Map<String, dynamic>?> sendTokenToBackend(String idToken) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.profileUrl),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Backend rejected token: ${response.body}');
        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      debugPrint('Backend unavailable (SocketException): $e');
      return null;
    } on HttpException catch (e) {
      debugPrint('Backend unavailable (HttpException): $e');
      return null;
    } catch (e) {
      debugPrint('Backend communication error: $e');
      return null;
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Determines where the user should land after a successful login.
  ///
  /// Returning users skip the onboarding flow entirely:
  /// - A student whose profile has `onboardingComplete: true` goes straight to
  ///   the student dashboard.
  /// - A counsellor goes to the counsellor dashboard.
  /// - Only new users / users with an incomplete profile go to `/onboarding`.
  ///
  /// Role is stored in Firestore (written during onboarding/role selection) so
  /// it survives across devices. If Firestore can't be reached, the
  /// device-local role from SharedPreferences is used as a fallback.
  Future<String> postLoginDestination() async {
    final user = _auth.currentUser;
    if (user == null) return '/onboarding';

    final prefs = await SharedPreferences.getInstance();
    final localRole = prefs.getString('user_role');

    String? remoteRole;
    bool? remoteOnboardingComplete;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? const <String, dynamic>{};
        remoteRole = data['role'] as String?;
        remoteOnboardingComplete = data['onboardingComplete'] == true;
      }
    } catch (e) {
      // Firestore read failed (offline, permissions) — fall back below so a
      // returning user is never forced back through onboarding just because of
      // a transient network error.
      debugPrint('postLoginDestination: could not read profile ($e)');
    }

    // Remote data wins when it gives a clear signal.
    if (remoteRole == 'counsellor') {
      // Sync the device-local role so AppShell shows the right dashboard.
      await prefs.setString('user_role', 'counsellor');
      return '/counsellor-dashboard';
    }
    if (remoteOnboardingComplete == true) {
      await prefs.setString('user_role', 'student');
      return '/student-dashboard';
    }

    // No clear remote signal (doc missing, read failed, or the profile doc
    // exists but carries no role/onboardingComplete marker — e.g. a counsellor
    // who posted but never completed onboarding fields): consult the
    // device-local flags so a returning user is never forced back through
    // onboarding because of a transient error or a partial Firestore doc.
    if (localRole == 'counsellor') return '/counsellor-dashboard';
    if (prefs.getBool('onboarding_complete') == true) {
      await prefs.setString('user_role', 'student');
      return '/student-dashboard';
    }
    return '/onboarding';
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Sends a new verification email if the current user's email is not verified.
  /// Returns true if the email was sent, false if already verified.
  Future<bool> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.emailVerified) return false;
    await user.sendEmailVerification();
    return true;
  }

  /// Checks whether the current user's email is verified.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
}