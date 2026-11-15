import 'package:flutter/foundation.dart';

/// Central configuration for connecting Auth, Firestore, Storage, Functions,
/// and the local AI Gateway to Firebase Local Emulator Suite in debug builds.
class EmulatorConfig {
  EmulatorConfig._();

  /// Opt-out override via `--dart-define=USE_FIREBASE_EMULATOR=false`.
  static const bool _useEmulatorFlag = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: true,
  );

  /// Emulators are strictly limited to debug builds (`kDebugMode`).
  static bool get isEnabled => kDebugMode && _useEmulatorFlag;

  // Ports synchronized with root `firebase.json`
  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int storagePort = 9199;
  static const int functionsPort = 5001;
  static const int aiGatewayPort = int.fromEnvironment(
    'AI_GATEWAY_PORT',
    defaultValue: 8081,
  );

  /// Resolves `10.0.2.2` for Android emulators and `localhost` elsewhere.
  static String get host {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get authOrigin => 'http://$host:$authPort';
  static String get firestoreHost => '$host:$firestorePort';
  static String get storageHost => '$host:$storagePort';
  static String get functionsOrigin => 'http://$host:$functionsPort';
  static String get aiGatewayUrl => 'http://$host:$aiGatewayPort';

  static bool _configured = false;
  static bool get isConfigured => _configured;

  /// Connects Firebase client SDK instances to local emulators when `kDebugMode`
  /// is active. Pass SDK bindings (e.g., `FirebaseAuth.instance.useAuthEmulator`,
  /// `FirebaseFirestore.instance.useFirestoreEmulator`,
  /// `FirebaseStorage.instance.useStorageEmulator`) once Firebase SDKs are wired.
  static Future<void> connectIfEnabled({
    Future<void> Function(String host, int port)? connectAuth,
    void Function(String host, int port)? connectFirestore,
    Future<void> Function(String host, int port)? connectStorage,
    void Function(String origin)? connectFunctions,
  }) async {
    if (!isEnabled || _configured) {
      return;
    }

    final resolvedHost = host;

    if (connectAuth != null) {
      await connectAuth(resolvedHost, authPort);
    }
    if (connectFirestore != null) {
      connectFirestore(resolvedHost, firestorePort);
    }
    if (connectStorage != null) {
      await connectStorage(resolvedHost, storagePort);
    }
    if (connectFunctions != null) {
      connectFunctions(functionsOrigin);
    }

    _configured = true;
    debugPrint(
      '[EmulatorConfig] Local emulator routing enabled on $resolvedHost '
      '(Auth:$authPort, Firestore:$firestorePort, Storage:$storagePort, '
      'Functions:$functionsPort, AIGateway:$aiGatewayPort)',
    );
  }
}
