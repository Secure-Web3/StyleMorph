import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/services/notification_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/domain/user_preferences.dart';
import 'package:stylemorph/features/shell/presentation/shell_state_provider.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';
import 'package:stylemorph/features/shell/presentation/widgets/notification_sheet.dart';

void main() {
  group('Phase 3.5: Notification Center Polish', () {
    test(
      'Localization provides compact category labels and All/Unread/Read filters in all 4 languages',
      () {
        for (final code in ['en', 'fa', 'ar', 'tr']) {
          final strings = AppStrings(code);
          expect(strings.notifCatAccount.isNotEmpty, isTrue);
          expect(strings.notifCatAi.isNotEmpty, isTrue);
          expect(strings.notifCatShop.isNotEmpty, isTrue);
          expect(strings.notifCatFinance.isNotEmpty, isTrue);
          expect(strings.notifFilterAll.isNotEmpty, isTrue);
          expect(strings.notifFilterUnread.isNotEmpty, isTrue);
          expect(strings.notifFilterRead.isNotEmpty, isTrue);
        }

        final en = AppStrings('en');
        expect(en.notifCatAccount, 'Account');
        expect(en.notifCatAi, 'AI');
        expect(en.notifCatShop, 'Shop');
        expect(en.notifCatFinance, 'Wallet');
        expect(en.notifFilterAll, 'All');
        expect(en.notifFilterUnread, 'Unread');
        expect(en.notifFilterRead, 'Read');
      },
    );

    test(
      'NotificationService.filterNotifications filters by category and status while preserving chronological order',
      () {
        const items = [
          AppNotification(
            id: 'n3_newest',
            category: 'account',
            emoji: '👤',
            title: 'Newest',
            body: 'Body 3',
            timestampLabel: '1m ago',
            targetRoute: 'profile_identity',
            isRead: false,
          ),
          AppNotification(
            id: 'n2_middle',
            category: 'ai',
            emoji: '✨',
            title: 'Middle',
            body: 'Body 2',
            timestampLabel: '5m ago',
            targetRoute: 'atelier_creations',
            isRead: true,
          ),
          AppNotification(
            id: 'n1_oldest',
            category: 'finance',
            emoji: '🪙',
            title: 'Oldest',
            body: 'Body 1',
            timestampLabel: '10m ago',
            targetRoute: 'profile_wallet',
            isRead: false,
          ),
        ];

        final unreadOnly = NotificationService.filterNotifications(
          items,
          category: 'all',
          status: 'unread',
        );
        expect(unreadOnly.map((e) => e.id).toList(), [
          'n3_newest',
          'n1_oldest',
        ]);

        final readOnly = NotificationService.filterNotifications(
          items,
          category: 'all',
          status: 'read',
        );
        expect(readOnly.map((e) => e.id).toList(), ['n2_middle']);

        final aiRead = NotificationService.filterNotifications(
          items,
          category: 'ai',
          status: 'read',
        );
        expect(aiRead.map((e) => e.id).toList(), ['n2_middle']);

        // Marking middle item read in ShellStateNotifier preserves exact order
        final notifier = ShellStateNotifier(
          null,
          const ShellState(
            notifications: [
              AppNotification(
                id: 'n3_newest',
                category: 'account',
                emoji: '👤',
                title: 'Newest',
                body: 'Body 3',
                timestampLabel: '1m ago',
                targetRoute: 'profile_identity',
                isRead: false,
              ),
              AppNotification(
                id: 'n2_middle',
                category: 'ai',
                emoji: '✨',
                title: 'Middle',
                body: 'Body 2',
                timestampLabel: '5m ago',
                targetRoute: 'atelier_creations',
                isRead: false,
              ),
              AppNotification(
                id: 'n1_oldest',
                category: 'finance',
                emoji: '🪙',
                title: 'Oldest',
                body: 'Body 1',
                timestampLabel: '10m ago',
                targetRoute: 'profile_wallet',
                isRead: false,
              ),
            ],
          ),
        );
        notifier.markNotificationRead('n2_middle');
        expect(notifier.state.notifications.map((e) => e.id).toList(), [
          'n3_newest',
          'n2_middle',
          'n1_oldest',
        ]);
        expect(notifier.state.notifications[1].isRead, isTrue);
      },
    );

    testWidgets(
      'NotificationSheet renders ShaderMask fade, All/Unread/Read segmented bar, and dynamic empty height',
      (tester) async {
        const mockItems = [
          AppNotification(
            id: 'm1',
            category: 'account',
            emoji: '👤',
            title: 'Unread Account',
            body: 'First Name: "Mostafa" → "Ali"',
            timestampLabel: 'Just now',
            targetRoute: 'profile_identity',
            isRead: false,
          ),
          AppNotification(
            id: 'm2',
            category: 'shop',
            emoji: '🛍️',
            title: 'Read Shop',
            body: 'Order shipped',
            timestampLabel: '5m ago',
            targetRoute: 'shop',
            isRead: true,
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(
              (ref) =>
                  AppStateNotifier()
                    ..state = const AppState(notifications: mockItems),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(localeProvider.notifier).setLanguage('en');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(extensions: const [AppColors.lightWhite]),
              builder: (context, child) => ShadTheme(
                data: AppTheme.buildShadTheme(
                  palette: AppPalette.white,
                  isDark: false,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
              home: const Scaffold(body: NotificationSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ShaderMask), findsOneWidget);
        expect(
          find.byKey(const Key('notification_status_filter_bar')),
          findsOneWidget,
        );

        // Tap Unread filter
        await tester.tap(find.byKey(const Key('notif_status_unread')));
        await tester.pumpAndSettle();
        expect(find.text('Unread Account'), findsOneWidget);
        expect(find.text('Read Shop'), findsNothing);

        // Tap Read filter
        await tester.tap(find.byKey(const Key('notif_status_read')));
        await tester.pumpAndSettle();
        expect(find.text('Unread Account'), findsNothing);
        expect(find.text('Read Shop'), findsOneWidget);

        // Switch to empty category -> sheet shrinks cleanly and shows empty state
        final strings = AppStrings('en');
        await tester.tap(find.text(strings.notifCatFinance));
        await tester.pumpAndSettle();
        expect(find.text(strings.noNotifications), findsOneWidget);
      },
    );

    test(
      'Rich diff builder formats profile & settings diffs, aggregates >3 items, and excludes sensitive fields',
      () {
        final singleDiff = AppStateNotifier.buildProfileDiffSummary(
          previousIdentity: {'firstName': 'Mostafa', 'city': 'Tehran'},
          currentIdentity: {'firstName': 'Ali', 'city': 'Mashhad'},
        );
        expect(
          singleDiff,
          'First Name: "Mostafa" → "Ali", City: "Tehran" → "Mashhad"',
        );

        final aggregatedWithSensitive =
            AppStateNotifier.buildProfileDiffSummary(
              previousIdentity: {
                'firstName': 'A',
                'lastName': 'B',
                'city': 'C',
                'country': 'D',
                'password': 'old_secret_password',
                'nationalId': '0011223344',
                'accessToken': 'tok_123',
              },
              currentIdentity: {
                'firstName': 'A2',
                'lastName': 'B2',
                'city': 'C2',
                'country': 'D2',
                'password': 'new_secret_password',
                'nationalId': '9988776655',
                'accessToken': 'tok_456',
              },
            );
        expect(aggregatedWithSensitive.contains('(+1 more)'), isTrue);
        expect(aggregatedWithSensitive.contains('secret_password'), isFalse);
        expect(aggregatedWithSensitive.contains('0011223344'), isFalse);
        expect(aggregatedWithSensitive.contains('tok_456'), isFalse);

        final settingsDiff = AppStateNotifier.buildSettingsDiffSummary(
          previous: const UserPreferences(
            appLanguage: 'en',
            brightnessMode: 'dark',
          ),
          current: const UserPreferences(
            appLanguage: 'fa',
            brightnessMode: 'light',
          ),
        );
        expect(settingsDiff, contains('Language: "English" → "فارسی"'));
        expect(settingsDiff, contains('Theme: "Dark" → "Light"'));
      },
    );

    test(
      'sendEmail gating triggers only for sensitive events with valid email, and firestore.rules secures mail_queue & referral notifications',
      () {
        expect(
          NotificationService.shouldDispatchEmail(
            sendEmail: false,
            recipientEmail: 'user@example.com',
          ),
          isFalse,
        );
        expect(
          NotificationService.shouldDispatchEmail(
            sendEmail: true,
            recipientEmail: '',
          ),
          isFalse,
        );
        expect(
          NotificationService.shouldDispatchEmail(
            sendEmail: true,
            recipientEmail: 'invalid',
          ),
          isFalse,
        );
        expect(
          NotificationService.shouldDispatchEmail(
            sendEmail: true,
            recipientEmail: 'user@example.com',
          ),
          isTrue,
        );

        final rulesFile = File('../firestore.rules').existsSync()
            ? File('../firestore.rules')
            : File('firestore.rules');
        expect(rulesFile.existsSync(), isTrue);
        final rules = rulesFile.readAsStringSync();

        expect(rules.contains('match /mail_queue/{mailId}'), isTrue);
        expect(
          rules.contains("request.resource.data.status == 'pending'"),
          isTrue,
        );
        expect(rules.contains('allow read, update, delete: if false;'), isTrue);
        expect(
          rules.contains(
            "request.resource.data.eventType == 'referral_joined'",
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'MainHeader renders pulsing unread bell dot when unread > 0 and omits it when unread == 0',
      (tester) async {
        // 1. Unread > 0 -> dot is rendered and animates cleanly
        final unreadContainer = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(
              (ref) => AppStateNotifier()
                ..state = const AppState(
                  notifications: [
                    AppNotification(
                      id: 'u1',
                      category: 'account',
                      emoji: '🔐',
                      title: 'New Sign-In',
                      body: 'Active session',
                      timestampLabel: 'Just now',
                      targetRoute: 'profile_sessions',
                      isRead: false,
                    ),
                  ],
                ),
            ),
          ],
        );
        addTearDown(unreadContainer.dispose);
        unreadContainer.read(localeProvider.notifier).setLanguage('en');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: unreadContainer,
            child: MaterialApp(
              theme: ThemeData(extensions: const [AppColors.lightWhite]),
              builder: (context, child) => ShadTheme(
                data: AppTheme.buildShadTheme(
                  palette: AppPalette.white,
                  isDark: false,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
              home: const Scaffold(appBar: MainHeader()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.byKey(const Key('header_notifications_unread_dot')),
          findsOneWidget,
        );

        // 2. Unread == 0 -> dot is absent and pumpAndSettle finishes cleanly
        final readContainer = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(
              (ref) => AppStateNotifier()..state = const AppState(),
            ),
          ],
        );
        addTearDown(readContainer.dispose);
        readContainer.read(localeProvider.notifier).setLanguage('en');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: readContainer,
            child: MaterialApp(
              theme: ThemeData(extensions: const [AppColors.lightWhite]),
              builder: (context, child) => ShadTheme(
                data: AppTheme.buildShadTheme(
                  palette: AppPalette.white,
                  isDark: false,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
              home: const Scaffold(appBar: MainHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('header_notifications_unread_dot')),
          findsNothing,
        );
      },
    );
  });
}
