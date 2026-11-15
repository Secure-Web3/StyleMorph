import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemorph_admin/main.dart';
import 'package:stylemorph_admin/core/state/admin_state.dart';
import 'package:stylemorph_admin/features/auth/presentation/auth_gate.dart';
import 'package:stylemorph_admin/features/auth/presentation/consumer_web_portal_screen.dart';
import 'package:stylemorph_admin/features/layout/presentation/admin_scaffold.dart';
import 'package:stylemorph_admin/features/layout/presentation/admin_sidebar.dart';
import 'package:stylemorph_admin/features/seller_portal/presentation/seller_scaffold.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget buildTestableApp({AuthGateRole initialRole = AuthGateRole.landing}) {
    return ProviderScope(
      overrides: [
        authRoleProvider.overrideWith((ref) {
          final notifier = AuthRoleNotifier();
          notifier.selectRole(initialRole);
          return notifier;
        }),
      ],
      child: const StyleMorphAdminApp(),
    );
  }

  group('1. 3-Way Auth Gate & Routing Tests', () {
    testWidgets('Renders 3-Way Auth Gate with all 3 dedicated portal options',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.landing));
      await tester.pumpAndSettle();

      expect(find.byType(AuthGateScreen), findsOneWidget);
      expect(find.text('StyleMorph Unified Gate'), findsOneWidget);
      expect(find.text('پنل مدیریت کلان (Admin)'), findsOneWidget);
      expect(find.text('پورتال فروشندگان (Sellers)'), findsOneWidget);
      expect(find.text('وب‌اپلیکیشن کاربران (Web App)'), findsOneWidget);
    });

    testWidgets('Routes cleanly into Admin Panel from Auth Gate and logs out',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.landing));
      await tester.pumpAndSettle();

      final adminEnterBtn = find.text('ورود به پنل مدیریت');
      expect(adminEnterBtn, findsOneWidget);
      await tester.tap(adminEnterBtn);
      await tester.pumpAndSettle();

      // Now inside AdminScaffold
      expect(find.byType(AdminScaffold), findsOneWidget);
      expect(find.byType(AdminSidebar), findsOneWidget);

      // Verify Admin Logout
      final logoutBtn = find.byTooltip('خروج به درگاه اصلی');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Returns to AuthGateScreen
      expect(find.byType(AuthGateScreen), findsOneWidget);
    });

    testWidgets('Routes cleanly into Seller Portal from Auth Gate and logs out',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.landing));
      await tester.pumpAndSettle();

      final sellerEnterBtn = find.text('ورود به پورتال فروشندگان');
      expect(sellerEnterBtn, findsOneWidget);
      await tester.tap(sellerEnterBtn);
      await tester.pumpAndSettle();

      // Now inside SellerScaffold
      expect(find.byType(SellerScaffold), findsOneWidget);
      expect(find.text('بوتیک زاگرس'), findsOneWidget);
      expect(find.text('پورتال همکاران تجاری B2B'), findsOneWidget);

      // Verify Seller Logout
      final logoutBtn = find.text('خروج به درگاه اصلی');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Returns to AuthGateScreen
      expect(find.byType(AuthGateScreen), findsOneWidget);
    });

    testWidgets('Routes cleanly into Consumer Web Portal from Auth Gate and logs out',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.landing));
      await tester.pumpAndSettle();

      final consumerEnterBtn = find.text('ورود به پورتال وب کاربران');
      expect(consumerEnterBtn, findsOneWidget);
      await tester.tap(consumerEnterBtn);
      await tester.pumpAndSettle();

      // Inside ConsumerWebPortalScreen
      expect(find.byType(ConsumerWebPortalScreen), findsOneWidget);
      expect(find.text('StyleMorph Consumer Web'), findsOneWidget);

      // Logout to Auth Gate
      final logoutBtn = find.text('خروج به درگاه اصلی');
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Returns to AuthGateScreen
      expect(find.byType(AuthGateScreen), findsOneWidget);
    });
  });

  group('2. Final 8-Section Admin Panel Architecture Tests', () {
    testWidgets('Sidebar has exactly 8 clean Persian sections without letter prefixes',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.admin));
      await tester.pumpAndSettle();

      expect(kSidebarNavItems.length, 8);
      expect(kSidebarNavItems[0].titleFa, 'داشبورد کلان');
      expect(kSidebarNavItems[1].titleFa, 'امور مالی و دفتر کل');
      expect(kSidebarNavItems[2].titleFa, 'مدیریت ماژولهای اپ');
      expect(kSidebarNavItems[3].titleFa, 'دروازه هوش مصنوعی');
      expect(kSidebarNavItems[4].titleFa, 'مدیریت فروشندگان');
      expect(kSidebarNavItems[5].titleFa, 'تنظیمات زیرساختی');
      expect(kSidebarNavItems[6].titleFa, 'تبلیغات درونبرنامهای');
      expect(kSidebarNavItems[7].titleFa, 'پشتیبانی و تیکتینگ');

      // Ensure no A-I prefixes
      for (final item in kSidebarNavItems) {
        expect(item.titleFa.contains(RegExp(r'^[A-I]\s')), isFalse);
      }
    });

    testWidgets('Navigates across all 8 Admin sections successfully',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.admin));
      await tester.pumpAndSettle();

      // Section 0: Command Dashboard
      expect(find.text('داشبورد کلان مانیتورینگ سیستم'), findsOneWidget);
      expect(find.text('دسترسی مستقیم و ناوبری بخش‌های ۸‌گانه مدیریتی'), findsOneWidget);

      // Section 1: Finance & Ledger
      await tester.tap(find.text('امور مالی و دفتر کل').first);
      await tester.pumpAndSettle();
      expect(find.text('امور مالی و دفتر کل تغییرناپذیر (Immutable Ledger)'), findsOneWidget);

      // Section 2: Mobile App Modules
      await tester.tap(find.text('مدیریت ماژولهای اپ').first);
      await tester.pumpAndSettle();
      expect(find.text('مدیریت ماژولهای اپلیکیشن (Mobile Modules Manager)'), findsOneWidget);
      expect(find.text('پروفایل'), findsWidgets);
      expect(find.text('کمد مجازی'), findsWidgets);
      expect(find.text('تندرستی'), findsWidgets);

      // Section 3: AI Gateway
      await tester.tap(find.text('دروازه هوش مصنوعی').first);
      await tester.pumpAndSettle();
      expect(find.text('دروازه هوش مصنوعی، بالانسر کلیدها و قیمت‌گذاری (AI Gateway)'), findsOneWidget);

      // Section 4: Seller Governance
      await tester.tap(find.text('مدیریت فروشندگان').first);
      await tester.pumpAndSettle();
      expect(find.text('مدیریت فروشندگان و قوانین مالی (Seller Governance)'), findsOneWidget);

      // Section 5: Infrastructure Settings (4 sub-tabs)
      await tester.tap(find.text('تنظیمات زیرساختی').first);
      await tester.pumpAndSettle();
      expect(find.text('تنظیمات زیرساختی، امنیت و پیکربندی (Infrastructure & Security)'), findsOneWidget);
      expect(find.text('زبان، تم و پیکربندی (Remote Config)'), findsOneWidget);
      expect(find.text('کاربران و نشست‌ها (Users & RBAC)'), findsOneWidget);
      expect(find.text('هاب بات‌ها و وب‌هوک (Bot & API Hub)'), findsOneWidget);
      expect(find.text('لاگ ممیزی و بکاپ (Audit & Backup)'), findsOneWidget);

      // Section 6: In-App Ads, SSV, Adaptive Generosity & Permanent Wellness Lock
      await tester.tap(find.text('تبلیغات درونبرنامهای').first);
      await tester.pumpAndSettle();
      expect(find.text('تبلیغات درون‌برنامه‌ای و اسپانسرینگ مد (AdMob & AI Sponsoring)'), findsOneWidget);
      expect(find.text('موتور سخاوت تطبیقی سکه (Adaptive Generosity Engine)'), findsOneWidget);
      expect(find.text('قفل دائمی حریم خصوصی بخش تندرستی (Permanent Wellness Ad Lock)'), findsOneWidget);

      // Section 7: Support & Ticketing
      await tester.tap(find.text('پشتیبانی و تیکتینگ').first);
      await tester.pumpAndSettle();
      expect(find.text('میز پشتیبانی هوشمند و داوری مغایرت‌ها (Smart Support Desk)'), findsOneWidget);
      expect(find.text('لاگ خطای هوش مصنوعی (AI Error Log)'), findsOneWidget);
    });
  });

  group('3. Seller Portal Isolation (RBAC) & Theme/RTL Tests', () {
    testWidgets('Seller Portal is completely isolated from Admin Sidebar and Admin sections',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.seller));
      await tester.pumpAndSettle();

      expect(find.byType(SellerScaffold), findsOneWidget);
      expect(find.byType(AdminSidebar), findsNothing);
      expect(find.text('داشبورد کلان مانیتورینگ سیستم'), findsNothing);
      expect(find.text('دفتر کل مالی و مانیتورینگ تراز سکه (Double-Entry Ledger)'), findsNothing);

      // Verify dedicated Seller tabs
      expect(find.text('داشبورد فروشگاه'), findsOneWidget);
      expect(find.text('کاتالوگ محصولات'), findsOneWidget);
      expect(find.text('کمپین‌های تبلیغاتی'), findsOneWidget);
      expect(find.text('کیف پول و واریزی‌ها'), findsOneWidget);
    });

    testWidgets('Verifies RTL Directionality and Theme Toggle behavior',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableApp(initialRole: AuthGateRole.admin));
      await tester.pumpAndSettle();

      // Check RTL Directionality
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);

      // Toggle Theme
      final themeToggleBtn = find.byTooltip('تغییر پوسته (Dark / Light)');
      expect(themeToggleBtn, findsOneWidget);
      await tester.tap(themeToggleBtn);
      await tester.pumpAndSettle();
    });
  });
}
