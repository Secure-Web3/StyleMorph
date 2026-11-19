import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing permanent local storage persistence of the
/// `has_seen_welcome` first-run flag across app sessions and user sign-outs.
class WelcomePersistenceService {
  static const String keyHasSeenWelcome = 'has_seen_welcome';

  /// Reads whether the user has previously seen or passed the welcome screen.
  Future<bool> hasSeenWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyHasSeenWelcome) ?? false;
    } catch (e) {
      debugPrint('[WelcomePersistenceService] hasSeenWelcome error: $e');
      return false;
    }
  }

  /// Permanently persists `has_seen_welcome = true` in local storage.
  Future<void> setHasSeenWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyHasSeenWelcome, true);
    } catch (e) {
      debugPrint('[WelcomePersistenceService] setHasSeenWelcome error: $e');
    }
  }
}

final welcomePersistenceServiceProvider =
    Provider<WelcomePersistenceService>((ref) {
  return WelcomePersistenceService();
});

/// StateNotifier that manages the in-memory and persistent state of `hasSeenWelcome`.
class HasSeenWelcomeNotifier extends StateNotifier<AsyncValue<bool>> {
  final WelcomePersistenceService _service;

  HasSeenWelcomeNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final hasSeen = await _service.hasSeenWelcome();
      state = AsyncValue.data(hasSeen);
    } catch (e, st) {
      debugPrint('[HasSeenWelcomeNotifier] load error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Marks the welcome screen as seen permanently and updates all reactive listeners.
  Future<void> markSeen() async {
    state = const AsyncValue.data(true);
    await _service.setHasSeenWelcome();
  }
}

final hasSeenWelcomeProvider =
    StateNotifierProvider<HasSeenWelcomeNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(welcomePersistenceServiceProvider);
  return HasSeenWelcomeNotifier(service);
});
