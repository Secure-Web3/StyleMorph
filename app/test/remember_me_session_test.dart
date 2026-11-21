import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/session_persistence_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_switch.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionPersistenceService Tests', () {
    test(
      'SessionPersistenceService defaults to true for Remember Me',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = SessionPersistenceService();

        final initial = await service.getRememberMe();
        expect(initial, isTrue);
      },
    );

    test(
      'SessionPersistenceService sets and reads rememberMe correctly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = SessionPersistenceService();

        await service.setRememberMe(false);
        expect(await service.getRememberMe(), isFalse);

        await service.setRememberMe(true);
        expect(await service.getRememberMe(), isTrue);
      },
    );

    test(
      'SessionPersistenceService applyPersistence updates local storage flag',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = SessionPersistenceService();

        await service.applyPersistence(false);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(SessionPersistenceService.keyRememberMe), isFalse);

        await service.applyPersistence(true);
        expect(prefs.getBool(SessionPersistenceService.keyRememberMe), isTrue);
      },
    );

    test(
      'checkAndClearNonPersistentSessionOnStartup handles uninitialized Firebase safely',
      () async {
        SharedPreferences.setMockInitialValues({
          SessionPersistenceService.keyRememberMe: false,
        });
        final service = SessionPersistenceService();
        // Should not throw even if Firebase.apps is empty in test runner
        expect(
          () => service.checkAndClearNonPersistentSessionOnStartup(),
          returnsNormally,
        );
      },
    );
  });

  group('Remember Me Localization & State Tests', () {
    test('AppStrings provides correct authRememberMe in all 4 languages', () {
      expect(AppStrings('fa').authRememberMe, equals('مرا به خاطر بسپار'));
      expect(AppStrings('en').authRememberMe, equals('Remember Me'));
      expect(AppStrings('ar').authRememberMe, equals('تذكرني'));
      expect(AppStrings('tr').authRememberMe, equals('Beni hatırla'));
    });

    test(
      'AuthFormState defaults rememberMe to true and copyWith modifies it',
      () {
        const state = AuthFormState();
        expect(state.rememberMe, isTrue);

        final modified = state.copyWith(rememberMe: false);
        expect(modified.rememberMe, isFalse);

        final restored = modified.copyWith(rememberMe: true);
        expect(restored.rememberMe, isTrue);
      },
    );
  });

  group('AuthScreen Remember Me UI Tests', () {
    testWidgets(
      'AuthScreen renders Remember Me checkbox defaulted to true and toggles on tap',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: const Locale('en'),
              home: const Scaffold(body: AuthScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Remember Me checkbox tile is rendered
        final checkboxFinder = find.byType(AppCheckboxTile);
        expect(checkboxFinder, findsOneWidget);

        final tile = tester.widget<AppCheckboxTile>(checkboxFinder);
        expect(tile.label, equals('Remember Me'));
        expect(tile.value, isTrue);

        // Tap on the checkbox tile to toggle
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();

        final updatedTile = tester.widget<AppCheckboxTile>(checkboxFinder);
        expect(updatedTile.value, isFalse);
      },
    );
  });
}
