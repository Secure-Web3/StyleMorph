import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/welcome_persistence_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/domain/auth_repository.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/auth/presentation/welcome_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _AlwaysSuccessAuthFormNotifier extends AuthFormNotifier {
  _AlwaysSuccessAuthFormNotifier(super.repo, super.ref);

  @override
  Future<bool> login() async => true;

  @override
  Future<bool> signup() async => true;

  @override
  Future<bool> signInWithGoogle() async => true;
}

Widget _wrapWithApp({
  required ProviderContainer container,
  required Widget home,
}) {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: testTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fa')],
      locale: const Locale('en'),
      home: home,
    ),
  );
}

void main() {
  group('Firestore Rules & Auth Provisioning Alignment', () {
    test(
      'firestore.rules hasValidSessionOnSelf safely handles null resource',
      () {
        final rulesFile = File('../firestore.rules');
        expect(
          rulesFile.existsSync(),
          isTrue,
          reason: 'firestore.rules must exist at repository root',
        );
        final content = rulesFile.readAsStringSync();
        expect(
          content.contains('resource == null'),
          isTrue,
          reason:
              'hasValidSessionOnSelf must guard resource == null so new users can read/create users/{uid}',
        );
      },
    );
  });

  group('WelcomeScreen -> AuthScreen Navigation Stack', () {
    testWidgets(
      'Tapping Get Started preserves root route and successful login pops AuthScreen',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer(
          overrides: [
            authFormProvider.overrideWith(
              (ref) =>
                  _AlwaysSuccessAuthFormNotifier(_FakeAuthRepository(), ref),
            ),
          ],
        );

        await tester.pumpWidget(
          _wrapWithApp(
            container: container,
            home: Consumer(
              builder: (context, ref, _) {
                final hasSeen =
                    ref.watch(hasSeenWelcomeProvider).value ?? false;
                return hasSeen
                    ? const Scaffold(body: Text('ROOT_GATE_SHELL'))
                    : const WelcomeScreen();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final strings = AppStrings('en');
        await tester.tap(find.text(strings.authGetStarted));
        await tester.pumpAndSettle();

        // AuthScreen should be pushed on top of the root route (not replacing it).
        expect(find.byType(AuthScreen), findsOneWidget);
        final authContext = tester.element(find.byType(AuthScreen));
        expect(Navigator.of(authContext).canPop(), isTrue);

        // Trigger login on AuthScreen and verify it pops back to the root route.
        final signInButton = find.text(strings.authLoginBtn).last;
        await tester.ensureVisible(signInButton);
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        expect(find.byType(AuthScreen), findsNothing);
        expect(find.text('ROOT_GATE_SHELL'), findsOneWidget);

        container.dispose();
      },
    );
  });
}
