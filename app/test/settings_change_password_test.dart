import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/theme_provider.dart';
import 'package:stylemorph/core/widgets/app_button.dart';
import 'package:stylemorph/core/widgets/app_text_field.dart';
import 'package:stylemorph/features/profile/presentation/widgets/change_password_dialog.dart';
import 'package:stylemorph/features/profile/presentation/widgets/settings_sub_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore() async {}
}

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  Widget buildTestWidget({
    required Widget child,
    Locale locale = const Locale('fa'),
    AppState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          appStateProvider.overrideWith(
            (ref) => _TestAppStateNotifier(initialState),
          ),
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
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('SettingsSubTab Change Password Tile Tests', () {
    testWidgets(
      'renders Change Password tile in Persian and opens dialog on tap',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildTestWidget(
            child: const SettingsSubTab(),
            locale: const Locale('fa'),
          ),
        );
        await tester.pumpAndSettle();

        // Find Change Password tile
        expect(find.text('تغییر رمز عبور'), findsOneWidget);
        expect(find.text('به‌روزرسانی رمز عبور ورود به حساب'), findsOneWidget);

        // Tap Change Password tile
        await tester.tap(find.text('تغییر رمز عبور'));
        await tester.pumpAndSettle();

        // ChangePasswordDialog is now open
        expect(find.byType(ChangePasswordDialog), findsOneWidget);
      },
    );

    testWidgets('renders Change Password tile in English', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(
          child: const SettingsSubTab(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Update your account login password'), findsOneWidget);
    });
  });

  group('ChangePasswordDialog Email/Password Flow Tests', () {
    testWidgets('renders fields, live strength bar, and handles validation', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const ChangePasswordDialog(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify fields
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(
        find.text('Forgot current password? Send reset link to email'),
        findsOneWidget,
      );

      // Find text fields
      final textFields = find.byType(AppTextField);
      expect(textFields, findsNWidgets(3));

      // Attempt submit without filling fields
      final updateButton = find.widgetWithText(AppButton, 'Update Password');
      expect(updateButton, findsOneWidget);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Enter your current password'), findsWidgets);
      expect(
        find.text('Password must be at least 8 characters long.'),
        findsOneWidget,
      );

      // Enter short new password and mismatching confirm password
      await tester.enterText(textFields.at(0), 'oldpassword123');
      await tester.enterText(textFields.at(1), 'short');
      await tester.enterText(textFields.at(2), 'mismatch');
      await tester.pumpAndSettle();

      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters long.'),
        findsOneWidget,
      );
      expect(
        find.text('New password and confirmation do not match.'),
        findsOneWidget,
      );

      // Enter matching strong password (>= 8 chars with letters & numbers)
      await tester.enterText(textFields.at(1), 'NewPass12345!');
      await tester.enterText(textFields.at(2), 'NewPass12345!');
      await tester.pumpAndSettle();

      // Error clears
      expect(
        find.text('Password must be at least 8 characters long.'),
        findsNothing,
      );
      expect(
        find.text('New password and confirmation do not match.'),
        findsNothing,
      );
    });
  });
}
