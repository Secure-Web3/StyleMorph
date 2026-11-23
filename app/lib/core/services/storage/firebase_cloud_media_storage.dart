import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'media_storage_service.dart';

/// Media storage implementation that uploads assets to Firebase Cloud Storage.
/// Activated when switching to Blaze plan in production.
class FirebaseCloudMediaStorage implements MediaStorageService {
  final FirebaseStorage? _storage;

  FirebaseCloudMediaStorage({FirebaseStorage? storage})
    : _storage =
          storage ??
          (Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null);

  @override
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw StateError(
        'FirebaseCloudMediaStorage: FirebaseStorage is not initialized.',
      );
    }

    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final storageRef = storage.ref().child(cleanPath);

    final metadata = SettableMetadata(
      contentType: mimeType,
      customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
    );

    await storageRef.putData(bytes, metadata);
    return await storageRef.getDownloadURL();
  }

  @override
  Future<void> deleteMedia(String urlOrPath) async {
    final storage = _storage;
    if (storage == null || urlOrPath.isEmpty) return;

    // Skip Data URLs as they do not exist in Cloud Storage
    if (urlOrPath.startsWith('data:')) return;

    try {
      if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
        await storage.refFromURL(urlOrPath).delete();
      } else {
        final cleanPath = urlOrPath.startsWith('/')
            ? urlOrPath.substring(1)
            : urlOrPath;
        await storage.ref().child(cleanPath).delete();
      }
    } catch (_) {
      // Best-effort cleanup: silence missing file or permission errors during delete
    }
  }
}
