import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shell/domain/notification_item.dart';

/// Firestore-backed notification model with nullable [createdAt] to handle
/// pending `FieldValue.serverTimestamp()` writes cleanly.
@immutable
class NotificationEntry {
  final String id;
  final String title;
  final String body;
  final String category;
  final String targetRoute;
  final String emoji;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.targetRoute,
    this.emoji = '🔔',
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawTs = data['createdAt'];
    DateTime? createdAt;
    if (rawTs is Timestamp) {
      createdAt = rawTs.toDate();
    } else if (rawTs is String) {
      createdAt = DateTime.tryParse(rawTs);
    }

    final category = data['category']?.toString().trim() ?? 'account';
    return NotificationEntry(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      category: category.isEmpty ? 'account' : category,
      targetRoute: data['targetRoute']?.toString() ?? 'profile_identity',
      emoji: (data['emoji']?.toString().trim().isNotEmpty ?? false)
          ? data['emoji'].toString()
          : _defaultEmojiForCategory(category),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  AppNotification toAppNotification() {
    return AppNotification(
      id: id,
      category: category,
      emoji: emoji,
      title: title,
      body: body,
      timestampLabel: NotificationService.formatTimestampLabel(createdAt),
      targetRoute: targetRoute,
      isRead: isRead,
    );
  }

  static String _defaultEmojiForCategory(String category) {
    switch (category) {
      case 'ai':
        return '✨';
      case 'shop':
        return '🛍️';
      case 'finance':
        return '🪙';
      case 'account':
      default:
        return '🔔';
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsStreamProvider = StreamProvider.autoDispose
    .family<List<AppNotification>, String>((ref, uid) {
      return ref.watch(notificationServiceProvider).watchNotifications(uid);
    });

/// Safely returns the current authenticated user's UID, or `null` if Firebase
/// is not initialized or no user is signed in.
String? currentAuthenticatedUid() {
  try {
    if (Firebase.apps.isEmpty) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return uid;
  } catch (_) {
    return null;
  }
}

class NotificationService {
  final FirebaseFirestore? _customFirestore;

  NotificationService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Sorts notifications descending by [createdAt], placing pending/null
  /// server timestamps at the top so newly created items appear immediately.
  static List<NotificationEntry> sortNotifications(
    List<NotificationEntry> items,
  ) {
    final sorted = List<NotificationEntry>.from(items);
    sorted.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;
      return tb.compareTo(ta);
    });
    return sorted;
  }

  /// Filters notifications by [category] (`'all'` returns every item).
  static List<AppNotification> filterByCategory(
    List<AppNotification> items,
    String category,
  ) {
    if (category == 'all') return items;
    return items.where((n) => n.category == category).toList();
  }

  /// Counts unread notifications.
  static int countUnread(List<AppNotification> items) {
    return items.where((n) => !n.isRead).length;
  }

  static String formatTimestampLabel(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Streams all notifications from `users/{uid}/notifications` without
  /// artificial limits or server-side `orderBy` so pending `serverTimestamp`
  /// documents are never dropped.
  Stream<List<AppNotification>> watchNotifications(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    final firestore = _firestore;
    if (firestore == null) return const Stream.empty();

    try {
      return firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .snapshots()
          .map((snap) {
            final entries = snap.docs
                .map(NotificationEntry.fromFirestore)
                .toList();
            return sortNotifications(
              entries,
            ).map((e) => e.toAppNotification()).toList();
          });
    } catch (e) {
      debugPrint('[NotificationService] watchNotifications error: $e');
      return const Stream.empty();
    }
  }

  /// Non-blocking, fire-and-forget safe writer for `users/{uid}/notifications`.
  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    String category = 'account',
    String targetRoute = 'profile_identity',
    String emoji = '🔔',
  }) async {
    if (uid.isEmpty) return;
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'category': category,
            'targetRoute': targetRoute,
            'emoji': emoji,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('[NotificationService] createNotification error: $e');
    }
  }

  /// Marks a single notification as read in Firestore.
  Future<void> markAsRead(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('[NotificationService] markAsRead error: $e');
    }
  }

  /// Marks all unread notifications for [uid] as read using a `WriteBatch`.
  Future<void> markAllAsRead(String uid) async {
    if (uid.isEmpty) return;
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final col = firestore
          .collection('users')
          .doc(uid)
          .collection('notifications');
      final unreadSnap = await col.where('isRead', isEqualTo: false).get();
      if (unreadSnap.docs.isEmpty) return;

      final batch = firestore.batch();
      for (final doc in unreadSnap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[NotificationService] markAllAsRead error: $e');
    }
  }
}
