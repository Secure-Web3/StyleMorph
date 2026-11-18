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
  final String deviceName;
  final String deviceModel;
  final String platform;
  final String osVersion;
  final String userAgent;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isActive;

  const SessionInfo({
    required this.sessionId,
    required this.deviceName,
    required this.deviceModel,
    required this.platform,
    required this.osVersion,
    required this.userAgent,
    required this.createdAt,
    required this.lastActiveAt,
    required this.isActive,
  });

  factory SessionInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SessionInfo(
      sessionId: d['sessionId'] as String? ?? doc.id,
      deviceName: d['deviceName'] as String? ?? 'Unknown Device',
      deviceModel: d['deviceModel'] as String? ?? '',
      platform: d['platform'] as String? ?? 'Unknown',
      osVersion: d['osVersion'] as String? ?? '',
      userAgent: d['userAgent'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt:
          (d['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        'platform': platform,
        'osVersion': osVersion,
        'userAgent': userAgent,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastActiveAt': Timestamp.fromDate(lastActiveAt),
        'isActive': isActive,
      };
}

// ── Service ────────────────────────────────────────────────────────────────

class SessionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SessionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ── Current session ID ──────────────────────────────────────────────────

  String? _cachedSessionId;

  Future<String> currentSessionId() async {
    if (_cachedSessionId != null) return _cachedSessionId!;
    try {
      final stored = await SessionLocalStorage.getSessionId();
      if (stored != null && stored.isNotEmpty) {
        _cachedSessionId = stored;
        return stored;
      }
      final newId = _generateSessionId();
      await SessionLocalStorage.setSessionId(newId);
      _cachedSessionId = newId;
      return newId;
    } catch (_) {
      _cachedSessionId ??= _generateSessionId();
      return _cachedSessionId!;
    }
  }

  String _generateSessionId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = (DateTime.now().microsecond ^ DateTime.now().hashCode)
        .abs()
        .toRadixString(36);
    return 'sess_${ts}_$rand';
  }

  // ── Device metadata ─────────────────────────────────────────────────────

  Map<String, String> _buildDeviceMeta() {
    if (kIsWeb) {
      return {
        'platform': 'Web',
        'deviceName': 'Web Browser',
        'deviceModel': 'Browser',
        'osVersion': 'Web',
        'userAgent': 'Web App',
      };
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return {
          'platform': 'Android',
          'deviceName': 'Android Device',
          'deviceModel': 'Android',
          'osVersion': 'Android',
          'userAgent': 'StyleMorph/Android',
        };
      case TargetPlatform.iOS:
        return {
          'platform': 'iOS',
          'deviceName': 'iPhone / iPad',
          'deviceModel': 'iOS Device',
          'osVersion': 'iOS',
          'userAgent': 'StyleMorph/iOS',
        };
      case TargetPlatform.windows:
        return {
          'platform': 'Desktop',
          'deviceName': 'Windows PC',
          'deviceModel': 'Windows',
          'osVersion': 'Windows',
          'userAgent': 'StyleMorph/Windows',
        };
      case TargetPlatform.macOS:
        return {
          'platform': 'Desktop',
          'deviceName': 'Mac',
          'deviceModel': 'macOS',
          'osVersion': 'macOS',
          'userAgent': 'StyleMorph/macOS',
        };
      case TargetPlatform.linux:
        return {
          'platform': 'Desktop',
          'deviceName': 'Linux PC',
          'deviceModel': 'Linux',
          'osVersion': 'Linux',
          'userAgent': 'StyleMorph/Linux',
        };
      default:
        return {
          'platform': 'Unknown',
          'deviceName': 'Unknown Device',
          'deviceModel': '',
          'osVersion': '',
          'userAgent': 'StyleMorph',
        };
    }
  }

  // ── Upsert session in Firestore ─────────────────────────────────────────

  Future<void> upsertSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sessionId = await currentSessionId();
    final meta = _buildDeviceMeta();
    final now = Timestamp.now();

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId);

      final existing = await docRef.get();
      if (existing.exists) {
        await docRef.update({'lastActiveAt': now, 'isActive': true});
      } else {
        final session = SessionInfo(
          sessionId: sessionId,
          deviceName: meta['deviceName']!,
          deviceModel: meta['deviceModel']!,
          platform: meta['platform']!,
          osVersion: meta['osVersion']!,
          userAgent: meta['userAgent']!,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          isActive: true,
        );
        await docRef.set(session.toMap());
      }
      debugPrint('[SessionService] Session upserted: $sessionId');
    } catch (e) {
      debugPrint('[SessionService] upsertSession error: $e');
    }
  }

  // ── Revoke a specific session ───────────────────────────────────────────

  Future<void> revokeSession(String targetSessionId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(targetSessionId)
          .delete();
      debugPrint('[SessionService] Revoked session: $targetSessionId');
    } catch (e) {
      debugPrint('[SessionService] revokeSession error: $e');
    }
  }

  // ── Revoke all OTHER sessions ───────────────────────────────────────────

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
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
      debugPrint('[SessionService] All other sessions revoked.');
    } catch (e) {
      debugPrint('[SessionService] revokeAllOtherSessions error: $e');
    }
  }

  // ── Real-time stream of THIS device's session (for remote sign-out) ─────

  Stream<DocumentSnapshot<Map<String, dynamic>>?> watchCurrentSession(
      String uid, String sessionId) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .snapshots();
  }

  // ── Real-time stream of ALL user sessions ───────────────────────────────

  Stream<List<SessionInfo>> watchAllSessions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('lastActiveAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SessionInfo.fromDoc).toList());
  }

  // ── Read auth policy from Firestore (for future admin toggle) ───────────

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
