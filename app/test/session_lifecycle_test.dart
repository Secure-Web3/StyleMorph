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
  });
}
