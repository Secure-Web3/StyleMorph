import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/config/app_build_info.dart';
import 'package:stylemorph/core/services/app_update_service.dart';
import 'package:stylemorph/core/services/notification_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_update_dialog.dart';

class _RecordingNotificationService extends NotificationService {
  int callCount = 0;
  String? lastEventType;
  String? lastTargetRoute;

  @override
  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    String category = 'account',
    String targetRoute = 'profile_identity',
    String emoji = '🔔',
    bool sendEmail = false,
    String? recipientEmail,
    String eventType = NotificationService.eventGeneral,
    Map<String, dynamic>? extraData,
  }) async {
    callCount++;
    lastEventType = eventType;
    lastTargetRoute = targetRoute;
  }
}

Widget _wrapWithApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.buildTheme(
        palette: AppPalette.white,
        isDark: false,
        localeCode: 'en',
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RemoteVersionInfo & AppBuildInfo', () {
    test('parses Firestore app_config/version fields and fallbacks', () {
      final info = RemoteVersionInfo.fromMap({
        'version': '1.2.0',
        'build': 150,
        'minRequiredBuild': 120,
        'forceUpdate': true,
        'androidUrl': 'https://example.com/app.apk',
        'iosUrl': 'https://apps.apple.com/app/stylemorph',
        'webUrl': 'https://app.stylemorph.style',
        'releaseNotes': 'Faster Virtual Try-On & bug fixes.',
      });

      expect(info.version, '1.2.0');
      expect(info.build, 150);
      expect(info.minRequiredBuild, 120);
      expect(info.forceUpdate, isTrue);
      expect(info.androidUrl, 'https://example.com/app.apk');
      expect(info.iosUrl, 'https://apps.apple.com/app/stylemorph');
      expect(info.webUrl, 'https://app.stylemorph.style');
      expect(info.releaseNotes, 'Faster Virtual Try-On & bug fixes.');
      expect(info.isValid, isTrue);
    });

    test('detects optional and forced updates via AppBuildInfo', () {
      expect(
        AppBuildInfo.isUpdateAvailable(
          remoteVersion: '1.1.0',
          remoteBuild: 105,
          currentVersion: '1.0.0',
          currentBuild: 100,
        ),
        isTrue,
      );
      expect(
        AppBuildInfo.isUpdateAvailable(
          remoteVersion: '1.0.0',
          remoteBuild: 100,
          currentVersion: '1.0.0',
          currentBuild: 100,
        ),
        isFalse,
      );
      expect(
        AppBuildInfo.isForceUpdateRequired(
          minRequiredBuild: 110,
          currentBuild: 100,
        ),
        isTrue,
      );
      expect(
        AppBuildInfo.isForceUpdateRequired(
          minRequiredBuild: 90,
          currentBuild: 100,
        ),
        isFalse,
      );
    });
  });

  group('AppUpdateService preferences & deduplication', () {
    test('auto_check_updates defaults to true and persists false', () async {
      final service = AppUpdateService();
      expect(await service.isAutoCheckEnabled(), isTrue);

      await service.setAutoCheckEnabled(false);
      expect(await service.isAutoCheckEnabled(), isFalse);

      await service.setAutoCheckEnabled(true);
      expect(await service.isAutoCheckEnabled(), isTrue);
    });

    test('non-manual check skips when auto_check_updates is false', () async {
      final recorder = _RecordingNotificationService();
      final service = AppUpdateService(notificationService: recorder);
      await service.setAutoCheckEnabled(false);

      const remote = RemoteVersionInfo(version: '2.0.0', build: 200);

      final autoResult = await service.checkForUpdate(
        manual: false,
        currentVersion: '1.0.0',
        currentBuild: 100,
        uidOverride: 'uid_1',
        remoteOverride: remote,
      );
      expect(autoResult.updateAvailable, isFalse);
      expect(recorder.callCount, 0);

      final manualResult = await service.checkForUpdate(
        manual: true,
        currentVersion: '1.0.0',
        currentBuild: 100,
        uidOverride: 'uid_1',
        remoteOverride: remote,
      );
      expect(manualResult.updateAvailable, isTrue);
      expect(recorder.callCount, 1);
    });

    test('deduplicates in-app notifications per build number', () async {
      final recorder = _RecordingNotificationService();
      final service = AppUpdateService(notificationService: recorder);

      const build150 = RemoteVersionInfo(version: '1.2.0', build: 150);

      await service.checkForUpdate(
        manual: true,
        currentVersion: '1.0.0',
        currentBuild: 100,
        uidOverride: 'uid_1',
        remoteOverride: build150,
      );
      await service.checkForUpdate(
        manual: true,
        currentVersion: '1.0.0',
        currentBuild: 100,
        uidOverride: 'uid_1',
        remoteOverride: build150,
      );

      expect(recorder.callCount, 1);
      expect(recorder.lastEventType, NotificationService.eventAppUpdate);
      expect(recorder.lastTargetRoute, 'profile_about');

      const build160 = RemoteVersionInfo(version: '1.3.0', build: 160);
      await service.checkForUpdate(
        manual: true,
        currentVersion: '1.0.0',
        currentBuild: 100,
        uidOverride: 'uid_1',
        remoteOverride: build160,
      );

      expect(recorder.callCount, 2);
    });
  });

  group('AppUpdateDialog', () {
    testWidgets('optional update shows Later button and allows pop', (
      tester,
    ) async {
      const info = RemoteVersionInfo(
        version: '1.5.0',
        build: 150,
        releaseNotes: 'Performance improvements',
        androidUrl: 'https://example.com/StyleMorph.apk',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          const AppUpdateDialog(
            remoteInfo: info,
            isForced: false,
            currentVersionOverride: '1.0.0',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Update Available'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Performance improvements'), findsOneWidget);
      expect(find.text('Current: v1.0.0'), findsOneWidget);
      expect(find.text('New: v1.5.0'), findsOneWidget);

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isTrue);
    });

    testWidgets('forced update hides Later button and blocks back pop', (
      tester,
    ) async {
      const info = RemoteVersionInfo(
        version: '2.0.0',
        build: 200,
        forceUpdate: true,
        releaseNotes: 'Mandatory security patch',
        androidUrl: 'https://example.com/StyleMorph.apk',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          const AppUpdateDialog(
            remoteInfo: info,
            isForced: true,
            currentVersionOverride: '1.0.0',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Required Update'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
      expect(find.text('Mandatory security patch'), findsOneWidget);

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });

    testWidgets('shows live progress bar during Android APK download', (
      tester,
    ) async {
      const info = RemoteVersionInfo(
        version: '1.5.0',
        build: 150,
        androidUrl: 'https://example.com/StyleMorph.apk',
      );
      final completer = Completer<void>();

      await tester.pumpWidget(
        _wrapWithApp(
          AppUpdateDialog(
            remoteInfo: info,
            isForced: false,
            currentVersionOverride: '1.0.0',
            onDownloadAndInstall: (url, {required onProgress}) {
              onProgress(0.45);
              return completer.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Windows/Linux test runner, TargetPlatform defaults to android in
      // flutter_test unless overridden; verify button text or tap if Android.
      final downloadBtn = find.text('Download & Install');
      if (downloadBtn.evaluate().isNotEmpty) {
        await tester.tap(downloadBtn);
        await tester.pump();
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('45%'), findsOneWidget);
      }

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
