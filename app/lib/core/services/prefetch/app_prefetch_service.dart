import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_state.dart';
import '../../widgets/app_media_image.dart';
import '../../../features/wardrobe/presentation/wardrobe_provider.dart';

/// Lightweight non-blocking background prefetch service triggered on auth entry.
///
/// Pre-warms the user's profile avatar, media album slots, and initial paginated (limit 20)
/// wardrobe items into memory to make tab switches instant with zero visible lag.
class AppPrefetchService {
  bool _hasPrefetched = false;
  final Set<String> _inFlightUrls = {};

  bool get hasPrefetched => _hasPrefetched;

  /// Triggers background prefetching if not already executed for this session.
  Future<void> prefetchOnAuth({
    required WidgetRef ref,
    required BuildContext context,
  }) async {
    if (_hasPrefetched) return;
    _hasPrefetched = true;

    // Run asynchronously without blocking the UI thread
    Future.microtask(() async {
      if (!context.mounted) return;
      await _prewarmProfileAndMedia(ref, context);
      if (!context.mounted) return;
      await _prewarmWardrobeInitial(ref, context);
    });
  }

  Future<void> _prewarmProfileAndMedia(
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final appState = ref.read(appStateProvider);

      // 1. Pre-warm Avatar
      final avatarUrl = appState.effectiveAvatarUrl;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        _prewarmUrl(context, avatarUrl);
      }

      // 2. Pre-warm Media Album Slots
      for (final url in appState.mediaSlots.values) {
        if (url.isNotEmpty) {
          _prewarmUrl(context, url);
        }
      }
    } catch (_) {
      // Graceful fallback for uninitialized or guest state
    }
  }

  Future<void> _prewarmWardrobeInitial(
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final wardrobeState = ref.read(wardrobeProvider);

      // Trigger initial page load (limit 20) if not already loaded or loading
      if (wardrobeState.items.isEmpty && !wardrobeState.isLoading) {
        await ref.read(wardrobeProvider.notifier).loadInitial();
      }

      // Pre-warm thumbnails of first items
      final items = ref.read(wardrobeProvider).items;
      for (final item in items.take(12)) {
        if (!context.mounted) return;
        if (item.thumbUrl.isNotEmpty) {
          _prewarmUrl(context, item.thumbUrl);
        }
      }
    } catch (_) {
      // Graceful fallback
    }
  }

  void _prewarmUrl(BuildContext context, String url) {
    final clean = url.trim();
    if (clean.isEmpty || _inFlightUrls.contains(clean)) return;
    _inFlightUrls.add(clean);

    if (context.mounted) {
      AppMediaImage.precache(context, clean);
    }
  }

  /// Reset prefetch flag (e.g., on sign out or testing).
  @visibleForTesting
  void reset() {
    _hasPrefetched = false;
    _inFlightUrls.clear();
  }
}

final appPrefetchServiceProvider = Provider<AppPrefetchService>((ref) {
  return AppPrefetchService();
});
