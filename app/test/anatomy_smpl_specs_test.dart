import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/widgets/anatomy_sub_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }
}

void main() {
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
          appStateProvider.overrideWith((ref) => _TestAppStateNotifier(initialState)),
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

  group('Anatomy & DNA Specs Sub-Tab Tests (Task 19)', () {
    testWidgets('Renders all 4 SMPL AI layers and anthropometric header in Persian', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        aiDnaValues: {
          'gender': 'female',
          'height': '170',
          'weight': '60',
        },
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const AnatomySubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Layer 1: Biometrics Header & Gender Selector
      expect(find.text('پایه بیومتریک و فرم اندام'), findsOneWidget);
      expect(find.text('زنانه'), findsOneWidget);
      expect(find.text('مردانه'), findsOneWidget);
      expect(find.text('غیردوگانه / خنثی'), findsOneWidget);

      // Live BMI Badge (60 / (1.7^2) ~ 20.8 -> Normal)
      expect(find.textContaining('شاخص توده بدنی (BMI)'), findsOneWidget);
      expect(find.textContaining('نرمال و متناسب'), findsOneWidget);

      // Layer 1: Female-tailored silhouettes
      expect(find.text('ساعت شنی'), findsOneWidget);
      expect(find.text('گلابی / مثلثی'), findsOneWidget);
      expect(find.text('سیب / گرد'), findsOneWidget);

      // Layer 2: Colorimetry
      expect(find.text('رنگ‌شناسی و مشخصات ظاهری'), findsOneWidget);
      expect(find.text('تناژ پوست (فیتزپاتریک I–VI)'), findsOneWidget);
      expect(find.text('ته‌رنگ پوست (Undertone)'), findsOneWidget);
      expect(find.text('گرم (Warm)'), findsOneWidget);
      expect(find.text('سرد (Cool)'), findsOneWidget);
      expect(find.text('خنثی (Neutral)'), findsOneWidget);
      expect(find.text('رنگ چشم'), findsOneWidget);

      // Layer 3: Anthropometric Fit Dimensions Section
      expect(find.text('ابعاد کلیدی تناسب و پرو مجازی'), findsOneWidget);
      // Ensure legacy "Tailoring & Try-On Measurements" title is completely removed
      expect(find.text('اندازه‌های دقیق خیاطی و پرو (Tailoring)'), findsNothing);

      // Linear and peripheral anthropometrics
      expect(find.text('عرض شانه (cm)'), findsOneWidget);
      expect(find.text('دور سینه (cm)'), findsOneWidget);
      expect(find.text('دور کمر (cm)'), findsOneWidget);
      expect(find.text('دور شکم (cm)'), findsOneWidget);
      expect(find.text('دور باسن (cm)'), findsOneWidget);
      expect(find.text('قد آستین (cm)'), findsOneWidget);
      expect(find.text('قد فاق تا مچ (cm)'), findsOneWidget);
      expect(find.text('دور طوق گردن (cm)'), findsOneWidget);
      expect(find.text('سایز کفش (EU / US)'), findsOneWidget);

      // Bra Size is VISIBLE because gender is 'female'
      expect(find.text('سایز سوتین (ویژه بانوان)'), findsOneWidget);

      // Layer 4: Fit Preference
      expect(find.text('سلیقه تن‌خور و استایل لباس'), findsOneWidget);
      expect(find.text('جذب / فیت اندامی'), findsOneWidget);
      expect(find.text('استاندارد / کلاسیک'), findsOneWidget);
      expect(find.text('آزاد / اورسایز'), findsOneWidget);
    });

    testWidgets('Conditional Bra Size is hidden when gender is male', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        aiDnaValues: {
          'gender': 'male',
          'height': '182',
          'weight': '80',
        },
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const AnatomySubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Male silhouettes shown
      expect(find.text('ذوزنقه‌ای متوازن'), findsOneWidget);
      expect(find.text('بیضی'), findsWidgets);

      // Bra Size must NOT be rendered for Male
      expect(find.text('سایز سوتین (ویژه بانوان)'), findsNothing);
    });

    testWidgets('English localization renders correctly without hardcoded Persian strings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        aiDnaValues: {
          'gender': 'female',
          'height': '165',
          'weight': '55',
        },
      );

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('en'),
          initialState: state,
          child: const AnatomySubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Headers & Section Titles
      expect(find.text('Biometric Base & Silhouette'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Non-Binary'), findsOneWidget);

      // BMI badge in English
      expect(find.textContaining('Body Mass Index (BMI)'), findsOneWidget);
      expect(find.textContaining('Normal'), findsOneWidget);

      // Silhouettes in English
      expect(find.text('Hourglass'), findsOneWidget);
      expect(find.text('Pear / Triangle'), findsOneWidget);

      // Visual specs in English
      expect(find.text('Visual & Colorimetry Specs'), findsOneWidget);
      expect(find.text('Fitzpatrick Skin Tone (I–VI)'), findsOneWidget);
      expect(find.text('Skin Undertone'), findsOneWidget);
      expect(find.text('Warm'), findsOneWidget);
      expect(find.text('Cool'), findsOneWidget);
      expect(find.text('Neutral'), findsOneWidget);

      // Anthropometric Header in English
      expect(find.text('Anthropometric Fit Dimensions'), findsOneWidget);
      expect(find.text('Tailoring & Try-On Measurements'), findsNothing);

      // Fields in English
      expect(find.text('Shoulder Width (cm)'), findsOneWidget);
      expect(find.text('Chest / Bust (cm)'), findsOneWidget);
      expect(find.text('Waist (cm)'), findsOneWidget);
      expect(find.text('Abdomen (cm)'), findsOneWidget);
      expect(find.text('Hips (cm)'), findsOneWidget);
      expect(find.text('Sleeve Length (cm)'), findsOneWidget);
      expect(find.text('Inseam Length (cm)'), findsOneWidget);
      expect(find.text('Neck Circumference (cm)'), findsOneWidget);
      expect(find.text('Shoe Size (EU / US)'), findsOneWidget);
      expect(find.text('Bra Size (Female)'), findsOneWidget);

      // Fit preference in English
      expect(find.text('Garment Fit Preference'), findsOneWidget);
      expect(find.text('Slim Fit'), findsOneWidget);
      expect(find.text('Regular Fit'), findsOneWidget);
      expect(find.text('Relaxed / Oversized'), findsOneWidget);

      // Verify no mixed Persian leaked into English mode
      expect(find.text('داده‌های خیاطی'), findsNothing);
      expect(find.text('زنانه (Female)'), findsNothing);
      expect(find.text('مردانه (Male)'), findsNothing);
    });

    testWidgets('Tapping gender option updates state dynamically', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        aiDnaValues: {
          'gender': 'male',
          'height': '175',
          'weight': '70',
        },
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const AnatomySubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially male, so Bra Size is hidden
      expect(find.text('سایز سوتین (ویژه بانوان)'), findsNothing);

      // Tap 'Female' ('زنانه')
      await tester.tap(find.text('زنانه'));
      await tester.pumpAndSettle();

      // Now Bra Size becomes visible
      expect(find.text('سایز سوتین (ویژه بانوان)'), findsOneWidget);
    });
  });
}
