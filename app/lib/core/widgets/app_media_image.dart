import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Universal image rendering widget that seamlessly displays both
/// Base64 Data URLs (`data:image/...;base64,...`) and standard network URLs (`http://`, `https://`).
class AppMediaImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final AlignmentGeometry alignment;

  const AppMediaImage(
    this.imageUrl, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.alignment = Alignment.center,
  });

  /// In-memory LRU-like cache for decoded Base64 bytes to prevent re-decoding on rebuilds.
  static final Map<String, Uint8List> _decodedBytesCache = {};
  static const int _maxCacheEntries = 64;

  /// Returns true if the string represents an inline Data URL.
  static bool isDataUrl(String? url) {
    if (url == null) return false;
    return url.trimLeft().startsWith('data:');
  }

  /// Extracts and decodes byte data from a Base64 Data URL.
  static Uint8List? tryDecodeDataUrl(String dataUrl) {
    try {
      final cached = _decodedBytesCache[dataUrl];
      if (cached != null) return cached;

      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) return null;

      final base64Payload = dataUrl.substring(commaIndex + 1).trim();
      final bytes = base64Decode(base64Payload);

      if (_decodedBytesCache.length >= _maxCacheEntries) {
        _decodedBytesCache.remove(_decodedBytesCache.keys.first);
      }
      _decodedBytesCache[dataUrl] = bytes;

      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Clears the in-memory cache (primarily used in testing).
  @visibleForTesting
  static void clearCache() {
    _decodedBytesCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      if (errorBuilder != null) {
        return errorBuilder!(
          context,
          ArgumentError('Empty or null image URL'),
          StackTrace.current,
        );
      }
      return SizedBox(width: width, height: height);
    }

    if (isDataUrl(url)) {
      final bytes = tryDecodeDataUrl(url);
      if (bytes == null) {
        if (errorBuilder != null) {
          return errorBuilder!(
            context,
            FormatException('Invalid Data URL payload'),
            StackTrace.current,
          );
        }
        return SizedBox(width: width, height: height);
      }

      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: errorBuilder,
      );
    }

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
