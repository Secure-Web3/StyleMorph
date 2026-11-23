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
import 'package:stylemorph/features/wardrobe/presentation/widgets/wardrobe_filter_panel.dart';
import 'package:stylemorph/features/shop/data/shop_repository.dart';
import 'package:stylemorph/features/shop/presentation/shop_provider.dart';
import 'package:stylemorph/features/shop/presentation/shop_tab.dart';

Widget _buildWardrobeTestApp({WardrobeRepository? repo}) {
  return ProviderScope(
    overrides: [
      if (repo != null) wardrobeRepositoryProvider.overrideWithValue(repo),
    ],
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
  );
}

void main() {
  group('Phase 2: Wardrobe Tests', () {
    test(
      'WardrobeRepository starts empty with zero fake items and manages state',
      () {
        final repo = WardrobeRepository();
        expect(repo.getItems().length, 0);

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
        expect(repo.getItems().length, 1);

        repo.toggleFavorite('test_1');
        expect(
          repo.getItems().firstWhere((e) => e.id == 'test_1').isFavorite,
          true,
        );

        repo.toggleArchive('test_1');
        expect(
          repo.getItems().firstWhere((e) => e.id == 'test_1').isArchived,
          true,
        );

        repo.deleteItem('test_1');
        expect(repo.getItems().length, 0);
      },
    );

    test('WardrobeNotifier filtering and search works reactive', () {
      final repo = WardrobeRepository([
        const WardrobeItem(
          id: 'item_1',
          name: 'پیراهن سفید',
          category: 'cl',
          subCategory: 'بالاتنه',
          colorName: 'سفید',
          colorHex: '#f4f4f2',
          season: 'بهار',
          occasion: 'روزمره',
          material: 'نخ',
          size: 'M',
          isFavorite: false,
          isArchived: false,
        ),
        const WardrobeItem(
          id: 'item_2',
          name: 'شلوار جین سرمه‌ای',
          category: 'cl',
          subCategory: 'پایین‌تنه',
          colorName: 'سرمه‌ای',
          colorHex: '#1f2f56',
          season: 'همه',
          occasion: 'روزمره',
          material: 'جین',
          size: '38',
          isFavorite: false,
          isArchived: false,
        ),
        const WardrobeItem(
          id: 'item_3',
          name: 'کتانی سفید',
          category: 'sh',
          subCategory: 'اسپورت',
          colorName: 'سفید',
          colorHex: '#f4f4f2',
          season: 'همه',
          occasion: 'ورزشی',
          material: 'چرم',
          size: '42',
          isFavorite: false,
          isArchived: false,
        ),
        const WardrobeItem(
          id: 'item_4',
          name: 'مانتو بژ',
          category: 'cl',
          subCategory: 'رویه‌پوش',
          colorName: 'بژ',
          colorHex: '#d6bf9b',
          season: 'بهار',
          occasion: 'روزمره',
          material: 'ویسکوز',
          size: 'M',
          isFavorite: false,
          isArchived: true,
        ),
      ]);
      final notifier = WardrobeNotifier(repo);

      // Default active count (4 total - 1 archived = 3)
      expect(notifier.state.filteredItems.length, 3);

      // Filter by category: cl (2 items)
      notifier.setCategory('cl');
      expect(notifier.state.filter.category, 'cl');
      expect(
        notifier.state.filteredItems.every((e) => e.category == 'cl'),
        true,
      );
      expect(notifier.state.filteredItems.length, 2);

      // Search
      notifier.setSearch('جین');
      expect(notifier.state.filteredItems.length, 1);
      expect(notifier.state.filteredItems.first.name, 'شلوار جین سرمه‌ای');

      // Clear search
      notifier.setSearch('');
      notifier.setCategory('all');
      expect(notifier.state.filteredItems.length, 3);

      // Advanced filter: color
      notifier.applyAdvancedFilters(color: '#f4f4f2', season: '', occasion: '');
      expect(notifier.state.filter.activeFilterCount, 1);
      expect(notifier.state.filteredItems.length, 2);

      // Clear filters
      notifier.clearFilters();
      expect(notifier.state.filter.activeFilterCount, 0);
      expect(notifier.state.filteredItems.length, 3);

      // Archive view
      notifier.toggleArchiveView();
      expect(notifier.state.filter.showArchived, true);
      expect(notifier.state.filteredItems.length, 1);
      expect(notifier.state.filteredItems.first.id, 'item_4');
    });

    testWidgets(
      'WardrobeTab starts empty with clean empty state and header count',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_buildWardrobeTestApp());
        await tester.pumpAndSettle();

        expect(find.text('کمد مجازی'), findsOneWidget);
        expect(find.text('همه'), findsWidgets);
        expect(find.text('کمد شما هنوز خالی است'), findsOneWidget);
        expect(find.text('افزودن اولین لباس'), findsOneWidget);
        expect(find.text('۰'), findsWidgets);
      },
    );

    testWidgets(
      'WardrobeTab filter button opens WardrobeFilterSheet and displays active count badge',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = WardrobeRepository([
          const WardrobeItem(
            id: 'item_1',
            name: 'پیراهن آبی کلاسیک',
            category: 'cl',
            subCategory: 'بالاتنه',
            colorName: 'آبی',
            colorHex: '#3b6ea5',
            season: 'بهار',
            occasion: 'رسمی',
            material: 'پنبه',
            size: 'M',
            isFavorite: false,
            isArchived: false,
          ),
        ]);

        await tester.pumpWidget(_buildWardrobeTestApp(repo: repo));
        await tester.pumpAndSettle();

        // Tap filter icon
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        // WardrobeFilterSheet is opened
        expect(find.byType(WardrobeFilterSheet), findsOneWidget);
        expect(find.text('فیلترهای پیشرفته'), findsOneWidget);
        expect(find.text('اعمال فیلترها'), findsOneWidget);
        expect(find.text('پاک کردن فیلترها'), findsOneWidget);

        // Select season 'بهار' inside WardrobeFilterSheet
        final seasonChip = find.descendant(
          of: find.byType(WardrobeFilterSheet),
          matching: find.text('بهار'),
        );
        await tester.tap(seasonChip);
        await tester.pumpAndSettle();

        // Tap apply
        await tester.tap(find.text('اعمال فیلترها'));
        await tester.pumpAndSettle();

        // Sheet is dismissed
        expect(find.byType(WardrobeFilterSheet), findsNothing);
        // Active filter count badge (1) is rendered
        expect(find.text('۱'), findsWidgets);
      },
    );

    testWidgets(
      'Archive view hides Add Item tile, and WardrobeItemCard exposes archive action',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = WardrobeRepository([
          const WardrobeItem(
            id: 'item_1',
            name: 'پیراهن آبی',
            category: 'cl',
            subCategory: 'بالاتنه',
            colorName: 'آبی',
            colorHex: '#3b6ea5',
            season: 'بهار',
            occasion: 'رسمی',
            material: 'پنبه',
            size: 'M',
            isFavorite: false,
            isArchived: false,
          ),
        ]);

        await tester.pumpWidget(_buildWardrobeTestApp(repo: repo));
        await tester.pumpAndSettle();

        // In active view: dashed add item card exists
        expect(find.text('افزودن آیتم'), findsOneWidget);
        // Quick archive icon exists on card
        expect(find.byIcon(Icons.inventory_2_outlined), findsWidgets);

        // Tap archive button on the card to archive the item
        final archiveCardIcons = find.byIcon(Icons.inventory_2_outlined);
        // The second one is on the card (first is in the search bar)
        await tester.tap(archiveCardIcons.last);
        await tester.pumpAndSettle();

        // Item was archived, active view is now empty!
        expect(find.text('کمد شما هنوز خالی است'), findsOneWidget);

        // Switch to archive view via search bar archive button
        await tester.tap(find.byIcon(Icons.inventory_2_outlined).first);
        await tester.pumpAndSettle();

        // In archive view: item is visible, but dashed Add Item card is NOT rendered!
        expect(find.text('افزودن آیتم'), findsNothing);
        // Item has restore icon
        expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);

        // Tap restore icon
        await tester.tap(find.byIcon(Icons.unarchive_outlined));
        await tester.pumpAndSettle();

        // Now archive view is empty
        expect(find.text('بایگانی خالی است'), findsOneWidget);
      },
    );
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
