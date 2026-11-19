import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

class MediaService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage? _storage;

  MediaService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null as dynamic),
        _storage = storage ??
            (Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null);

  /// Uploads media file to Firebase Storage under `users/{uid}/media/{slotKey}_{timestamp}.{ext}`
  /// and persists download URL in Firestore document `users/{uid}` under `mediaSlots.{slotKey}`.
  Future<String> uploadMediaSlot({
    required String uid,
    required String slotKey,
    required XFile file,
    bool isVideo = false,
  }) async {
    if (Firebase.apps.isEmpty || _storage == null) {
      // Mock fallback when Firebase is not initialized
      final mockUrl =
          'https://firebasestorage.googleapis.com/v0/b/mock/o/users%2F$uid%2Fmedia%2F${file.name}';
      return mockUrl;
    }

    final ext = file.name.contains('.')
        ? file.name.split('.').last
        : (isVideo ? 'mp4' : 'webp');
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$slotKey.$ext';
    final ref = _storage.ref().child('users').child(uid).child('media').child(filename);

    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(
      contentType: isVideo ? 'video/mp4' : 'image/jpeg',
      customMetadata: {'uid': uid, 'slotKey': slotKey},
    );

    await ref.putData(bytes, metadata);
    final downloadUrl = await ref.getDownloadURL();

    // Persist in Firestore
    final userDoc = _firestore.collection('users').doc(uid);
    await userDoc.set({
      'mediaSlots': {
        slotKey: downloadUrl,
      },
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

    return downloadUrl;
  }

  /// Deletes reference media from Firebase Storage and Firestore.
  Future<void> deleteMediaSlot({
    required String uid,
    required String slotKey,
    String? mediaUrl,
  }) async {
    if (Firebase.apps.isNotEmpty) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.update({
        'mediaSlots.$slotKey': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await userDoc.collection('media').doc(slotKey).delete();
      } catch (_) {}

      if (_storage != null && mediaUrl != null && mediaUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(mediaUrl).delete();
        } catch (_) {}
      }
    }
  }

  /// Persists persona modeling mode in Firestore.
  Future<void> savePersonaMode({
    required String uid,
    required String mode,
  }) async {
    if (Firebase.apps.isNotEmpty) {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.set({
        'personaMode': mode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
