import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/profile/presentation/widgets/legal_doc_modal_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({Locale locale = const Locale('en')}) {
    return ProviderScope(
      child: MaterialApp(
        theme: testTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('fa'),
          Locale('ar'),
          Locale('tr'),
        ],
        locale: locale,
        home: const Scaffold(body: AuthScreen()),
      ),
    );
  }

  group('AuthScreen Legal Footer Links & Read-Only Preview Tests', () {
    testWidgets(
      'renders all 3 legal links in footer above copyright text in LTR and RTL',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. English (LTR)
        await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('auth_footer_legal_terms')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('auth_footer_legal_privacy')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('auth_footer_legal_info')), findsOneWidget);
        expect(find.text('StyleMorph 2026 ©'), findsOneWidget);

        // Verify Terms link label in English
        expect(find.text('Terms'), findsOneWidget);
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('Legal Info'), findsOneWidget);

        // 2. Persian (RTL)
        await tester.pumpWidget(buildTestApp(locale: const Locale('fa')));
        await tester.pumpAndSettle();

        expect(find.text('شرایط استفاده'), findsOneWidget);
        expect(find.text('حریم خصوصی'), findsOneWidget);
        expect(find.text('مشخصات حقوقی'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Terms link opens v2.0 modal on tab 0 in pure read-only preview mode',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final termsLink = find.byKey(const Key('auth_footer_legal_terms'));
        expect(termsLink, findsOneWidget);

        await tester.tap(termsLink);
        await tester.pumpAndSettle();

        // Verify LegalDocModalSheet is opened
        expect(find.byType(LegalDocModalSheet), findsOneWidget);

        // Verify read-only preview constraints:
        // - NO agreement checkbox
        // - NO sign button
        // - NO electronic audit receipt
        // - Only Close button is rendered
        expect(find.byKey(const Key('agreement_checkbox')), findsNothing);
        expect(find.byKey(const Key('agreement_sign_button')), findsNothing);
        expect(
          find.byKey(const Key('agreement_audit_receipt_card')),
          findsNothing,
        );
        expect(find.text('Close'), findsOneWidget);

        // Tap Close to dismiss
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocModalSheet), findsNothing);
      },
    );

    testWidgets(
      'tapping Privacy link opens v2.0 modal on tab 1 in pure read-only preview mode',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final privacyLink = find.byKey(const Key('auth_footer_legal_privacy'));
        expect(privacyLink, findsOneWidget);

        await tester.tap(privacyLink);
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocModalSheet), findsOneWidget);
        expect(find.byKey(const Key('agreement_checkbox')), findsNothing);
        expect(find.byKey(const Key('agreement_sign_button')), findsNothing);
        expect(find.text('Close'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocModalSheet), findsNothing);
      },
    );

    testWidgets(
      'tapping Legal Info link opens v2.0 modal on tab 2 in pure read-only preview mode',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final legalInfoLink = find.byKey(const Key('auth_footer_legal_info'));
        expect(legalInfoLink, findsOneWidget);

        await tester.tap(legalInfoLink);
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocModalSheet), findsOneWidget);
        expect(find.byKey(const Key('agreement_checkbox')), findsNothing);
        expect(find.byKey(const Key('agreement_sign_button')), findsNothing);
        expect(find.text('Close'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocModalSheet), findsNothing);
      },
    );
  });
}
