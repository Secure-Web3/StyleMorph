import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/services/referral_service.dart';
import '../../profile/data/user_preferences.dart';
import '../domain/auth_repository.dart';

/// Concrete implementation of [AuthRepository] using Firebase Auth, Cloud Firestore,
/// Google Sign-In, and Apple Sign-In.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final GoogleSignIn? _customGoogleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _customAuth = auth,
        _customFirestore = firestore,
        _customGoogleSignIn = googleSignIn;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn =>
      _customGoogleSignIn ?? GoogleSignIn();

  @override
  Stream<User?> get authStateChanges {
    try {
      if (Firebase.apps.isEmpty) {
        return Stream.value(null);
      }
      return _auth.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  User? get currentUser {
    try {
      if (Firebase.apps.isEmpty) return null;
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      await provisionFirestoreUser(
        credential.user!,
        authProvider: 'email',
      );
    }

    return credential;
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    // On Web, use the Firebase-native popup flow — the google_sign_in package
    // redirect flow requires additional OAuth client configuration and does not
    // work reliably on hosted web apps without a google-signin-client_id meta tag.
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      final userCredential = await _auth.signInWithPopup(provider);
      if (userCredential.user != null) {
        await provisionFirestoreUser(
          userCredential.user!,
          authProvider: 'google',
        );
      }
      return userCredential;
    }

    // Native mobile flow via google_sign_in package.
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the sign-in flow.
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      await provisionFirestoreUser(
        userCredential.user!,
        authProvider: 'google',
      );
    }

    return userCredential;
  }

  @override
  Future<UserCredential?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final OAuthProvider oauthProvider = OAuthProvider('apple.com');
    final AuthCredential credential = oauthProvider.credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      await provisionFirestoreUser(
        userCredential.user!,
        authProvider: 'apple',
      );
    }

    return userCredential;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Creates or merges a Firestore user document for [user].
  ///
  /// Errors here are logged but intentionally NOT re-thrown so that a
  /// Firestore permission issue (e.g. rules not yet deployed) never surfaces
  /// as an authentication failure to the end user.
  @override
  Future<void> provisionFirestoreUser(
    User user, {
    required String authProvider,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        final referralCode = ReferralService.generateReferralCode();
        final initialPreferences = const UserPreferences().toMap();
        await userDoc.set({
          'email': user.email ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': authProvider,
          'referralCode': referralCode,
          'referralCount': 0,
          'networkTier': 'Starter',
          'coins': 0,
          'preferences': initialPreferences,
        }, SetOptions(merge: true));

        try {
          await _firestore.collection('referral_codes').doc(referralCode).set({
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (e) {
      // Log the exact Firestore error without blocking the auth flow.
      debugPrint('[FirebaseAuthRepository] provisionFirestoreUser error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Generates a cryptographic nonce for Apple Sign-In.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
