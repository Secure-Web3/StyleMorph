import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/theme_provider.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/unsaved_changes_dialog.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  bool saveCalled = false;

  _TestAppStateNotifier([AppState? initial]) : super() {
    if (initial != null) {
      state = initial;
    }
  }

  @override
  Future<void> loadProfileFromFirestore() async {}

  @override
  Future<bool> saveProfileToFirestore() async {
    saveCalled = true;
    state = state.copyWith(hasUnsavedProfileChanges: false);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  group('AppState Unsaved Changes Unit Tests', () {
    test('Initial AppState hasUnsavedChanges is false', () {
      const state = AppState();
      expect(state.hasUnsavedChanges, isFalse);
      expect(state.hasUnsavedProfileChanges, isFalse);
    });

    test(
      'markDirty, clearDirty, and setHasUnsavedChanges manipulate state correctly',
      () {
        final notifier = AppStateNotifier();
        expect(notifier.state.hasUnsavedChanges, isFalse);

        notifier.markDirty();
        expect(notifier.state.hasUnsavedChanges, isTrue);

        notifier.clearDirty();
        expect(notifier.state.hasUnsavedChanges, isFalse);

        notifier.setHasUnsavedChanges(true);
        expect(notifier.state.hasUnsavedChanges, isTrue);

        notifier.setHasUnsavedChanges(false);
        expect(notifier.state.hasUnsavedChanges, isFalse);
      },
    );

    test('Sub-tab edits automatically set hasUnsavedChanges to true', () {
      final notifier = AppStateNotifier();
      expect(notifier.state.hasUnsavedChanges, isFalse);

      notifier.updateIdentityField('firstName', 'Ali');
      expect(notifier.state.hasUnsavedChanges, isTrue);

      notifier.clearDirty();
      expect(notifier.state.hasUnsavedChanges, isFalse);

      notifier.updateAiDnaField('height', '180');
      expect(notifier.state.hasUnsavedChanges, isTrue);

      notifier.clearDirty();
      notifier.setFashionThemePalette('obsidian');
      expect(notifier.state.hasUnsavedChanges, isTrue);
    });
  });

  group('UnsavedChangesDialog Widget Tests', () {
    Widget buildDialogTestWidget({Locale locale = const Locale('fa')}) {
      return ProviderScope(
        overrides: [
          themeProvider.overrideWith((ref) => ThemeNotifier()),
          localeProvider.overrideWith((ref) => LocaleNotifier()),
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
          home: const Scaffold(body: Center(child: UnsavedChangesDialog())),
        ),
      );
    }

    testWidgets('Renders UnsavedChangesDialog with 3 actions in Persian', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildDialogTestWidget(locale: const Locale('fa')),
      );
      await tester.pumpAndSettle();

      expect(find.text('تغییرات ذخیره‌نشده'), findsOneWidget);
      expect(
        find.text(
          'تغییراتی در فرم ایجاد کرده‌اید که هنوز ذخیره نشده‌اند. مایلید تغییرات را ذخیره کنید یا نادیده بگیرید؟',
        ),
        findsOneWidget,
      );
      expect(find.text('ذخیره و ادامه'), findsOneWidget);
      expect(find.text('خروج بدون ذخیره'), findsOneWidget);
      expect(find.text('انصراف'), findsOneWidget);
    });

    testWidgets('Renders UnsavedChangesDialog with 3 actions in English', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildDialogTestWidget(locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('Save & Continue'), findsOneWidget);
      expect(find.text('Discard & Leave'), findsOneWidget);
      expect(find.text('Stay / Cancel'), findsOneWidget);
    });

    testWidgets(
      'Tapping Discard & Leave dismisses dialog with discardAndLeave action',
      (tester) async {
        UnsavedChangesAction? returnedAction;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              themeProvider.overrideWith((ref) => ThemeNotifier()),
              localeProvider.overrideWith((ref) => LocaleNotifier()),
            ],
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('fa'),
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
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      returnedAction = await UnsavedChangesDialog.show(context);
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(UnsavedChangesDialog), findsOneWidget);

        await tester.tap(find.text('خروج بدون ذخیره'));
        await tester.pumpAndSettle();

        expect(find.byType(UnsavedChangesDialog), findsNothing);
        expect(returnedAction, UnsavedChangesAction.discardAndLeave);
      },
    );
  });

  group('Profile Sub-Tab Switch Guard Tests', () {
    Widget buildProfileTestWidget({required _TestAppStateNotifier notifier}) {
      return ProviderScope(
        overrides: [
          appStateProvider.overrideWith((ref) => notifier),
          themeProvider.overrideWith((ref) => ThemeNotifier()),
          localeProvider.overrideWith((ref) => LocaleNotifier()),
        ],
        child: MaterialApp(
          theme: testTheme,
          locale: const Locale('fa'),
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
          home: const Scaffold(body: ProfileTab()),
        ),
      );
    }

    testWidgets(
      'When hasUnsavedChanges is true, switching sub-tab triggers confirmation dialog',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final notifier = _TestAppStateNotifier(
          const AppState(
            currentTab: AppTab.profile,
            currentProfileTab: 'p-identity',
            hasUnsavedProfileChanges: true,
            preferences: UserPreferences(appMode: 'advanced'),
          ),
        );

        await tester.pumpWidget(buildProfileTestWidget(notifier: notifier));
        await tester.pumpAndSettle();

        // Tap on Settings tab in sidebar
        final settingsTab = find.text('تنظیمات');
        expect(settingsTab, findsOneWidget);

        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Unsaved Changes dialog must appear
        expect(find.byType(UnsavedChangesDialog), findsOneWidget);
        expect(find.text('تغییرات ذخیره‌نشده'), findsOneWidget);

        // Tap Discard & Leave
        await tester.tap(find.text('خروج بدون ذخیره'));
        await tester.pumpAndSettle();

        // Dialog is dismissed and tab is switched to settings
        expect(find.byType(UnsavedChangesDialog), findsNothing);
        expect(notifier.state.currentProfileTab, 'p-settings');
        expect(notifier.state.hasUnsavedChanges, isFalse);
      },
    );

    testWidgets(
      'When hasUnsavedChanges is false, switching sub-tab proceeds directly without dialog',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final notifier = _TestAppStateNotifier(
          const AppState(
            currentTab: AppTab.profile,
            currentProfileTab: 'p-identity',
            hasUnsavedProfileChanges: false,
            preferences: UserPreferences(appMode: 'advanced'),
          ),
        );

        await tester.pumpWidget(buildProfileTestWidget(notifier: notifier));
        await tester.pumpAndSettle();

        final settingsTab = find.text('تنظیمات');
        expect(settingsTab, findsOneWidget);

        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // No confirmation dialog shown
        expect(find.byType(UnsavedChangesDialog), findsNothing);
        expect(notifier.state.currentProfileTab, 'p-settings');
      },
    );
  });
}
