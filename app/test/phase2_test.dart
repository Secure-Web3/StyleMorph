import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/features/wardrobe/domain/wardrobe_item.dart';
import 'package:stylemorph/features/wardrobe/data/wardrobe_repository.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_provider.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_tab.dart';
import 'package:stylemorph/features/shop/data/shop_repository.dart';
import 'package:stylemorph/features/shop/presentation/shop_provider.dart';
import 'package:stylemorph/features/shop/presentation/shop_tab.dart';

void main() {
  group('Phase 2: Wardrobe Tests', () {
    test('WardrobeRepository returns initial 22 items and manages state', () {
      final repo = WardrobeRepository();
      expect(repo.getItems().length, 22);

      const newItem = WardrobeItem(
        id: 'test_1',
        name: 'پیراهن تست',
        category: 'cl',
        subCategory: 'بالاتنه',
        colorName: 'سفید',
        colorHex: '#ffffff',
        season: 'بهار',
        occasion: 'روزمره',
        material: 'نخ',
        size: 'M',
        isFavorite: false,
        isArchived: false,
      );

      repo.addItem(newItem);
      expect(repo.getItems().length, 23);

      repo.toggleFavorite('test_1');
      expect(
        repo.getItems().firstWhere((e) => e.id == 'test_1').isFavorite,
        true,
      );

      repo.deleteItem('test_1');
      expect(repo.getItems().length, 22);
    });

    test('WardrobeNotifier filtering and search works reactive', () {
      final repo = WardrobeRepository();
      final notifier = WardrobeNotifier(repo);

      // Default active count (22 total - 1 archived = 21)
      expect(notifier.state.filteredItems.length, 21);

      // Filter by category: cl
      notifier.setCategory('cl');
      expect(notifier.state.filter.category, 'cl');
      expect(
        notifier.state.filteredItems.every((e) => e.category == 'cl'),
        true,
      );

      // Search
      notifier.setSearch('جین');
      expect(notifier.state.filteredItems.length, 1);
      expect(notifier.state.filteredItems.first.name, 'شلوار جین سرمه‌ای');

      // Clear search
      notifier.setSearch('');
      notifier.setCategory('all');
      expect(notifier.state.filteredItems.length, 21);
    });

    testWidgets('WardrobeTab renders correctly with categories and items', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
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
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: WardrobeTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('کمد مجازی'), findsOneWidget);
      expect(find.text('آپلود آیتم'), findsOneWidget);
      expect(find.text('همه'), findsOneWidget);
      expect(find.text('لباس'), findsOneWidget);
    });
  });

  group('Phase 2: Shop Tests', () {
    test('ShopRepository loads all 16 products with multi-sellers', () {
      final repo = ShopRepository();
      final products = repo.getProducts();
      expect(products.length, 16);

      final p1 = repo.getProductById(1);
      expect(p1, isNotNull);
      expect(p1!.name, 'پیراهن کتان آستین‌بلند');
      expect(p1.sellers.length, 3);
      expect(p1.lowestPrice, 480000);
    });

    test('ShopNotifier wishlist, comparison and category filtering work', () {
      final repo = ShopRepository();
      final notifier = ShopNotifier(repo);

      expect(notifier.state.products.length, 16);
      expect(notifier.state.filteredProducts.length, 16);

      // Wishlist toggle
      notifier.toggleWishlist(1);
      expect(notifier.state.wishlist.contains(1), true);

      // Filter category shoe
      notifier.setCategory('shoe');
      expect(
        notifier.state.filteredProducts.every((p) => p.category == 'shoe'),
        true,
      );

      // Wishlist filter
      notifier.setCategory('fav');
      expect(notifier.state.filteredProducts.length, 1);
      expect(notifier.state.filteredProducts.first.id, 1);

      // Comparison toggle (max 3)
      notifier.toggleCompare(1);
      notifier.toggleCompare(2);
      notifier.toggleCompare(3);
      notifier.toggleCompare(4); // should not exceed 3
      expect(notifier.state.compareList.length, 3);
    });

    testWidgets('ShopTab renders search, categories, and products', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
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
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: ShopTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فروشگاه مد و استایل'), findsOneWidget);
      expect(find.text('پوشاک'), findsOneWidget);
      expect(find.text('کفش'), findsOneWidget);
    });
  });
}
