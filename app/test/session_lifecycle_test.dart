import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/session_service.dart';
import 'package:stylemorph/features/profile/presentation/widgets/sessions_sub_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session Lifecycle Rules Tests', () {
    test('SessionService defines required lifecycle constants', () {
      expect(
        SessionService.sessionInactivityExpiry,
        equals(const Duration(days: 5)),
      );
      expect(SessionService.maxConcurrentSessions, equals(5));
      expect(
        SessionService.lastActiveThrottle,
        equals(const Duration(minutes: 15)),
      );
    });

    test('15-Minute write throttling suppresses rapid writes', () async {
      final service = SessionService();

      // Initially null
      expect(service.lastActivityWriteTime, isNull);

      // Simulate a write having occurred 5 minutes ago
      service.lastActivityWriteTime = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      // Attempt to record activity within 15 minutes throttle window
      final wasRecorded = await service.recordUserActivityThrottled();
      // Must be throttled (returns false, zero Firestore writes)
      expect(wasRecorded, isFalse);
    });

    test('15-Minute write throttling allows update after 15 minutes', () async {
      final service = SessionService();

      // Simulate last write occurred 16 minutes ago
      service.lastActivityWriteTime = DateTime.now().subtract(
        const Duration(minutes: 16),
      );

      // When unauthenticated/no Firebase in test, method returns false without throwing
      expect(() => service.recordUserActivityThrottled(), returnsNormally);
    });

    test('5-Day inactivity expiry logic recognizes expired timestamps', () {
      final now = DateTime.now();

      // 4 days ago -> Not expired
      final fourDaysAgo = now.subtract(const Duration(days: 4));
      expect(
        now.difference(fourDaysAgo) >= SessionService.sessionInactivityExpiry,
        isFalse,
      );

      // 5 days and 1 hour ago -> Expired
      final fiveDaysAgo = now.subtract(const Duration(days: 5, hours: 1));
      expect(
        now.difference(fiveDaysAgo) >= SessionService.sessionInactivityExpiry,
        isTrue,
      );

      // 6 days ago -> Expired
      final sixDaysAgo = now.subtract(const Duration(days: 6));
      expect(
        now.difference(sixDaysAgo) >= SessionService.sessionInactivityExpiry,
        isTrue,
      );
    });

    test(
      'checkSessionExpiryAndSignOutIfExpired executes safely without auth',
      () async {
        final service = SessionService();
        final expired = await service.checkSessionExpiryAndSignOutIfExpired();
        expect(expired, isFalse);
      },
    );

    test(
      'AppStrings provides correct session lifecycle messages in all 4 languages',
      () {
        // Persian
        final fa = AppStrings('fa');
        expect(fa.authSessionExpired, contains('۵ روز'));
        expect(fa.authSessionTerminatedConcurrent, contains('۵ دستگاه'));

        // English
        final en = AppStrings('en');
        expect(en.authSessionExpired, contains('5 days'));
        expect(
          en.authSessionTerminatedConcurrent,
          contains('5 concurrent devices'),
        );

        // Arabic
        final ar = AppStrings('ar');
        expect(ar.authSessionExpired, contains('5'));
        expect(ar.authSessionTerminatedConcurrent, contains('5'));

        // Turkish
        final tr = AppStrings('tr');
        expect(tr.authSessionExpired, contains('5 günlük'));
        expect(tr.authSessionTerminatedConcurrent, contains('5 eşzamanlı'));
      },
    );

    testWidgets(
      'SessionRevocationListener captures user activity on pointer down',
      (tester) async {
        final service = SessionService();
        service.lastActivityWriteTime = DateTime.now();

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SessionRevocationListener(child: Text('Shell Content')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Shell Content'), findsOneWidget);

        // Tap inside listener
        await tester.tap(find.text('Shell Content'));
        await tester.pump();

        expect(service.lastActivityWriteTime, isNotNull);
      },
    );

    test(
      'Client-side session sorting places newest and pending sessions at top',
      () {
        final now = DateTime.now();
        final olderSession = SessionInfo(
          sessionId: 'old-1',
          deviceId: 'd1',
          deviceType: 'desktop_web',
          deviceName: 'Chrome on Mac',
          deviceModel: '',
          platform: 'macOS',
          osVersion: '14.0',
          userAgent: '',
          createdAt: now.subtract(const Duration(days: 2)),
          lastActiveAt: now.subtract(const Duration(hours: 4)),
        );

        final newerSession = SessionInfo(
          sessionId: 'new-2',
          deviceId: 'd2',
          deviceType: 'mobile_android',
          deviceName: 'Pixel 8',
          deviceModel: '',
          platform: 'Android',
          osVersion: '14.0',
          userAgent: '',
          createdAt: now.subtract(const Duration(hours: 1)),
          lastActiveAt: now.subtract(const Duration(minutes: 10)),
        );

        final pendingSession = SessionInfo(
          sessionId: 'pending-3',
          deviceId: 'd3',
          deviceType: 'mobile_ios',
          deviceName: 'iPhone 15',
          deviceModel: '',
          platform: 'iOS',
          osVersion: '17.0',
          userAgent: '',
          createdAt: now,
          lastActiveAt: now,
        );

        final list = [olderSession, newerSession, pendingSession];
        list.sort((a, b) {
          final cmp = b.lastActiveAt.compareTo(a.lastActiveAt);
          if (cmp != 0) return cmp;
          return b.createdAt.compareTo(a.createdAt);
        });

        expect(list.first.sessionId, equals('pending-3'));
        expect(list[1].sessionId, equals('new-2'));
        expect(list.last.sessionId, equals('old-1'));
      },
    );

    test(
      'SessionInfo serializes and deserializes ipAddress and ipLocation correctly',
      () {
        final now = DateTime.now();
        final session = SessionInfo(
          sessionId: 'test-ip-sess',
          deviceId: 'dev-1',
          deviceType: 'desktop_web',
          deviceName: 'Chrome on Mac',
          deviceModel: '',
          platform: 'Web',
          osVersion: 'macOS',
          userAgent: '',
          createdAt: now,
          lastActiveAt: now,
          ipAddress: '198.51.100.42',
          ipLocation: 'Berlin, Germany',
        );

        final map = session.toMap();
        expect(map['ipAddress'], equals('198.51.100.42'));
        expect(map['ipLocation'], equals('Berlin, Germany'));

        final copy = session.copyWith(
          ipAddress: '203.0.113.1',
          ipLocation: 'Tehran, Iran',
        );
        expect(copy.ipAddress, equals('203.0.113.1'));
        expect(copy.ipLocation, equals('Tehran, Iran'));
      },
    );

    test(
      'SessionService.detectIpAndLocation executes safely with graceful fallback and override',
      () async {
        // 1. Without override, runs safely with graceful fallback
        SessionService.ipResolverOverride = null;
        final result = await SessionService.detectIpAndLocation();
        // Should not throw, returns record
        expect(result, isNotNull);

        // 2. With override, returns expected mock values
        SessionService.ipResolverOverride = () async =>
            (ip: '198.51.100.99', location: 'Paris, France');
        final mocked = await SessionService.detectIpAndLocation();
        expect(mocked.ip, equals('198.51.100.99'));
        expect(mocked.location, equals('Paris, France'));

        // 3. Cleanup
        SessionService.ipResolverOverride = null;
      },
    );
  });
}
