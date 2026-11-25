import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/services/notification_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/shell/presentation/shell_state_provider.dart';
import 'package:stylemorph/features/shell/presentation/widgets/notification_sheet.dart';
import 'package:stylemorph/features/wardrobe/data/wardrobe_repository.dart';
import 'package:stylemorph/features/wardrobe/domain/wardrobe_item.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_provider.dart';

class _RecordingNotificationService extends NotificationService {
  final List<Map<String, dynamic>> recorded = [];

  @override
  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    String category = 'account',
    String targetRoute = 'profile_identity',
    String emoji = '🔔',
    bool sendEmail = false,
    String? recipientEmail,
    String eventType = NotificationService.eventGeneral,
    Map<String, dynamic>? extraData,
  }) async {
    recorded.add({
      'uid': uid,
      'title': title,
      'body': body,
      'category': category,
      'targetRoute': targetRoute,
      'emoji': emoji,
      'sendEmail': sendEmail,
      'eventType': eventType,
    });
  }
}

Widget _buildSheetHost({
  required List<AppNotification> notifications,
  required Locale locale,
  Size surfaceSize = const Size(430, 800),
  ShellStateNotifier? customNotifier,
}) {
  final notifier =
      customNotifier ??
      ShellStateNotifier(null, ShellState(notifications: notifications));

  return ProviderScope(
    overrides: [
      shellStateProvider.overrideWith((ref) => notifier),
      localeProvider.overrideWith(
        (ref) => LocaleNotifier()..setLanguage(locale.languageCode),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      theme: ThemeData(extensions: const [AppColors.lightWhite]),
      builder: (context, child) => Directionality(
        textDirection:
            locale.languageCode == 'fa' || locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: ShadTheme(
          data: AppTheme.buildShadTheme(
            palette: AppPalette.white,
            isDark: false,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('open_sheet_btn'),
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NotificationSheet(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Phase 3.6: Notification Center UX & Lifecycle Upgrade', () {
    const sampleNotifications = [
      AppNotification(
        id: 'n_account',
        category: 'account',
        emoji: '🔐',
        title: 'Account Alert',
        body: 'New login',
        timestampLabel: 'Just now',
        targetRoute: 'profile_identity',
        isRead: false,
      ),
      AppNotification(
        id: 'n_wardrobe',
        category: 'wardrobe',
        emoji: '👗',
        title: 'Wardrobe Added',
        body: 'Silk Shirt added',
        timestampLabel: '1m ago',
        targetRoute: 'wardrobe',
        isRead: false,
      ),
      AppNotification(
        id: 'n_wellness',
        category: 'wellness',
        emoji: '🌿',
        title: 'Wellness Tip',
        body: 'Hydration reminder',
        timestampLabel: '2m ago',
        targetRoute: 'wellness',
        isRead: true,
      ),
      AppNotification(
        id: 'n_stylist',
        category: 'stylist',
        emoji: '🪄',
        title: 'Stylist Look',
        body: 'New outfit idea',
        timestampLabel: '3m ago',
        targetRoute: 'stylist',
        isRead: false,
      ),
      AppNotification(
        id: 'n_atelier_legacy',
        category: 'ai',
        emoji: '✨',
        title: 'Atelier Render',
        body: 'Render ready',
        timestampLabel: '4m ago',
        targetRoute: 'atelier_creations',
        isRead: true,
      ),
      AppNotification(
        id: 'n_shop_legacy',
        category: 'deals',
        emoji: '🛍️',
        title: 'Shop Drop',
        body: '20% off',
        timestampLabel: '5m ago',
        targetRoute: 'shop',
        isRead: false,
      ),
      AppNotification(
        id: 'n_wallet_legacy',
        category: 'finance',
        emoji: '🪙',
        title: 'Wallet Bonus',
        body: '+50 coins',
        timestampLabel: '6m ago',
        targetRoute: 'profile_wallet',
        isRead: true,
      ),
    ];

    test('All 8 module categories and legacy mappings filter accurately', () {
      expect(NotificationService.normalizeCategory('ai'), 'atelier');
      expect(NotificationService.normalizeCategory('deals'), 'shop');
      expect(NotificationService.normalizeCategory('finance'), 'wallet');
      expect(NotificationService.normalizeCategory('system'), 'account');

      expect(
        NotificationService.filterByCategory(sampleNotifications, 'all').length,
        7,
      );
      expect(
        NotificationService.filterByCategory(
          sampleNotifications,
          'account',
        ).map((e) => e.id).toList(),
        ['n_account'],
      );
      expect(
        NotificationService.filterByCategory(
          sampleNotifications,
          'wardrobe',
        ).map((e) => e.id).toList(),
        ['n_wardrobe'],
      );
      expect(
        NotificationService.filterByCategory(
          sampleNotifications,
          'wellness',
        ).map((e) => e.id).toList(),
        ['n_wellness'],
      );
      expect(
        NotificationService.filterByCategory(
          sampleNotifications,
          'stylist',
        ).map((e) => e.id).toList(),
        ['n_stylist'],
      );
      expect(
        NotificationService.filterByCategory(
          sampleNotifications,
          'atelier',
        ).map((e) => e.id).toList(),
        ['n_atelier_legacy'],
      );
      expect(
        NotificationService.filterByCategory(
          sampleNotifications,
          'shop',
        ).map((e) => e.id).toList(),
        ['n_shop_legacy'],
      );
      expect(
        NotificationService.filterByCategory(
          sampleNotifications,
          'wallet',
        ).map((e) => e.id).toList(),
        ['n_wallet_legacy'],
      );
    });

    test(
      'computeExpiresAt returns 30 days for routine and 90 days for sensitive/financial events',
      () {
        final now = DateTime.utc(2026, 6, 1, 12, 0);

        final routineWardrobe = NotificationService.computeExpiresAt(
          category: 'wardrobe',
          eventType: 'wardrobe_item_added',
          sendEmail: false,
          now: now,
        );
        expect(routineWardrobe.difference(now).inDays, 30);

        final walletEvent = NotificationService.computeExpiresAt(
          category: 'wallet',
          eventType: NotificationService.eventGeneral,
          sendEmail: false,
          now: now,
        );
        expect(walletEvent.difference(now).inDays, 90);

        final emailEvent = NotificationService.computeExpiresAt(
          category: 'account',
          eventType: NotificationService.eventGeneral,
          sendEmail: true,
          now: now,
        );
        expect(emailEvent.difference(now).inDays, 90);

        for (final sensitiveEvent in [
          NotificationService.eventReferralJoined,
          NotificationService.eventKycStatus,
          NotificationService.eventNewSession,
          NotificationService.eventAgreementSigned,
          'terms_signed',
        ]) {
          final expires = NotificationService.computeExpiresAt(
            category: 'account',
            eventType: sensitiveEvent,
            sendEmail: false,
            now: now,
          );
          expect(expires.difference(now).inDays, 90);
        }
      },
    );

    testWidgets(
      'NotificationSheet renders all 8 category tabs in order and locks height to 75%',
      (tester) async {
        const size = Size(430, 800);
        await tester.pumpWidget(
          _buildSheetHost(
            notifications: sampleNotifications,
            locale: const Locale('en'),
            surfaceSize: size,
          ),
        );
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        final en = AppStrings('en');
        final categoryScrollable = find.descendant(
          of: find.byType(ShaderMask),
          matching: find.byType(Scrollable),
        );
        for (final label in [
          en.allText,
          en.notifCatAccount,
          en.notifCatWardrobe,
          en.notifCatWellness,
          en.notifCatStylist,
          en.notifCatAtelier,
          en.notifCatShop,
          en.notifCatWallet,
        ]) {
          final chipFinder = find.descendant(
            of: categoryScrollable,
            matching: find.text(label),
          );
          await tester.scrollUntilVisible(
            chipFinder,
            100,
            scrollable: categoryScrollable,
          );
          expect(chipFinder, findsOneWidget);
        }

        final containerFinder = find.byKey(
          const Key('notification_sheet_fixed_container'),
        );
        expect(containerFinder, findsOneWidget);
        final rect = tester.getRect(containerFinder);
        // Default Flutter test viewport height is 600.0 -> 75% = 450.0
        expect(rect.height, closeTo(600.0 * 0.75, 1.0));

        // Switch to an empty filter ('Read' + 'Wardrobe') and verify height stays 75%
        await tester.tap(find.text(en.notifCatWardrobe).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('notif_status_read')));
        await tester.pumpAndSettle();
        expect(find.text(en.noNotifications), findsOneWidget);
        expect(
          tester.getRect(containerFinder).height,
          closeTo(600.0 * 0.75, 1.0),
        );
      },
    );

    testWidgets(
      'Single-item Mark-as-Read marks only that item without closing sheet, and Delete removes item cleanly',
      (tester) async {
        final notifier = ShellStateNotifier(
          null,
          const ShellState(notifications: sampleNotifications),
        );
        await tester.pumpWidget(
          _buildSheetHost(
            notifications: sampleNotifications,
            locale: const Locale('en'),
            customNotifier: notifier,
          ),
        );
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        // Tap single-item Mark-as-Read on n_account
        await tester.tap(find.byKey(const Key('notif_mark_read_n_account')));
        await tester.pumpAndSettle();

        // Sheet must remain open
        expect(
          find.byKey(const Key('notification_sheet_fixed_container')),
          findsOneWidget,
        );
        // Only n_account became read; n_wardrobe remains unread
        expect(
          notifier.state.notifications
              .firstWhere((e) => e.id == 'n_account')
              .isRead,
          isTrue,
        );
        expect(
          notifier.state.notifications
              .firstWhere((e) => e.id == 'n_wardrobe')
              .isRead,
          isFalse,
        );
        // Checkmark icon for n_account disappears once read
        expect(
          find.byKey(const Key('notif_mark_read_n_account')),
          findsNothing,
        );

        // Tap manual Delete on n_wardrobe
        await tester.tap(find.byKey(const Key('notif_delete_n_wardrobe')));
        await tester.pumpAndSettle();

        expect(
          notifier.state.notifications.any((e) => e.id == 'n_wardrobe'),
          isFalse,
        );
        expect(find.byKey(const Key('notif_card_n_wardrobe')), findsNothing);
      },
    );

    testWidgets(
      'Horizontal swipe switches between All, Unread, and Read in LTR and RTL',
      (tester) async {
        // LTR test
        await tester.pumpWidget(
          _buildSheetHost(
            notifications: sampleNotifications,
            locale: const Locale('en'),
          ),
        );
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        final pageViewFinder = find.byKey(
          const Key('notification_status_page_view'),
        );
        expect(pageViewFinder, findsOneWidget);

        // Swipe left in LTR moves from All (0) -> Unread (1)
        await tester.fling(pageViewFinder, const Offset(-300, 0), 800);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('notif_card_n_account')), findsOneWidget);
        expect(find.byKey(const Key('notif_card_n_wellness')), findsNothing);

        // Swipe left again in LTR moves from Unread (1) -> Read (2)
        await tester.fling(pageViewFinder, const Offset(-300, 0), 800);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('notif_card_n_wellness')), findsOneWidget);
        expect(find.byKey(const Key('notif_card_n_account')), findsNothing);
      },
    );

    testWidgets(
      'Horizontal swipe switches between All, Unread, and Read in RTL',
      (tester) async {
        await tester.pumpWidget(
          _buildSheetHost(
            notifications: sampleNotifications,
            locale: const Locale('fa'),
          ),
        );
        await tester.tap(find.byKey(const Key('open_sheet_btn')));
        await tester.pumpAndSettle();

        final pageViewFinder = find.byKey(
          const Key('notification_status_page_view'),
        );
        expect(pageViewFinder, findsOneWidget);

        // In RTL, swiping right (+300) moves forward from All (0) -> Unread (1)
        await tester.fling(pageViewFinder, const Offset(300, 0), 800);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('notif_card_n_account')), findsOneWidget);
        expect(find.byKey(const Key('notif_card_n_wellness')), findsNothing);
      },
    );

    test(
      'WardrobeNotifier fires non-blocking wardrobe notifications on add, update, archive, and delete',
      () async {
        final recorder = _RecordingNotificationService();
        final repo = InMemoryWardrobeRepository();
        final notifier = WardrobeNotifier(repo, null, 'user_123', recorder);
        await notifier.loadInitial();

        final newItem = WardrobeItem(
          id: 'w_test_1',
          title: 'Cashmere Coat',
          category: 'outerwear',
          subCategory: 'Coat',
          colorName: 'Camel',
          colorHex: '#C19A6B',
          season: 'Winter',
          occasion: 'Formal',
          material: 'Cashmere',
          size: 'M',
        );

        await notifier.addItem(newItem);
        await notifier.updateItem(newItem.copyWith(title: 'Camel Coat'));
        await notifier.toggleArchive('w_test_1');
        await notifier.toggleArchive('w_test_1');
        await notifier.deleteItem('w_test_1');

        expect(recorder.recorded.length, 5);
        for (final entry in recorder.recorded) {
          expect(entry['uid'], 'user_123');
          expect(entry['category'], 'wardrobe');
          expect(entry['targetRoute'], 'wardrobe');
          expect(entry['sendEmail'], isFalse);
        }
        expect(recorder.recorded[0]['title'], 'Wardrobe Item Added');
        expect(recorder.recorded[1]['title'], 'Wardrobe Item Updated');
        expect(recorder.recorded[2]['title'], 'Wardrobe Item Archived');
        expect(recorder.recorded[3]['title'], 'Wardrobe Item Restored');
        expect(recorder.recorded[4]['title'], 'Wardrobe Item Removed');
      },
    );
  });
}
