import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';
import 'package:stylemorph/features/shop/presentation/shop_provider.dart';
import 'package:stylemorph/features/shop/presentation/shop_tab.dart';
import 'package:stylemorph/features/shop/presentation/widgets/shop_filter_sheet.dart';
import 'package:stylemorph/features/shop/presentation/widgets/shop_web_discovery_view.dart';

Widget _wrapWithApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ProviderContainer? container,
}) {
  final app = MaterialApp(
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
    theme: AppTheme.buildTheme(palette: AppPalette.editorial, isDark: false),
    home: Scaffold(body: child),
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  testWidgets('sm_logo_transparent.png has exact alpha == 0 on all corners', (
    tester,
  ) async {
    final file = File('assets/images/brand/sm_logo_transparent.png');
    expect(file.existsSync(), isTrue);

    final byteData = await tester.runAsync(() async {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data, image.width, image.height);
    });
    expect(byteData, isNotNull);

    final (rgba, w, h) = byteData!;
    expect(rgba, isNotNull);
    int alphaAt(int x, int y) => rgba!.getUint8((y * w + x) * 4 + 3);

    expect(alphaAt(0, 0), 0);
    expect(alphaAt(w - 1, 0), 0);
    expect(alphaAt(0, h - 1), 0);
    expect(alphaAt(w - 1, h - 1), 0);
  });

  group('ShopTab declutter', () {
    testWidgets(
      'renders 2-row header with Fit For Me first, compact sort menu, and dismissible pills',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(container: container, child: const ShopTab()),
        );
        await tester.pumpAndSettle();

        final strings = const AppStrings('en');

        // Compact sort PopupMenuButton replaces tall bottom sheet
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);

        // Fit For Me is first chip in Row 2, bulky banner & 4th row are gone
        expect(find.text(strings.shopFitMeChip), findsOneWidget);
        expect(find.text(strings.shopFitMeBanner), findsNothing);
        expect(find.textContaining('${strings.shopSortPrefix}:'), findsNothing);

        // Activate a filter via provider and verify dismissible pill + Clear All
        container
            .read(shopProvider.notifier)
            .updateFilter(const ShopFilter(brands: ['زارا'], fitFilter: true));
        await tester.pumpAndSettle();

        expect(find.text('Zara'), findsOneWidget);
        expect(find.text(strings.shopClearAllFilters), findsOneWidget);

        // Dismiss Zara pill
        await tester.tap(find.text('Zara'));
        await tester.pumpAndSettle();
        expect(container.read(shopProvider).filter.brands, isEmpty);

        // Tap Clear All to reset fitFilter as well
        await tester.tap(find.text(strings.shopClearAllFilters));
        await tester.pumpAndSettle();
        expect(container.read(shopProvider).filter.fitFilter, isFalse);
      },
    );
  });

  group('ShopFilterSheet context-aware & collapsed Members Only', () {
    testWidgets('shows shoe sizes for shoe category and hides Members Only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          child: ShopFilterSheet(
            initialFilter: const ShopFilter(category: 'shoe'),
            products: const [],
            onApply: (_) {},
            onReset: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = const AppStrings('en');
      expect(find.text('36'), findsOneWidget);
      expect(find.text('XS'), findsNothing);

      // Members Only is collapsed by default
      expect(find.text(strings.shopMembersOnly), findsOneWidget);
      expect(find.text(strings.shopToggleAvail), findsNothing);

      // Expanding Members Only reveals member-store controls
      await tester.tap(find.text(strings.shopMembersOnly));
      await tester.pumpAndSettle();
      expect(find.text(strings.shopToggleAvail), findsOneWidget);
    });

    testWidgets('shows letter sizes for cloth and hides sizes for bag', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          child: ShopFilterSheet(
            initialFilter: const ShopFilter(category: 'cloth'),
            products: const [],
            onApply: (_) {},
            onReset: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('XS'), findsOneWidget);
      expect(find.text('36'), findsNothing);

      await tester.pumpWidget(
        _wrapWithApp(
          child: ShopFilterSheet(
            key: const ValueKey('bag'),
            initialFilter: const ShopFilter(category: 'bag'),
            products: const [],
            onApply: (_) {},
            onReset: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('XS'), findsNothing);
      expect(find.text('36'), findsNothing);
    });
  });

  group('MainShellScreen & ShopWebDiscoveryView across locales', () {
    for (final lang in [
      AppLanguage.fromCode('fa'),
      AppLanguage.fromCode('en'),
    ]) {
      testWidgets('renders cleanly in ${lang.code}', (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(localeProvider.notifier).setLanguage(lang.code);
        container.read(appStateProvider.notifier).switchTab(AppTab.shop);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: lang.locale,
              supportedLocales: const [Locale('fa'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.buildTheme(
                palette: AppPalette.editorial,
                isDark: false,
              ),
              home: const MainShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PageView), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          _wrapWithApp(
            locale: lang.locale,
            container: container,
            child: ShopWebDiscoveryView(
              searchUri: Uri.https('www.google.com', '/search', {
                'tbm': 'isch',
                'udm': '2',
                'q': 'fashion',
              }),
              searchQuery: 'fashion',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ShopWebDiscoveryView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  test('ShopWebDiscoveryView injected CSS enforces crisp unblurred images', () {
    final js = ShopWebDiscoveryView.buildCrispImagesJs();
    expect(js, contains('filter: none !important'));
    expect(js, contains('-webkit-filter: none !important'));
    expect(js, contains('backdrop-filter: none !important'));
    expect(js, contains('opacity: 1 !important'));
    expect(js.toLowerCase(), isNot(contains('blur(')));
  });
}
