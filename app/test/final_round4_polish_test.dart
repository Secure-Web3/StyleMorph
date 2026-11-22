import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/utils/digit_formatter.dart';
import 'package:stylemorph/core/widgets/app_toast.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/about_sub_tab.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore() async {}

  @override
  Future<bool> saveProfileToFirestore() async {
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

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_theme_palette': 'editorial',
      'user_theme_mode': 'light',
      'app_language_code': 'en',
    });
  });

  group('Final Round 4 Polish - Step 1: Sidebar Footer Anchoring', () {
    testWidgets(
      'Simple Mode anchors Settings & About to the bottom after Spacer',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = AppState(
          isLoggedIn: true,
          currentTab: AppTab.profile,
          currentProfileTab: 'p-identity',
          preferences: const UserPreferences(appMode: 'simple'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(state),
              ),
            ],
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('en'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(body: ProfileTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In Simple Mode, p-sessions is omitted from the sidebar
        expect(find.byKey(const Key('profile_nav_p-sessions')), findsNothing);
        expect(find.byKey(const Key('profile_nav_p-settings')), findsOneWidget);
        expect(find.byKey(const Key('profile_nav_p-about')), findsOneWidget);

        // Verify Column and Spacer exist in the sidebar
        expect(find.byType(Spacer), findsWidgets);
      },
    );

    testWidgets(
      'Advanced Mode retains Sessions, Settings & About at the bottom',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = AppState(
          isLoggedIn: true,
          currentTab: AppTab.profile,
          currentProfileTab: 'p-identity',
          preferences: const UserPreferences(appMode: 'advanced'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(state),
              ),
            ],
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('en'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(body: ProfileTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In Advanced Mode, all three bottom items exist
        expect(find.byKey(const Key('profile_nav_p-sessions')), findsOneWidget);
        expect(find.byKey(const Key('profile_nav_p-settings')), findsOneWidget);
        expect(find.byKey(const Key('profile_nav_p-about')), findsOneWidget);
        expect(find.byType(Spacer), findsWidgets);
      },
    );
  });

  group('Final Round 4 Polish - Step 2: MainHeader 2-Row Redesign', () {
    testWidgets(
      'Renders top row with avatar, name/email, notification bell & coins chip',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          currentTab: AppTab.profile,
          userName: 'Elena Rostova',
          loyaltyRank: 'Gold',
          stylePoints: 1850,
          coins: 250,
          showHeaderCoins: true,
          preferences: const UserPreferences(showEmailInHeader: true),
          identityValues: const {'email': 'elena@example.com'},
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(state),
              ),
            ],
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('en'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(
                appBar: MainHeader(),
                body: SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top row items
        expect(find.text('Elena Rostova'), findsOneWidget);
        expect(find.text('elena@example.com'), findsOneWidget);
        expect(
          find.byKey(const Key('header_notifications_bell')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('header_coins_chip')), findsOneWidget);

        // Bottom row items (Profile mode)
        expect(
          find.byKey(const Key('header_loyalty_rank_badge')),
          findsOneWidget,
        );
        expect(find.textContaining('Gold'), findsWidgets);
        expect(
          find.byKey(const Key('header_profile_progress_bar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('header_complete_profile_btn')),
          findsOneWidget,
        );
      },
    );
  });

  group('Final Round 4 Polish - Step 3: Semantic Capsule Toasts', () {
    testWidgets(
      'AppToast displays floating capsule for each semantic variant',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          AppToast.showSuccess(context, 'Success Saved!'),
                      child: const Text('Show Success'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          AppToast.showError(context, 'Error Occurred!'),
                      child: const Text('Show Error'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          AppToast.showWarning(context, 'Warning Caution!'),
                      child: const Text('Show Warning'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          AppToast.showInfo(context, 'Info Update!'),
                      child: const Text('Show Info'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Trigger success toast
        await tester.tap(find.text('Show Success'));
        await tester.pump();
        expect(find.text('Success Saved!'), findsOneWidget);
        expect(find.byKey(const Key('app_toast_capsule')), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        // Dismiss snackbar
        ScaffoldMessenger.of(
          tester.element(find.text('Success Saved!')),
        ).hideCurrentSnackBar();
        await tester.pumpAndSettle();

        // Trigger error toast
        await tester.tap(find.text('Show Error'));
        await tester.pump();
        expect(find.text('Error Occurred!'), findsOneWidget);
        expect(find.byKey(const Key('app_toast_capsule')), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      },
    );
  });

  group(
    'Final Round 4 Polish - Step 4: Re-openable Signed Contract & Audit Trail',
    () {
      testWidgets(
        'Signed agreement card is clickable and opens read-only audit receipt',
        (tester) async {
          tester.view.physicalSize = const Size(1000, 1800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final now = DateTime.utc(2026, 11, 22, 12, 30);
          final consent = LegalConsentAudit(
            contractVersion: 'v1.0',
            acceptedAt: now,
            signerUid: 'user-xyz-123',
            signerName: 'Jane Doe',
            signerEmail: 'jane@example.com',
            ipAddress: '198.51.100.42',
            deviceInfo: 'Windows (Desktop Chrome)',
          );

          final state = AppState(
            isLoggedIn: true,
            termsAcceptedAt: now,
            legalConsent: consent,
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appStateProvider.overrideWith(
                  (ref) => _TestAppStateNotifier(state),
                ),
              ],
              child: MaterialApp(
                theme: testTheme,
                locale: const Locale('en'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const Scaffold(
                  body: SingleChildScrollView(child: AboutSubTab()),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Clickable signed card exists
          final signedCard = find.byKey(
            const Key('agreement_signed_clickable_card'),
          );
          expect(signedCard, findsOneWidget);

          // Tap card to open modal
          await tester.tap(signedCard);
          await tester.pumpAndSettle();

          // Modal with audit receipt exists
          expect(
            find.byKey(const Key('contract_audit_receipt_card')),
            findsOneWidget,
          );
          expect(find.text('user-xyz-123'), findsOneWidget);
          expect(find.text('198.51.100.42'), findsOneWidget);
          expect(find.text('v1.0'), findsOneWidget);
          expect(find.text('Windows (Desktop Chrome)'), findsOneWidget);

          // Close modal
          final closeBtn = find.text('Close');
          expect(closeBtn, findsWidgets);
          await tester.tap(closeBtn.last);
          await tester.pumpAndSettle();
        },
      );
    },
  );

  group('Final Round 4 Polish - Step 5: Locale-Aware Digit Formatting', () {
    test('DigitFormatter produces Western digits for en and tr', () {
      expect(DigitFormatter.localizeDigits('12345', 'en'), '12345');
      expect(DigitFormatter.localizeDigits('12345', 'tr'), '12345');
      expect(DigitFormatter.localizeDigits('v۱.۰.۰', 'en'), 'v1.0.0');
      expect(DigitFormatter.localizeDigits('v۱.۰.۰', 'tr'), 'v1.0.0');
      expect(DigitFormatter.localizeDigits('Clause ۱.۵', 'en'), 'Clause 1.5');
    });

    test('DigitFormatter produces Persian digits for fa', () {
      expect(DigitFormatter.localizeDigits('12345', 'fa'), '۱۲۳۴۵');
      expect(DigitFormatter.localizeDigits(2026, 'fa'), '۲۰۲۶');
    });

    test('DigitFormatter produces Arabic-Indic digits for ar', () {
      expect(DigitFormatter.localizeDigits('12345', 'ar'), '١٢٣٤٥');
      expect(DigitFormatter.localizeDigits(99, 'ar'), '٩٩');
    });

    test(
      'DigitFormatter.toLatinDigits converts any non-latin digits safely',
      () {
        expect(DigitFormatter.toLatinDigits('۱۲۳۴۵'), '12345');
        expect(DigitFormatter.toLatinDigits('١٢٣٤٥'), '12345');
        expect(DigitFormatter.toLatinDigits('12345'), '12345');
      },
    );

    test('AppStrings.formatNumber delegates accurately per locale', () {
      const enStrings = AppStrings('en');
      const faStrings = AppStrings('fa');
      const trStrings = AppStrings('tr');
      const arStrings = AppStrings('ar');

      expect(enStrings.formatNumber(100), '100');
      expect(trStrings.formatNumber(100), '100');
      expect(faStrings.formatNumber(100), '۱۰۰');
      expect(arStrings.formatNumber(100), '١٠٠');
    });
  });
}
