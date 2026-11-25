import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

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
    this.rewardEarned = 0,
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
      rewardEarned: (data['rewardEarned'] as num?)?.toInt() ?? 0,
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
  /// Never regenerates or overwrites an existing persisted code.
  Future<String> ensureUserReferralCode(
    String uid, {
    String? existingCode,
  }) async {
    if (uid.isEmpty) return '';
    final fallbackCode = existingCode?.trim().toUpperCase() ?? '';
    final firestore = _firestore;
    if (firestore == null) {
      return fallbackCode;
    }

    try {
      final userDocRef = firestore.collection('users').doc(uid);
      final userSnap = await userDocRef.get();
      final currentCode =
          userSnap.data()?['referralCode']?.toString().trim().toUpperCase() ??
          '';
      if (currentCode.isNotEmpty) {
        try {
          final codeRef = firestore
              .collection('referral_codes')
              .doc(currentCode);
          final codeSnap = await codeRef.get();
          if (!codeSnap.exists) {
            await codeRef.set({
              'uid': uid,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        } catch (e) {
          debugPrint('[ReferralService] referral_codes sync notice: $e');
        }
        return currentCode;
      }

      // Generate unique 8-char code
      String candidateCode = generateReferralCode();
      for (int i = 0; i < 5; i++) {
        final existing = await firestore
            .collection('referral_codes')
            .doc(candidateCode)
            .get();
        if (!existing.exists) break;
        candidateCode = generateReferralCode();
      }

      // Use a transaction so concurrent calls never overwrite an existing code
      final resolvedCode = await firestore.runTransaction<String>((tx) async {
        final freshUserSnap = await tx.get(userDocRef);
        final existingInTx =
            freshUserSnap
                .data()?['referralCode']
                ?.toString()
                .trim()
                .toUpperCase() ??
            '';
        if (existingInTx.isNotEmpty) {
          return existingInTx;
        }
        tx.set(userDocRef, {
          'referralCode': candidateCode,
        }, SetOptions(merge: true));
        tx.set(
          firestore.collection('referral_codes').doc(candidateCode),
          {'uid': uid, 'createdAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        return candidateCode;
      });

      return resolvedCode;
    } catch (e) {
      debugPrint('[ReferralService] ensureUserReferralCode notice: $e');
      return fallbackCode;
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

  /// Executes atomic dual-sided referral attribution on registration or OAuth sign-in:
  /// - Saves referral record under `users/{inviterUid}/referrals/{newUserUid}` with rewardEarned: 0.
  /// - Records `referredBy` and `referredByCode` on `users/{newUserUid}`.
  /// - Prevents self-referral and duplicate redemption safely and idempotently.
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
      if (!codeDoc.exists) {
        debugPrint(
          '[ReferralService] Referral code "$cleanCode" does not exist in referral_codes.',
        );
        if (!codeDoc.metadata.isFromCache) {
          await clearPendingReferralCode();
        }
        return false;
      }

      final inviterUid = codeDoc.data()?['uid']?.toString() ?? '';
      if (inviterUid.isEmpty || inviterUid == newUserUid) {
        debugPrint(
          '[ReferralService] Self-referral or invalid inviter ($inviterUid) rejected for $newUserUid.',
        );
        await clearPendingReferralCode();
        return false;
      }

      final newUserRef = firestore.collection('users').doc(newUserUid);
      final newUserSnap = await newUserRef.get();
      if (newUserSnap.exists) {
        final existingReferredBy =
            newUserSnap.data()?['referredBy']?.toString() ?? '';
        if (existingReferredBy.isNotEmpty) {
          debugPrint(
            '[ReferralService] User $newUserUid already attributed to inviter $existingReferredBy. Skipping duplicate attribution.',
          );
          await clearPendingReferralCode();
          return false;
        }
      }

      final referralRecordRef = firestore
          .collection('users')
          .doc(inviterUid)
          .collection('referrals')
          .doc(newUserUid);

      final referralPayload = <String, dynamic>{
        'inviteeUid': newUserUid,
        'displayName': (displayName != null && displayName.isNotEmpty)
            ? displayName
            : (newEmail.isNotEmpty ? newEmail.split('@').first : 'User'),
        'email': newEmail,
        'rewardEarned': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();

      // 1. Save referral entry under users/{inviterUid}/referrals/{newUserUid}
      // Zero writes to protected financial fields (walletBalance, coins, referralCount, networkTier)
      batch.set(referralRecordRef, referralPayload, SetOptions(merge: true));

      // 2. Set referredBy metadata on new user
      batch.set(newUserRef, {
        'referredBy': inviterUid,
        'referredByCode': cleanCode,
      }, SetOptions(merge: true));

      try {
        await batch.commit();
      } catch (batchErr) {
        debugPrint(
          '[ReferralService] Batch commit failed ($batchErr); falling back to standalone referral record write.',
        );
        await referralRecordRef.set(referralPayload, SetOptions(merge: true));
        try {
          await newUserRef.set({
            'referredBy': inviterUid,
            'referredByCode': cleanCode,
          }, SetOptions(merge: true));
        } catch (userUpdateErr) {
          debugPrint(
            '[ReferralService] Optional referredBy update notice: $userUpdateErr',
          );
        }
      }

      await clearPendingReferralCode();
      final inviteeLabel =
          (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (newEmail.isNotEmpty ? newEmail.split('@').first : 'A friend');
      unawaited(
        NotificationService(firestore: firestore).createNotification(
          uid: inviterUid,
          title: 'New Friend Joined',
          body: '$inviteeLabel signed up using your referral code!',
          category: 'finance',
          targetRoute: 'profile_referral',
          emoji: '🤝',
          extraData: {'eventType': 'referral_joined', 'inviteeUid': newUserUid},
        ),
      );
      debugPrint(
        '[ReferralService] Successfully attributed referral $cleanCode ($inviterUid -> $newUserUid).',
      );
      return true;
    } catch (e) {
      debugPrint('[ReferralService] applyReferralOnSignUp error: $e');
      return false;
    }
  }

  /// Public alias for referral attribution (e.g. for OAuth / Email flows).
  Future<bool> applyReferralCode({
    required String newUserUid,
    required String newEmail,
    String? displayName,
    required String referralCode,
  }) => applyReferralOnSignUp(
    newUserUid: newUserUid,
    newEmail: newEmail,
    displayName: displayName,
    referralCode: referralCode,
  );

  static List<ReferralEntry> _sortedEntries(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final entries = docs.map(ReferralEntry.fromFirestore).toList();
    entries.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.now();
      final bTime = b.createdAt ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
    return entries;
  }

  /// Fetches real invited friends list for [uid] with limit(50).
  Future<List<ReferralEntry>> getReferrals(String uid) async {
    if (uid.isEmpty) return const [];
    final firestore = _firestore;
    if (firestore == null) return const [];

    try {
      final snap = await firestore
          .collection('users')
          .doc(uid)
          .collection('referrals')
          .limit(50)
          .get();
      return _sortedEntries(snap.docs);
    } catch (e) {
      debugPrint('[ReferralService] getReferrals notice: $e');
      return const [];
    }
  }

  /// Streams real invited friends list for [uid] with limit(50).
  Stream<List<ReferralEntry>> referralsStream(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    final firestore = _firestore;
    if (firestore == null) return const Stream.empty();

    try {
      return firestore
          .collection('users')
          .doc(uid)
          .collection('referrals')
          .limit(50)
          .snapshots()
          .map((snap) => _sortedEntries(snap.docs));
    } catch (e) {
      debugPrint('[ReferralService] referralsStream notice: $e');
      return const Stream.empty();
    }
  }

  /// Captures `?ref=CODE`, `?refCode=CODE`, or `/r/CODE` from the URL and persists it in local storage.
  Future<void> captureReferralFromUri(Uri uri) async {
    try {
      String? code =
          uri.queryParameters['ref'] ?? uri.queryParameters['refCode'];
      if (code == null || code.trim().isEmpty) {
        final segments = uri.pathSegments;
        final rIndex = segments.indexWhere(
          (s) => s.toLowerCase() == 'r' || s.toLowerCase() == 'ref',
        );
        if (rIndex != -1 && rIndex + 1 < segments.length) {
          code = segments[rIndex + 1];
        }
      }
      if ((code == null || code.trim().isEmpty) && uri.fragment.isNotEmpty) {
        final fragUri = Uri.tryParse(uri.fragment);
        if (fragUri != null) {
          code =
              fragUri.queryParameters['ref'] ??
              fragUri.queryParameters['refCode'];
          if (code == null || code.trim().isEmpty) {
            final segments = fragUri.pathSegments;
            final rIndex = segments.indexWhere(
              (s) => s.toLowerCase() == 'r' || s.toLowerCase() == 'ref',
            );
            if (rIndex != -1 && rIndex + 1 < segments.length) {
              code = segments[rIndex + 1];
            }
          }
        }
      }

      if (code != null && code.trim().isNotEmpty) {
        final clean = code.trim().toUpperCase();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(pendingReferralKey, clean);
        debugPrint('[ReferralService] Captured pending referral code: $clean');
      }
    } catch (e) {
      debugPrint('[ReferralService] captureReferralFromUri notice: $e');
    }
  }

  /// Reads pending referral code stored in local storage, returning normalized uppercase code.
  Future<String?> getPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(pendingReferralKey);
      if (code != null && code.trim().isNotEmpty) {
        return code.trim().toUpperCase();
      }
      return null;
    } catch (e) {
      debugPrint('[ReferralService] getPendingReferralCode notice: $e');
      return null;
    }
  }

  /// Clears pending referral code from local storage once redeemed or invalid.
  Future<void> clearPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(pendingReferralKey);
    } catch (e) {
      debugPrint('[ReferralService] clearPendingReferralCode notice: $e');
    }
  }
}
