import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/services/referral_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/widgets/referral_sub_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {
    // Keep test state deterministic
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Referral OAuth & Startup Capture Tests', () {
    test(
      'captureReferralFromUri captures ?ref=CODE and normalizes to uppercase',
      () async {
        final service = ReferralService();
        final uri = Uri.parse('https://app.stylemorph.style/?ref=xyz123ab');
        await service.captureReferralFromUri(uri);

        final storedCode = await service.getPendingReferralCode();
        expect(storedCode, 'XYZ123AB');

        await service.clearPendingReferralCode();
        final afterClear = await service.getPendingReferralCode();
        expect(afterClear, isNull);
      },
    );

    test('captureReferralFromUri captures /r/CODE path format', () async {
      final service = ReferralService();
      final uri = Uri.parse('https://app.stylemorph.style/r/99abcdef');
      await service.captureReferralFromUri(uri);

      final storedCode = await service.getPendingReferralCode();
      expect(storedCode, '99ABCDEF');
    });

    test('captureReferralFromUri captures ?refCode=CODE format', () async {
      final service = ReferralService();
      final uri = Uri.parse('https://app.stylemorph.style/?refCode=pro45678');
      await service.captureReferralFromUri(uri);

      final storedCode = await service.getPendingReferralCode();
      expect(storedCode, 'PRO45678');
    });

    test(
      'Empty or missing ref in URI does not overwrite existing code',
      () async {
        final service = ReferralService();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ReferralService.pendingReferralKey, 'EXISTING8');

        final uri = Uri.parse('https://app.stylemorph.style/');
        await service.captureReferralFromUri(uri);

        final storedCode = await service.getPendingReferralCode();
        expect(storedCode, 'EXISTING8');
      },
    );

    test(
      'applyReferralOnSignUp returns false when code or uid is empty',
      () async {
        final service = ReferralService();
        final res1 = await service.applyReferralOnSignUp(
          newUserUid: '',
          newEmail: 'test@example.com',
          referralCode: 'XYZ12345',
        );
        expect(res1, isFalse);

        final res2 = await service.applyReferralOnSignUp(
          newUserUid: 'user_123',
          newEmail: 'test@example.com',
          referralCode: '   ',
        );
        expect(res2, isFalse);
      },
    );

    test('applyReferralOnSignUp gracefully handles null firestore', () async {
      final service = ReferralService();
      final res = await service.applyReferralOnSignUp(
        newUserUid: 'user_123',
        newEmail: 'test@example.com',
        referralCode: 'XYZ12345',
      );
      expect(res, isFalse);
    });
  });

  group('ReferralSubTab Live Stream & Display Widget Tests', () {
    testWidgets(
      'ReferralSubTab displays initial and live updated referrals seamlessly',
      (tester) async {
        final initialReferrals = [
          ReferralEntry(
            id: 'ref_1',
            inviteeUid: 'uid_friend_1',
            displayName: 'Friend One',
            email: 'friend1@example.com',
            rewardEarned: 0,
            createdAt: DateTime(2026, 11, 24),
          ),
        ];

        final initialState = AppState(
          referralCode: 'MYREF123',
          referrals: initialReferrals,
          referralCount: 1,
          networkTier: 'Starter',
        );

        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(
              (ref) => _TestAppStateNotifier(initialState),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('fa'),
              supportedLocales: const [Locale('fa'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(body: ReferralSubTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Friend One is shown
        expect(find.text('Friend One'), findsOneWidget);
        expect(find.text('friend1@example.com'), findsOneWidget);

        // Simulate live arrival of newly joined friend via stream/updateReferralData
        final updatedList = [
          ...initialReferrals,
          ReferralEntry(
            id: 'ref_2',
            inviteeUid: 'uid_friend_2',
            displayName: 'Friend Two',
            email: 'friend2@example.com',
            rewardEarned: 0,
            createdAt: DateTime(2026, 11, 24, 12, 0),
          ),
        ];

        container
            .read(appStateProvider.notifier)
            .setReferralData(referrals: updatedList);
        await tester.pumpAndSettle();

        // Verify Friend Two appears immediately without page reload
        expect(find.text('Friend Two'), findsOneWidget);
        expect(find.text('friend2@example.com'), findsOneWidget);
        expect(container.read(appStateProvider).referralCount, 2);
      },
    );

    test(
      'captureReferralFromUri captures #/?ref=CODE from hash fragment URL',
      () async {
        final service = ReferralService();
        final uri = Uri.parse(
          'https://stylemorph-preview.web.app/#/?ref=9q7kbzkd',
        );
        await service.captureReferralFromUri(uri);

        final storedCode = await service.getPendingReferralCode();
        expect(storedCode, '9Q7KBZKD');
      },
    );

    testWidgets(
      'ReferralSubTab renders compact tap-to-copy 8-char code box without separate copy button',
      (tester) async {
        String? clipboardText;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.setData') {
                final args = call.arguments as Map<dynamic, dynamic>;
                clipboardText = args['text']?.toString();
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        final initialState = const AppState(
          referralCode: '9Q7KBZKD',
          referrals: [],
          referralCount: 0,
          networkTier: 'Starter',
        );

        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(
              (ref) => _TestAppStateNotifier(initialState),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('fa'),
              supportedLocales: const [Locale('fa'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(body: ReferralSubTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final codeFinder = find.text('9Q7KBZKD');
        expect(codeFinder, findsOneWidget);

        // No separate copy icon button should exist
        expect(find.byIcon(Icons.copy), findsNothing);
        expect(find.byIcon(Icons.content_copy), findsNothing);

        // Tapping the code box itself copies the 8-char code to clipboard
        await tester.tap(codeFinder);
        await tester.pump();
        expect(clipboardText, '9Q7KBZKD');

        // Verify monospace Latin font is enforced on the code box
        final textWidget = tester.widget<Text>(codeFinder);
        expect(textWidget.style?.fontFamily, 'monospace');
      },
    );

    test(
      'ensureUserReferralCode returns existingCode consistently without regenerating',
      () async {
        final service = ReferralService();
        final first = await service.ensureUserReferralCode(
          'uid_abc',
          existingCode: '9q7kbzkd',
        );
        final second = await service.ensureUserReferralCode(
          'uid_abc',
          existingCode: '9q7kbzkd',
        );
        expect(first, '9Q7KBZKD');
        expect(second, '9Q7KBZKD');
      },
    );

    test(
      'ReferralEntry.toMap produces exact fields allowed by firestore.rules',
      () {
        final entry = ReferralEntry(
          id: 'invitee_1',
          inviteeUid: 'invitee_1',
          displayName: 'Alice',
          email: 'alice@example.com',
          rewardEarned: 0,
          createdAt: DateTime(2026, 11, 25),
        );
        final map = entry.toMap();
        expect(map['inviteeUid'], 'invitee_1');
        expect(map['rewardEarned'], 0);
        expect(map['displayName'], 'Alice');
        expect(map['email'], 'alice@example.com');
        expect(map.containsKey('createdAt'), isTrue);
      },
    );
  });
}
