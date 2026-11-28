import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection_probe_stub.dart'
    if (dart.library.io) 'connection_probe_io.dart'
    as probe;

@immutable
class ConnectionHealthState {
  final bool isChecking;
  final bool isServerUnreachable;
  final bool isDismissed;
  final DateTime? lastCheckedAt;

  const ConnectionHealthState({
    this.isChecking = false,
    this.isServerUnreachable = false,
    this.isDismissed = false,
    this.lastCheckedAt,
  });

  bool get shouldShowBanner => isServerUnreachable && !isDismissed;

  ConnectionHealthState copyWith({
    bool? isChecking,
    bool? isServerUnreachable,
    bool? isDismissed,
    DateTime? lastCheckedAt,
  }) {
    return ConnectionHealthState(
      isChecking: isChecking ?? this.isChecking,
      isServerUnreachable: isServerUnreachable ?? this.isServerUnreachable,
      isDismissed: isDismissed ?? this.isDismissed,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }
}

/// Lightweight Riverpod notifier monitoring reachability of Firebase and
/// GitHub endpoints (4-second timeout) to surface generic connectivity alerts.
class ConnectionHealthNotifier extends StateNotifier<ConnectionHealthState> {
  final Future<bool> Function() _probeFn;

  ConnectionHealthNotifier({Future<bool> Function()? probeFn})
    : _probeFn = probeFn ?? _defaultProbe,
      super(const ConnectionHealthState());

  static Future<bool> _defaultProbe() {
    if (kIsWeb) return Future.value(true);
    return probe.probeServerReachabilityImpl(
      timeout: const Duration(seconds: 4),
    );
  }

  /// Runs a non-blocking reachability check and updates [state].
  /// Returns `true` if servers are reachable, `false` otherwise.
  Future<bool> checkReachability({bool resetDismissed = false}) async {
    if (kIsWeb) return true;
    state = state.copyWith(
      isChecking: true,
      isDismissed: resetDismissed ? false : state.isDismissed,
    );
    var reachable = true;
    try {
      reachable = await _probeFn().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      reachable = false;
    }
    if (!mounted) return reachable;
    state = state.copyWith(
      isChecking: false,
      isServerUnreachable: !reachable,
      isDismissed: reachable ? false : state.isDismissed,
      lastCheckedAt: DateTime.now(),
    );
    return reachable;
  }

  void dismissBanner() {
    state = state.copyWith(isDismissed: true);
  }
}

final connectionHealthProvider =
    StateNotifierProvider<ConnectionHealthNotifier, ConnectionHealthState>(
      (ref) => ConnectionHealthNotifier(),
    );
