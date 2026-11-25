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

    final category = NotificationService.normalizeCategory(
      data['category']?.toString() ?? 'account',
    );
    return NotificationEntry(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      category: category,
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
    switch (NotificationService.normalizeCategory(category)) {
      case 'atelier':
        return '✨';
      case 'wardrobe':
        return '👗';
      case 'wellness':
        return '🌿';
      case 'stylist':
        return '🪄';
      case 'shop':
        return '🛍️';
      case 'wallet':
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

  /// Maps legacy and module category identifiers to canonical module keys
  /// (`account`, `wardrobe`, `wellness`, `stylist`, `atelier`, `shop`, `wallet`,
  /// or `all`).
  static String normalizeCategory(String raw) {
    final clean = raw.trim().toLowerCase();
    switch (clean) {
      case 'all':
        return 'all';
      case 'ai':
      case 'atelier':
        return 'atelier';
      case 'deals':
      case 'shop':
        return 'shop';
      case 'finance':
      case 'wallet':
        return 'wallet';
      case 'system':
      case 'account':
        return 'account';
      case 'wardrobe':
        return 'wardrobe';
      case 'wellness':
        return 'wellness';
      case 'stylist':
        return 'stylist';
      default:
        return 'account';
    }
  }

  /// Filters notifications by [category] (`'all'` returns every item),
  /// normalizing legacy category values for backward compatibility.
  static List<AppNotification> filterByCategory(
    List<AppNotification> items,
    String category,
  ) {
    final normalizedTarget = normalizeCategory(category);
    if (normalizedTarget == 'all') return items;
    return items
        .where((n) => normalizeCategory(n.category) == normalizedTarget)
        .toList();
  }

  /// Filters notifications by both [category] (`'all' | ...`) and read [status]
  /// (`'all' | 'unread' | 'read'`), preserving their original chronological order.
  static List<AppNotification> filterNotifications(
    List<AppNotification> items, {
    String category = 'all',
    String status = 'all',
  }) {
    final normalizedTarget = normalizeCategory(category);
    return items.where((n) {
      final matchesCategory =
          normalizedTarget == 'all' ||
          normalizeCategory(n.category) == normalizedTarget;
      if (!matchesCategory) return false;
      switch (status) {
        case 'unread':
          return !n.isRead;
        case 'read':
          return n.isRead;
        case 'all':
        default:
          return true;
      }
    }).toList();
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

  /// Typed event constants for notification & sensitive email routing.
  static const String eventGeneral = 'general';
  static const String eventReferralJoined = 'referral_joined';
  static const String eventAppUpdate = 'app_update';
  static const String eventKycStatus = 'kyc_status';
  static const String eventMediaReview = 'media_review';
  static const String eventWardrobeApproved = 'wardrobe_approved';
  static const String eventAtelierRenderReady = 'atelier_render_ready';
  static const String eventNewSession = 'new_session';
  static const String eventAgreementSigned = 'agreement_signed';

  /// Returns `true` only when email dispatch is explicitly requested and a
  /// valid non-empty recipient email is provided (cost-controlled policy).
  static bool shouldDispatchEmail({
    required bool sendEmail,
    required String? recipientEmail,
  }) {
    if (!sendEmail) return false;
    final cleanEmail = recipientEmail?.trim() ?? '';
    return cleanEmail.contains('@') && cleanEmail.length > 3;
  }

  /// Computes the Firestore TTL expiration timestamp:
  /// - **90 days** for sensitive/security/financial events (`sendEmail == true`,
  ///   `wallet`, `referral_joined`, `kyc`, `new_session`, `terms_signed`).
  /// - **30 days** for routine notifications.
  static DateTime computeExpiresAt({
    required String category,
    required String eventType,
    required bool sendEmail,
    DateTime? now,
  }) {
    final base = now ?? DateTime.now();
    final normalizedCat = normalizeCategory(category);
    final normalizedEvent = eventType.trim().toLowerCase();
    final isSensitive =
        sendEmail ||
        normalizedCat == 'wallet' ||
        normalizedEvent == eventReferralJoined ||
        normalizedEvent == eventKycStatus ||
        normalizedEvent == eventNewSession ||
        normalizedEvent == eventAgreementSigned ||
        normalizedEvent.contains('kyc') ||
        normalizedEvent.contains('terms_signed');
    return base.add(Duration(days: isSensitive ? 90 : 30));
  }

  /// Non-blocking, fire-and-forget safe writer for `users/{uid}/notifications`.
  /// Always attaches an `expiresAt` [Timestamp] for native Firestore TTL.
  /// When [sendEmail] is `true` and [recipientEmail] is valid, also enqueues
  /// a lightweight document in `mail_queue` for sensitive/critical events.
  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    String category = 'account',
    String targetRoute = 'profile_identity',
    String emoji = '🔔',
    bool sendEmail = false,
    String? recipientEmail,
    String eventType = eventGeneral,
    Map<String, dynamic>? extraData,
  }) async {
    if (uid.isEmpty) return;
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final canonicalCategory = normalizeCategory(category);
      final expiresAt = computeExpiresAt(
        category: canonicalCategory,
        eventType: eventType,
        sendEmail: sendEmail,
      );
      final payload = <String, dynamic>{
        'title': title,
        'body': body,
        'category': canonicalCategory,
        'targetRoute': targetRoute,
        'emoji': emoji,
        'isRead': false,
        'eventType': eventType,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };
      if (extraData != null && extraData.isNotEmpty) {
        payload.addAll(extraData);
      }

      await firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add(payload);

      if (shouldDispatchEmail(
        sendEmail: sendEmail,
        recipientEmail: recipientEmail,
      )) {
        await firestore.collection('mail_queue').add({
          'to': recipientEmail!.trim(),
          'subject': title,
          'body': body,
          'eventType': eventType,
          'uid': uid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[NotificationService] createNotification error: $e');
    }
  }

  /// Phase 4 AI/Compliance Hook: KYC verification approved or rejected.
  /// Always dispatches a sensitive email when [recipientEmail] is available.
  Future<void> notifyKycStatus({
    required String uid,
    required bool approved,
    String? reason,
    String? recipientEmail,
  }) {
    final body = approved
        ? 'Your identity verification (KYC) has been approved.'
        : 'Your KYC submission requires attention${reason != null && reason.isNotEmpty ? ': $reason' : '.'}';
    return createNotification(
      uid: uid,
      title: approved ? 'KYC Verified' : 'KYC Review Update',
      body: body,
      category: 'account',
      targetRoute: 'profile_identity',
      emoji: approved ? '✅' : '⚠️',
      sendEmail: true,
      recipientEmail: recipientEmail,
      eventType: eventKycStatus,
    );
  }

  /// Phase 4 AI Hook: Profile/Identity media review status.
  Future<void> notifyMediaReviewStatus({
    required String uid,
    required String mediaLabel,
    required bool approved,
    String? reason,
  }) {
    final body = approved
        ? 'Your $mediaLabel photo passed quality review.'
        : 'Your $mediaLabel photo needs a retake${reason != null && reason.isNotEmpty ? ': $reason' : '.'}';
    return createNotification(
      uid: uid,
      title: approved ? 'Media Approved' : 'Media Review Update',
      body: body,
      category: 'ai',
      targetRoute: 'profile_identity',
      emoji: approved ? '📸' : '🖼️',
      eventType: eventMediaReview,
    );
  }

  /// Phase 4 AI Hook: Wardrobe item tagging & approval completed.
  Future<void> notifyWardrobeItemApproved({
    required String uid,
    required String itemName,
  }) {
    return createNotification(
      uid: uid,
      title: 'Wardrobe Item Ready',
      body: '$itemName has been tagged and added to your digital closet.',
      category: 'wardrobe',
      targetRoute: 'wardrobe',
      emoji: '👗',
      eventType: eventWardrobeApproved,
    );
  }

  /// Phase 4 AI Hook: Virtual Atelier render completed.
  Future<void> notifyAtelierRenderReady({
    required String uid,
    required String creationTitle,
  }) {
    return createNotification(
      uid: uid,
      title: 'Atelier Render Ready',
      body: 'Your look "$creationTitle" is ready to view.',
      category: 'atelier',
      targetRoute: 'atelier_creations',
      emoji: '✨',
      eventType: eventAtelierRenderReady,
    );
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

  /// Deletes a single notification document from `users/{uid}/notifications`.
  Future<void> deleteNotification(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('[NotificationService] deleteNotification error: $e');
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
