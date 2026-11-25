import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_logo.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/auth/presentation/welcome_screen.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/widgets/about_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/anatomy_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lightTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );
  final darkTheme = AppTheme.buildTheme(
    palette: AppPalette.obsidian,
    isDark: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_theme_palette': 'editorial',
      'user_theme_mode': 'light',
      'app_language_code': 'fa',
    });
  });

  Widget wrapApp({
    required Widget child,
    ThemeData? theme,
    Locale locale = const Locale('fa'),
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MaterialApp(
        theme: theme ?? lightTheme,
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
        home: child,
      ),
    );
  }

  group('Part 1 UI & Brand Polish Tests', () {
    testWidgets(
      'AppLogo renders official SM monogram Image.asset in light, dark, and overlay modes',
      (tester) async {
        for (final entry in <(ThemeData, AppLogoVariant)>[
          (lightTheme, AppLogoVariant.auto),
          (darkTheme, AppLogoVariant.auto),
          (darkTheme, AppLogoVariant.overlay),
        ]) {
          await tester.pumpWidget(
            wrapApp(
              theme: entry.$1,
              child: Scaffold(
                body: Center(child: AppLogo(size: 56, variant: entry.$2)),
              ),
            ),
          );
          await tester.pump();

          final imageFinder = find.descendant(
            of: find.byType(AppLogo),
            matching: find.byType(Image),
          );
          expect(imageFinder, findsOneWidget);
          final image = tester.widget<Image>(imageFinder);
          expect(image.image, isA<AssetImage>());
          expect(
            (image.image as AssetImage).assetName,
            equals(AppLogo.assetPath),
          );
          expect(
            find.descendant(
              of: find.byType(AppLogo),
              matching: find.byType(CustomPaint),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'AboutSubTab, WelcomeScreen, AppDrawer, and AuthScreen modes render AppLogo without legacy wand emblem',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // 1. AboutSubTab
        await tester.pumpWidget(
          wrapApp(
            overrides: [
              appStateProvider.overrideWith(
                (ref) =>
                    _TestAppStateNotifier(const AppState(isLoggedIn: true)),
              ),
            ],
            child: const Scaffold(
              body: SingleChildScrollView(child: AboutSubTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppLogo), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is FaIcon &&
                w.icon?.codePoint ==
                    FontAwesomeIcons.wandMagicSparkles.codePoint,
          ),
          findsNothing,
        );

        // 2. WelcomeScreen
        await tester.pumpWidget(wrapApp(child: const WelcomeScreen()));
        await tester.pump();
        expect(find.byType(AppLogo), findsOneWidget);

        // 3. AppDrawer
        await tester.pumpWidget(
          wrapApp(
            overrides: [
              appStateProvider.overrideWith(
                (ref) =>
                    _TestAppStateNotifier(const AppState(isLoggedIn: true)),
              ),
            ],
            child: const Scaffold(body: AppDrawer()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppLogo), findsOneWidget);

        // 4. AuthScreen (Sign In, Sign Up, Reset Password)
        for (final mode in AuthMode.values) {
          await tester.pumpWidget(wrapApp(child: const AuthScreen()));
          await tester.pump();
          final container = ProviderScope.containerOf(
            tester.element(find.byType(AuthScreen)),
          );
          container.read(authFormProvider.notifier).setMode(mode);
          await tester.pumpAndSettle();
          expect(find.byType(AppLogo), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'IdentitySubTab renders full minimum legal age text cleanly without ellipsis truncation',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final localeCode in ['fa', 'en', 'ar', 'tr']) {
          final strings = AppStrings(localeCode);
          await tester.pumpWidget(
            wrapApp(
              locale: Locale(localeCode),
              child: const Scaffold(
                body: SingleChildScrollView(child: IdentitySubTab()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final ageTextFinder = find.text(strings.idDobAgeRequirement);
          expect(ageTextFinder, findsOneWidget);

          final textWidget = tester.widget<Text>(ageTextFinder);
          expect(textWidget.softWrap, isTrue);
          expect(textWidget.overflow, isNot(equals(TextOverflow.ellipsis)));
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'AnatomySubTab renders all measurement labels cleanly on narrow 360px mobile viewport without overflow or ellipsis',
      (tester) async {
        // Simulate mobile/compact width (480px -> 448px content width, triggers <460px 2-column layout in Layer 3)
        await tester.binding.setSurfaceSize(const Size(480, 2800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final localeCode in ['fa', 'en', 'ar', 'tr']) {
          final strings = AppStrings(localeCode);
          await tester.pumpWidget(
            wrapApp(
              locale: Locale(localeCode),
              overrides: [
                appStateProvider.overrideWith(
                  (ref) => _TestAppStateNotifier(
                    const AppState(
                      isLoggedIn: true,
                      preferences: UserPreferences(appMode: 'advanced'),
                    ),
                  ),
                ),
              ],
              child: const Scaffold(
                body: SingleChildScrollView(child: AnatomySubTab()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final labels = [
            strings.aiShoulder,
            strings.aiChest,
            strings.aiWaist,
            strings.aiBelly,
            strings.aiHips,
            strings.aiSleeve,
            strings.aiInseam,
            strings.aiNeck,
            strings.aiShoeSize,
          ];

          for (final label in labels) {
            final labelFinder = find.text(label);
            expect(labelFinder, findsOneWidget);
            final textWidget = tester.widget<Text>(labelFinder);
            expect(textWidget.overflow, isNot(equals(TextOverflow.ellipsis)));
            expect(textWidget.softWrap, isTrue);
          }
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
