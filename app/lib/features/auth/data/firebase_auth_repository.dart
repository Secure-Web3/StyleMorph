import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
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
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<UserCredential?> signInWithApple() async {
    try {
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
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> provisionFirestoreUser(
    User user, {
    required String authProvider,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'email': user.email ?? '',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': authProvider,
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Allow downstream flow if network/offline
      rethrow;
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
