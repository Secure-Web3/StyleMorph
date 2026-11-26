import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_build_info.dart';
import 'app_update_installer_stub.dart'
    if (dart.library.io) 'app_update_installer_io.dart'
    as installer;
import 'notification_service.dart';

/// Parsed remote version metadata from Firestore `app_config/version`.
@immutable
class RemoteVersionInfo {
  final String version;
  final int build;
  final int minRequiredBuild;
  final bool forceUpdate;
  final String? androidUrl;
  final String? iosUrl;
  final String? webUrl;
  final String? releaseNotes;

  const RemoteVersionInfo({
    required this.version,
    required this.build,
    this.minRequiredBuild = 0,
    this.forceUpdate = false,
    this.androidUrl,
    this.iosUrl,
    this.webUrl,
    this.releaseNotes,
  });

  factory RemoteVersionInfo.fromMap(Map<String, dynamic> data) {
    return RemoteVersionInfo(
      version: (data['version'] ?? data['latestVersion'] ?? '')
          .toString()
          .trim(),
      build:
          (data['build'] as num?)?.toInt() ??
          (data['latestBuild'] as num?)?.toInt() ??
          0,
      minRequiredBuild: (data['minRequiredBuild'] as num?)?.toInt() ?? 0,
      forceUpdate: data['forceUpdate'] == true,
      androidUrl:
          _nonEmpty(data['androidUrl']) ??
          _nonEmpty(data['apkUrl']) ??
          _nonEmpty(data['downloadUrl']),
      iosUrl: _nonEmpty(data['iosUrl']) ?? _nonEmpty(data['storeUrl']),
      webUrl: _nonEmpty(data['webUrl']),
      releaseNotes: _nonEmpty(data['releaseNotes']),
    );
  }

  static String? _nonEmpty(Object? value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  bool get isValid => version.isNotEmpty || build > 0;

  String get resolvedVersion => version.isNotEmpty ? version : '1.0.$build';
}

/// Result returned by [AppUpdateService.checkForUpdate].
@immutable
class AppUpdateCheckResult {
  final RemoteVersionInfo? remoteInfo;
  final bool updateAvailable;
  final bool isForced;

  const AppUpdateCheckResult({
    this.remoteInfo,
    required this.updateAvailable,
    required this.isForced,
  });

  const AppUpdateCheckResult.none()
    : remoteInfo = null,
      updateAvailable = false,
      isForced = false;
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final autoCheckUpdatesProvider = FutureProvider<bool>((ref) async {
  return ref.watch(appUpdateServiceProvider).isAutoCheckEnabled();
});

/// Handles remote version checks (`app_config/version`), user auto-check
/// preferences, per-build notification deduplication, and native Android APK
/// download + installation.
class AppUpdateService {
  static const String prefAutoCheckUpdates = 'auto_check_updates';
  static const String prefLastNotifiedBuild = 'last_notified_update_build';

  final FirebaseFirestore? _customFirestore;
  final NotificationService _notificationService;
  final Future<SharedPreferences> Function() _prefsProvider;

  AppUpdateService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    Future<SharedPreferences> Function()? prefsProvider,
  }) : _customFirestore = firestore,
       _notificationService = notificationService ?? NotificationService(),
       _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Returns whether automatic background update checks are enabled (default `true`).
  Future<bool> isAutoCheckEnabled() async {
    try {
      final prefs = await _prefsProvider();
      return prefs.getBool(prefAutoCheckUpdates) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Persists the user's preference for automatic update checks.
  Future<void> setAutoCheckEnabled(bool enabled) async {
    final prefs = await _prefsProvider();
    await prefs.setBool(prefAutoCheckUpdates, enabled);
  }

  /// Checks Firestore `app_config/version` against [AppBuildInfo] (or optional
  /// overrides for testing).
  ///
  /// When [manual] is `false`, respects [isAutoCheckEnabled] and returns
  /// [AppUpdateCheckResult.none] immediately if disabled.
  Future<AppUpdateCheckResult> checkForUpdate({
    bool manual = false,
    String? currentVersion,
    int? currentBuild,
    String? uidOverride,
    RemoteVersionInfo? remoteOverride,
  }) async {
    if (!manual) {
      final enabled = await isAutoCheckEnabled();
      if (!enabled) return const AppUpdateCheckResult.none();
    }

    try {
      RemoteVersionInfo? info = remoteOverride;
      if (info == null) {
        final firestore = _firestore;
        if (firestore == null) return const AppUpdateCheckResult.none();

        final doc = await firestore
            .collection('app_config')
            .doc('version')
            .get()
            .timeout(const Duration(seconds: 6));

        if (!doc.exists || doc.data() == null) {
          return const AppUpdateCheckResult.none();
        }
        info = RemoteVersionInfo.fromMap(doc.data()!);
      }

      if (!info.isValid) return const AppUpdateCheckResult.none();

      final hasUpdate = AppBuildInfo.isUpdateAvailable(
        remoteVersion: info.version,
        remoteBuild: info.build,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
      final isForced =
          info.forceUpdate ||
          AppBuildInfo.isForceUpdateRequired(
            minRequiredBuild: info.minRequiredBuild,
            currentBuild: currentBuild,
          );
      final updateAvailable = hasUpdate || isForced;

      if (updateAvailable) {
        await _notifyOncePerBuild(
          info: info,
          isForced: isForced,
          uidOverride: uidOverride,
        );
      }

      return AppUpdateCheckResult(
        remoteInfo: info,
        updateAvailable: updateAvailable,
        isForced: isForced,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] checkForUpdate error: $e');
      return const AppUpdateCheckResult.none();
    }
  }

  Future<void> _notifyOncePerBuild({
    required RemoteVersionInfo info,
    required bool isForced,
    String? uidOverride,
  }) async {
    final uid = uidOverride ?? currentAuthenticatedUid();
    if (uid == null || uid.isEmpty) return;

    try {
      final prefs = await _prefsProvider();
      final targetBuild = info.build > 0 ? info.build : info.minRequiredBuild;
      final lastNotified = prefs.getInt(prefLastNotifiedBuild) ?? 0;
      if (targetBuild > 0 && lastNotified >= targetBuild) {
        return;
      }

      await _notificationService.createNotification(
        uid: uid,
        title: 'App Update Available',
        body: 'StyleMorph v${info.resolvedVersion} is now available.',
        category: 'account',
        targetRoute: 'profile_about',
        emoji: '🚀',
        eventType: NotificationService.eventAppUpdate,
        extraData: {
          'version': info.resolvedVersion,
          'build': info.build,
          'forceUpdate': isForced,
        },
      );

      if (targetBuild > 0) {
        await prefs.setInt(prefLastNotifiedBuild, targetBuild);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] _notifyOncePerBuild error: $e');
    }
  }

  /// Downloads and triggers native Android APK installation with live
  /// `0.0..1.0` progress callbacks.
  Future<void> downloadAndInstallApk(
    String url, {
    required void Function(double progress) onProgress,
  }) {
    return installer.downloadAndInstallApkImpl(url, onProgress: onProgress);
  }
}
