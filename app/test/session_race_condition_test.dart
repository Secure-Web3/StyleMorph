import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/services/session_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/features/auth/domain/auth_repository.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/profile/presentation/widgets/sessions_sub_tab.dart';

class MockSessionDocSnapshot implements SessionDocSnapshot {
  @override
  final bool exists;
  final Map<String, dynamic>? sessionData;

  MockSessionDocSnapshot({required this.exists, this.sessionData});

  @override
  Map<String, dynamic>? data() => sessionData;
}

class TestSessionService extends SessionService {
  final StreamController<SessionDocSnapshot?> sessionStreamController;
  final StreamController<bool> blockedStreamController;
  final String testSessionId;
  final String testDeviceId;

  TestSessionService({
    required this.sessionStreamController,
    required this.blockedStreamController,
    this.testSessionId = 'test_session_123',
    this.testDeviceId = 'test_device_456',
  });

  @override
  Future<String> currentSessionId() async => testSessionId;

  @override
  Future<String> currentDeviceId() async => testDeviceId;

  @override
  Stream<SessionDocSnapshot?> watchCurrentSession(
    String uid,
    String sessionId,
  ) {
    return sessionStreamController.stream;
  }

  @override
  Stream<bool> watchDeviceBlocked(String uid, String deviceId) {
    return blockedStreamController.stream;
  }

  @override
  Future<bool> checkSessionExpiryAndSignOutIfExpired() async => false;
}

class MockAuthRepository implements AuthRepository {
  bool signOutCalled = false;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SessionRevocationListener.testUidOverride = null;
  });

  group('Session Race Condition & Revocation Tests', () {
    test(
      'clearCurrentSessionId resets session ID without wiping persistent deviceId',
      () async {
        final service = SessionService();

        final sessId1 = await service.currentSessionId();
        final devId1 = await service.currentDeviceId();

        expect(sessId1, isNotEmpty);
        expect(devId1, isNotEmpty);

        // Subsequent calls return cached IDs
        expect(await service.currentSessionId(), equals(sessId1));
        expect(await service.currentDeviceId(), equals(devId1));

        // Clear current session ID
        await service.clearCurrentSessionId();

        // Next call generates a fresh session ID
        final sessId2 = await service.currentSessionId();
        final devId2 = await service.currentDeviceId();

        expect(sessId2, isNotEmpty);
        expect(sessId2, isNot(equals(sessId1)));

        // Persistent device ID MUST remain unchanged
        expect(devId2, equals(devId1));
      },
    );

    testWidgets(
      'SessionRevocationListener does NOT sign the user out when initial snapshot emits exists == false before upsertSession',
      (tester) async {
        SessionRevocationListener.testUidOverride = 'test_race_user_1';

        final sessionController =
            StreamController<SessionDocSnapshot?>.broadcast();
        final blockedController = StreamController<bool>.broadcast();
        final mockAuthRepo = MockAuthRepository();

        final mockService = TestSessionService(
          sessionStreamController: sessionController,
          blockedStreamController: blockedController,
        );

        final container = ProviderContainer(
          overrides: [
            sessionServiceProvider.overrideWithValue(mockService),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
        );

        container.read(appStateProvider.notifier).login();
        expect(container.read(appStateProvider).isLoggedIn, isTrue);
        expect(mockAuthRepo.signOutCalled, isFalse);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SessionRevocationListener(child: Text('Protected Home')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Protected Home'), findsOneWidget);

        // Initial snapshot arrives with exists == false (upsertSession has not written doc yet)
        sessionController.add(MockSessionDocSnapshot(exists: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Must NOT sign out
        expect(mockAuthRepo.signOutCalled, isFalse);
        expect(container.read(appStateProvider).isLoggedIn, isTrue);

        await sessionController.close();
        await blockedController.close();
        container.dispose();
      },
    );

    testWidgets(
      'SessionRevocationListener DOES sign the user out if session doc first exists and is subsequently deleted',
      (tester) async {
        SessionRevocationListener.testUidOverride = 'test_race_user_2';

        final sessionController =
            StreamController<SessionDocSnapshot?>.broadcast();
        final blockedController = StreamController<bool>.broadcast();
        final mockAuthRepo = MockAuthRepository();

        final mockService = TestSessionService(
          sessionStreamController: sessionController,
          blockedStreamController: blockedController,
        );

        final container = ProviderContainer(
          overrides: [
            sessionServiceProvider.overrideWithValue(mockService),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
        );

        container.read(appStateProvider.notifier).login();
        expect(container.read(appStateProvider).isLoggedIn, isTrue);
        expect(mockAuthRepo.signOutCalled, isFalse);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SessionRevocationListener(child: Text('Protected Home')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Protected Home'), findsOneWidget);

        // 1. Session doc exists initially
        sessionController.add(
          MockSessionDocSnapshot(
            exists: true,
            sessionData: {'isActive': true, 'isBlocked': false},
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(mockAuthRepo.signOutCalled, isFalse);
        expect(container.read(appStateProvider).isLoggedIn, isTrue);

        // 2. Session doc is subsequently deleted (revoked remotely)
        sessionController.add(MockSessionDocSnapshot(exists: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // MUST sign out now
        expect(mockAuthRepo.signOutCalled, isTrue);
        expect(container.read(appStateProvider).isLoggedIn, isFalse);

        await sessionController.close();
        await blockedController.close();
        container.dispose();
      },
    );

    testWidgets(
      'SessionRevocationListener DOES sign the user out if session doc first exists and is subsequently marked isActive: false',
      (tester) async {
        SessionRevocationListener.testUidOverride = 'test_race_user_3';

        final sessionController =
            StreamController<SessionDocSnapshot?>.broadcast();
        final blockedController = StreamController<bool>.broadcast();
        final mockAuthRepo = MockAuthRepository();

        final mockService = TestSessionService(
          sessionStreamController: sessionController,
          blockedStreamController: blockedController,
        );

        final container = ProviderContainer(
          overrides: [
            sessionServiceProvider.overrideWithValue(mockService),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
          ],
        );

        container.read(appStateProvider.notifier).login();
        expect(container.read(appStateProvider).isLoggedIn, isTrue);
        expect(mockAuthRepo.signOutCalled, isFalse);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SessionRevocationListener(child: Text('Protected Home')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Protected Home'), findsOneWidget);

        // 1. Session doc exists and is active initially
        sessionController.add(
          MockSessionDocSnapshot(
            exists: true,
            sessionData: {'isActive': true, 'isBlocked': false},
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(mockAuthRepo.signOutCalled, isFalse);
        expect(container.read(appStateProvider).isLoggedIn, isTrue);

        // 2. Session doc is marked inactive
        sessionController.add(
          MockSessionDocSnapshot(
            exists: true,
            sessionData: {'isActive': false, 'isBlocked': false},
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // MUST sign out now
        expect(mockAuthRepo.signOutCalled, isTrue);
        expect(container.read(appStateProvider).isLoggedIn, isFalse);

        await sessionController.close();
        await blockedController.close();
        container.dispose();
      },
    );
  });
}
