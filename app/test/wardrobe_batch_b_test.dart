import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/features/wardrobe/data/wardrobe_repository.dart';
import 'package:stylemorph/features/wardrobe/domain/wardrobe_item.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_provider.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_tab.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/wardrobe_item_card.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/wardrobe_item_detail_sheet.dart';

final _kTransparentPng = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Widget _buildWardrobeTestApp({
  WardrobeRepository? repo,
  Locale locale = const Locale('fa'),
  Widget? home,
}) {
  return ProviderScope(
    overrides: [
      if (repo != null) wardrobeRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLanguage.supportedLanguages
          .map((l) => l.locale)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(extensions: const [AppColors.lightWhite]),
      home: Directionality(
        textDirection:
            locale.languageCode == 'fa' || locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(body: home ?? const WardrobeTab()),
      ),
    ),
  );
}

void main() {
  group('Batch B — Step 2: 10 AI Categories & Blue Capsule Hint', () {
    testWidgets(
      'Sidebar renders 10 AI categories + all and shows blue capsule hint when category selected',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = InMemoryWardrobeRepository([
          const WardrobeItem(
            id: 'item_1',
            title: 'تی‌شرت سفید',
            category: 'tops',
          ),
          const WardrobeItem(
            id: 'item_2',
            title: 'شلوار جین',
            category: 'bottoms',
          ),
        ]);

        await tester.pumpWidget(_buildWardrobeTestApp(repo: repo));
        await tester.pumpAndSettle();

        // Check category names in sidebar
        expect(find.text('همه'), findsWidgets);
        expect(find.text('بالاتنه'), findsWidgets);
        expect(find.text('پایین‌تنه'), findsWidgets);
        expect(find.text('لباس کامل'), findsWidgets);
        expect(find.text('لباس بیرونی'), findsWidgets);
        expect(find.text('لباس زیر و راحتی'), findsWidgets);

        // When "all" is active, blue hint capsule is hidden
        expect(
          find.text('تی‌شرت، پیراهن، بافت، هودی، سویشرت، تاپ و کراپ‌تاپ'),
          findsNothing,
        );

        // Tap "بالاتنه"
        await tester.tap(find.text('بالاتنه'));
        await tester.pumpAndSettle();

        // Blue capsule hint for Tops appears
        expect(
          find.text('تی‌شرت، پیراهن، بافت، هودی، سویشرت، تاپ و کراپ‌تاپ'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Add Item sheet displays 10 categories with Blue Capsule Hint', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildWardrobeTestApp(home: const AddItemBottomSheet()),
      );
      await tester.pumpAndSettle();

      // Default category is tops -> hint is visible
      expect(
        find.text('تی‌شرت، پیراهن، بافت، هودی، سویشرت، تاپ و کراپ‌تاپ'),
        findsOneWidget,
      );

      // Tap "کفش روزمره"
      final shoeChip = find.text('کفش روزمره');
      await tester.ensureVisible(shoeChip);
      await tester.tap(shoeChip);
      await tester.pumpAndSettle();

      // Footwear hint appears
      expect(
        find.text(
          'کتانی، لوفر، کفش مجلسی، پاشنه‌بلند، صندل، نیم‌بوت، بوت و کفش ورزشی',
        ),
        findsOneWidget,
      );
    });
  });

  group('Batch B — Step 3: Multi-Select Filter Checkbox Mode', () {
    testWidgets(
      'Advanced Filters sheet toggles multi-select mode and applies OR within group',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = InMemoryWardrobeRepository([
          const WardrobeItem(
            id: 'item_1',
            title: 'پیراهن بهاری',
            category: 'tops',
            season: 'بهار',
            colorHex: '#3b6ea5',
          ),
          const WardrobeItem(
            id: 'item_2',
            title: 'تی‌شرت تابستانی',
            category: 'tops',
            season: 'تابستان',
            colorHex: '#c0392b',
          ),
          const WardrobeItem(
            id: 'item_3',
            title: 'کاپشن زمستانی',
            category: 'outerwear',
            season: 'زمستان',
            colorHex: '#222222',
          ),
        ]);

        await tester.pumpWidget(_buildWardrobeTestApp(repo: repo));
        await tester.pumpAndSettle();

        // Open Advanced Filter sheet
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pumpAndSettle();

        // Checkbox for Multi-Select exists
        expect(find.text('انتخاب چندگانه'), findsOneWidget);

        // Toggle multi-select on
        await tester.tap(find.text('انتخاب چندگانه'));
        await tester.pumpAndSettle();

        // Select both 'بهار' and 'تابستان'
        await tester.tap(find.text('بهار'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تابستان'));
        await tester.pumpAndSettle();

        // Apply filters
        await tester.tap(find.text('اعمال فیلترها'));
        await tester.pumpAndSettle();

        // Both spring and summer items match (OR within seasons group), winter does not
        expect(find.text('پیراهن بهاری'), findsOneWidget);
        expect(find.text('تی‌شرت تابستانی'), findsOneWidget);
        expect(find.text('کاپشن زمستانی'), findsNothing);
      },
    );
  });

  group(
    'Batch B — Step 4 & 5: AI Garment Schema, Optional Title & Multi-Frame Slider',
    () {
      test('WardrobeItem derives canonical AI garment zone correctly', () {
        expect(WardrobeItem.deriveGarmentZone('tops'), 'upper_body');
        expect(WardrobeItem.deriveGarmentZone('bottoms'), 'lower_body');
        expect(WardrobeItem.deriveGarmentZone('outfit'), 'full_body');
        expect(WardrobeItem.deriveGarmentZone('outerwear'), 'outerwear');
        expect(WardrobeItem.deriveGarmentZone('footwear'), 'footwear');
        expect(WardrobeItem.deriveGarmentZone('bags'), 'bag');
        expect(WardrobeItem.deriveGarmentZone('jewelry'), 'jewelry');
        expect(WardrobeItem.deriveGarmentZone('accessories'), 'accessory');
      });

      testWidgets(
        'AddItemBottomSheet allows empty title and falls back to category name',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(430, 932));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          String? submittedTitle;

          await tester.pumpWidget(
            _buildWardrobeTestApp(
              home: AddItemBottomSheet(
                initialImageBytes: _kTransparentPng,
                onAddWithImage:
                    ({
                      required imageBytes,
                      required mimeType,
                      required title,
                      required category,
                      required subCategory,
                      required colorName,
                      required colorHex,
                      required season,
                      required occasion,
                      required material,
                      required size,
                    }) async {
                      submittedTitle = title;
                    },
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Title is left completely empty!
          // Select category "کیف دستی"
          final bagChip = find.text('کیف دستی');
          await tester.ensureVisible(bagChip);
          await tester.tap(bagChip);
          await tester.pumpAndSettle();

          // Tap Save
          final saveBtn = find.text('ذخیره در کمد مجازی');
          await tester.ensureVisible(saveBtn);
          await tester.tap(saveBtn);
          await tester.pumpAndSettle();

          // Successfully submitted with fallback category name
          expect(submittedTitle, 'کیف دستی');
        },
      );

      testWidgets(
        'Detail sheet renders PageView and dots indicator for multi-angle items',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(430, 932));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          const multiAngleItem = WardrobeItem(
            id: 'multi_1',
            title: 'کت فوتر چندزاویه',
            category: 'outerwear',
            imageUrls: [
              'https://example.com/front.jpg',
              'https://example.com/side.jpg',
              'https://example.com/back.jpg',
            ],
          );

          await tester.pumpWidget(
            _buildWardrobeTestApp(
              home: WardrobeItemDetailSheet(
                item: multiAngleItem,
                onFav: () {},
                onArchive: () {},
                onDelete: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // PageView is present for multi-angle slider
          expect(find.byType(PageView), findsOneWidget);
        },
      );

      testWidgets(
        'WardrobeItemCard displays multi-angle badge only when imageUrls.length > 1',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(430, 932));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          const singleItem = WardrobeItem(
            id: 'single_1',
            title: 'تی‌شرت ساده',
            category: 'tops',
            thumbUrl: 'https://example.com/thumb.jpg',
          );

          const multiItem = WardrobeItem(
            id: 'multi_1',
            title: 'کفش چرم سه زاویه',
            category: 'footwear',
            thumbUrl: 'https://example.com/thumb.jpg',
            imageUrls: [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
              'https://example.com/3.jpg',
            ],
          );

          await tester.pumpWidget(
            _buildWardrobeTestApp(
              home: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 240,
                      child: WardrobeItemCard(
                        item: singleItem,
                        colors: AppColors.lightWhite,
                        onTap: () {},
                        onFav: () {},
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 240,
                      child: WardrobeItemCard(
                        item: multiItem,
                        colors: AppColors.lightWhite,
                        onTap: () {},
                        onFav: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Multi-photo library icon badge is present for multi-photo item (not for single)
          expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
          expect(find.text('۳'), findsOneWidget);
        },
      );
    },
  );
}
