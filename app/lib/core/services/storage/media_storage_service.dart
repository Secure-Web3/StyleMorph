import 'dart:typed_data';

/// Supported storage backend modes for media persistence.
enum StorageBackendMode {
  /// Stores compressed images as inline Base64 Data URLs inside Firestore documents.
  /// Designed for Firebase Spark (Free) plan where Cloud Storage is unavailable.
  firestoreInline,

  /// Stores media files in Firebase Cloud Storage buckets (requires Blaze plan).
  firebaseStorage,
}

/// Thrown when an inline media payload exceeds the safe byte limit for Firestore storage.
class MediaPayloadTooLargeException implements Exception {
  final int byteCount;
  final int maxAllowedBytes;

  const MediaPayloadTooLargeException({
    required this.byteCount,
    required this.maxAllowedBytes,
  });

  @override
  String toString() =>
      'MediaPayloadTooLargeException: Payload size (${byteCount ~/ 1024} KB) '
      'exceeds maximum allowed threshold for inline storage (${maxAllowedBytes ~/ 1024} KB).';
}

/// Abstract contract for media persistence and deletion.
abstract class MediaStorageService {
  /// Uploads media bytes and returns either a download URL or a Base64 Data URL.
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  });

  /// Deletes or clears the media at [urlOrPath].
  Future<void> deleteMedia(String urlOrPath);
}
