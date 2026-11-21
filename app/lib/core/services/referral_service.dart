import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ReferralEntry {
  final String id;
  final String inviteeUid;
  final String displayName;
  final String email;
  final int rewardEarned;
  final DateTime? createdAt;

  const ReferralEntry({
    required this.id,
    required this.inviteeUid,
    required this.displayName,
    required this.email,
    this.rewardEarned = 100,
    this.createdAt,
  });

  factory ReferralEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data['createdAt'];
    DateTime? dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is String) {
      dt = DateTime.tryParse(ts);
    }
    return ReferralEntry(
      id: doc.id,
      inviteeUid: data['inviteeUid']?.toString() ?? doc.id,
      displayName: data['displayName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      rewardEarned: (data['rewardEarned'] as num?)?.toInt() ?? 100,
      createdAt: dt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inviteeUid': inviteeUid,
      'displayName': displayName,
      'email': email,
      'rewardEarned': rewardEarned,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

final referralServiceProvider = Provider<ReferralService>((ref) {
  return ReferralService();
});

class ReferralService {
  final FirebaseFirestore? _customFirestore;

  ReferralService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    if (Firebase.apps.isNotEmpty) {
      return FirebaseFirestore.instance;
    }
    return null;
  }

  static const String pendingReferralKey = 'pending_referral_code';
  static const String _referralCharset = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Generates a unique, human-readable 8-character referral code
  /// excluding ambiguous characters like 0/O and 1/I.
  static String generateReferralCode([int length = 8]) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _referralCharset[random.nextInt(_referralCharset.length)],
    ).join();
  }

  /// Calculates dynamic Network Tier:
  /// Starter: 0–4, Silver: 5–14, Gold: 15–49, Ambassador: 50+
  static String calculateTier(int count) {
    if (count >= 50) return 'Ambassador';
    if (count >= 15) return 'Gold';
    if (count >= 5) return 'Silver';
    return 'Starter';
  }

  /// Ensures a referral code exists for [uid], generating and indexing one if missing.
  Future<String> ensureUserReferralCode(
    String uid, {
    String? existingCode,
  }) async {
    if (uid.isEmpty) return '';
    final firestore = _firestore;
    if (firestore == null) {
      return existingCode?.isNotEmpty == true
          ? existingCode!
          : generateReferralCode();
    }

    try {
      final userDocRef = firestore.collection('users').doc(uid);
      final userSnap = await userDocRef.get();
      final currentCode = userSnap.data()?['referralCode']?.toString() ?? '';
      if (currentCode.isNotEmpty) {
        return currentCode;
      }

      // Generate unique 8-char code
      String code = generateReferralCode();
      for (int i = 0; i < 5; i++) {
        final existing = await firestore
            .collection('referral_codes')
            .doc(code)
            .get();
        if (!existing.exists) break;
        code = generateReferralCode();
      }

      final batch = firestore.batch();
      batch.set(userDocRef, {'referralCode': code}, SetOptions(merge: true));
      batch.set(firestore.collection('referral_codes').doc(code), {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      return code;
    } catch (e) {
      debugPrint('[ReferralService] ensureUserReferralCode notice: $e');
      return existingCode?.isNotEmpty == true
          ? existingCode!
          : generateReferralCode();
    }
  }

  /// Resolves an 8-character referral code to the inviter's UID.
  Future<String?> resolveReferralCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore
          .collection('referral_codes')
          .doc(cleanCode)
          .get();
      if (doc.exists) {
        return doc.data()?['uid']?.toString();
      }
    } catch (e) {
      debugPrint('[ReferralService] resolveReferralCode notice: $e');
    }
    return null;
  }

  /// Executes atomic dual-sided reward on registration with a valid referral code:
  /// - Inviter receives +100 Coins, +1 referral count, and updated Network Tier.
  /// - New user receives +50 Coins and has `referredBy` recorded.
  /// - Saves referral record under `users/{inviterUid}/referrals/{newUserUid}`.
  /// - Prevents self-referral and duplicate redemption.
  Future<bool> applyReferralOnSignUp({
    required String newUserUid,
    required String newEmail,
    String? displayName,
    required String referralCode,
  }) async {
    final cleanCode = referralCode.trim().toUpperCase();
    if (cleanCode.isEmpty || newUserUid.isEmpty) return false;
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final codeDoc = await firestore
          .collection('referral_codes')
          .doc(cleanCode)
          .get();
      if (!codeDoc.exists) return false;

      final inviterUid = codeDoc.data()?['uid']?.toString() ?? '';
      if (inviterUid.isEmpty || inviterUid == newUserUid) {
        // Prevent self-referral
        return false;
      }

      final newUserRef = firestore.collection('users').doc(newUserUid);
      final newUserSnap = await newUserRef.get();
      if (newUserSnap.exists && newUserSnap.data()?['referredBy'] != null) {
        // Prevent duplicate redemption
        return false;
      }

      final inviterSnap = await firestore
          .collection('users')
          .doc(inviterUid)
          .get();
      if (!inviterSnap.exists) {
        return false;
      }

      final referralRecordRef = firestore
          .collection('users')
          .doc(inviterUid)
          .collection('referrals')
          .doc(newUserUid);

      final batch = firestore.batch();

      // 1. Save referral entry under users/{inviterUid}/referrals/{newUserUid}
      // Note: Financial rewards and inviter referralCount/networkTier are processed
      // via Cloud Function in Slice 2 to adhere to Zero-Trust client write rules.
      batch.set(referralRecordRef, {
        'inviteeUid': newUserUid,
        'displayName': (displayName != null && displayName.isNotEmpty)
            ? displayName
            : newEmail.split('@').first,
        'email': newEmail,
        'rewardEarned': 100,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Set referredBy metadata on new user
      batch.set(newUserRef, {
        'referredBy': inviterUid,
        'referredByCode': cleanCode,
      }, SetOptions(merge: true));

      await batch.commit();
      await clearPendingReferralCode();
      return true;
    } catch (e) {
      debugPrint('[ReferralService] applyReferralOnSignUp error: $e');
      return false;
    }
  }

  /// Fetches real invited friends list for [uid].
  Future<List<ReferralEntry>> getReferrals(String uid) async {
    if (uid.isEmpty) return const [];
    final firestore = _firestore;
    if (firestore == null) return const [];

    try {
      final snap = await firestore
          .collection('users')
          .doc(uid)
          .collection('referrals')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(ReferralEntry.fromFirestore).toList();
    } catch (e) {
      debugPrint('[ReferralService] getReferrals notice: $e');
      return const [];
    }
  }

  /// Captures `?ref=CODE` from the URL when opened on Web and persists it in local storage.
  Future<void> captureReferralFromUri(Uri uri) async {
    try {
      final refParam = uri.queryParameters['ref'];
      if (refParam != null && refParam.trim().isNotEmpty) {
        final clean = refParam.trim().toUpperCase();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(pendingReferralKey, clean);
      }
    } catch (e) {
      debugPrint('[ReferralService] captureReferralFromUri notice: $e');
    }
  }

  /// Reads pending referral code stored in local storage.
  Future<String?> getPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(pendingReferralKey);
    } catch (e) {
      debugPrint('[ReferralService] getPendingReferralCode notice: $e');
      return null;
    }
  }

  /// Clears pending referral code from local storage once redeemed.
  Future<void> clearPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pendingReferralKey);
    } catch (e) {
      debugPrint('[ReferralService] clearPendingReferralCode notice: $e');
    }
  }
}
