import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_storage.dart';

// ── Model ──────────────────────────────────────────────────────────────────

@immutable
class SessionInfo {
  final String sessionId;
  final String deviceId;
  final String
  deviceType; // 'mobile_web' | 'desktop_web' | 'mobile_app' | 'desktop_app'
  final String deviceName;
  final String deviceModel;
  final String platform;
  final String osVersion;
  final String userAgent;
  final bool isPrimary;
  final bool isBlocked;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const SessionInfo({
    required this.sessionId,
    required this.deviceId,
    required this.deviceType,
    required this.deviceName,
    required this.deviceModel,
    required this.platform,
    required this.osVersion,
    required this.userAgent,
    this.isPrimary = false,
    this.isBlocked = false,
    this.isActive = true,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory SessionInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SessionInfo(
      sessionId: d['sessionId'] as String? ?? doc.id,
      deviceId: d['deviceId'] as String? ?? '',
      deviceType: d['deviceType'] as String? ?? 'desktop_web',
      deviceName: d['deviceName'] as String? ?? 'Unknown Device',
      deviceModel: d['deviceModel'] as String? ?? '',
      platform: d['platform'] as String? ?? 'Unknown',
      osVersion: d['osVersion'] as String? ?? '',
      userAgent: d['userAgent'] as String? ?? '',
      isPrimary: d['isPrimary'] as bool? ?? false,
      isBlocked: d['isBlocked'] as bool? ?? false,
      isActive: d['isActive'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt:
          (d['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sessionId': sessionId,
    'deviceId': deviceId,
    'deviceType': deviceType,
    'deviceName': deviceName,
    'deviceModel': deviceModel,
    'platform': platform,
    'osVersion': osVersion,
    'userAgent': userAgent,
    'isPrimary': isPrimary,
    'isBlocked': isBlocked,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastActiveAt': Timestamp.fromDate(lastActiveAt),
  };

  SessionInfo copyWith({
    String? sessionId,
    String? deviceId,
    String? deviceType,
    String? deviceName,
    String? deviceModel,
    String? platform,
    String? osVersion,
    String? userAgent,
    bool? isPrimary,
    bool? isBlocked,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return SessionInfo(
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      userAgent: userAgent ?? this.userAgent,
      isPrimary: isPrimary ?? this.isPrimary,
      isBlocked: isBlocked ?? this.isBlocked,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

// ── Service ────────────────────────────────────────────────────────────────

class SessionService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  static const Duration sessionInactivityExpiry = Duration(days: 5);
  static const Duration lastActiveThrottle = Duration(minutes: 15);
  static const int maxConcurrentSessions = 5;

  DateTime? _lastActivityWriteTime;

  @visibleForTesting
  DateTime? get lastActivityWriteTime => _lastActivityWriteTime;

  @visibleForTesting
  set lastActivityWriteTime(DateTime? val) => _lastActivityWriteTime = val;

  SessionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _customFirestore = firestore,
      _customAuth = auth;

  // ── Persistent IDs ────────────────────────────────────────────────────────

  String? _cachedSessionId;
  String? _cachedDeviceId;

  Future<String> currentSessionId() async {
    if (_cachedSessionId != null) return _cachedSessionId!;
    try {
      final stored = await SessionLocalStorage.getSessionId();
      if (stored != null && stored.isNotEmpty) {
        _cachedSessionId = stored;
        return stored;
      }
      final newId = _generateId('sess');
      await SessionLocalStorage.setSessionId(newId);
      _cachedSessionId = newId;
      return newId;
    } catch (_) {
      _cachedSessionId ??= _generateId('sess');
      return _cachedSessionId!;
    }
  }

  Future<String> currentDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    try {
      final stored = await SessionLocalStorage.getDeviceId();
      if (stored != null && stored.isNotEmpty) {
        _cachedDeviceId = stored;
        return stored;
      }
      final newId = _generateId('dev');
      await SessionLocalStorage.setDeviceId(newId);
      _cachedDeviceId = newId;
      return newId;
    } catch (_) {
      _cachedDeviceId ??= _generateId('dev');
      return _cachedDeviceId!;
    }
  }

  String _generateId(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = (DateTime.now().microsecond ^ DateTime.now().hashCode)
        .abs()
        .toRadixString(36);
    return '${prefix}_${ts}_$rand';
  }

  // ── Device metadata & resolution ──────────────────────────────────────────

  Map<String, String> _buildDeviceMeta() {
    if (kIsWeb) {
      final ua = SessionLocalStorage.getUserAgent() ?? '';
      final isMobile = RegExp(
        r'Mobile|Android|iPhone|iPad|iPod|webOS|BlackBerry|IEMobile|Opera Mini',
        caseSensitive: false,
      ).hasMatch(ua);

      String os = 'Web';
      if (ua.contains('Android')) {
        os = 'Android';
      } else if (RegExp(
        r'iPhone|iPad|iPod',
        caseSensitive: false,
      ).hasMatch(ua)) {
        os = 'iOS';
      } else if (ua.contains('Windows')) {
        os = 'Windows';
      } else if (ua.contains('Macintosh') || ua.contains('Mac OS')) {
        os = 'macOS';
      } else if (ua.contains('Linux')) {
        os = 'Linux';
      } else if (ua.contains('CrOS')) {
        os = 'ChromeOS';
      }

      String browser = 'Browser';
      if (ua.contains('Edg/')) {
        browser = 'Edge';
      } else if (ua.contains('Chrome/')) {
        browser = 'Chrome';
      } else if (ua.contains('Safari/') && !ua.contains('Chrome/')) {
        browser = 'Safari';
      } else if (ua.contains('Firefox/')) {
        browser = 'Firefox';
      } else if (ua.contains('OPR/') || ua.contains('Opera/')) {
        browser = 'Opera';
      }

      final formFactor = isMobile ? 'Mobile Web' : 'Desktop Web';
      return {
        'deviceType': isMobile ? 'mobile_web' : 'desktop_web',
        'deviceName': '$formFactor • $browser ($os)',
        'deviceModel': '$browser on $os',
        'platform': 'Web',
        'osVersion': os,
        'userAgent': ua.isNotEmpty ? ua : '$formFactor Browser',
      };
    }

    final ua = SessionLocalStorage.getUserAgent() ?? '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return {
          'deviceType': 'mobile_app',
          'deviceName': 'Android App',
          'deviceModel': 'Android Device',
          'platform': 'Android',
          'osVersion': 'Android',
          'userAgent': ua.isNotEmpty ? ua : 'StyleMorph/Android',
        };
      case TargetPlatform.iOS:
        return {
          'deviceType': 'mobile_app',
          'deviceName': 'iOS App',
          'deviceModel': 'iPhone / iPad',
          'platform': 'iOS',
          'osVersion': 'iOS',
          'userAgent': ua.isNotEmpty ? ua : 'StyleMorph/iOS',
        };
      case TargetPlatform.windows:
        return {
          'deviceType': 'desktop_app',
          'deviceName': 'Windows App',
          'deviceModel': 'Windows PC',
          'platform': 'Desktop',
          'osVersion': 'Windows',
          'userAgent': ua.isNotEmpty ? ua : 'StyleMorph/Windows',
        };
      case TargetPlatform.macOS:
        return {
          'deviceType': 'desktop_app',
          'deviceName': 'macOS App',
          'deviceModel': 'Mac',
          'platform': 'Desktop',
          'osVersion': 'macOS',
          'userAgent': ua.isNotEmpty ? ua : 'StyleMorph/macOS',
        };
      case TargetPlatform.linux:
        return {
          'deviceType': 'desktop_app',
          'deviceName': 'Linux App',
          'deviceModel': 'Linux PC',
          'platform': 'Desktop',
          'osVersion': 'Linux',
          'userAgent': ua.isNotEmpty ? ua : 'StyleMorph/Linux',
        };
      default:
        return {
          'deviceType': 'unknown',
          'deviceName': 'Unknown Device',
          'deviceModel': 'Unknown',
          'platform': 'Unknown',
          'osVersion': '',
          'userAgent': ua.isNotEmpty ? ua : 'StyleMorph',
        };
    }
  }

  // ── Upsert session in Firestore (with Legacy Primary Auto-Assignment) ─────

  Future<void> upsertSession() async {
    if (Firebase.apps.isEmpty && _customFirestore == null) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final sessionId = await currentSessionId();
    final deviceId = await currentDeviceId();
    final meta = _buildDeviceMeta();
    final now = Timestamp.now();

    try {
      // 1. Check if device is blocked
      final blockedSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('blocked_devices')
          .doc(deviceId)
          .get();

      final isDeviceBlocked =
          blockedSnap.exists &&
          (blockedSnap.data()?['isBlocked'] as bool? ?? false);

      // 2. Fetch all existing sessions to handle Primary Device assignment
      final allSessionsSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .get();

      final existingSessions = allSessionsSnap.docs;
      final hasPrimary = existingSessions.any(
        (doc) => (doc.data()['isPrimary'] as bool? ?? false) == true,
      );

      bool isThisSessionPrimary = false;

      if (hasPrimary) {
        // If an existing session is primary, keep this session's existing isPrimary value
        final existingCurrentDoc = existingSessions
            .cast<QueryDocumentSnapshot<Map<String, dynamic>>?>()
            .firstWhere((doc) => doc?.id == sessionId, orElse: () => null);
        isThisSessionPrimary =
            existingCurrentDoc?.data()['isPrimary'] as bool? ?? false;
      } else {
        // LEGACY AUTO-ASSIGN: If NO session in Firestore has isPrimary == true:
        if (existingSessions.isEmpty) {
          isThisSessionPrimary = true;
        } else {
          // Find earliest session by createdAt timestamp
          QueryDocumentSnapshot<Map<String, dynamic>> earliestDoc =
              existingSessions.first;
          DateTime earliestTime =
              (earliestDoc.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now();

          for (final doc in existingSessions) {
            final t = (doc.data()['createdAt'] as Timestamp?)?.toDate();
            if (t != null && t.isBefore(earliestTime)) {
              earliestTime = t;
              earliestDoc = doc;
            }
          }

          if (earliestDoc.id == sessionId) {
            isThisSessionPrimary = true;
          } else {
            // Promote earliest session to Primary immediately in Firestore
            await earliestDoc.reference.update({'isPrimary': true});
            isThisSessionPrimary = false;
          }
        }
      }

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId);

      final existing = await docRef.get();
      if (existing.exists) {
        // Automatic 5-day inactivity expiration check upon open/login
        final existingLastActive =
            (existing.data()?['lastActiveAt'] as Timestamp?)?.toDate();
        if (existingLastActive != null &&
            DateTime.now().difference(existingLastActive) >=
                sessionInactivityExpiry) {
          debugPrint(
            '[SessionService] Session $sessionId has expired (> 5 days inactivity). Deleting document and signing out.',
          );
          await docRef.delete();
          await _auth.signOut();
          return;
        }

        final Map<String, dynamic> updateData = {
          'isActive': !isDeviceBlocked,
          'isBlocked': isDeviceBlocked,
          'isPrimary': isThisSessionPrimary,
          'deviceId': deviceId,
          'deviceType': meta['deviceType'],
          'deviceName': meta['deviceName'],
          'deviceModel': meta['deviceModel'],
          'platform': meta['platform'],
          'osVersion': meta['osVersion'],
          'userAgent': meta['userAgent'],
        };

        // Throttle lastActiveAt updates to at most once every 15 minutes
        final shouldUpdateLastActive =
            _lastActivityWriteTime == null ||
            now.toDate().difference(_lastActivityWriteTime!) >=
                lastActiveThrottle;

        if (shouldUpdateLastActive) {
          updateData['lastActiveAt'] = now;
          _lastActivityWriteTime = DateTime.now();
        }

        await docRef.update(updateData);
      } else {
        final session = SessionInfo(
          sessionId: sessionId,
          deviceId: deviceId,
          deviceType: meta['deviceType']!,
          deviceName: meta['deviceName']!,
          deviceModel: meta['deviceModel']!,
          platform: meta['platform']!,
          osVersion: meta['osVersion']!,
          userAgent: meta['userAgent']!,
          isPrimary: isThisSessionPrimary,
          isBlocked: isDeviceBlocked,
          isActive: !isDeviceBlocked,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
        await docRef.set(session.toMap());
        _lastActivityWriteTime = DateTime.now();
      }

      // Enforce maximum of 5 concurrent active sessions upon login
      await enforceMaxActiveSessions(user.uid, sessionId);

      debugPrint(
        '[SessionService] Session upserted: $sessionId (primary: $isThisSessionPrimary)',
      );
    } catch (e) {
      debugPrint('[SessionService] upsertSession error: $e');
    }
  }

  // ── Blocking & Unblocking Controls ────────────────────────────────────────

  Future<bool> blockDevice({
    required String targetSessionId,
    required String targetDeviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final targetDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(targetSessionId);

      final targetDoc = await targetDocRef.get();
      if (targetDoc.exists &&
          (targetDoc.data()?['isPrimary'] as bool? ?? false)) {
        // Never allow blocking the Primary Device
        return false;
      }

      final batch = _firestore.batch();
      batch.update(targetDocRef, {'isBlocked': true, 'isActive': false});

      final blockedDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('blocked_devices')
          .doc(targetDeviceId);

      batch.set(blockedDocRef, {
        'deviceId': targetDeviceId,
        'isBlocked': true,
        'blockedAt': FieldValue.serverTimestamp(),
        'deviceName': deviceName,
        'deviceType': deviceType,
      });

      await batch.commit();
      debugPrint(
        '[SessionService] Blocked device $targetDeviceId on session $targetSessionId',
      );
      return true;
    } catch (e) {
      debugPrint('[SessionService] blockDevice error: $e');
      return false;
    }
  }

  Future<bool> unblockDevice({
    required String targetSessionId,
    required String targetDeviceId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final batch = _firestore.batch();
      final targetDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(targetSessionId);

      batch.update(targetDocRef, {
        'isBlocked': false,
        'isActive': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      final blockedDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('blocked_devices')
          .doc(targetDeviceId);

      batch.delete(blockedDocRef);

      await batch.commit();
      debugPrint('[SessionService] Unblocked device $targetDeviceId');
      return true;
    } catch (e) {
      debugPrint('[SessionService] unblockDevice error: $e');
      return false;
    }
  }

  Future<bool> isDeviceBlocked(String uid, String deviceId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked_devices')
          .doc(deviceId)
          .get();
      return doc.exists && (doc.data()?['isBlocked'] as bool? ?? false);
    } catch (_) {
      return false;
    }
  }

  Stream<bool> watchDeviceBlocked(String uid, String deviceId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('blocked_devices')
        .doc(deviceId)
        .snapshots()
        .map(
          (snap) =>
              snap.exists && (snap.data()?['isBlocked'] as bool? ?? false),
        );
  }

  // ── Revoke sessions ───────────────────────────────────────────────────────

  Future<bool> revokeSession(String targetSessionId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(targetSessionId);

      final doc = await docRef.get();
      if (doc.exists && (doc.data()?['isPrimary'] as bool? ?? false)) {
        // Cannot delete Primary Device
        return false;
      }

      await docRef.delete();
      debugPrint('[SessionService] Revoked session: $targetSessionId');
      return true;
    } catch (e) {
      debugPrint('[SessionService] revokeSession error: $e');
      return false;
    }
  }

  Future<void> revokeAllOtherSessions() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final myId = await currentSessionId();
    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        if (doc.id != myId) {
          final isPrimary = doc.data()['isPrimary'] as bool? ?? false;
          if (!isPrimary) {
            batch.delete(doc.reference);
          }
        }
      }
      await batch.commit();
      debugPrint('[SessionService] All other secondary sessions revoked.');
    } catch (e) {
      debugPrint('[SessionService] revokeAllOtherSessions error: $e');
    }
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<DocumentSnapshot<Map<String, dynamic>>?> watchCurrentSession(
    String uid,
    String sessionId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .snapshots();
  }

  Stream<List<SessionInfo>> watchAllSessions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('lastActiveAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SessionInfo.fromDoc).toList());
  }

  // ── Config policy hook ────────────────────────────────────────────────────

  Future<bool> enforceSingleSession() async {
    try {
      final doc = await _firestore
          .collection('system_config')
          .doc('auth_policy')
          .get();
      if (!doc.exists) return false;
      return doc.data()?['enforceSingleSession'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Session Lifecycle: 5-Day Expiry, Max 5 Devices & 15-Min Write Throttling ──

  /// Automatically checks if the current session has been inactive for > 5 days.
  /// If expired, deletes the session document from Firestore and signs out of Firebase Auth.
  Future<bool> checkSessionExpiryAndSignOutIfExpired() async {
    if (Firebase.apps.isEmpty && _customFirestore == null) return false;
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final sessionId = await currentSessionId();
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId);

      final doc = await docRef.get();
      if (!doc.exists) return false;

      final lastActive = (doc.data()?['lastActiveAt'] as Timestamp?)?.toDate();
      if (lastActive != null &&
          DateTime.now().difference(lastActive) >= sessionInactivityExpiry) {
        debugPrint(
          '[SessionService] Session $sessionId has expired (> 5 days inactivity). Deleting and signing out.',
        );
        await docRef.delete();
        await _auth.signOut();
        return true;
      }
    } catch (e) {
      debugPrint(
        '[SessionService] checkSessionExpiryAndSignOutIfExpired error: $e',
      );
    }
    return false;
  }

  /// Enforces a maximum of 5 concurrent active devices/sessions per account.
  /// If active sessions exceed 5, automatically deletes the oldest non-current session document.
  Future<void> enforceMaxActiveSessions(
    String uid,
    String currentSessionId,
  ) async {
    if (Firebase.apps.isEmpty && _customFirestore == null) return;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .get();

      final activeDocs = snap.docs.where((doc) {
        final data = doc.data();
        final isActive = data['isActive'] as bool? ?? true;
        final isBlocked = data['isBlocked'] as bool? ?? false;
        return isActive && !isBlocked;
      }).toList();

      if (activeDocs.length > maxConcurrentSessions) {
        final nonCurrent = activeDocs
            .where((d) => d.id != currentSessionId)
            .toList();

        nonCurrent.sort((a, b) {
          final tA =
              (a.data()['lastActiveAt'] as Timestamp?)?.toDate() ??
              (a.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final tB =
              (b.data()['lastActiveAt'] as Timestamp?)?.toDate() ??
              (b.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return tA.compareTo(tB);
        });

        int excessCount = activeDocs.length - maxConcurrentSessions;
        for (final doc in nonCurrent) {
          if (excessCount <= 0) break;
          final isPrimary = doc.data()['isPrimary'] as bool? ?? false;
          if (isPrimary && nonCurrent.length > excessCount) {
            continue;
          }
          debugPrint(
            '[SessionService] Active sessions exceed $maxConcurrentSessions. Pruning oldest session: ${doc.id}',
          );
          await doc.reference.delete();
          excessCount--;
        }
      }
    } catch (e) {
      debugPrint('[SessionService] enforceMaxActiveSessions error: $e');
    }
  }

  /// Throttles `lastActiveAt` updates in Firestore to at most once every 15 minutes
  /// (only when user activity occurs) so page refreshes or rapid clicks do not generate
  /// unnecessary Firestore writes.
  Future<bool> recordUserActivityThrottled() async {
    final now = DateTime.now();
    if (_lastActivityWriteTime != null &&
        now.difference(_lastActivityWriteTime!) < lastActiveThrottle) {
      return false; // Throttled: no write
    }

    if (Firebase.apps.isEmpty && _customFirestore == null) return false;
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final sessionId = await currentSessionId();
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId);

      final doc = await docRef.get();
      if (doc.exists && (doc.data()?['isActive'] as bool? ?? true)) {
        await docRef.update({'lastActiveAt': FieldValue.serverTimestamp()});
        _lastActivityWriteTime = DateTime.now();
        debugPrint(
          '[SessionService] Throttled lastActiveAt updated in Firestore for $sessionId',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[SessionService] recordUserActivityThrottled error: $e');
    }
    return false;
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

/// Stream of all sessions for the current user.
final allSessionsProvider = StreamProvider<List<SessionInfo>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  final service = ref.watch(sessionServiceProvider);
  return service.watchAllSessions(user.uid);
});

/// FutureProvider for the current local session ID.
final currentSessionIdProvider = FutureProvider<String>((ref) {
  final service = ref.watch(sessionServiceProvider);
  return service.currentSessionId();
});

/// FutureProvider for the current local device ID.
final currentDeviceIdProvider = FutureProvider<String>((ref) {
  final service = ref.watch(sessionServiceProvider);
  return service.currentDeviceId();
});
