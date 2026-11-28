import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/session_service.dart';
import 'package:stylemorph/core/services/totp_helper.dart';
import 'package:stylemorph/core/services/two_factor_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/widgets/sessions_sub_tab.dart';

class _FakeSessionService extends SessionService {
  final String currentId;
  bool revokeCalled = false;
  bool blockCalled = false;

  _FakeSessionService({required this.currentId});

  @override
  Future<String> currentSessionId() async => currentId;

  @override
  Future<String> currentDeviceId() async => 'dev_current';

  @override
  Future<void> upsertSession() async {}

  @override
  Future<bool> revokeSession(String targetSessionId) async {
    revokeCalled = true;
    return true;
  }

  @override
  Future<bool> blockDevice({
    required String targetSessionId,
    required String targetDeviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    blockCalled = true;
    return true;
  }
}

class _PreviewOtpDispatcher implements EmailOtpDispatcher {
  String? lastCode;

  @override
  Future<bool> dispatchOtp({
    required String uid,
    required String email,
    required String code,
  }) async {
    lastCode = code;
    return true;
  }
}

Widget _wrapWithApp({
  required Widget child,
  required ProviderContainer container,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.buildTheme(palette: AppPalette.editorial, isDark: false),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SessionRevocationListener.testUidOverride = null;
  });

  group('Telegram 72-Hour Rule & Sign-Out Cleanup', () {
    test('remainingTrustDuration enforces 72-hour minimum session age', () {
      final now = DateTime(2026, 11, 28, 12, 0);

      final youngSession = SessionInfo(
        sessionId: 'sess_young',
        deviceId: 'dev_1',
        deviceType: 'mobile_app',
        deviceName: 'Android App',
        deviceModel: 'Pixel',
        platform: 'Android',
        osVersion: '15',
        userAgent: 'StyleMorph/Android',
        createdAt: now.subtract(const Duration(hours: 23, minutes: 45)),
        lastActiveAt: now,
      );

      final remaining = SessionService.remainingTrustDuration(
        youngSession,
        now: now,
      );
      expect(remaining.inHours, 48);
      expect(remaining.inMinutes.remainder(60), 15);

      final trustedSession = youngSession.copyWith(
        createdAt: now.subtract(const Duration(hours: 72)),
      );
      expect(
        SessionService.remainingTrustDuration(trustedSession, now: now),
        Duration.zero,
      );
    });

    test(
      'deleteCurrentSessionOnSignOut clears sessionId safely when offline/uninitialized',
      () async {
        final service = SessionService();
        final idBefore = await service.currentSessionId();
        final devBefore = await service.currentDeviceId();
        expect(idBefore, isNotEmpty);

        await service.deleteCurrentSessionOnSignOut('uid_offline_test');

        final idAfter = await service.currentSessionId();
        final devAfter = await service.currentDeviceId();
        expect(idAfter, isNot(equals(idBefore)));
        expect(devAfter, equals(devBefore));
      },
    );
  });

  group('Step-Up 6-Digit Verification Logic', () {
    test('verifyStepUpCode validates TOTP when TOTP 2FA is enabled', () {
      final service = TwoFactorService();
      const secret = 'JBSWY3DPEHPK3PXP';
      const config = TwoFactorConfig(
        enabled: true,
        method: TwoFactorMethod.totp,
        totpSecret: secret,
      );

      final validCode = TotpHelper.generateCode(secret);
      expect(
        service.verifyStepUpCode(config: config, uid: 'u1', code: validCode),
        isTrue,
      );
      expect(
        service.verifyStepUpCode(config: config, uid: 'u1', code: '000000'),
        isFalse,
      );
    });

    test('verifyStepUpCode validates Email OTP when 2FA is disabled', () async {
      final dispatcher = _PreviewOtpDispatcher();
      final service = TwoFactorService(emailDispatcher: dispatcher);
      const config = TwoFactorConfig(enabled: false);

      await service.requestEmailOtp(uid: 'u1', email: 'u1@example.com');
      expect(dispatcher.lastCode, isNotNull);

      expect(
        service.verifyStepUpCode(
          config: config,
          uid: 'u1',
          code: dispatcher.lastCode!,
        ),
        isTrue,
      );
      expect(
        service.verifyStepUpCode(config: config, uid: 'u1', code: '123456'),
        isFalse,
      );
    });
  });

  group('SessionsSubTab UI: 2FA Banner, 72h Cooldown & Step-Up OTP', () {
    testWidgets(
      'shows 2FA warning banner while keeping session cards visible, and enforces 72h cooldown on young sessions',
      (tester) async {
        SessionRevocationListener.testUidOverride = 'uid_test_1';
        final now = DateTime.now();
        final fakeSessionService = _FakeSessionService(currentId: 'sess_curr');
        final sessions = [
          SessionInfo(
            sessionId: 'sess_curr',
            deviceId: 'dev_current',
            deviceType: 'mobile_app',
            deviceName: 'Android App',
            deviceModel: 'Pixel',
            platform: 'Android',
            osVersion: '15',
            userAgent: 'StyleMorph/Android',
            createdAt: now.subtract(const Duration(hours: 2)),
            lastActiveAt: now,
          ),
          SessionInfo(
            sessionId: 'sess_old_primary',
            deviceId: 'dev_old',
            deviceType: 'desktop_web',
            deviceName: 'Desktop Web • Chrome',
            deviceModel: 'Chrome',
            platform: 'Web',
            osVersion: 'Windows',
            userAgent: 'Chrome',
            isPrimary: true,
            createdAt: now.subtract(const Duration(days: 10)),
            lastActiveAt: now.subtract(const Duration(hours: 1)),
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            sessionServiceProvider.overrideWithValue(fakeSessionService),
            currentSessionIdProvider.overrideWith((_) async => 'sess_curr'),
            allSessionsProvider.overrideWith((_) => Stream.value(sessions)),
            twoFactorConfigProvider(
              'uid_test_1',
            ).overrideWith((_) => Stream.value(const TwoFactorConfig())),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(container: container, child: const SessionsSubTab()),
        );
        await tester.pumpAndSettle();

        final strings = const AppStrings('en');

        // 2FA warning banner is visible when 2FA is off
        expect(find.text(strings.sessTwoFaBannerTitle), findsOneWidget);
        expect(find.text(strings.sessTwoFaBannerBtn), findsOneWidget);

        // Session cards remain visible
        expect(find.text('Android App'), findsOneWidget);
        expect(find.text('Desktop Web • Chrome'), findsOneWidget);

        // Expand old target session (even if legacy isPrimary == true, Delete & Block are shown)
        await tester.tap(find.text('Desktop Web • Chrome'));
        await tester.pumpAndSettle();
        expect(find.text(strings.sessDelete), findsOneWidget);
        expect(find.text(strings.sessBlockBtn), findsOneWidget);

        // Tapping Delete on young session (< 72h) shows 72-hour protection modal
        await tester.ensureVisible(find.text(strings.sessDelete));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.sessDelete));
        await tester.pumpAndSettle();
        expect(find.text(strings.sessCooldownTitle), findsOneWidget);
        expect(fakeSessionService.revokeCalled, isFalse);
      },
    );

    testWidgets(
      'trusted session (>= 72h) requires Step-Up 6-digit OTP before deleting',
      (tester) async {
        SessionRevocationListener.testUidOverride = 'uid_test_2';
        final now = DateTime.now();
        final fakeSessionService = _FakeSessionService(currentId: 'sess_curr');
        final dispatcher = _PreviewOtpDispatcher();
        final twoFactorService = TwoFactorService(emailDispatcher: dispatcher);

        final sessions = [
          SessionInfo(
            sessionId: 'sess_curr',
            deviceId: 'dev_current',
            deviceType: 'mobile_app',
            deviceName: 'Android App',
            deviceModel: 'Pixel',
            platform: 'Android',
            osVersion: '15',
            userAgent: 'StyleMorph/Android',
            createdAt: now.subtract(const Duration(hours: 80)),
            lastActiveAt: now,
          ),
          SessionInfo(
            sessionId: 'sess_target',
            deviceId: 'dev_target',
            deviceType: 'desktop_web',
            deviceName: 'Desktop Web • Safari',
            deviceModel: 'Safari',
            platform: 'Web',
            osVersion: 'macOS',
            userAgent: 'Safari',
            createdAt: now.subtract(const Duration(days: 15)),
            lastActiveAt: now.subtract(const Duration(hours: 2)),
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            sessionServiceProvider.overrideWithValue(fakeSessionService),
            twoFactorServiceProvider.overrideWithValue(twoFactorService),
            currentSessionIdProvider.overrideWith((_) async => 'sess_curr'),
            allSessionsProvider.overrideWith((_) => Stream.value(sessions)),
            twoFactorConfigProvider(
              'uid_test_2',
            ).overrideWith((_) => Stream.value(const TwoFactorConfig())),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(container: container, child: const SessionsSubTab()),
        );
        await tester.pumpAndSettle();

        final strings = const AppStrings('en');

        // Expand target session and tap Delete
        await tester.tap(find.text('Desktop Web • Safari'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(strings.sessDelete));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.sessDelete));
        await tester.pumpAndSettle();

        // Confirm delete modal
        expect(find.text(strings.sessConfirmDeleteTitle), findsOneWidget);
        await tester.tap(find.text(strings.sessDelete).last);
        await tester.pumpAndSettle();

        // Step-Up OTP modal appears
        expect(find.text(strings.sessStepUpTitle), findsOneWidget);
        expect(dispatcher.lastCode, isNotNull);
        expect(fakeSessionService.revokeCalled, isFalse);

        // Enter the dispatched 6-digit OTP and verify
        await tester.enterText(find.byType(TextField), dispatcher.lastCode!);
        await tester.tap(find.text(strings.sessStepUpVerifyBtn));
        await tester.pumpAndSettle();

        expect(fakeSessionService.revokeCalled, isTrue);
      },
    );
  });
}
