import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/loyalty_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/auth_view.dart';
import 'package:stylemorph/features/profile/presentation/widgets/ai_dna_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/gallery_sub_tab.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {}

  @override
  Future<bool> saveProfileToFirestore() async => true;
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
    AppStrings.clearDynamicOverrides();
  });

  tearDown(() {
    AppStrings.clearDynamicOverrides();
  });

  Widget createTestApp({
    AppState? initialState,
    Locale locale = const Locale('en'),
    Widget? child,
  }) {
    final notifier = _TestAppStateNotifier(initialState ?? const AppState());

    return ProviderScope(
      overrides: [appStateProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        theme: testTheme,
        locale: locale,
        supportedLocales: const [
          Locale('en'),
          Locale('fa'),
          Locale('ar'),
          Locale('tr'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child ?? const SizedBox.shrink()),
      ),
    );
  }

  group('Task 28: Final Codebase Audit & Zero Duplication', () {
    test(
      'Zero Duplication: Aliases cleanly point to canonical implementations',
      () {
        expect(const AuthView(), isA<AuthScreen>());
        expect(const AiDnaSubTab(), isA<AnatomySubTab>());
        expect(const GallerySubTab(), isA<MediaSubTab>());
      },
    );

    test('100% Real Profile Progress: Zero baseline on empty profile', () {
      final progress = AppStateNotifier.calculateProfileProgress(
        identity: {},
        aiDna: {},
        personaMode: 'full_body',
        mediaSlots: {},
      );
      expect(progress, equals(0.0));
    });

    test(
      '100% Real Profile Progress: Accurately computes weighted completion without fake numbers',
      () {
        // Identity 9 fields = 25%
        // Anatomy 12 fields = 40%
        // Media 4 req = 25%, 3 opt = 10%
        final fullProgress = AppStateNotifier.calculateProfileProgress(
          identity: {
            'email': 'user@example.com',
            'firstName': 'John',
            'lastName': 'Doe',
            'nick': 'johndoe',
            'mobile': '+12025550199',
            'nid': '1234567890',
            'dob': '1995-05-15',
            'country': 'United States',
            'address': '123 Main St',
          },
          aiDna: {
            'gender': 'male',
            'height': '180',
            'weight': '75',
            'shoulder': '45',
            'chest': '98',
            'waist': '82',
            'belly': '80',
            'hips': '96',
            'skinTone': 'type_3',
            'bodyShape': 'inverted_triangle',
            'faceShape': 'oval',
            'hair': 'black_wavy',
          },
          personaMode: 'full_body',
          mediaSlots: {
            'front_face': 'https://storage.googleapis.com/face.jpg',
            'side_face': 'https://storage.googleapis.com/side.jpg',
            'body_front': 'https://storage.googleapis.com/front.jpg',
            'body_side': 'https://storage.googleapis.com/bside.jpg',
            'body_back': 'https://storage.googleapis.com/back.jpg',
            'hand_skin': 'https://storage.googleapis.com/hand.jpg',
            'scan_360': 'https://storage.googleapis.com/scan.mp4',
          },
        );
        expect(fullProgress, closeTo(1.0, 0.001));
      },
    );

    test(
      'Loyalty Points: Computed mathematically from real metrics with zero fake bonuses',
      () {
        final pointsZero = LoyaltyService.calculateStylePoints(
          profileProgress: 0.0,
          isEmailVerified: false,
          referralCount: 0,
          aiUsageCount: 0,
          coinActivity: 0,
        );
        expect(pointsZero, equals(0));
        expect(LoyaltyService.getRank(pointsZero), equals(LoyaltyRank.bronze));

        final pointsActive = LoyaltyService.calculateStylePoints(
          profileProgress: 0.8,
          isEmailVerified: true,
          referralCount: 5,
          aiUsageCount: 12,
          coinActivity: 250,
        );
        // 0.8 * 300 = 240
        // verified = 100
        // referrals = 5 * 150 = 750
        // ai = 12 * 10 = 120
        // coin = 250 ~/ 10 = 25
        // Total = 240 + 100 + 750 + 120 + 25 = 1235 => Silver Tier (500-1499)
        expect(pointsActive, equals(1235));
        expect(
          LoyaltyService.getRank(pointsActive),
          equals(LoyaltyRank.silver),
        );
      },
    );
  });

  group('Task 28: Database-Driven Localization Compliance', () {
    test('Resolves newUser localized string across all 4 locales', () {
      expect(const AppStrings('en').newUser, equals('New User'));
      expect(const AppStrings('fa').newUser, equals('کاربر جدید'));
      expect(const AppStrings('ar').newUser, equals('مستخدم جديد'));
      expect(const AppStrings('tr').newUser, equals('Yeni Kullanıcı'));
    });

    test(
      'Dynamic database translation overrides seamlessly override static dictionary',
      () {
        const stringsEn = AppStrings('en');
        expect(stringsEn.get('appName'), equals('StyleMorph'));

        // Inject dynamic override from remote database / config
        AppStrings.setDynamicOverrides('en', {
          'appName': 'StyleMorph Studio AI',
          'customPromotionBanner': 'Seasonal Fashion Week Live!',
        });

        expect(stringsEn.get('appName'), equals('StyleMorph Studio AI'));
        expect(
          stringsEn.resolveKey('customPromotionBanner'),
          equals('Seasonal Fashion Week Live!'),
        );

        // Clearing overrides restores canonical dictionary
        AppStrings.clearDynamicOverrides();
        expect(stringsEn.get('appName'), equals('StyleMorph'));
      },
    );

    test('resolveKey cleanly falls back without UI code changes', () {
      const stringsFa = AppStrings('fa');
      expect(
        stringsFa.resolveKey(
          'unregisteredFutureKey',
          fallback: 'پیش‌فرض داینامیک',
        ),
        equals('پیش‌فرض داینامیک'),
      );
    });

    testWidgets(
      'MainHeader renders localized fallback for new user without hardcoded string',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            initialState: const AppState(
              userName: '',
              userHandle: '',
              currentTab: AppTab.profile,
            ),
            locale: const Locale('en'),
            child: const MainHeader(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('New User'), findsOneWidget);
        expect(find.text('کاربر جدید'), findsNothing);
      },
    );

    testWidgets(
      'MainHeader renders Persian localized fallback when locale is fa',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            initialState: const AppState(
              userName: '',
              userHandle: '',
              currentTab: AppTab.profile,
            ),
            locale: const Locale('fa'),
            child: const MainHeader(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('کاربر جدید'), findsOneWidget);
      },
    );
  });
}
