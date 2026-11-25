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
import 'package:stylemorph/features/shell/presentation/shell_state_provider.dart';
import 'package:stylemorph/features/shell/presentation/widgets/notification_sheet.dart';

void main() {
  group('Phase 3: Live Firestore Notification Center', () {
    test(
      'firestore.rules defines match /notifications/{notificationId} under users/{userId}',
      () {
        final rulesFile = File('../firestore.rules').existsSync()
            ? File('../firestore.rules')
            : File('firestore.rules');
        expect(rulesFile.existsSync(), isTrue);
        final content = rulesFile.readAsStringSync();

        expect(content.contains('match /users/{userId}'), isTrue);
        expect(
          content.contains('match /notifications/{notificationId}'),
          isTrue,
        );
        expect(
          content.contains(
            'allow read, create, update, delete: if isOwner(userId);',
          ),
          isTrue,
        );
      },
    );

    test(
      'NotificationService.sortNotifications places pending/null createdAt at top and sorts descending',
      () {
        final older = NotificationEntry(
          id: 'n1',
          title: 'Older',
          body: 'Old body',
          category: 'ai',
          targetRoute: 'atelier_creations',
          createdAt: DateTime(2026, 1, 1, 10, 0),
        );
        final newer = NotificationEntry(
          id: 'n2',
          title: 'Newer',
          body: 'New body',
          category: 'shop',
          targetRoute: 'shop',
          createdAt: DateTime(2026, 1, 2, 10, 0),
        );
        const pending = NotificationEntry(
          id: 'n3',
          title: 'Pending',
          body: 'Pending serverTimestamp',
          category: 'account',
          targetRoute: 'profile_identity',
          createdAt: null,
        );

        final sorted = NotificationService.sortNotifications([
          older,
          newer,
          pending,
        ]);

        expect(sorted.map((e) => e.id).toList(), ['n3', 'n2', 'n1']);
      },
    );

    test(
      'NotificationService.filterByCategory filters All and specific categories accurately',
      () {
        const items = [
          AppNotification(
            id: '1',
            category: 'account',
            emoji: '👤',
            title: 'Profile Updated',
            body: 'Saved',
            timestampLabel: 'Just now',
            targetRoute: 'profile_identity',
          ),
          AppNotification(
            id: '2',
            category: 'ai',
            emoji: '✨',
            title: 'AI Ready',
            body: 'Done',
            timestampLabel: '1m ago',
            targetRoute: 'atelier_creations',
          ),
          AppNotification(
            id: '3',
            category: 'finance',
            emoji: '🪙',
            title: 'Coins Added',
            body: '+50',
            timestampLabel: '2m ago',
            targetRoute: 'profile_wallet',
          ),
        ];

        expect(NotificationService.filterByCategory(items, 'all').length, 3);
        expect(
          NotificationService.filterByCategory(
            items,
            'account',
          ).map((e) => e.id).toList(),
          ['1'],
        );
        expect(
          NotificationService.filterByCategory(
            items,
            'ai',
          ).map((e) => e.id).toList(),
          ['2'],
        );
        expect(
          NotificationService.filterByCategory(
            items,
            'finance',
          ).map((e) => e.id).toList(),
          ['3'],
        );
        expect(NotificationService.filterByCategory(items, 'shop'), isEmpty);
      },
    );

    test(
      'NotificationService.countUnread and ShellStateNotifier markAsRead / markAllAsRead work',
      () {
        const initial = [
          AppNotification(
            id: 'a1',
            category: 'account',
            emoji: '🔐',
            title: 'New Sign-In Detected',
            body: 'New session',
            timestampLabel: 'Just now',
            targetRoute: 'profile_sessions',
            isRead: false,
          ),
          AppNotification(
            id: 'a2',
            category: 'account',
            emoji: '⚙️',
            title: 'Settings Updated',
            body: 'Saved',
            timestampLabel: 'Just now',
            targetRoute: 'profile_settings',
            isRead: false,
          ),
        ];

        expect(NotificationService.countUnread(initial), 2);

        final notifier = ShellStateNotifier(
          null,
          const ShellState(notifications: initial),
        );
        expect(notifier.state.unreadNotificationsCount, 2);

        notifier.markNotificationRead('a1');
        expect(notifier.state.unreadNotificationsCount, 1);
        expect(notifier.state.notifications.first.isRead, isTrue);

        notifier.markAllNotificationsRead();
        expect(notifier.state.unreadNotificationsCount, 0);
        expect(notifier.state.notifications.every((n) => n.isRead), isTrue);
      },
    );

    testWidgets(
      'NotificationSheet shows Account & Activity filter and falls back gracefully when unauthenticated',
      (tester) async {
        const mockItems = [
          AppNotification(
            id: 'm1',
            category: 'account',
            emoji: '👤',
            title: 'Profile Updated',
            body: 'Your personal & profile changes were saved.',
            timestampLabel: 'Just now',
            targetRoute: 'profile_identity',
            isRead: false,
          ),
          AppNotification(
            id: 'm2',
            category: 'shop',
            emoji: '🛍️',
            title: 'New Drop',
            body: 'Collection live',
            timestampLabel: '5m ago',
            targetRoute: 'shop',
            isRead: false,
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

        final strings = AppStrings('en');
        expect(find.text(strings.notifCatAccount), findsOneWidget);
        expect(find.text('Profile Updated'), findsOneWidget);
        expect(find.text('New Drop'), findsOneWidget);

        await tester.tap(find.text(strings.notifCatAccount));
        await tester.pumpAndSettle();

        expect(find.text('Profile Updated'), findsOneWidget);
        expect(find.text('New Drop'), findsNothing);

        await tester.tap(find.text(strings.markAllRead));
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).unreadNotificationsCount, 0);
      },
    );
  });
}
