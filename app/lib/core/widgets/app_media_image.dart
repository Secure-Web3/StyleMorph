import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Universal image rendering widget that seamlessly displays both
/// Base64 Data URLs (`data:image/...;base64,...`) and standard network URLs (`http://`, `https://`).
///
/// Features bounded LRU memory caching of decoded bytes, gapless playback
/// across rebuilds, and automatic lifecycle recovery upon app/browser tab resume.
class AppMediaImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final AlignmentGeometry alignment;
  final bool gaplessPlayback;

  const AppMediaImage(
    this.imageUrl, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.alignment = Alignment.center,
    this.gaplessPlayback = true,
  });

  /// In-memory bounded LRU cache for decoded Base64 bytes keyed by content hash.
  static final LinkedHashMap<int, Uint8List> _decodedBytesCache =
      LinkedHashMap<int, Uint8List>();
  static const int _maxCacheEntries = 128;

  /// Returns true if the string represents an inline Data URL.
  static bool isDataUrl(String? url) {
    if (url == null) return false;
    return url.trimLeft().startsWith('data:');
  }

  /// Extracts and decodes byte data from a Base64 Data URL using LRU caching.
  static Uint8List? tryDecodeDataUrl(String dataUrl) {
    final hash = dataUrl.hashCode;
    final cached = _decodedBytesCache.remove(hash);
    if (cached != null) {
      _decodedBytesCache[hash] = cached;
      return cached;
    }

    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) return null;

      final base64Payload = dataUrl.substring(commaIndex + 1).trim();
      final bytes = base64Decode(base64Payload);

      if (_decodedBytesCache.length >= _maxCacheEntries) {
        _decodedBytesCache.remove(_decodedBytesCache.keys.first);
      }
      _decodedBytesCache[hash] = bytes;

      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Pre-warms an image URL (Data URL or network URL) into the cache and Flutter framework.
  static Future<void> precache(BuildContext context, String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return;

    try {
      if (isDataUrl(clean)) {
        final bytes = tryDecodeDataUrl(clean);
        if (bytes != null && context.mounted) {
          await precacheImage(MemoryImage(bytes), context);
        }
      } else if (context.mounted) {
        await precacheImage(NetworkImage(clean), context);
      }
    } catch (_) {
      // Graceful ignore for background prefetch errors
    }
  }

  /// Clears the in-memory cache (primarily used in testing).
  @visibleForTesting
  static void clearCache() {
    _decodedBytesCache.clear();
  }

  @override
  State<AppMediaImage> createState() => _AppMediaImageState();
}

class _AppMediaImageState extends State<AppMediaImage>
    with WidgetsBindingObserver {
  int _renderCycle = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from background or browser tab switch, trigger repaint
    // to recover any decoded image surfaces evicted by browser/OS memory pressure.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        _renderCycle++;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl?.trim();

    if (url == null || url.isEmpty) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          context,
          ArgumentError('Empty or null image URL'),
          StackTrace.current,
        );
      }
      return SizedBox(width: widget.width, height: widget.height);
    }

    if (AppMediaImage.isDataUrl(url)) {
      final bytes = AppMediaImage.tryDecodeDataUrl(url);
      if (bytes == null) {
        if (widget.errorBuilder != null) {
          return widget.errorBuilder!(
            context,
            FormatException('Invalid Data URL payload'),
            StackTrace.current,
          );
        }
        return SizedBox(width: widget.width, height: widget.height);
      }

      return Image.memory(
        bytes,
        key: ValueKey('${url.hashCode}_$_renderCycle'),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.errorBuilder,
      );
    }

    return Image.network(
      url,
      key: ValueKey('${url.hashCode}_$_renderCycle'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      gaplessPlayback: widget.gaplessPlayback,
      loadingBuilder: widget.loadingBuilder,
      errorBuilder: widget.errorBuilder,
    );
  }
}
