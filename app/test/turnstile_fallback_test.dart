import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/features/auth/presentation/widgets/fallback_security_challenge.dart';

void main() {
  Widget buildTestableWidget({
    required ValueChanged<String> onVerified,
    FallbackChallengeController? controller,
    Locale locale = const Locale('fa'),
  }) {
    return MaterialApp(
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
        body: Center(
          child: FallbackSecurityChallenge(
            controller: controller,
            onVerified: onVerified,
          ),
        ),
      ),
    );
  }

  group('FallbackSecurityChallenge Tests', () {
    testWidgets(
      'renders fallback challenge layout with security icon and math question',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(onVerified: (_) {}, locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.security_rounded), findsOneWidget);
        expect(find.textContaining('+'), findsOneWidget);
      },
    );

    testWidgets(
      'solves challenge successfully with western digits and triggers onVerified',
      (tester) async {
        String? verifiedToken;
        await tester.pumpWidget(
          buildTestableWidget(
            onVerified: (token) => verifiedToken = token,
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        // Find the question text: e.g. "Security check: X + Y = ?"
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        final questionTextWidget = textWidgets.firstWhere(
          (t) => (t.data ?? '').contains('+'),
        );
        final questionText = questionTextWidget.data!;

        // Extract numbers from "Security check: X + Y = ?"
        final match = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(questionText)!;
        final a = int.parse(match.group(1)!);
        final b = int.parse(match.group(2)!);
        final answer = (a + b).toString();

        // Enter correct answer
        await tester.enterText(find.byType(TextField), answer);
        await tester.pumpAndSettle();

        expect(verifiedToken, isNotNull);
        expect(verifiedToken!.startsWith('local_fallback_challenge_'), isTrue);
        expect(find.text('Verified'), findsOneWidget);
      },
    );

    testWidgets('solves challenge successfully with Persian digits', (
      tester,
    ) async {
      String? verifiedToken;
      await tester.pumpWidget(
        buildTestableWidget(
          onVerified: (token) => verifiedToken = token,
          locale: const Locale('fa'),
        ),
      );
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final questionTextWidget = textWidgets.firstWhere(
        (t) => (t.data ?? '').contains('+'),
      );
      final questionText = questionTextWidget.data!;

      // In Persian, numbers can be Persian digits: ۰-۹
      final persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
      String normalizedQuestion = questionText;
      for (int i = 0; i < 10; i++) {
        normalizedQuestion = normalizedQuestion.replaceAll(
          persianDigits[i],
          '$i',
        );
      }

      final match = RegExp(
        r'(\d+)\s*\+\s*(\d+)',
      ).firstMatch(normalizedQuestion)!;
      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      final sum = a + b;

      // Convert sum to Persian string
      final sumStr = sum.toString();
      final persianSum = sumStr.split('').map((char) {
        final d = int.tryParse(char);
        return d != null ? persianDigits[d] : char;
      }).join();

      // Enter Persian answer
      await tester.enterText(find.byType(TextField), persianSum);
      await tester.pumpAndSettle();

      expect(verifiedToken, isNotNull);
      expect(verifiedToken!.startsWith('local_fallback_challenge_'), isTrue);
      expect(find.text('تایید شد'), findsOneWidget);
    });

    testWidgets(
      'controller.reset() resets verification state and clears input',
      (tester) async {
        final controller = FallbackChallengeController();
        String? verifiedToken;

        await tester.pumpWidget(
          buildTestableWidget(
            controller: controller,
            onVerified: (token) => verifiedToken = token,
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        final questionTextWidget = textWidgets.firstWhere(
          (t) => (t.data ?? '').contains('+'),
        );
        final match = RegExp(
          r'(\d+)\s*\+\s*(\d+)',
        ).firstMatch(questionTextWidget.data!)!;
        final a = int.parse(match.group(1)!);
        final b = int.parse(match.group(2)!);
        final answer = (a + b).toString();

        await tester.enterText(find.byType(TextField), answer);
        await tester.pumpAndSettle();
        expect(verifiedToken, isNotNull);
        expect(find.text('Verified'), findsOneWidget);

        // Trigger reset
        controller.reset();
        await tester.pumpAndSettle();

        // TextField should be empty again and question prompt visible
        expect(find.text('Verified'), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
      },
    );
  });
}
