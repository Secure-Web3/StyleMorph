import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage/firebase_cloud_media_storage.dart';
import '../../../core/services/storage/firestore_inline_media_storage.dart';
import '../../../core/services/storage/media_storage_provider.dart';
import '../../../core/services/storage/media_storage_service.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  final mediaStorage = ref.watch(mediaStorageServiceProvider);
  return MediaService(mediaStorage: mediaStorage);
});

class MediaService {
  final FirebaseFirestore? _firestore;
  final MediaStorageService _mediaStorage;

  MediaService({
    FirebaseFirestore? firestore,
    MediaStorageService? mediaStorage,
    FirebaseStorage? storage,
  }) : _firestore =
           firestore ??
           (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null),
       _mediaStorage =
           mediaStorage ??
           (storage != null
               ? FirebaseCloudMediaStorage(storage: storage)
               : const FirestoreInlineMediaStorage());

  /// Uploads media file under `users/{uid}/media/{slotKey}_{timestamp}.{ext}`
  /// and persists URL or Data URL in Firestore document `users/{uid}` under `mediaSlots.{slotKey}`.
  Future<String> uploadMediaSlot({
    required String uid,
    required String slotKey,
    required XFile file,
    bool isVideo = false,
  }) async {
    final ext = file.name.contains('.')
        ? file.name.split('.').last
        : (isVideo ? 'mp4' : 'jpg');
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$slotKey.$ext';
    final path = 'users/$uid/media/$filename';

    final bytes = await file.readAsBytes();
    final mimeType = isVideo ? 'video/mp4' : 'image/jpeg';

    final downloadUrl = await _mediaStorage.uploadImage(
      path: path,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (downloadUrl.trimLeft().startsWith('blob:')) {
      throw StateError(
        'MediaService: Refusing to persist ephemeral blob: URL to Firestore.',
      );
    }

    // Persist in Firestore
    if (Firebase.apps.isNotEmpty && _firestore != null) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.set({
        'mediaSlots': {slotKey: downloadUrl},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also track in subcollection `users/{uid}/media/{slotKey}` for audit & versioning
      try {
        await userDoc.collection('media').doc(slotKey).set({
          'slotKey': slotKey,
          'url': downloadUrl,
          'isVideo': isVideo,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    return downloadUrl;
  }

  /// Deletes reference media from storage and Firestore.
  Future<void> deleteMediaSlot({
    required String uid,
    required String slotKey,
    String? mediaUrl,
  }) async {
    if (Firebase.apps.isNotEmpty && _firestore != null) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.update({
        'mediaSlots.$slotKey': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await userDoc.collection('media').doc(slotKey).delete();
      } catch (_) {}
    }

    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      try {
        await _mediaStorage.deleteMedia(mediaUrl);
      } catch (_) {}
    }
  }

  /// Persists persona modeling mode in Firestore.
  Future<void> savePersonaMode({
    required String uid,
    required String mode,
  }) async {
    if (Firebase.apps.isNotEmpty && _firestore != null) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.set({
        'personaMode': mode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
