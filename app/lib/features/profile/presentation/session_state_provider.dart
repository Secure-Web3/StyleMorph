import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/session_service.dart';

export '../../../core/services/session_service.dart';

/// Provider for the total count of active and unblocked sessions.
final activeSessionsCountProvider = Provider<int>((ref) {
  final sessionsAsync = ref.watch(allSessionsProvider);
  return sessionsAsync.valueOrNull
          ?.where((s) => s.isActive && !s.isBlocked)
          .length ??
      0;
});

/// Provider for the current device's active SessionInfo if available.
final currentSessionProvider = Provider<SessionInfo?>((ref) {
  final currentIdAsync = ref.watch(currentSessionIdProvider);
  final sessionsAsync = ref.watch(allSessionsProvider);
  final currentId = currentIdAsync.valueOrNull;
  final sessions = sessionsAsync.valueOrNull;
  if (currentId == null || sessions == null) return null;
  for (final s in sessions) {
    if (s.sessionId == currentId) return s;
  }
  return null;
});

/// Provider for whether the current device is designated as primary.
final isCurrentDevicePrimaryProvider = Provider<bool>((ref) {
  final current = ref.watch(currentSessionProvider);
  return current?.isPrimary ?? false;
});
