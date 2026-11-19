import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/widgets/camera_alignment_guide_dialog.dart';
import 'package:stylemorph/features/profile/presentation/widgets/media_sub_tab.dart';

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

  group('Media Sub-Tab Dual-Persona Architecture Unit Tests', () {
    test('calculateProfileProgress calculates Privacy Avatar mode correctly', () {
      final baseProgress = AppStateNotifier.calculateProfileProgress(
        identity: {'email': 'test@stylemorph.com'},
        aiDna: const {},
        personaMode: 'privacy_avatar',
        mediaSlots: const {},
      );
      // Email = 0.10, media = 0.0
      expect(baseProgress, closeTo(0.10, 0.001));

      // 1 slot uploaded in privacy_avatar mode (50% of 0.20 = 0.10)
      final p1 = AppStateNotifier.calculateProfileProgress(
        identity: {'email': 'test@stylemorph.com'},
        aiDna: const {},
        personaMode: 'privacy_avatar',
        mediaSlots: {'front_face': 'https://firebasestorage.com/front.jpg'},
      );
      expect(p1, closeTo(0.20, 0.001));

      // Both required slots uploaded in privacy_avatar mode (100% of 0.20 = 0.20)
      final p2 = AppStateNotifier.calculateProfileProgress(
        identity: {'email': 'test@stylemorph.com'},
        aiDna: const {},
        personaMode: 'privacy_avatar',
        mediaSlots: {
          'front_face': 'https://firebasestorage.com/front.jpg',
          'side_face': 'https://firebasestorage.com/side.jpg',
        },
      );
      expect(p2, closeTo(0.30, 0.001));
    });

    test('calculateProfileProgress calculates Full Real-Body mode correctly', () {
      final baseProgress = AppStateNotifier.calculateProfileProgress(
        identity: {'email': 'test@stylemorph.com'},
        aiDna: const {},
        personaMode: 'full_body',
        mediaSlots: const {},
      );
      expect(baseProgress, closeTo(0.10, 0.001));

      // 4 required slots (full 0.15 score)
      final pReq = AppStateNotifier.calculateProfileProgress(
        identity: {'email': 'test@stylemorph.com'},
        aiDna: const {},
        personaMode: 'full_body',
        mediaSlots: {
          'front_face': 'url1',
          'side_face': 'url2',
          'body_front': 'url3',
          'body_side': 'url4',
        },
      );
      expect(pReq, closeTo(0.25, 0.001));

      // Plus all 3 optional slots (full 0.05 score) -> 0.10 + 0.15 + 0.05 = 0.30
      final pAll = AppStateNotifier.calculateProfileProgress(
        identity: {'email': 'test@stylemorph.com'},
        aiDna: const {},
        personaMode: 'full_body',
        mediaSlots: {
          'front_face': 'url1',
          'side_face': 'url2',
          'body_front': 'url3',
          'body_side': 'url4',
          'body_back': 'url5',
          'hand_skin': 'url6',
          'scan_360': 'url7',
        },
      );
      expect(pAll, closeTo(0.30, 0.001));
    });

    test('AppStateNotifier updates personaMode and mediaSlots dynamically', () {
      final notifier = _TestAppStateNotifier(const AppState(
        identityValues: {'email': 'test@stylemorph.com'},
        profileProgress: 0.10,
      ));
      expect(notifier.state.personaMode, 'full_body');

      notifier.setPersonaMode('privacy_avatar');
      expect(notifier.state.personaMode, 'privacy_avatar');
      expect(notifier.state.hasUnsavedProfileChanges, isTrue);

      notifier.updateMediaSlot('front_face', 'https://storage/face.jpg');
      expect(notifier.state.mediaSlots['front_face'], 'https://storage/face.jpg');
      expect(notifier.state.profileProgress, greaterThan(0.10));

      notifier.deleteMediaSlot('front_face');
      expect(notifier.state.mediaSlots.containsKey('front_face'), isFalse);
    });
  });

  group('Media Sub-Tab Widget Tests', () {
    testWidgets('Renders all 7 slots in Full Real-Body Persona mode by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        personaMode: 'full_body',
        identityValues: {'email': 'user@stylemorph.com'},
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const MediaSubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Persona Mode Title & Options
      expect(find.text('حالت مدل‌سازی پرسونای هوش مصنوعی'), findsOneWidget);
      expect(find.text('پرسونای کامل اندام واقعی'), findsWidgets);
      expect(find.text('آواتار حریم خصوصی (چهره و مو)'), findsWidgets);

      // Check all 7 slot titles in Persian mode
      expect(find.text('چهره و مو از روبرو'), findsOneWidget);
      expect(find.text('نیمرخ چهره و مو (۹۰ درجه)'), findsOneWidget);
      expect(find.text('تمام‌قد روبرو (حالت A-Pose)'), findsOneWidget);
      expect(find.text('تمام‌قد نیمرخ (۹۰ درجه)'), findsOneWidget);
      expect(find.text('تمام‌قد از پشت سر'), findsOneWidget);
      expect(find.text('کلوزآپ دست و رنگ پوست'), findsOneWidget);
      expect(find.text('اسکن ویدیویی ۳۶۰ درجه بدن'), findsOneWidget);

      // Check required & optional badges
      expect(find.text('الزامی'), findsNWidgets(4));
      expect(find.text('اختیاری'), findsNWidgets(2));
      expect(find.text('پیشرفته (PRO)'), findsOneWidget);
    });

    testWidgets('Renders only 2 required slots in Privacy Avatar mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        personaMode: 'privacy_avatar',
        identityValues: {'email': 'user@stylemorph.com'},
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const MediaSubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Check mode description is rendered
      expect(
        find.text('بدون نیاز به عکس قدی؛ چهره و موی شما با مانکن سه‌بعدی آناتومی ترکیب می‌شود.'),
        findsOneWidget,
      );

      // Check only the 2 face & hair slots exist
      expect(find.text('چهره و مو از روبرو'), findsOneWidget);
      expect(find.text('نیمرخ چهره و مو (۹۰ درجه)'), findsOneWidget);

      // Verify full body slots and 360 scan are completely hidden
      expect(find.text('تمام‌قد روبرو (حالت A-Pose)'), findsNothing);
      expect(find.text('تمام‌قد نیمرخ (۹۰ درجه)'), findsNothing);
      expect(find.text('اسکن ویدیویی ۳۶۰ درجه بدن'), findsNothing);
    });

    testWidgets('English localization renders correctly without hardcoded Persian strings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        personaMode: 'full_body',
        identityValues: {'email': 'user@stylemorph.com'},
      );

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('en'),
          initialState: state,
          child: const MediaSubTab(),
        ),
      );
      await tester.pumpAndSettle();

      // English titles & modes
      expect(find.text('AI Persona Modeling Architecture'), findsOneWidget);
      expect(find.text('Full Real-Body Persona'), findsWidgets);
      expect(find.text('Privacy Face & Hair Avatar'), findsWidgets);

      // English slots
      expect(find.text('Front Face & Hair'), findsOneWidget);
      expect(find.text('Side Profile Face & Hair (90°)'), findsOneWidget);
      expect(find.text('Full Body Front (A-Pose)'), findsOneWidget);
      expect(find.text('Full Body Side Profile (90°)'), findsOneWidget);
      expect(find.text('Full Body Back View'), findsOneWidget);
      expect(find.text('Hand & Skin Tone Close-up'), findsOneWidget);
      expect(find.text('360° Body Scan Video'), findsOneWidget);

      // Badges
      expect(find.text('Required'), findsNWidgets(4));
      expect(find.text('Optional'), findsNWidgets(2));
      expect(find.text('Advanced (PRO)'), findsOneWidget);

      // Confirm no Persian strings leaked in English mode
      expect(find.text('در انتظار بارگذاری'), findsNothing);
      expect(find.text('الزامی'), findsNothing);
    });

    testWidgets('CameraAlignmentGuideDialog renders pose instructions and Ready button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('en'),
          child: const CameraAlignmentGuideDialog(
            slotKey: 'body_front',
            slotTitle: 'Full Body Front (A-Pose)',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pose & Alignment Guide'), findsOneWidget);
      expect(find.text('Full Body Front (A-Pose)'), findsOneWidget);
      expect(
        find.text('Stand in standard A-Pose (arms 30° from body, feet shoulder-width).'),
        findsOneWidget,
      );
      expect(find.text('Ready to Capture'), findsOneWidget);

      await tester.tap(find.text('Ready to Capture'));
      await tester.pumpAndSettle();
    });
  });
}
