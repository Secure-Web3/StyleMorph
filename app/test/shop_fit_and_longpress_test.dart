import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/shop/domain/shop_product.dart';
import 'package:stylemorph/features/shop/domain/shop_query_builder.dart';
import 'package:stylemorph/features/shop/presentation/shop_provider.dart';
import 'package:stylemorph/features/shop/presentation/widgets/shop_web_discovery_view.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_theme_palette': 'editorial',
      'user_theme_mode': 'light',
      'app_language_code': 'en',
    });
  });

  group('Step 3 - Fit For Me Gender & Anatomy Binding', () {
    test(
      'normalizes gender across locales and builds Men/Women Fit For Me queries',
      () {
        for (final maleVal in ['male', 'مرد', 'erkek', 'ذكر']) {
          final spec = ShopSearchQueryBuilder.resolveProfileFitSpec({
            'gender': maleVal,
            'shoeSize': '43',
            'chest': '100',
            'fitPreference': 'slim',
          });
          expect(spec.normalizedGenderCode, equals('m'));
          expect(spec.genderSearchKeyword, equals("Men's"));
          expect(spec.clothingSize, equals('L'));
          expect(spec.shoeSize, equals('43'));
          expect(spec.fitPreference, equals('slim'));
        }

        final maleQuery = ShopSearchQueryBuilder.buildQuery(
          filter: const ShopFilter(
            searchQuery: 'sneakers',
            category: 'shoe',
            fitFilter: true,
          ),
          localeCode: 'en',
          profileGender: 'male',
          shoeSize: '43',
          clothingSize: 'L',
        );
        expect(maleQuery, startsWith("Men's"));
        expect(maleQuery, contains('Shoe 43'));
        expect(maleQuery, isNot(contains("Women's")));

        final femaleQuery = ShopSearchQueryBuilder.buildQuery(
          filter: const ShopFilter(
            searchQuery: 'blazer',
            category: 'cloth',
            fitFilter: true,
          ),
          localeCode: 'en',
          profileGender: 'زن',
          clothingSize: 'S',
          fitPreference: 'regular',
        );
        expect(femaleQuery, startsWith("Women's"));
        expect(femaleQuery, contains('Size S'));
        expect(femaleQuery, contains('regular fit'));

        final unpersonalizedQuery = ShopSearchQueryBuilder.buildQuery(
          filter: const ShopFilter(
            searchQuery: 'blazer',
            category: 'cloth',
            fitFilter: false,
          ),
          localeCode: 'en',
          profileGender: 'male',
          clothingSize: 'L',
        );
        expect(unpersonalizedQuery, isNot(contains("Men's")));
        expect(unpersonalizedQuery, isNot(contains('Size L')));
      },
    );

    test(
      'ShopState.filteredProducts enforces profile gender and anatomy sizes when Fit For Me is ON',
      () {
        final maleSpec = ShopSearchQueryBuilder.resolveProfileFitSpec({
          'gender': 'male',
          'shoeSize': '43',
          'shirtSize': 'L',
        });

        final state = ShopState(
          products: const [
            ShopProduct(
              id: 1,
              name: 'Women Dress',
              category: 'cloth',
              gender: 'w',
              brand: 'Zara',
              iconName: 'shirt',
              colorHex: '#000000',
              sizes: ['L'],
              colors: ['Black'],
              rating: 4.5,
              reviewCount: 10,
              material: 'Cotton',
              season: 'Summer',
              wardrobeFit: [],
              sellers: [],
            ),
            ShopProduct(
              id: 2,
              name: 'Men Jacket',
              category: 'cloth',
              gender: 'm',
              brand: 'Zara',
              iconName: 'shirt',
              colorHex: '#000000',
              sizes: ['L'],
              colors: ['Black'],
              rating: 4.8,
              reviewCount: 20,
              material: 'Wool',
              season: 'Winter',
              wardrobeFit: [],
              sellers: [],
            ),
            ShopProduct(
              id: 3,
              name: 'Men Small Tee',
              category: 'cloth',
              gender: 'm',
              brand: 'Zara',
              iconName: 'shirt',
              colorHex: '#000000',
              sizes: ['S'],
              colors: ['White'],
              rating: 4.2,
              reviewCount: 5,
              material: 'Cotton',
              season: 'Summer',
              wardrobeFit: [],
              sellers: [],
            ),
          ],
          filter: const ShopFilter(fitFilter: true),
          profileFit: maleSpec,
        );

        final filtered = state.filteredProducts;
        expect(filtered.map((p) => p.id).toList(), equals([2]));
      },
    );
  });

  group('Step 1 & 2 - WebView Long-Press Menu & Theme Surface Background', () {
    test(
      'buildImageLongPressBridgeJs uses capturing listeners, elementFromPoint, and StyleMorphProductChannel',
      () {
        final js = ShopWebDiscoveryView.buildImageLongPressBridgeJs();
        expect(js, contains('document.elementFromPoint'));
        expect(js, contains('capture: true, passive: false'));
        expect(js, contains('StyleMorphProductChannel.postMessage'));
        expect(js, contains('backgroundImage'));
      },
    );

    testWidgets(
      'ShopWebDiscoveryView opens DiscoveryProductActionSheet with 3 actions on StyleMorphProductChannel message',
      (tester) async {
        void Function(String)? triggerChannelMessage;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeProvider.overrideWith(
                (ref) => LocaleNotifier()..setLanguage('en'),
              ),
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(AppState(isProfileLoaded: true)),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.buildTheme(
                palette: AppPalette.editorial,
                isDark: false,
              ),
              locale: const Locale('en'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Scaffold(
                body: ShopWebDiscoveryView(
                  searchUri: Uri.https('www.google.com', '/search', {
                    'tbm': 'isch',
                    'q': "Men's sneakers",
                  }),
                  searchQuery: "Men's sneakers",
                  onTestProductChannelReady: (handler) {
                    triggerChannelMessage = handler;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(triggerChannelMessage, isNotNull);
        triggerChannelMessage!(
          jsonEncode({
            'imageUrl': 'https://example.com/sneaker.jpg',
            'title': 'Classic Leather Sneaker',
            'pageUrl': 'https://example.com/product/123',
            'sourceHost': 'example.com',
          }),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DiscoveryProductActionSheet), findsOneWidget);
        expect(find.text('Send to Stylist'), findsOneWidget);
        expect(find.text('Send to Atelier'), findsOneWidget);
        expect(find.text('Save to Wishlist'), findsOneWidget);
      },
    );

    testWidgets(
      'resolveWebViewBackgroundColor matches Theme.of(context).colorScheme.surface in Light and Dark themes',
      (tester) async {
        Color? lightSurface;
        Color? darkSurface;

        final lightTheme = AppTheme.buildTheme(
          palette: AppPalette.white,
          isDark: false,
        );
        final darkTheme = AppTheme.buildTheme(
          palette: AppPalette.obsidian,
          isDark: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Builder(
              builder: (context) {
                lightSurface =
                    ShopWebDiscoveryView.resolveWebViewBackgroundColor(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(lightSurface, equals(lightTheme.colorScheme.surface));

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('dark_theme_app'),
            theme: darkTheme,
            home: Builder(
              builder: (context) {
                darkSurface =
                    ShopWebDiscoveryView.resolveWebViewBackgroundColor(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(darkSurface, equals(darkTheme.colorScheme.surface));
        expect(darkSurface, isNot(equals(lightSurface)));
      },
    );
  });
}
