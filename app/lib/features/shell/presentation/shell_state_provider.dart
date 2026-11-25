import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_state.dart';

export '../domain/app_tab.dart';
export '../domain/notification_item.dart';

@immutable
class ShellState {
  final AppTab currentTab;
  final List<AppNotification> notifications;

  const ShellState({
    this.currentTab = AppTab.profile,
    this.notifications = const [],
  });

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  ShellState copyWith({
    AppTab? currentTab,
    List<AppNotification>? notifications,
  }) {
    return ShellState(
      currentTab: currentTab ?? this.currentTab,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellState &&
          runtimeType == other.runtimeType &&
          currentTab == other.currentTab &&
          listEquals(notifications, other.notifications);

  @override
  int get hashCode => Object.hash(currentTab, notifications);
}

class ShellStateNotifier extends StateNotifier<ShellState> {
  final Ref? _ref;

  ShellStateNotifier([this._ref, ShellState? initial])
    : super(initial ?? const ShellState()) {
    if (_ref != null) {
      final appState = _ref.read(appStateProvider);
      state = state.copyWith(
        currentTab: appState.currentTab,
        notifications: appState.notifications,
      );

      _ref.listen<AppState>(appStateProvider, (previous, next) {
        if (state.currentTab != next.currentTab ||
            !listEquals(state.notifications, next.notifications)) {
          state = state.copyWith(
            currentTab: next.currentTab,
            notifications: next.notifications,
          );
        }
      });
    }
  }

  void switchTab(AppTab tab) {
    if (state.currentTab == tab) return;
    state = state.copyWith(currentTab: tab);
    if (_ref != null) {
      final appNotifier = _ref.read(appStateProvider.notifier);
      if (_ref.read(appStateProvider).currentTab != tab) {
        appNotifier.switchTab(tab);
      }
    }
  }

  void markNotificationRead(String id) {
    final updated = state.notifications.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);
    if (_ref != null) {
      _ref.read(appStateProvider.notifier).markNotificationRead(id);
    }
  }

  void markAllNotificationsRead() {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);
    if (_ref != null) {
      _ref.read(appStateProvider.notifier).markAllNotificationsRead();
    }
  }

  void deleteNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updated);
  }

  void setNotifications(List<AppNotification> notifications) {
    state = state.copyWith(notifications: notifications);
  }
}

final shellStateProvider =
    StateNotifierProvider<ShellStateNotifier, ShellState>((ref) {
      return ShellStateNotifier(ref);
    });
