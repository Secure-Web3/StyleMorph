import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_cloud_media_storage.dart';
import 'firestore_inline_media_storage.dart';
import 'media_storage_service.dart';

/// Active storage backend mode. Defaults to [StorageBackendMode.firestoreInline]
/// during Spark plan preview, switchable to [StorageBackendMode.firebaseStorage] for Blaze plan.
final storageBackendModeProvider = StateProvider<StorageBackendMode>((ref) {
  return StorageBackendMode.firestoreInline;
});

/// Resolves the appropriate [MediaStorageService] implementation based on [storageBackendModeProvider].
final mediaStorageServiceProvider = Provider<MediaStorageService>((ref) {
  final mode = ref.watch(storageBackendModeProvider);
  switch (mode) {
    case StorageBackendMode.firestoreInline:
      return const FirestoreInlineMediaStorage();
    case StorageBackendMode.firebaseStorage:
      return FirebaseCloudMediaStorage();
  }
});
