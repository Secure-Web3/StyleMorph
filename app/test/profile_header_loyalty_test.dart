import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/services/loyalty_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/widgets/loyalty_rank_modal.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {}

  @override
  Future<bool> saveProfileToFirestore() async {
    state = state.copyWith(hasUnsavedProfileChanges: false);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_theme_palette': 'editorial',
      'user_theme_mode': 'light',
      'app_language_code': 'en',
    });
  });

  group('LoyaltyService and StylePoints Calculations', () {
    test('calculateStylePoints follows transparent formula', () {
      // 1. Profile progress 50% = 150 pts
      // 2. Verified email = 100 pts
      // 3. 2 referrals = 300 pts
      // 4. 5 AI sessions = 50 pts
      // 5. 250 coins = 25 pts
      // Total = 150 + 100 + 300 + 50 + 25 = 625 pts
      final points = LoyaltyService.calculateStylePoints(
        profileProgress: 0.5,
        isEmailVerified: true,
        referralCount: 2,
        aiUsageCount: 5,
        coinActivity: 250,
      );
      expect(points, equals(625));
    });

    test('getRank correctly maps StylePoints to 4 progressive ranks', () {
      expect(LoyaltyService.getRank(0), equals(LoyaltyRank.bronze));
      expect(LoyaltyService.getRank(499), equals(LoyaltyRank.bronze));
      expect(LoyaltyService.getRank(500), equals(LoyaltyRank.silver));
      expect(LoyaltyService.getRank(1499), equals(LoyaltyRank.silver));
      expect(LoyaltyService.getRank(1500), equals(LoyaltyRank.gold));
      expect(LoyaltyService.getRank(3999), equals(LoyaltyRank.gold));
      expect(LoyaltyService.getRank(4000), equals(LoyaltyRank.diamond));
      expect(LoyaltyService.getRank(10000), equals(LoyaltyRank.diamond));
    });

    test('calculateProgressToNextRank calculates exact progression', () {
      // Bronze (0 - 500 threshold): at 250 pts = 50%
      expect(
        LoyaltyService.calculateProgressToNextRank(250),
        closeTo(0.5, 0.001),
      );

      // Silver (500 - 1500 threshold): at 1000 pts = 50%
      expect(
        LoyaltyService.calculateProgressToNextRank(1000),
        closeTo(0.5, 0.001),
      );

      // Diamond: max tier returns 1.0
      expect(LoyaltyService.calculateProgressToNextRank(4500), equals(1.0));
    });
  });

  group('Weighted Profile Completion Formula', () {
    test('40% Anatomy, 35% Media, 25% Identity', () {
      // 1. Empty profile has 0 score
      final emptyScore = AppStateNotifier.calculateProfileProgress(
        identity: const {},
        aiDna: const {},
        mediaSlots: const {},
      );
      expect(emptyScore, equals(0.0));

      // 2. All 9 identity fields filled = exactly 0.25 (25%)
      final identityFullScore = AppStateNotifier.calculateProfileProgress(
        identity: {
          'email': 'user@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'nick': 'johnd',
          'mobile': '+123456789',
          'nid': '1234567890',
          'dob': '1995-01-01',
          'city': 'Paris',
          'address': '123 Rue de la Mode',
        },
        aiDna: const {},
        mediaSlots: const {},
      );
      expect(identityFullScore, closeTo(0.25, 0.001));

      // 3. All 12 anatomy fields filled = exactly 0.40 (40%)
      final anatomyFullScore = AppStateNotifier.calculateProfileProgress(
        identity: const {},
        aiDna: {
          'gender': 'Male',
          'height': '180',
          'weight': '75',
          'shoulder': '44',
          'chest': '96',
          'waist': '80',
          'belly': '82',
          'hips': '98',
          'skinTone': 'fair',
          'bodyShape': 'athletic',
          'faceShape': 'oval',
          'hair': 'brown',
        },
        mediaSlots: const {},
      );
      expect(anatomyFullScore, closeTo(0.40, 0.001));

      // 4. Privacy avatar mode with 2 face slots = exactly 0.35 (35%)
      final mediaPrivacyScore = AppStateNotifier.calculateProfileProgress(
        identity: const {},
        aiDna: const {},
        personaMode: 'privacy_avatar',
        mediaSlots: {
          'front_face': 'https://example.com/face.jpg',
          'side_face': 'https://example.com/side.jpg',
        },
      );
      expect(mediaPrivacyScore, closeTo(0.35, 0.001));

      // 5. Full body mode with 4 required + 3 optional = exactly 0.35 (35%)
      final mediaFullBodyScore = AppStateNotifier.calculateProfileProgress(
        identity: const {},
        aiDna: const {},
        personaMode: 'full_body',
        mediaSlots: {
          'front_face': 'https://example.com/1.jpg',
          'side_face': 'https://example.com/2.jpg',
          'body_front': 'https://example.com/3.jpg',
          'body_side': 'https://example.com/4.jpg',
          'body_back': 'https://example.com/5.jpg',
          'hand_skin': 'https://example.com/6.jpg',
          'scan_360': 'https://example.com/7.jpg',
        },
      );
      expect(mediaFullBodyScore, closeTo(0.35, 0.001));

      // 6. Complete profile = 1.0 (100%)
      final fullScore = AppStateNotifier.calculateProfileProgress(
        identity: {
          'email': 'user@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'nick': 'johnd',
          'mobile': '+123456789',
          'nid': '1234567890',
          'dob': '1995-01-01',
          'city': 'Paris',
          'address': '123 Rue de la Mode',
        },
        aiDna: {
          'gender': 'Male',
          'height': '180',
          'weight': '75',
          'shoulder': '44',
          'chest': '96',
          'waist': '80',
          'belly': '82',
          'hips': '98',
          'skinTone': 'fair',
          'bodyShape': 'athletic',
          'faceShape': 'oval',
          'hair': 'brown',
        },
        personaMode: 'privacy_avatar',
        mediaSlots: {
          'front_face': 'https://example.com/face.jpg',
          'side_face': 'https://example.com/side.jpg',
        },
      );
      expect(fullScore, closeTo(1.0, 0.001));
    });
  });

  group('UserPreferences showEmailInHeader', () {
    test('defaults to false and round-trips toMap/fromMap', () {
      const prefs = UserPreferences();
      expect(prefs.showEmailInHeader, isFalse);

      final updated = prefs.copyWith(showEmailInHeader: true);
      expect(updated.showEmailInHeader, isTrue);

      final map = updated.toMap();
      expect(map['showEmailInHeader'], isTrue);

      final reconstructed = UserPreferences.fromMap(map);
      expect(reconstructed.showEmailInHeader, isTrue);
    });
  });

  group('MainHeader Widget Redesign', () {
    Widget buildHeaderHarness(AppState state) {
      return ProviderScope(
        key: UniqueKey(),
        overrides: [
          appStateProvider.overrideWith((ref) => _TestAppStateNotifier(state)),
        ],
        child: MaterialApp(
          theme: testTheme,
          locale: const Locale('en'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(appBar: const MainHeader(), body: Container()),
        ),
      );
    }

    testWidgets('Lv1 badge and Basic verification text are removed', (
      tester,
    ) async {
      final state = AppState(
        isLoggedIn: true,
        currentTab: AppTab.profile,
        userName: 'Elena Rostova',
        userHandle: '@elena',
        userLevel: 1,
        stylePoints: 120,
        loyaltyRank: 'Bronze',
        preferences: const UserPreferences(showEmailInHeader: false),
        identityValues: const {'email': 'elena@example.com'},
      );

      await tester.pumpWidget(buildHeaderHarness(state));
      await tester.pumpAndSettle();

      // Lv1 badge is removed
      expect(find.text('Lv1'), findsNothing);

      // "Basic verification" text is removed
      expect(find.textContaining('Basic verification'), findsNothing);
      expect(find.textContaining('تأیید پایه'), findsNothing);
    });

    testWidgets('Tappable Loyalty Rank & Points badge is displayed', (
      tester,
    ) async {
      final state = AppState(
        isLoggedIn: true,
        currentTab: AppTab.profile,
        userName: 'Elena Rostova',
        userHandle: '@elena',
        stylePoints: 120,
        loyaltyRank: 'Bronze',
      );

      await tester.pumpWidget(buildHeaderHarness(state));
      await tester.pumpAndSettle();

      // Finds the Rank and Points text badge (e.g., Bronze • 120 pts)
      expect(find.textContaining('Bronze • 120 pts'), findsOneWidget);
    });

    testWidgets('Header respects showEmailInHeader toggle and omits handle', (
      tester,
    ) async {
      // 1. When showEmailInHeader is false: email and handle are NOT shown (clean vertically centered name)
      final stateEmailOff = AppState(
        isLoggedIn: true,
        currentTab: AppTab.profile,
        userName: 'Elena Rostova',
        userHandle: '@elena',
        preferences: const UserPreferences(showEmailInHeader: false),
        identityValues: const {'email': 'elena@stylemorph.com'},
      );

      await tester.pumpWidget(buildHeaderHarness(stateEmailOff));
      await tester.pumpAndSettle();

      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('elena@stylemorph.com'), findsNothing);
      expect(find.text('@elena'), findsNothing);

      // 2. When showEmailInHeader is true: email IS shown beneath name
      final stateEmailOn = AppState(
        isLoggedIn: true,
        currentTab: AppTab.profile,
        userName: 'Elena Rostova',
        userHandle: '@elena',
        preferences: const UserPreferences(showEmailInHeader: true),
        identityValues: const {'email': 'elena@stylemorph.com'},
      );

      await tester.pumpWidget(buildHeaderHarness(stateEmailOn));
      await tester.pumpAndSettle();

      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('elena@stylemorph.com'), findsOneWidget);
      expect(find.text('@elena'), findsNothing);
    });

    testWidgets(
      'Profile completion section has no Basic (Free) plan chip and expands across width',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          currentTab: AppTab.profile,
          profileProgress: 0.75,
        );

        await tester.pumpWidget(buildHeaderHarness(state));
        await tester.pumpAndSettle();

        // "Basic (Free)" plan chip is completely removed
        expect(find.text('Basic (Free)'), findsNothing);
        expect(find.text('عادی (رایگان)'), findsNothing);

        // Contains loyalty rank badge, percentage, and "Complete" button
        expect(find.textContaining('Bronze'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
      },
    );

    testWidgets('Tapping Rank badge opens LoyaltyModalSheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = AppState(
        isLoggedIn: true,
        currentTab: AppTab.profile,
        userName: 'Elena Rostova',
        stylePoints: 120,
        loyaltyRank: 'Bronze',
      );

      await tester.pumpWidget(buildHeaderHarness(state));
      await tester.pumpAndSettle();

      final badgeFinder = find.textContaining('Bronze • 120 pts');
      expect(badgeFinder, findsOneWidget);

      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();

      // Loyalty modal sheet is open and displays title and sections
      expect(find.byType(LoyaltyModalSheet), findsOneWidget);
      expect(find.text('Loyalty Rank & StylePoints'), findsOneWidget);
      expect(find.text('How to Earn StylePoints'), findsOneWidget);
      expect(find.text('Loyalty Rank Perks'), findsOneWidget);
    });
  });
}
