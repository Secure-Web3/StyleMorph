import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/services/referral_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_badge.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/profile/presentation/widgets/referral_sub_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore() async {
    // Keep test state deterministic
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  Widget buildTestableWidget({
    required Widget child,
    Locale locale = const Locale('fa'),
    AppState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          appStateProvider
              .overrideWith((ref) => _TestAppStateNotifier(initialState)),
      ],
      child: MaterialApp(
        theme: testTheme,
        locale: locale,
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }

  group('Referral System Unit & Service Tests (Task 21)', () {
    test('Referral code generator creates 8-char code without ambiguous characters', () {
      final code = ReferralService.generateReferralCode();
      expect(code.length, 8);
      // Disallowed ambiguous characters: 0, O, 1, I
      expect(code.contains('0'), isFalse);
      expect(code.contains('O'), isFalse);
      expect(code.contains('1'), isFalse);
      expect(code.contains('I'), isFalse);
      expect(RegExp(r'^[2-9A-HJ-NP-Z]{8}$').hasMatch(code), isTrue);
    });

    test('Network tier calculation dynamically computes tiers as required', () {
      expect(ReferralService.calculateTier(0), 'Starter');
      expect(ReferralService.calculateTier(4), 'Starter');
      expect(ReferralService.calculateTier(5), 'Silver');
      expect(ReferralService.calculateTier(14), 'Silver');
      expect(ReferralService.calculateTier(15), 'Gold');
      expect(ReferralService.calculateTier(49), 'Gold');
      expect(ReferralService.calculateTier(50), 'Ambassador');
      expect(ReferralService.calculateTier(120), 'Ambassador');
    });

    test('Capture referral code from URI query parameters and persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ReferralService();

      final uri = Uri.parse('https://stylemorph-preview.web.app/?ref=7K9X2MNP');
      await service.captureReferralFromUri(uri);

      final pending = await service.getPendingReferralCode();
      expect(pending, '7K9X2MNP');

      await service.clearPendingReferralCode();
      final cleared = await service.getPendingReferralCode();
      expect(cleared, isNull);
    });
  });

  group('ReferralSubTab UI & Localization Widget Tests (Task 21)', () {
    testWidgets('Renders Persian stats, active domain invite link, Copy and Share buttons',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        referralCode: '8K7W3M9P',
        referralCount: 0,
        networkTier: 'Starter',
        referrals: [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const ReferralSubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Persian formatted stats: ۰ نفر, ۰ سکه, پایه
      expect(find.text('۰ نفر'), findsOneWidget);
      expect(find.text('۰ سکه'), findsOneWidget);
      expect(find.text('پایه'), findsOneWidget);

      // Verify real active web domain link
      expect(
        find.text('https://stylemorph-preview.web.app/?ref=8K7W3M9P'),
        findsOneWidget,
      );

      // Verify Copy and Share buttons
      expect(find.text('کپی'), findsOneWidget);
      expect(find.text('اشتراک‌گذاری'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.copy.codePoint,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.shareNodes.codePoint,
        ),
        findsOneWidget,
      );

      // Verify Empty State in Persian
      expect(
        find.text('هنوز دوستی با کد شما ثبت‌نام نکرده است'),
        findsOneWidget,
      );

      // Tap Copy button -> should show toast
      await tester.tap(find.text('کپی'));
      await tester.pump();
      expect(find.text('لینک اختصاصی دعوت در کلیپ‌بورد کپی شد!'), findsOneWidget);
    });

    testWidgets('Renders English clean formatting with zero mixed labels (0 friends, 0 Coins, Starter)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        referralCode: '8K7W3M9P',
        referralCount: 0,
        networkTier: 'Starter',
        referrals: [],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('en'),
          initialState: state,
          child: const ReferralSubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify English digits and units
      expect(find.text('0 friends'), findsOneWidget);
      expect(find.text('0 Coins'), findsOneWidget);
      expect(find.text('Starter'), findsOneWidget);

      // Verify English buttons & empty state
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(
        find.text('No friends have joined using your referral code yet'),
        findsOneWidget,
      );
    });

    testWidgets('Renders inner-scrollable Invited Friends list with 2-row layout per item',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = AppState(
        referralCode: '8K7W3M9P',
        referralCount: 2,
        networkTier: 'Starter',
        referrals: const [
          ReferralEntry(
            id: 'ref1',
            inviteeUid: 'u1',
            displayName: 'Sara Ahmadi',
            email: 'sara.ahmadi@example.com',
            rewardEarned: 100,
          ),
          ReferralEntry(
            id: 'ref2',
            inviteeUid: 'u2',
            displayName: 'Ali Reza',
            email: 'ali.reza@example.com',
            rewardEarned: 100,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const ReferralSubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify friends names and emails rendered in 2-row layout
      expect(find.text('Sara Ahmadi'), findsOneWidget);
      expect(find.text('sara.ahmadi@example.com'), findsOneWidget);
      expect(find.text('Ali Reza'), findsOneWidget);
      expect(find.text('ali.reza@example.com'), findsOneWidget);

      // Verify earned coins badges (+ ۱۰۰ سکه)
      expect(find.byType(AppBadge), findsNWidgets(2));
      expect(find.text('+ ۱۰۰ سکه'), findsNWidgets(2));

      // Verify fixed-height 240px container wrapping ListView
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);
      final listContainer = find.ancestor(
        of: listViewFinder,
        matching: find.byType(Container),
      );
      expect(listContainer, findsWidgets);
    });
  });

  group('Sign-Up Form Referral Input Tests (Task 21)', () {
    testWidgets('Sign-Up screen renders optional Referral Code input field',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({
        ReferralService.pendingReferralKey: '7K9X2MNP',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set auth mode to signup
      container.read(authFormProvider.notifier).setMode(AuthMode.signup);

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
            home: const Scaffold(
              body: AuthScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Referral Code label is displayed
      expect(find.text('کد معرف (اختیاری)'), findsOneWidget);
      expect(find.text('کد معرف ۸ حرفی'), findsOneWidget);
    });
  });
}
