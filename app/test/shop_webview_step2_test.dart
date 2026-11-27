import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/shop/domain/extracted_web_product.dart';
import 'package:stylemorph/features/shop/presentation/widgets/web_product_action_bar.dart';

Widget _wrapTest({required Widget child, Locale locale = const Locale('en')}) {
  return ProviderScope(
    child: MaterialApp(
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
      home: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    ),
  );
}

void main() {
  group('ExtractedWebProduct.fromJson', () {
    test('parses complete product metadata accurately', () {
      final product = ExtractedWebProduct.fromJson({
        'title': 'Cashmere Trench Coat',
        'imageUrl': 'https://example.com/coat.jpg',
        'pageUrl': 'https://www.zara.com/us/en/cashmere-trench',
        'sourceHost': 'www.zara.com',
        'priceText': '199.00',
        'currency': 'USD',
      });

      expect(product.title, 'Cashmere Trench Coat');
      expect(product.imageUrl, 'https://example.com/coat.jpg');
      expect(product.pageUrl, 'https://www.zara.com/us/en/cashmere-trench');
      expect(product.sourceHost, 'www.zara.com');
      expect(product.priceText, '199.00');
      expect(product.currency, 'USD');
      expect(product.isValid, isTrue);
    });

    test('handles missing price, image, and host gracefully', () {
      final product = ExtractedWebProduct.fromJson({
        'title': 'Minimalist Leather Tote',
        'pageUrl': 'https://shop.mango.com/item/123',
        'priceText': null,
        'imageUrl': '',
      });

      expect(product.title, 'Minimalist Leather Tote');
      expect(product.imageUrl, '');
      expect(product.sourceHost, 'shop.mango.com');
      expect(product.priceText, isNull);
      expect(product.currency, isNull);
      expect(product.isValid, isTrue);
    });

    test('marks product invalid when pageUrl is empty', () {
      final product = ExtractedWebProduct.fromJson({
        'title': 'Orphan Title',
        'pageUrl': '',
      });
      expect(product.isValid, isFalse);
    });
  });

  group('WebProductActionBar', () {
    const sampleProduct = ExtractedWebProduct(
      title: 'Tailored Linen Blazer',
      imageUrl: '',
      pageUrl: 'https://www.zara.com/blazer',
      sourceHost: 'www.zara.com',
      priceText: '129',
      currency: 'USD',
    );

    testWidgets('renders 3 actions cleanly in LTR (en) without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapTest(
          locale: const Locale('en'),
          child: const WebProductActionBar(product: sampleProduct),
        ),
      );
      await tester.pumpAndSettle();

      const strings = AppStrings('en');
      expect(find.text(strings.shopWebTryOnBtn), findsOneWidget);
      expect(find.text(strings.shopWebSaveWardrobeBtn), findsOneWidget);
      expect(find.text(strings.shopWebFeedbackBtn), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 3 actions cleanly in RTL (fa) and records feedback', (
      tester,
    ) async {
      WebProductFeedbackType? recorded;

      await tester.pumpWidget(
        _wrapTest(
          locale: const Locale('fa'),
          child: WebProductActionBar(
            product: sampleProduct,
            onFeedbackRecorded: (type) => recorded = type,
          ),
        ),
      );
      await tester.pumpAndSettle();

      const strings = AppStrings('fa');
      expect(find.text(strings.shopWebTryOnBtn), findsOneWidget);
      expect(find.text(strings.shopWebSaveWardrobeBtn), findsOneWidget);
      expect(find.text(strings.shopWebFeedbackBtn), findsOneWidget);

      await tester.tap(find.text(strings.shopWebFeedbackBtn));
      await tester.pumpAndSettle();

      expect(find.text(strings.shopWebFeedbackTitle), findsOneWidget);
      await tester.tap(find.text(strings.shopWebFeedbackAccurate));
      await tester.pumpAndSettle();

      expect(recorded, WebProductFeedbackType.accurate);
      expect(tester.takeException(), isNull);
    });
  });
}
