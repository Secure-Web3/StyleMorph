import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'totp_helper.dart';

/// Supported Two-Factor Authentication methods.
enum TwoFactorMethod {
  totp,
  email;

  String get firestoreValue => name;

  static TwoFactorMethod fromString(String? raw) {
    return raw == 'email' ? TwoFactorMethod.email : TwoFactorMethod.totp;
  }
}

/// Persisted 2FA configuration stored under `users/{uid}.twoFactor`.
@immutable
class TwoFactorConfig {
  final bool enabled;
  final TwoFactorMethod method;
  final String? totpSecret;

  const TwoFactorConfig({
    this.enabled = false,
    this.method = TwoFactorMethod.totp,
    this.totpSecret,
  });

  factory TwoFactorConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TwoFactorConfig();
    return TwoFactorConfig(
      enabled: map['enabled'] as bool? ?? false,
      method: TwoFactorMethod.fromString(map['method']?.toString()),
      totpSecret: map['totpSecret']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'method': method.firestoreValue,
    'totpSecret': totpSecret,
  };
}

/// Result of requesting an Email OTP challenge.
@immutable
class EmailOtpDispatchResult {
  final bool sent;
  final bool isPreviewFallback;
  final int cooldownRemainingSeconds;
  final String? previewCode;

  const EmailOtpDispatchResult({
    required this.sent,
    this.isPreviewFallback = false,
    this.cooldownRemainingSeconds = 0,
    this.previewCode,
  });
}

/// Pluggable dispatcher interface for sending 6-digit Email OTP codes.
/// Wire to a Cloud Function / SMTP endpoint on Blaze; defaults to safe
/// Spark-preview mode without crashing.
abstract class EmailOtpDispatcher {
  Future<bool> dispatchOtp({
    required String uid,
    required String email,
    required String code,
  });
}

/// Safe default dispatcher for Spark preview environments without Cloud Functions.
class PreviewEmailOtpDispatcher implements EmailOtpDispatcher {
  const PreviewEmailOtpDispatcher();

  @override
  Future<bool> dispatchOtp({
    required String uid,
    required String email,
    required String code,
  }) async {
    debugPrint(
      '[TwoFactorService] Email OTP dispatcher running in preview mode for $email.',
    );
    return false;
  }
}

class _PendingEmailOtp {
  final String code;
  final DateTime expiresAt;
  final DateTime sentAt;

  const _PendingEmailOtp({
    required this.code,
    required this.expiresAt,
    required this.sentAt,
  });
}

/// Service managing 2FA configuration persistence, TOTP enrollment, and Email OTP.
class TwoFactorService {
  static const Duration emailOtpTtl = Duration(minutes: 5);
  static const Duration emailResendCooldown = Duration(seconds: 60);
  static const Duration kTwoFactorInactivityTtl = Duration(days: 7);
  static const String _persistedSessionKey = 'two_factor_verified_session_v1';

  /// Persists 2FA verification for [uid] and [sessionId] with a 7-day inactivity TTL.
  static Future<void> markSessionVerified({
    required String uid,
    required String sessionId,
    DateTime? now,
  }) async {
    if (uid.isEmpty || sessionId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(<String, dynamic>{
        'uid': uid,
        'sessionId': sessionId,
        'lastActiveMs': (now ?? DateTime.now()).millisecondsSinceEpoch,
      });
      await prefs.setString(_persistedSessionKey, payload);
    } catch (e) {
      debugPrint('[TwoFactorService] markSessionVerified notice: $e');
    }
  }

  /// Returns true only if a persisted 2FA verification record matches [uid] and
  /// [sessionId] and has not exceeded [kTwoFactorInactivityTtl] (7 days).
  /// Automatically clears stale, expired, or mismatched records.
  static Future<bool> isPersistedSessionValid({
    required String uid,
    required String sessionId,
    DateTime? now,
  }) async {
    if (uid.isEmpty || sessionId.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistedSessionKey);
      if (raw == null || raw.isEmpty) return false;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await clearPersistedVerification();
        return false;
      }

      final storedUid = decoded['uid']?.toString() ?? '';
      final storedSessionId = decoded['sessionId']?.toString() ?? '';
      final lastActiveMs = decoded['lastActiveMs'];
      if (storedUid != uid ||
          storedSessionId != sessionId ||
          lastActiveMs is! int) {
        await clearPersistedVerification();
        return false;
      }

      final currentMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
      final elapsedMs = currentMs - lastActiveMs;
      if (elapsedMs < 0 || elapsedMs > kTwoFactorInactivityTtl.inMilliseconds) {
        await clearPersistedVerification();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[TwoFactorService] isPersistedSessionValid notice: $e');
      await clearPersistedVerification();
      return false;
    }
  }

  /// Refreshes the last-active timestamp if the persisted 2FA record is still valid.
  static Future<void> touchSessionActivity({
    required String uid,
    required String sessionId,
    DateTime? now,
  }) async {
    if (uid.isEmpty || sessionId.isEmpty) return;
    final valid = await isPersistedSessionValid(
      uid: uid,
      sessionId: sessionId,
      now: now,
    );
    if (!valid) return;
    await markSessionVerified(uid: uid, sessionId: sessionId, now: now);
  }

  /// Clears any persisted 2FA session verification record immediately.
  static Future<void> clearPersistedVerification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_persistedSessionKey);
    } catch (e) {
      debugPrint('[TwoFactorService] clearPersistedVerification notice: $e');
    }
  }

  /// Converts Persian (`۰-۹`) and Arabic-Indic (`٠-٩`) digits to ASCII `0-9`,
  /// strips non-digit characters (spaces, hyphens, etc.), and returns the
  /// normalized 6-digit OTP if valid, or `null` otherwise.
  static String? extractSixDigitOtp(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.writeCharCode(rune);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + (rune - 0x06F0));
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + (rune - 0x0660));
      }
    }
    final digits = buffer.toString();
    return digits.length == 6 ? digits : null;
  }

  final FirebaseFirestore? _customFirestore;
  final EmailOtpDispatcher _emailDispatcher;
  final Random _random;
  final DateTime Function() _nowProvider;
  final Map<String, _PendingEmailOtp> _pendingEmailOtps = {};

  TwoFactorService({
    FirebaseFirestore? firestore,
    EmailOtpDispatcher? emailDispatcher,
    Random? random,
    DateTime Function()? nowProvider,
  }) : _customFirestore = firestore,
       _emailDispatcher = emailDispatcher ?? const PreviewEmailOtpDispatcher(),
       _random = random ?? Random.secure(),
       _nowProvider = nowProvider ?? DateTime.now;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Loads `users/{uid}.twoFactor` safely.
  Future<TwoFactorConfig> loadConfig(String uid) async {
    if (uid.isEmpty) return const TwoFactorConfig();
    final db = _firestore;
    if (db == null) return const TwoFactorConfig();
    try {
      final snap = await db.collection('users').doc(uid).get();
      final data = snap.data();
      final raw = data?['twoFactor'];
      if (raw is Map<String, dynamic>) {
        return TwoFactorConfig.fromMap(raw);
      }
      if (raw is Map) {
        return TwoFactorConfig.fromMap(Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      debugPrint('[TwoFactorService] loadConfig notice: $e');
    }
    return const TwoFactorConfig();
  }

  /// Watches `users/{uid}.twoFactor` in real time.
  Stream<TwoFactorConfig> watchConfig(String uid) {
    if (uid.isEmpty) return Stream.value(const TwoFactorConfig());
    final db = _firestore;
    if (db == null) return Stream.value(const TwoFactorConfig());
    return db.collection('users').doc(uid).snapshots().map((snap) {
      final raw = snap.data()?['twoFactor'];
      if (raw is Map<String, dynamic>) {
        return TwoFactorConfig.fromMap(raw);
      }
      if (raw is Map) {
        return TwoFactorConfig.fromMap(Map<String, dynamic>.from(raw));
      }
      return const TwoFactorConfig();
    });
  }

  /// Verifies [code] against [secret] and persists TOTP 2FA on `users/{uid}`.
  Future<bool> enrollTotp({
    required String uid,
    required String secret,
    required String code,
  }) async {
    if (uid.isEmpty) return false;
    if (!TotpHelper.verifyCode(secret, code)) return false;
    await _saveConfig(
      uid,
      TwoFactorConfig(
        enabled: true,
        method: TwoFactorMethod.totp,
        totpSecret: secret,
      ),
    );
    return true;
  }

  /// Verifies the pending Email OTP [code] and activates Email 2FA on `users/{uid}`.
  Future<bool> enrollEmail({required String uid, required String code}) async {
    if (uid.isEmpty) return false;
    if (!verifyEmailOtp(uid: uid, code: code)) return false;
    await _saveConfig(
      uid,
      const TwoFactorConfig(
        enabled: true,
        method: TwoFactorMethod.email,
        totpSecret: null,
      ),
    );
    return true;
  }

  /// Disables 2FA and clears any stored TOTP secret.
  Future<void> disableTwoFactor(String uid) async {
    if (uid.isEmpty) return;
    _pendingEmailOtps.remove(uid);
    await _saveConfig(
      uid,
      const TwoFactorConfig(
        enabled: false,
        method: TwoFactorMethod.totp,
        totpSecret: null,
      ),
    );
  }

  /// Generates a 6-digit Email OTP with 5-minute TTL and 60s resend cooldown.
  Future<EmailOtpDispatchResult> requestEmailOtp({
    required String uid,
    required String email,
  }) async {
    final now = _nowProvider();
    final existing = _pendingEmailOtps[uid];
    if (existing != null) {
      final elapsed = now.difference(existing.sentAt);
      if (elapsed < emailResendCooldown) {
        return EmailOtpDispatchResult(
          sent: false,
          cooldownRemainingSeconds: (emailResendCooldown - elapsed).inSeconds,
        );
      }
    }

    final code = _random.nextInt(1000000).toString().padLeft(6, '0');
    _pendingEmailOtps[uid] = _PendingEmailOtp(
      code: code,
      expiresAt: now.add(emailOtpTtl),
      sentAt: now,
    );

    try {
      final dispatched = await _emailDispatcher.dispatchOtp(
        uid: uid,
        email: email,
        code: code,
      );
      return EmailOtpDispatchResult(
        sent: true,
        isPreviewFallback: !dispatched,
        previewCode: !dispatched && kDebugMode ? code : null,
      );
    } catch (e) {
      debugPrint('[TwoFactorService] requestEmailOtp notice: $e');
      return EmailOtpDispatchResult(
        sent: true,
        isPreviewFallback: true,
        previewCode: kDebugMode ? code : null,
      );
    }
  }

  /// Verifies an Email OTP against the active 5-minute challenge for [uid].
  bool verifyEmailOtp({required String uid, required String code}) {
    final pending = _pendingEmailOtps[uid];
    if (pending == null) return false;
    final now = _nowProvider();
    if (now.isAfter(pending.expiresAt)) {
      _pendingEmailOtps.remove(uid);
      return false;
    }
    final clean = code.trim();
    if (clean.length != 6 || clean != pending.code) return false;
    _pendingEmailOtps.remove(uid);
    return true;
  }

  /// Verifies a 6-digit login 2FA code using the user's configured [config].
  bool verifyLoginCode({
    required TwoFactorConfig config,
    required String uid,
    required String code,
  }) {
    if (!config.enabled) return true;
    switch (config.method) {
      case TwoFactorMethod.totp:
        final secret = config.totpSecret ?? '';
        if (secret.isEmpty) return false;
        return TotpHelper.verifyCode(secret, code);
      case TwoFactorMethod.email:
        return verifyEmailOtp(uid: uid, code: code);
    }
  }

  Future<void> _saveConfig(String uid, TwoFactorConfig config) async {
    final db = _firestore;
    if (db == null) return;
    await db.collection('users').doc(uid).set({
      'twoFactor': {
        ...config.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}

final twoFactorServiceProvider = Provider<TwoFactorService>((ref) {
  return TwoFactorService();
});

/// Watches the user's persisted 2FA configuration by UID.
final twoFactorConfigProvider = StreamProvider.autoDispose
    .family<TwoFactorConfig, String>((ref, uid) {
      return ref.watch(twoFactorServiceProvider).watchConfig(uid);
    });

/// Tracks whether the current runtime session has passed 2FA verification.
final twoFactorSessionVerifiedProvider = StateProvider<bool>((ref) => false);
