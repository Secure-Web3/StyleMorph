import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_chip.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';
import 'package:stylemorph/features/shop/domain/extracted_web_product.dart';
import 'package:stylemorph/features/shop/presentation/shop_provider.dart';
import 'package:stylemorph/features/shop/presentation/shop_tab.dart';
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
    theme: AppTheme.buildTheme(
      palette: AppPalette.editorial,
      isDark: false,
      localeCode: locale.languageCode,
    ),
    home: Scaffold(body: child),
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  const sampleProduct = ExtractedWebProduct(
    title: 'Silk Trench Coat',
    imageUrl: '',
    pageUrl: 'https://www.zara.com/silk-trench-coat',
    sourceHost: 'www.zara.com',
    priceText: '249',
    currency: 'USD',
  );

  group('Shop KeepAlive & Category Chip Order', () {
    testWidgets(
      'preserves ShopTab and ShopWebDiscoveryView state across PageView and Profile switches',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(appStateProvider.notifier).switchTab(AppTab.shop);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('en'),
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

        final shopStateBefore = tester.state(find.byType(ShopTab));
        expect(shopStateBefore, isA<AutomaticKeepAliveClientMixin>());

        final webViewStateBefore = tester.state(
          find.byType(ShopWebDiscoveryView),
        );
        expect(webViewStateBefore, isA<AutomaticKeepAliveClientMixin>());

        // Switch away to Wardrobe, then Profile, then back to Shop.
        container.read(appStateProvider.notifier).switchTab(AppTab.wardrobe);
        await tester.pumpAndSettle();
        container.read(appStateProvider.notifier).switchTab(AppTab.profile);
        await tester.pumpAndSettle();
        container.read(appStateProvider.notifier).switchTab(AppTab.shop);
        await tester.pumpAndSettle();

        final shopStateAfter = tester.state(find.byType(ShopTab));
        final webViewStateAfter = tester.state(
          find.byType(ShopWebDiscoveryView),
        );
        expect(identical(shopStateBefore, shopStateAfter), isTrue);
        expect(identical(webViewStateBefore, webViewStateAfter), isTrue);
      },
    );

    testWidgets(
      'renders Wishlist at index 0 and Fit For Me at index 1 in category chip row',
      (tester) async {
        await tester.pumpWidget(_wrapWithApp(child: const ShopTab()));
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        final chips = tester.widgetList<AppChip>(find.byType(AppChip)).toList();

        expect(chips.length, greaterThanOrEqualTo(3));
        expect(chips[0].label, strings.shopCatFav);
        expect(chips[1].label, strings.shopFitMeChip);
        expect(chips[2].label, strings.allText);
      },
    );
  });

  group('Shop 3-Action Bar, Long-Press Sheet & Wishlist Flow', () {
    testWidgets(
      'DiscoveryProductActionBar exposes strictly Stylist, Atelier, Wishlist and never Wardrobe',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(
            container: container,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: DiscoveryProductActionBar(product: sampleProduct),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        expect(find.text(strings.shopWebSendToStylistBtn), findsOneWidget);
        expect(find.text(strings.shopWebSendToAtelierBtn), findsOneWidget);
        expect(find.text(strings.shopWebSaveWishlistBtn), findsOneWidget);
        expect(find.text(strings.shopWebSaveWardrobeBtn), findsNothing);

        // Save to Wishlist
        await tester.tap(find.text(strings.shopWebSaveWishlistBtn));
        await tester.pumpAndSettle();
        expect(
          container.read(shopProvider).webWishlist,
          contains(sampleProduct),
        );
        ScaffoldMessenger.of(
          tester.element(find.byType(DiscoveryProductActionBar)),
        ).clearSnackBars();
        await tester.pumpAndSettle();

        // Send to Stylist
        await tester.tap(find.text(strings.shopWebSendToStylistBtn));
        await tester.pumpAndSettle();
        expect(
          container.read(shopHandoffProvider).stylistProduct,
          sampleProduct,
        );
        expect(container.read(appStateProvider).currentTab, AppTab.stylist);
      },
    );

    testWidgets(
      'DiscoveryProductActionSheet exposes strictly 3 actions and wires Send to Atelier',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(
            container: container,
            child: const SingleChildScrollView(
              child: DiscoveryProductActionSheet(product: sampleProduct),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        expect(find.text(strings.shopWebSendToStylistBtn), findsOneWidget);
        expect(find.text(strings.shopWebSendToAtelierBtn), findsOneWidget);
        expect(find.text(strings.shopWebSaveWishlistBtn), findsOneWidget);
        expect(find.text(strings.shopWebSaveWardrobeBtn), findsNothing);

        await tester.tap(find.text(strings.shopWebSendToAtelierBtn));
        await tester.pumpAndSettle();
        expect(
          container.read(shopHandoffProvider).atelierProduct,
          sampleProduct,
        );
        expect(container.read(appStateProvider).currentTab, AppTab.atelier);
      },
    );

    testWidgets(
      'saving external WebView product displays it when Wishlist chip is selected',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(container: container, child: const ShopTab()),
        );
        await tester.pumpAndSettle();

        container
            .read(shopProvider.notifier)
            .saveWebProductToWishlist(sampleProduct);
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        await tester.tap(find.text(strings.shopCatFav));
        await tester.pumpAndSettle();

        expect(find.text(sampleProduct.title), findsOneWidget);
        expect(find.text(strings.shopWishlistReopenBrowser), findsOneWidget);
        expect(find.text(strings.shopWebSendToStylistBtn), findsOneWidget);
        expect(find.text(strings.shopWebSendToAtelierBtn), findsOneWidget);
      },
    );

    test('buildImageLongPressBridgeJs wires StyleMorphProductChannel', () {
      final js = ShopWebDiscoveryView.buildImageLongPressBridgeJs();
      expect(js, contains('StyleMorphProductChannel'));
      expect(js, contains('contextmenu'));
      expect(js, contains('touchstart'));
      expect(js, contains('500'));
    });
  });
}
