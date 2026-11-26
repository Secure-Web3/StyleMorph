import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Cloud Messaging (FCM) initialization, `app_updates` topic
/// subscription, and push notification tap routing on Native Mobile (`!kIsWeb`).
///
/// Cleanly no-ops on Web (`kIsWeb`) and never throws during app startup.
class PushNotificationService {
  PushNotificationService._();

  static const String kAppUpdatesTopic = 'app_updates';

  static bool _initialized = false;
  static bool _pendingAppUpdateTap = false;
  static VoidCallback? _onAppUpdateTapCallback;
  static StreamSubscription<RemoteMessage>? _openedAppSub;

  /// Returns `true` when an FCM payload targets the in-app updater flow.
  static bool isAppUpdateMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim().toLowerCase();
    return type == 'app_update';
  }

  /// Registers a callback invoked when the user taps an `app_update` push
  /// notification (including cold-start launches via `getInitialMessage`).
  static void setOnAppUpdateTap(VoidCallback? callback) {
    _onAppUpdateTapCallback = callback;
    if (callback != null && _pendingAppUpdateTap) {
      _pendingAppUpdateTap = false;
      callback();
    }
  }

  /// Initializes FCM on Native Mobile, requests notification permissions,
  /// subscribes to [kAppUpdatesTopic], and wires tap listeners.
  static Future<void> initialize({VoidCallback? onAppUpdateTap}) async {
    if (onAppUpdateTap != null) {
      _onAppUpdateTapCallback = onAppUpdateTap;
    }
    if (kIsWeb || _initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.subscribeToTopic(kAppUpdatesTopic);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && isAppUpdateMessage(initialMessage.data)) {
        if (_onAppUpdateTapCallback != null) {
          _onAppUpdateTapCallback!.call();
        } else {
          _pendingAppUpdateTap = true;
        }
      }

      _openedAppSub ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (isAppUpdateMessage(message.data)) {
          if (_onAppUpdateTapCallback != null) {
            _onAppUpdateTapCallback!.call();
          } else {
            _pendingAppUpdateTap = true;
          }
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[PushNotificationService] Init notice: $e');
    }
  }

  /// Resets internal state for unit tests.
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _pendingAppUpdateTap = false;
    _onAppUpdateTapCallback = null;
    unawaited(_openedAppSub?.cancel());
    _openedAppSub = null;
  }
}
