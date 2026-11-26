import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/widgets/turnstile_skeleton.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  group('Turnstile Shimmer Skeleton Tests', () {
    test(
      'AppStrings provides correct authTurnstileChecking in all 4 languages',
      () {
        expect(
          AppStrings('fa').authTurnstileChecking,
          equals('در حال بررسی امنیتی...'),
        );
        expect(
          AppStrings('en').authTurnstileChecking,
          equals('Performing security check...'),
        );
        expect(
          AppStrings('ar').authTurnstileChecking,
          equals('جارٍ التحقق من الأمان...'),
        );
        expect(
          AppStrings('tr').authTurnstileChecking,
          equals('Güvenlik kontrolü yapılıyor...'),
        );
      },
    );

    testWidgets(
      'TurnstileSkeleton renders with exact 65px height, shield icon, and localized text',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: const Locale('en'),
            home: const Scaffold(
              body: Center(child: TurnstileSkeleton(width: 300, height: 65)),
            ),
          ),
        );

        // Verify the widget is rendered
        final skeletonFinder = find.byType(TurnstileSkeleton);
        expect(skeletonFinder, findsOneWidget);

        // Verify exact dimensions (300 x 65) to guarantee zero layout shift
        final renderBox = tester.renderObject(skeletonFinder) as RenderBox;
        expect(renderBox.size.width, equals(300.0));
        expect(renderBox.size.height, equals(65.0));

        // Verify compact loading spinner is present
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify localized checking text is present
        expect(find.text('Performing security check...'), findsOneWidget);

        // Pump animation forward to verify smooth pulsing
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(TurnstileSkeleton), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(TurnstileSkeleton), findsOneWidget);
      },
    );

    testWidgets(
      'TurnstileSkeleton renders in Persian with RTL directionality and Persian text',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fa'), Locale('en')],
            locale: const Locale('fa'),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Center(child: TurnstileSkeleton(width: 300, height: 65)),
              ),
            ),
          ),
        );

        expect(find.text('در حال بررسی امنیتی...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
