import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/theme_provider.dart';
import 'package:stylemorph/features/atelier/presentation/atelier_provider.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';
import 'package:stylemorph/features/shell/presentation/widgets/notification_sheet.dart';
import 'package:stylemorph/features/shell/presentation/widgets/support_widget.dart';

const _testNotifications = [
  AppNotification(
    id: 'notif_1',
    category: 'ai',
    emoji: '🪄',
    title: 'تصویر پرتره ادیتوریال شما در آتلیه آماده شد!',
    body: 'برای مشاهده، دانلود و اشتراک‌گذاری به بخش ساخته‌های من بروید.',
    timestampLabel: '۵ دقیقه پیش',
    targetRoute: 'atelier_creations',
    isRead: false,
  ),
  AppNotification(
    id: 'notif_2',
    category: 'shop',
    emoji: '📉',
    title: 'کت کتان بژ در لیست علاقه‌مندی‌های شما ۲۰٪ تخفیف خورد!',
    body: 'فرصت محدود فروشنده تاییدشده با گارانتی تطابق سایز.',
    timestampLabel: '۲۲ دقیقه پیش',
    targetRoute: 'shop',
    isRead: false,
  ),
  AppNotification(
    id: 'notif_3',
    category: 'finance',
    emoji: '🪙',
    title:
        'مریم کاظمی با لینک دعوت شما ثبت‌نام کرد و ۱۰۰ سکه به کیف پولتان اضافه شد.',
    body: 'پاداش سطح طلایی به حساب StyleCoin شما واریز شد.',
    timestampLabel: '۱ ساعت پیش',
    targetRoute: 'profile_wallet',
    isRead: false,
  ),
  AppNotification(
    id: 'notif_4',
    category: 'ai',
    emoji: '☀️',
    title:
        'هوای امروز ۱۸ درجه و آفتابی است؛ رامین یک ست جدید از کمدتان آماده کرده!',
    body: 'ست پیشنهادی بر اساس برنامه روزمره و پالت رنگی شما چیده شده است.',
    timestampLabel: '۲ ساعت پیش',
    targetRoute: 'stylist',
    isRead: false,
  ),
];

ProviderContainer _createTestContainer({List<Override> overrides = const []}) {
  return ProviderContainer(
    overrides: [
      appStateProvider.overrideWith(
        (ref) => AppStateNotifier()
          ..state = const AppState(
            userName: 'سارا احمدی',
            userHandle: '@sara_ahmadi',
            stylePoints: 350,
            profileProgress: 0.40,
            coins: 350,
            currentPlan: 'عادی (رایگان)',
            showFloatingSupport: true,
            showHeaderCoins: true,
            notifications: _testNotifications,
          ),
      ),
      ...overrides,
    ],
  );
}

Widget _wrapShell({ProviderContainer? container}) {
  return UncontrolledProviderScope(
    container: container ?? _createTestContainer(),
    child: MaterialApp(
      locale: const Locale('fa'),
      supportedLocales: AppLanguage.supportedLanguages
          .map((l) => l.locale)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(extensions: const [AppColors.lightWhite]),
      builder: (context, child) => ShadTheme(
        data: AppTheme.buildShadTheme(palette: AppPalette.white, isDark: false),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const MainShellScreen(),
    ),
  );
}

void main() {
  group('Step 1: 5-Tab Bottom Nav & Header Drawer Trigger', () {
    testWidgets('AppBottomNav shows only 5 tabs and no Profile item', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = _createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapShell(container: container));
      await tester.pumpAndSettle();

      final nav = find.byType(AppBottomNav);
      expect(
        find.descendant(of: nav, matching: find.text('کمد')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nav, matching: find.text('تندرستی')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nav, matching: find.text('استایلیست')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nav, matching: find.text('آتلیه')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nav, matching: find.text('فروشگاه')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nav, matching: find.text('پروفایل')),
        findsNothing,
      );

      // Tapping Wardrobe exits Profile and activates Wardrobe
      await tester.tap(find.descendant(of: nav, matching: find.text('کمد')));
      await tester.pumpAndSettle();
      expect(container.read(appStateProvider).currentTab, AppTab.wardrobe);
    });

    testWidgets(
      'MainHeader has no hamburger icon and tapping avatar/name opens Drawer',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_wrapShell(container: container));
        await tester.pumpAndSettle();

        // Hamburger icon must be removed
        expect(
          find.descendant(
            of: find.byType(MainHeader),
            matching: find.byWidgetPredicate(
              (w) => w is FaIcon && identical(w.icon, FontAwesomeIcons.bars),
            ),
          ),
          findsNothing,
        );
        expect(find.byTooltip('Menu'), findsNothing);

        // Avatar + username visible and clickable to open Drawer
        expect(
          find.descendant(
            of: find.byType(MainHeader),
            matching: find.text('سارا احمدی'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(MainHeader),
            matching: find.textContaining('@sara_ahmadi'),
          ),
          findsOneWidget,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(MainHeader),
            matching: find.text('سارا احمدی'),
          ),
        );
        await tester.pumpAndSettle();

        // Drawer is now open with navigation items
        expect(find.byType(Drawer), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(Drawer),
            matching: find.text('پروفایل'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(Drawer),
            matching: find.text('پاداش & شبکه'),
          ),
          findsOneWidget,
        );

        // Tap Rewards in Drawer -> switches to Profile referral sub-tab
        await tester.tap(
          find.descendant(
            of: find.byType(Drawer),
            matching: find.text('پاداش & شبکه'),
          ),
        );
        await tester.pumpAndSettle();
        expect(container.read(appStateProvider).currentTab, AppTab.profile);
        expect(
          container.read(appStateProvider).currentProfileTab,
          'p-referral',
        );
      },
    );
  });

  group('Step 2: 3-State Theme Mode (Light / Dark / System)', () {
    test('ThemeNotifier cycles Light -> Dark -> System -> Light', () {
      final notifier = ThemeNotifier();
      expect(notifier.state.mode, ThemeMode.light);

      notifier.cycleThemeMode();
      expect(notifier.state.mode, ThemeMode.dark);
      expect(notifier.state.isDark, true);

      notifier.cycleThemeMode();
      expect(notifier.state.mode, ThemeMode.system);

      notifier.cycleThemeMode();
      expect(notifier.state.mode, ThemeMode.light);
      expect(notifier.state.isDark, false);
    });

    testWidgets('Settings sub-tab lets user pick System Auto theme mode', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = _createTestContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapShell(container: container));
      await tester.pumpAndSettle();

      container.read(appStateProvider.notifier).switchProfileTab('p-settings');
      await tester.pumpAndSettle();

      expect(find.text('حالت روز (روشن)'), findsOneWidget);
      container.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(find.text('خودکار (هماهنگ با سیستم)'), findsOneWidget);
    });
  });

  group('Step 3 & 4: 7 Profile Sub-Tabs + Persona + Sticky Save Bar', () {
    testWidgets(
      'Profile displays all 7 sub-tabs including Persona and compact sidebar',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_wrapShell(container: container));
        await tester.pumpAndSettle();

        final profile = find.byType(ProfileTab);
        expect(
          find.descendant(of: profile, matching: find.text('هویتی')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: profile, matching: find.text('آلبوم رسانه')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: profile, matching: find.text('آناتومی AI')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: profile, matching: find.text('مالی & پلن')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: profile, matching: find.text('پاداش & شبکه')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: profile, matching: find.text('شخصیت همراه')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: profile, matching: find.text('تنظیمات')),
          findsOneWidget,
        );

        // Persona sub-tab (disabled in sidebar with coming soon badge; verify content via direct switch)
        container
            .read(appStateProvider.notifier)
            .switchProfileTab('p-companion');
        await tester.pumpAndSettle();

        expect(find.text('شخصیت همراه و دستیار هوشمند'), findsOneWidget);
        expect(find.text('رامین'), findsOneWidget);
        expect(find.text('لنا'), findsOneWidget);
        expect(find.text('آرش'), findsOneWidget);
      },
    );

    testWidgets(
      'Sticky bottom Save Changes bar tracks dirty state and hides on read-only tabs',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_wrapShell(container: container));
        await tester.pumpAndSettle();

        // Inline save button in Identity must be removed
        expect(find.text('ذخیره تغییرات این بخش'), findsNothing);

        // Sticky bar starts disabled on Identity tab
        expect(find.text('تغییراتی ثبت نشده'), findsOneWidget);
        expect(find.text('ذخیره تغییرات'), findsNothing);

        // Edit first name field -> marks dirty
        await tester.enterText(find.byType(TextField).first, 'سارای عزیز');
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).hasUnsavedProfileChanges, true);
        expect(find.text('ذخیره تغییرات'), findsOneWidget);

        // Tap Save Changes -> resets dirty state
        await tester.tap(find.text('ذخیره تغییرات'));
        await tester.pumpAndSettle();

        expect(
          container.read(appStateProvider).hasUnsavedProfileChanges,
          false,
        );
        expect(find.text('تغییراتی ثبت نشده'), findsOneWidget);

        // Switch to read-only Wallet tab -> sticky bar must be hidden
        container.read(appStateProvider.notifier).switchProfileTab('p-wallet');
        await tester.pumpAndSettle();
        expect(find.text('تغییراتی ثبت نشده'), findsNothing);
        expect(find.text('ذخیره تغییرات'), findsNothing);
      },
    );
  });

  group('Step 5 & 6: Support Widget Visibility Bug Fix, Edge Snapping & Bounds', () {
    testWidgets(
      'Turning off floating support hides only button while keeping screen content visible',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_wrapShell(container: container));
        await tester.pumpAndSettle();

        expect(find.byType(SupportWidget), findsOneWidget);
        expect(find.byType(ProfileTab), findsOneWidget);

        // Turn off floating support
        container.read(appStateProvider.notifier).toggleFloatingSupport(false);
        await tester.pumpAndSettle();

        // Floating support overlay gone, but ProfileTab and Shell stay 100% visible
        expect(find.byType(SupportWidget), findsNothing);
        expect(find.byType(ProfileTab), findsOneWidget);
        expect(find.text('شناسنامه و اطلاعات هویتی'), findsOneWidget);
      },
    );

    testWidgets(
      'SupportWidget snaps to nearest horizontal edge on drag end and opens bounded popup',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_wrapShell(container: container));
        await tester.pumpAndSettle();

        final supportButtonMaterial = find
            .descendant(
              of: find.byType(SupportWidget),
              matching: find.byType(Material),
            )
            .first;

        final initialRect = tester.getRect(supportButtonMaterial);

        // Drag toward right side and release
        await tester.drag(supportButtonMaterial, const Offset(260, -250));
        await tester.pumpAndSettle();

        final snappedRect = tester.getRect(supportButtonMaterial);

        // Should snap cleanly to right wall (430 - 48 - 12 = 370) or left wall (12)
        expect(snappedRect.left == 12.0 || snappedRect.left == 370.0, true);
        expect(snappedRect.top != initialRect.top, true);

        // Tap support button -> opens popup strictly inside body bounds
        await tester.tap(supportButtonMaterial);
        await tester.pumpAndSettle();

        expect(find.text('پشتیبانی آنلاین'), findsOneWidget);
        final bodyRect = tester.getRect(find.byType(SupportWidget));
        final popupFinder = find.descendant(
          of: find.byType(SupportWidget),
          matching: find.byWidgetPredicate(
            (w) => w is Positioned && w.width != null,
          ),
        );
        final popupRect = tester.getRect(popupFinder.first);
        expect(popupRect.top >= bodyRect.top, true);
        expect(popupRect.bottom <= bodyRect.bottom, true);
        expect(popupRect.left >= bodyRect.left, true);
        expect(popupRect.right <= bodyRect.right, true);
      },
    );
  });

  group('Step 7: Interactive Notification Center & Deep-Links', () {
    testWidgets(
      'Bell opens NotificationSheet, Mark All Read clears badge, and items deep-link',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(_wrapShell(container: container));
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).unreadNotificationsCount, 4);

        // Open Notification Sheet
        await tester.tap(find.byTooltip('مرکز اعلان‌ها'));
        await tester.pumpAndSettle();

        expect(find.byType(NotificationSheet), findsOneWidget);
        expect(find.text('مرکز اعلان‌ها'), findsOneWidget);
        expect(find.text('خواندن همه ✓'), findsOneWidget);
        expect(
          find.text('تصویر پرتره ادیتوریال شما در آتلیه آماده شد!'),
          findsOneWidget,
        );

        // Tap Atelier Ready notification -> closes sheet & deep-links to Atelier (My Creations)
        await tester.tap(
          find.text('تصویر پرتره ادیتوریال شما در آتلیه آماده شد!'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NotificationSheet), findsNothing);
        expect(container.read(appStateProvider).currentTab, AppTab.atelier);
        expect(container.read(atelierProvider).activeTab, 'creations');
        expect(container.read(appStateProvider).unreadNotificationsCount, 3);

        // Re-open Notification Sheet & tap Mark all read
        await tester.tap(find.byTooltip('مرکز اعلان‌ها'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('خواندن همه ✓'));
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).unreadNotificationsCount, 0);
      },
    );
  });

  group('Step 8: Global Multi-Language Switching (EN LTR & AR RTL)', () {
    Widget wrapWithLocaleProvider(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final lang = ref.watch(localeProvider);
            return MaterialApp(
              locale: lang.locale,
              supportedLocales: AppLanguage.supportedLanguages
                  .map((l) => l.locale)
                  .toList(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(extensions: const [AppColors.lightWhite]),
              builder: (context, child) => ShadTheme(
                data: AppTheme.buildShadTheme(
                  palette: AppPalette.white,
                  isDark: false,
                ),
                child: Directionality(
                  textDirection: lang.textDirection,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              home: const MainShellScreen(),
            );
          },
        ),
      );
    }

    testWidgets(
      'Switching to EN switches Directionality to LTR and translates Shell, Profile, Wardrobe, and Shop with Western digits',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(wrapWithLocaleProvider(container));
        await tester.pumpAndSettle();

        container.read(localeProvider.notifier).setLanguage('en');
        await tester.pumpAndSettle();

        // Global Directionality flipped to LTR
        expect(
          Directionality.of(tester.element(find.byType(ProfileTab))),
          TextDirection.ltr,
        );

        // Header uses English + Western digits
        final header = find.byType(MainHeader);
        expect(
          find.descendant(of: header, matching: find.text('Sara Ahmadi')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: header, matching: find.textContaining('350')),
          findsWidgets,
        );
        expect(
          find.descendant(of: header, matching: find.text('40%')),
          findsOneWidget,
        );

        // Bottom nav shows English tabs
        final nav = find.byType(AppBottomNav);
        expect(
          find.descendant(of: nav, matching: find.text('Shop')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('Atelier')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('Stylist')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('Wellness')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('Wardrobe')),
          findsOneWidget,
        );

        // All 7 Profile sidebar tabs are translated to English
        final profile = find.byType(ProfileTab);
        for (final tabLabel in const [
          'Identity',
          'Media',
          'AI Anatomy',
          'Wallet & Plan',
          'Rewards & Net',
          'Companion',
          'Settings',
        ]) {
          expect(
            find.descendant(of: profile, matching: find.text(tabLabel)),
            findsOneWidget,
          );
        }

        // Assert zero Arabic/Persian characters inside MainShellScreen while on Identity sub-tab
        final persianOrArabic = RegExp(r'[\u0600-\u06FF]');
        final renderedTexts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(MainShellScreen),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data ?? '')
            .where((s) => persianOrArabic.hasMatch(s))
            .toList();
        expect(renderedTexts, isEmpty);

        // Settings sub-tab labels are translated to English
        await tester.tap(
          find.descendant(of: profile, matching: find.text('Settings')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Settings & Customization'), findsOneWidget);
        expect(find.text('Fashion Theme Palette'), findsOneWidget);
        expect(find.text('Show Floating Support Widget'), findsOneWidget);
        expect(find.text('Sign Out of Account'), findsOneWidget);

        // Wardrobe & Shop render in English
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Wardrobe')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Virtual Wardrobe'), findsOneWidget);
        expect(find.text('کمد مجازی'), findsNothing);

        await tester.tap(find.descendant(of: nav, matching: find.text('Shop')));
        await tester.pumpAndSettle();
        expect(find.text('Fashion & Style Shop'), findsOneWidget);
        expect(find.text('فروشگاه مد و استایل'), findsNothing);
      },
    );

    testWidgets(
      'Switching to AR keeps Directionality RTL and renders Arabic UI strings',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = _createTestContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(wrapWithLocaleProvider(container));
        await tester.pumpAndSettle();

        container.read(localeProvider.notifier).setLanguage('ar');
        await tester.pumpAndSettle();

        expect(
          Directionality.of(tester.element(find.byType(ProfileTab))),
          TextDirection.rtl,
        );

        final header = find.byType(MainHeader);
        expect(
          find.descendant(of: header, matching: find.text('سارة أحمدي')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: header, matching: find.text('٤٠٪')),
          findsOneWidget,
        );

        final profile = find.byType(ProfileTab);
        for (final tabLabel in const [
          'الهوية',
          'الوسائط',
          'تشريح AI',
          'المحفظة والخطة',
          'المكافآت',
          'المرافق الذكي',
          'الإعدادات',
        ]) {
          expect(
            find.descendant(of: profile, matching: find.text(tabLabel)),
            findsOneWidget,
          );
        }

        final nav = find.byType(AppBottomNav);
        expect(
          find.descendant(of: nav, matching: find.text('الخزانة')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nav, matching: find.text('المتجر')),
          findsOneWidget,
        );
      },
    );
  });
}
