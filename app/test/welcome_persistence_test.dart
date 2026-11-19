import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/welcome_persistence_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/auth/presentation/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('First-Run Only WelcomeScreen Persistence Tests', () {
    test('WelcomePersistenceService defaults to false and sets has_seen_welcome to true',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = WelcomePersistenceService();

      final initial = await service.hasSeenWelcome();
      expect(initial, isFalse);

      await service.setHasSeenWelcome();

      final afterSet = await service.hasSeenWelcome();
      expect(afterSet, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(WelcomePersistenceService.keyHasSeenWelcome), isTrue);
    });

    test('HasSeenWelcomeNotifier reads from service and marks seen reactively',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = WelcomePersistenceService();
      final notifier = HasSeenWelcomeNotifier(service);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.value, isFalse);

      await notifier.markSeen();
      expect(notifier.state.value, isTrue);

      final isSaved = await service.hasSeenWelcome();
      expect(isSaved, isTrue);
    });

    testWidgets('Tapping Get Started on WelcomeScreen marks has_seen_welcome as true',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fa')],
            locale: const Locale('fa'),
            home: const WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('fa');
      final getStartedButton = find.text(strings.authGetStarted);
      expect(getStartedButton, findsOneWidget);

      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();

      // Verify that hasSeenWelcome is now true
      final hasSeen = container.read(hasSeenWelcomeProvider).value;
      expect(hasSeen, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(WelcomePersistenceService.keyHasSeenWelcome), isTrue);

      // Verify that navigation replaced WelcomeScreen with AuthScreen
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });
}
