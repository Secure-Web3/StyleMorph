import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/services/loyalty_service.dart';
import '../../../core/services/referral_service.dart';
import '../../../core/state/app_state.dart';
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

  /// Intelligently splits a full display name into first and last name.
  static (String, String) splitDisplayName(String? displayName) {
    if (displayName == null) return ('', '');
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return ('', '');
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (parts.first, '');
    }
    final first = parts.first;
    final last = parts.sublist(1).join(' ');
    return (first, last);
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
        final (first, last) =
            splitDisplayName(userCredential.user!.displayName);
        await provisionFirestoreUser(
          userCredential.user!,
          authProvider: 'google',
          firstName: first,
          lastName: last,
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
      final (first, last) = splitDisplayName(
        googleUser.displayName ?? userCredential.user!.displayName,
      );
      await provisionFirestoreUser(
        userCredential.user!,
        authProvider: 'google',
        firstName: first,
        lastName: last,
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
      final givenName = appleCredential.givenName?.trim();
      final familyName = appleCredential.familyName?.trim();
      final (fallbackFirst, fallbackLast) =
          splitDisplayName(userCredential.user!.displayName);
      await provisionFirestoreUser(
        userCredential.user!,
        authProvider: 'apple',
        firstName: (givenName != null && givenName.isNotEmpty)
            ? givenName
            : fallbackFirst,
        lastName: (familyName != null && familyName.isNotEmpty)
            ? familyName
            : fallbackLast,
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
  /// Extracts first and last name and photoURL for Google/Apple sign-in, marks
  /// emailVerified as true, and awards the +100 StylePoints email verification
  /// bonus automatically without overwriting existing user edits.
  @override
  Future<void> provisionFirestoreUser(
    User user, {
    required String authProvider,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      final isOAuth = authProvider == 'google' || authProvider == 'apple';

      String extractedFirst = (firstName ?? '').trim();
      String extractedLast = (lastName ?? '').trim();
      if (extractedFirst.isEmpty &&
          extractedLast.isEmpty &&
          user.displayName != null) {
        final (f, l) = splitDisplayName(user.displayName);
        extractedFirst = f;
        extractedLast = l;
      }

      final photoUrl = user.photoURL?.trim() ?? '';
      final isEmailVerified = isOAuth || user.emailVerified;

      if (!snapshot.exists) {
        final referralCode = ReferralService.generateReferralCode();
        final initialPreferences = const UserPreferences().toMap();

        final identityMap = <String, String>{
          'email': user.email ?? '',
        };
        if (extractedFirst.isNotEmpty) {
          identityMap['firstName'] = extractedFirst;
        }
        if (extractedLast.isNotEmpty) {
          identityMap['lastName'] = extractedLast;
        }

        final progress = AppState.calculateProfileProgress(
          identity: identityMap,
          aiDna: const {},
          mediaSlots: const {},
        );
        final stylePoints = LoyaltyService.calculateStylePoints(
          profileProgress: progress,
          isEmailVerified: isEmailVerified,
          referralCount: 0,
          aiUsageCount: 0,
          coinActivity: 0,
        );
        final loyaltyRank =
            LoyaltyService.getRank(stylePoints).nameCapitalized;
        final fullName = [extractedFirst, extractedLast]
            .where((s) => s.isNotEmpty)
            .join(' ');

        final initialData = <String, dynamic>{
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': authProvider,
          'referralCode': referralCode,
          'preferences': initialPreferences,
          'emailVerified': isEmailVerified,
          'identity': identityMap,
          'profileProgress': progress,
          'stylePoints': stylePoints,
          'loyaltyRank': loyaltyRank,
        };

        if (fullName.isNotEmpty) {
          initialData['displayName'] = fullName;
          initialData['firstName'] = extractedFirst;
          initialData['lastName'] = extractedLast;
        } else if (user.displayName != null &&
            user.displayName!.isNotEmpty) {
          initialData['displayName'] = user.displayName!;
        }

        if (photoUrl.isNotEmpty) {
          initialData['photoURL'] = photoUrl;
        }

        await userDoc.set(initialData, SetOptions(merge: true));

        try {
          await _firestore.collection('referral_codes').doc(referralCode).set({
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      } else {
        // Document exists. Auto-populate empty fields without overwriting user edits.
        final existingData = snapshot.data() ?? {};
        final updates = <String, dynamic>{};

        final Map<String, dynamic> existingIdentity =
            existingData['identity'] is Map
                ? Map<String, dynamic>.from(existingData['identity'] as Map)
                : {};

        final currentFirst = (existingIdentity['firstName'] ??
                existingData['firstName'])
            ?.toString()
            .trim() ??
            '';
        final currentLast = (existingIdentity['lastName'] ??
                existingData['lastName'])
            ?.toString()
            .trim() ??
            '';
        final currentPhoto =
            (existingData['photoURL'])?.toString().trim() ?? '';
        final currentEmailVerified =
            existingData['emailVerified'] == true || user.emailVerified;

        bool identityChanged = false;
        final updatedIdentity = Map<String, String>.from(
          existingIdentity.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        );

        if (currentFirst.isEmpty && extractedFirst.isNotEmpty) {
          updatedIdentity['firstName'] = extractedFirst;
          updates['firstName'] = extractedFirst;
          identityChanged = true;
        }

        if (currentLast.isEmpty && extractedLast.isNotEmpty) {
          updatedIdentity['lastName'] = extractedLast;
          updates['lastName'] = extractedLast;
          identityChanged = true;
        }

        final existingDisplayName =
            existingData['displayName']?.toString().trim() ?? '';
        if (existingDisplayName.isEmpty) {
          final newFullName = [
            updatedIdentity['firstName'] ?? currentFirst,
            updatedIdentity['lastName'] ?? currentLast,
          ].where((s) => s.isNotEmpty).join(' ');
          if (newFullName.isNotEmpty) {
            updates['displayName'] = newFullName;
          } else if (user.displayName != null &&
              user.displayName!.isNotEmpty) {
            updates['displayName'] = user.displayName!;
          }
        }

        if (currentPhoto.isEmpty && photoUrl.isNotEmpty) {
          updates['photoURL'] = photoUrl;
        }

        bool verifiedNow = false;
        if (isOAuth && existingData['emailVerified'] != true) {
          updates['emailVerified'] = true;
          verifiedNow = true;
        }

        if (identityChanged) {
          updates['identity'] = updatedIdentity;
        }

        if (identityChanged || verifiedNow) {
          final Map<String, String> existingAiDna = existingData['aiDna'] is Map
              ? Map<String, String>.from(
                  (existingData['aiDna'] as Map).map(
                    (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                  ),
                )
              : {};
          final Map<String, String> existingMedia =
              existingData['mediaSlots'] is Map
                  ? Map<String, String>.from(
                      (existingData['mediaSlots'] as Map).map(
                        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                      ),
                    )
                  : {};
          final personaMode =
              existingData['personaMode']?.toString() ?? 'full_body';

          final progress = AppState.calculateProfileProgress(
            identity: updatedIdentity,
            aiDna: existingAiDna,
            personaMode: personaMode,
            mediaSlots: existingMedia,
          );
          updates['profileProgress'] = progress;

          final referralCount =
              (existingData['referralCount'] as num?)?.toInt() ?? 0;
          final aiUsageCount =
              (existingData['aiUsageCount'] as num?)?.toInt() ?? 0;
          final coins = (existingData['walletBalance'] as num?)?.toInt() ??
              (existingData['coins'] as num?)?.toInt() ??
              (existingData['coinBalance'] as num?)?.toInt() ??
              0;
          final isVerified = isOAuth || currentEmailVerified || verifiedNow;

          final stylePoints = LoyaltyService.calculateStylePoints(
            profileProgress: progress,
            isEmailVerified: isVerified,
            referralCount: referralCount,
            aiUsageCount: aiUsageCount,
            coinActivity: coins,
          );
          updates['stylePoints'] = stylePoints;
          updates['loyaltyRank'] =
              LoyaltyService.getRank(stylePoints).nameCapitalized;
        }

        if (updates.isNotEmpty) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await userDoc.set(updates, SetOptions(merge: true));
        }
      }
    } catch (e) {
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
