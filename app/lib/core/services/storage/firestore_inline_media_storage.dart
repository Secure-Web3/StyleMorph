import 'dart:convert';
import 'dart:typed_data';

import 'media_storage_service.dart';

/// Media storage implementation that encodes image bytes into compact Base64 Data URLs.
/// Used during the Spark plan preview when Firebase Storage is not provisioned.
class FirestoreInlineMediaStorage implements MediaStorageService {
  /// Default safe maximum byte size for inline storage (200 KB).
  /// Firestore document limit is 1 MB; 200 KB preserves ample headroom for user data.
  static const int defaultMaxByteSize = 200 * 1024;

  final int maxByteSize;

  const FirestoreInlineMediaStorage({this.maxByteSize = defaultMaxByteSize});

  @override
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (bytes.lengthInBytes > maxByteSize) {
      throw MediaPayloadTooLargeException(
        byteCount: bytes.lengthInBytes,
        maxAllowedBytes: maxByteSize,
      );
    }

    final encoded = base64Encode(bytes);
    return 'data:$mimeType;base64,$encoded';
  }

  @override
  Future<void> deleteMedia(String urlOrPath) async {
    // Inline Base64 Data URLs are stored directly in Firestore fields;
    // deletion is handled atomically by document field clearing.
    return;
  }
}
