import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/services/push_notification_service.dart';
import 'package:stylemorph/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    PushNotificationService.resetForTesting();
  });

  group('PushNotificationService', () {
    test('uses canonical app_updates topic and identifies update payloads', () {
      expect(PushNotificationService.kAppUpdatesTopic, 'app_updates');
      expect(
        PushNotificationService.isAppUpdateMessage({'type': 'app_update'}),
        isTrue,
      );
      expect(
        PushNotificationService.isAppUpdateMessage({'type': 'APP_UPDATE'}),
        isTrue,
      );
      expect(
        PushNotificationService.isAppUpdateMessage({'type': 'promo'}),
        isFalse,
      );
      expect(PushNotificationService.isAppUpdateMessage({}), isFalse);
    });

    test(
      'initialize completes safely without throwing when Firebase is uninitialized',
      () async {
        await expectLater(PushNotificationService.initialize(), completes);
      },
    );
  });

  group('AppUpdateSessionCoordinator', () {
    test(
      'enforces 30-minute cooldown for automatic checks unless manual or forced',
      () {
        final coordinator = AppUpdateSessionCoordinator();
        final t0 = DateTime(2026, 11, 26, 10, 0);

        expect(coordinator.shouldRunAutoCheck(now: t0), isTrue);

        coordinator.markCheckCompleted(isForced: false, now: t0);

        expect(
          coordinator.shouldRunAutoCheck(
            now: t0.add(const Duration(minutes: 10)),
          ),
          isFalse,
        );
        expect(
          coordinator.shouldRunAutoCheck(
            manual: true,
            now: t0.add(const Duration(minutes: 10)),
          ),
          isTrue,
        );
        expect(
          coordinator.shouldRunAutoCheck(
            now: t0.add(const Duration(minutes: 30)),
          ),
          isTrue,
        );

        coordinator.markCheckCompleted(isForced: true, now: t0);
        expect(
          coordinator.shouldRunAutoCheck(
            now: t0.add(const Duration(minutes: 1)),
          ),
          isTrue,
        );
      },
    );

    test(
      'suppresses optional update dialog after once per session but always shows forced',
      () {
        final coordinator = AppUpdateSessionCoordinator();

        expect(coordinator.shouldShowDialog(isForced: false), isTrue);
        coordinator.markCheckCompleted(isForced: false, dialogShown: true);

        expect(coordinator.shouldShowDialog(isForced: false), isFalse);
        expect(coordinator.shouldShowDialog(isForced: true), isTrue);
      },
    );
  });

  group('GitHub Release -> Firestore & FCM pipeline files', () {
    test(
      'publish_release_update.mjs and build_android_apk.yml contain expected wiring',
      () {
        final scriptFile = File(
          '../.github/scripts/publish_release_update.mjs',
        );
        final workflowFile = File('../.github/workflows/build_android_apk.yml');

        expect(scriptFile.existsSync(), isTrue);
        expect(workflowFile.existsSync(), isTrue);

        final scriptSource = scriptFile.readAsStringSync();
        expect(scriptSource, contains('app_config/version'));
        expect(scriptSource, contains("topic: 'app_updates'"));
        expect(scriptSource, contains('FIREBASE_SERVICE_ACCOUNT'));
        expect(scriptSource, contains('StyleMorph v'));

        final workflowSource = workflowFile.readAsStringSync();
        expect(workflowSource, contains('force_update:'));
        expect(workflowSource, contains('publish_release_update.mjs'));
        expect(
          workflowSource,
          contains(r'StyleMorph-V${APP_VERSION}-B${BUILD_NUMBER}-arm64.apk'),
        );
        expect(
          workflowSource,
          contains(r'StyleMorph-V${APP_VERSION}-B${BUILD_NUMBER}-arm32.apk'),
        );
        expect(
          workflowSource,
          contains(
            r'StyleMorph-V${APP_VERSION}-B${BUILD_NUMBER}-universal.apk',
          ),
        );
        expect(workflowSource, contains('--dart-define=BUILD_NUMBER'));
        expect(workflowSource, contains('--dart-define=APP_VERSION'));

        final manifestFile = File('android/app/src/main/AndroidManifest.xml');
        expect(manifestFile.existsSync(), isTrue);
        final manifestSource = manifestFile.readAsStringSync();
        expect(
          manifestSource,
          contains('com.google.firebase.messaging.default_notification_icon'),
        );
        expect(manifestSource, contains('@drawable/ic_stat_stylemorph'));
      },
    );
  });
}
