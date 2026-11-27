import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/theme_provider.dart';
import 'package:stylemorph/features/shop/domain/shop_query_builder.dart';
import 'package:stylemorph/features/shop/presentation/shop_provider.dart';
import 'package:stylemorph/features/shop/presentation/shop_tab.dart';
import 'package:stylemorph/features/shop/presentation/widgets/shop_web_discovery_view.dart';

Widget _wrapWithApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeData? theme,
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
    theme:
        theme ??
        AppTheme.buildTheme(palette: AppPalette.editorial, isDark: false),
    home: Scaffold(body: child),
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  group('ShopSearchQueryBuilder', () {
    test('returns curated default query when all filters are empty', () {
      const filter = ShopFilter();
      final uri = ShopSearchQueryBuilder.buildSearchUri(
        filter: filter,
        localeCode: 'en',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/search');
      expect(uri.queryParameters['tbm'], 'isch');
      expect(uri.queryParameters['udm'], '2');
      expect(uri.queryParameters['q'], 'luxury fashion outfit lookbook');
    });

    test('combines search text, category, brands, colors, and Fit For Me', () {
      const filter = ShopFilter(
        searchQuery: 'linen blazer',
        category: 'cloth',
        brands: ['Zara'],
        colors: ['Beige'],
        fitFilter: true,
      );

      final uri = ShopSearchQueryBuilder.buildSearchUri(
        filter: filter,
        localeCode: 'en',
        clothingSize: 'M',
        shoeSize: '42',
      );

      final q = uri.queryParameters['q']!;
      expect(uri.queryParameters['tbm'], 'isch');
      expect(q, contains('linen blazer'));
      expect(q, contains('clothing'));
      expect(q, contains('Zara'));
      expect(q, contains('Beige'));
      expect(q, contains('Size M'));
      expect(q, contains('outfit buy'));
    });

    test('uses shoe size when category is shoe and Fit For Me is enabled', () {
      const filter = ShopFilter(category: 'shoe', fitFilter: true);

      final q = ShopSearchQueryBuilder.buildQuery(
        filter: filter,
        localeCode: 'en',
        clothingSize: 'L',
        shoeSize: '43',
      );

      expect(q, contains('shoes'));
      expect(q, contains('Shoe 43'));
      expect(q, isNot(contains('Size L')));
    });
  });

  group('ShopTab & ShopWebDiscoveryView', () {
    testWidgets(
      'preserves all 4 top filter rows and updates generated query reactively',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(container: container, child: const ShopTab()),
        );
        await tester.pumpAndSettle();

        final strings = const AppStrings('en');

        // Row 1: Search input + Filter & Sort buttons
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
        expect(find.byIcon(Icons.sort_rounded), findsOneWidget);

        // Row 2: Category chips
        expect(find.text(strings.allText), findsOneWidget);
        expect(find.text(strings.shopCatCloth), findsOneWidget);
        expect(find.text(strings.wardCatSh), findsOneWidget);

        // Row 3: Fit For Me toggle banner
        expect(find.text(strings.shopFitMeBanner), findsOneWidget);

        // Row 4: Status & active Sort bar
        expect(
          find.textContaining('${strings.shopSortPrefix}:'),
          findsOneWidget,
        );

        // Discovery view is mounted
        expect(find.byType(ShopWebDiscoveryView), findsOneWidget);

        // Reactively update search query, category, and Fit For Me
        await tester.enterText(find.byType(TextField), 'silk dress');
        await tester.tap(find.text(strings.shopCatCloth));
        await tester.tap(find.text(strings.shopFitMeBanner));
        await tester.pumpAndSettle();

        final view = tester.widget<ShopWebDiscoveryView>(
          find.byType(ShopWebDiscoveryView),
        );
        expect(view.searchQuery, contains('silk dress'));
        expect(view.searchQuery, contains('clothing'));
        expect(view.searchQuery, contains('Size M'));
        expect(view.searchUri.queryParameters['tbm'], 'isch');
      },
    );

    testWidgets('theme switching updates ShopWebDiscoveryView without errors', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final themeState = ref.watch(themeProvider);
              return MaterialApp(
                theme: AppTheme.buildTheme(
                  palette: themeState.palette,
                  isDark: themeState.isDark,
                ),
                home: Scaffold(
                  body: ShopWebDiscoveryView(
                    searchUri: Uri.https('www.google.com', '/search', {
                      'tbm': 'isch',
                      'udm': '2',
                      'q': 'luxury fashion',
                    }),
                    searchQuery: 'luxury fashion',
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch across multiple palettes and dark/light modes
      final themeNotifier = container.read(themeProvider.notifier);
      themeNotifier.setPalette(AppPalette.obsidian);
      themeNotifier.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShopWebDiscoveryView), findsOneWidget);
    });
  });
}
