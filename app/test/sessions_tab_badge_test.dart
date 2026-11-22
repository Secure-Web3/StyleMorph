import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/services/session_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore() async {
    // Keep initialState intact for deterministic tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  final mockSessions = [
    SessionInfo(
      sessionId: 'sess_1',
      deviceId: 'dev_1',
      deviceType: 'desktop_web',
      deviceName: 'Chrome on Windows',
      deviceModel: 'PC',
      platform: 'Web',
      osVersion: 'Windows 11',
      userAgent: 'Mozilla/5.0 Chrome',
      isActive: true,
      isBlocked: false,
      isPrimary: true,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    ),
    SessionInfo(
      sessionId: 'sess_2',
      deviceId: 'dev_2',
      deviceType: 'mobile',
      deviceName: 'Pixel 8',
      deviceModel: 'Pixel 8',
      platform: 'Android',
      osVersion: 'Android 14',
      userAgent: 'StyleMorph App',
      isActive: true,
      isBlocked: false,
      isPrimary: false,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    ),
  ];

  Widget buildTestableWidget({
    required Widget child,
    Locale locale = const Locale('fa'),
    List<SessionInfo>? sessions,
  }) {
    final state = const AppState(
      currentTab: AppTab.profile,
      currentProfileTab: 'p-identity',
      preferences: UserPreferences(appMode: 'advanced'),
    );

    return ProviderScope(
      overrides: [
        appStateProvider.overrideWith((ref) => _TestAppStateNotifier(state)),
        allSessionsProvider.overrideWith(
          (ref) => Stream.value(sessions ?? mockSessions),
        ),
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
        home: Scaffold(body: child),
      ),
    );
  }

  group('Sessions Sidebar Tab Icon & Badge Tests (Task 24)', () {
    testWidgets(
      'Renders standard Icons.devices_rounded and non-overlapping session badge in Persian',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildTestableWidget(
            locale: const Locale('fa'),
            child: const ProfileTab(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify standard Icons.devices_rounded icon is rendered
        final devicesIconFinder = find.byIcon(Icons.devices_rounded);
        expect(devicesIconFinder, findsOneWidget);

        // 2. Verify Persian session count numeral '۲' (2 active sessions)
        final badgeTextFinder = find.text('۲');
        expect(badgeTextFinder, findsOneWidget);

        // 3. Verify Non-overlapping geometry: badge must NOT overlap or obscure the icon
        final iconRect = tester.getRect(devicesIconFinder);
        final badgeRect = tester.getRect(badgeTextFinder);

        // The rect of the badge should not intersect the rect of the icon
        final overlaps = iconRect.overlaps(badgeRect);
        expect(
          overlaps,
          isFalse,
          reason: 'Badge ($badgeRect) must not overlap the icon ($iconRect)',
        );
      },
    );

    testWidgets('Renders standard icon and English session count numeral "2"', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('en'),
          child: const ProfileTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Icons.devices_rounded
      expect(find.byIcon(Icons.devices_rounded), findsOneWidget);

      // Verify English digit '2'
      final badgeTextFinder = find.text('2');
      expect(badgeTextFinder, findsOneWidget);

      // Verify no overlap
      final iconRect = tester.getRect(find.byIcon(Icons.devices_rounded));
      final badgeRect = tester.getRect(badgeTextFinder);
      expect(iconRect.overlaps(badgeRect), isFalse);
    });

    testWidgets('Does not render badge when active sessions count is zero', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableWidget(
          locale: const Locale('fa'),
          sessions: const [],
          child: const ProfileTab(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.devices_rounded), findsOneWidget);
      expect(find.text('۰'), findsNothing);
      expect(find.text('0'), findsNothing);
    });
  });
}
