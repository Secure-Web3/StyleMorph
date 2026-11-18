import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_storage.dart';

// ── Model ──────────────────────────────────────────────────────────────────

@immutable
class SessionInfo {
  final String sessionId;
  final String deviceId;
  final String deviceType; // 'mobile_web' | 'desktop_web' | 'mobile_app' | 'desktop_app'
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
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SessionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
      } else if (RegExp(r'iPhone|iPad|iPod', caseSensitive: false).hasMatch(ua)) {
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

      if (isMobile) {
        return {
          'deviceType': 'mobile_web',
          'deviceName': 'Mobile Web • $browser ($os)',
          'deviceModel': '$browser on $os',
          'platform': 'Web',
          'osVersion': os,
          'userAgent': ua.isNotEmpty ? ua : 'Mobile Web Browser',
        };
      } else {
        return {
          'deviceType': 'desktop_web',
          'deviceName': 'Desktop Web • $browser ($os)',
          'deviceModel': '$browser on $os',
          'platform': 'Web',
          'osVersion': os,
          'userAgent': ua.isNotEmpty ? ua : 'Desktop Web Browser',
        };
      }
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

  // ── Upsert session in Firestore (with Master/Primary assignment) ──────────

  Future<void> upsertSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sessionId = await currentSessionId();
    final deviceId = await currentDeviceId();
    final meta = _buildDeviceMeta();
    final now = Timestamp.now();

    try {
      // Check if device is blocked
      final blockedSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('blocked_devices')
          .doc(deviceId)
          .get();

      final isDeviceBlocked = blockedSnap.exists &&
          (blockedSnap.data()?['isBlocked'] as bool? ?? false);

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId);

      final existing = await docRef.get();
      if (existing.exists) {
        await docRef.update({
          'lastActiveAt': now,
          'isActive': !isDeviceBlocked,
          'isBlocked': isDeviceBlocked,
          'deviceId': deviceId,
          'deviceType': meta['deviceType'],
          'deviceName': meta['deviceName'],
          'deviceModel': meta['deviceModel'],
          'platform': meta['platform'],
          'osVersion': meta['osVersion'],
          'userAgent': meta['userAgent'],
        });
      } else {
        // Check if ANY existing session has isPrimary == true
        final primaryQuery = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .where('isPrimary', isEqualTo: true)
            .limit(1)
            .get();

        final hasPrimary = primaryQuery.docs.isNotEmpty;
        final shouldBePrimary = !hasPrimary; // First session becomes Primary Master!

        final session = SessionInfo(
          sessionId: sessionId,
          deviceId: deviceId,
          deviceType: meta['deviceType']!,
          deviceName: meta['deviceName']!,
          deviceModel: meta['deviceModel']!,
          platform: meta['platform']!,
          osVersion: meta['osVersion']!,
          userAgent: meta['userAgent']!,
          isPrimary: shouldBePrimary,
          isBlocked: isDeviceBlocked,
          isActive: !isDeviceBlocked,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
        await docRef.set(session.toMap());
      }
      debugPrint('[SessionService] Session upserted: $sessionId (dev: $deviceId)');
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
      batch.update(targetDocRef, {
        'isBlocked': true,
        'isActive': false,
      });

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
      debugPrint('[SessionService] Blocked device $targetDeviceId on session $targetSessionId');
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
        .map((snap) =>
            snap.exists && (snap.data()?['isBlocked'] as bool? ?? false));
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
      String uid, String sessionId) {
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
