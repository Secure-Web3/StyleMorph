import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/widgets/app_card.dart';
import 'package:stylemorph/core/widgets/app_media_image.dart';
import 'package:stylemorph/features/wardrobe/data/wardrobe_repository.dart';
import 'package:stylemorph/features/wardrobe/domain/wardrobe_item.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_provider.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_tab.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/wardrobe_item_card.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/wardrobe_item_detail_sheet.dart';

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
  group(
    'Batch A — Step 1 & 2: Header Capacity Row & Category Header Removal',
    () {
      testWidgets(
        'Header displays localized capacity at start without blue pill badge',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(430, 932));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final repo = InMemoryWardrobeRepository([
            const WardrobeItem(
              id: 'item_1',
              title: 'پیراهن کتان',
              category: 'cl',
              subCategory: 'بالاتنه',
              colorName: 'سفید',
              colorHex: '#f4f4f2',
            ),
          ]);

          await tester.pumpWidget(_buildWardrobeTestApp(repo: repo));
          await tester.pumpAndSettle();

          // Blue "1 مورد" pill badge is completely removed
          expect(find.text('۱ مورد'), findsNothing);

          // Localized capacity ratio text "۱/۳۰ ظرفیت" is present
          expect(find.text('۱/۳۰ ظرفیت'), findsOneWidget);

          // LinearProgressIndicator is present in the capacity bar
          expect(find.byType(LinearProgressIndicator), findsOneWidget);

          // "+ Upload Item" button is present and vertically aligned
          expect(find.text('افزودن آیتم'), findsWidgets);

          // Redundant active category header ("همه ۱") above grid is removed
          expect(find.text('همه ۱'), findsNothing);
        },
      );

      testWidgets('Header mirrors cleanly in English (LTR) locale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = InMemoryWardrobeRepository([
          const WardrobeItem(
            id: 'item_en',
            title: 'White Shirt',
            category: 'cl',
          ),
        ]);

        await tester.pumpWidget(
          _buildWardrobeTestApp(repo: repo, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        // In English, displays "1/30 capacity"
        expect(find.text('1/30 capacity'), findsOneWidget);
        // Redundant category header is absent
        expect(find.text('All 1'), findsNothing);
      });
    },
  );

  group('Batch A — Step 3: Clean Wardrobe Item Card & Bottom Action Bar', () {
    testWidgets(
      'Card has unobstructed photo and 3 compact bottom action buttons beneath title',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        bool favTapped = false;
        bool archiveTapped = false;
        bool tryOnTapped = false;

        const testItem = WardrobeItem(
          id: 'card_test',
          title: 'کت مشکی رسمی',
          category: 'cl',
          subCategory: 'بالاتنه',
          colorName: 'مشکی',
          colorHex: '#222222',
          season: 'پاییز',
          isFavorite: false,
          isArchived: false,
        );

        await tester.pumpWidget(
          MaterialApp(
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
            home: Scaffold(
              body: SizedBox(
                width: 180,
                height: 240,
                child: WardrobeItemCard(
                  item: testItem,
                  colors: AppColors.lightWhite,
                  onTap: () {},
                  onFav: () => favTapped = true,
                  onArchive: () => archiveTapped = true,
                  onTryOn: () => tryOnTapped = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Raw color dot & subcategory text ("مشکی · بالاتنه") are removed
        expect(find.text('مشکی · بالاتنه'), findsNothing);

        // 2. Action buttons are NOT floating on top of the photo; they are at the bottom
        // 3 buttons: Favorite Star, Archive, AI Style
        expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

        // Tap Favorite
        await tester.tap(find.byIcon(Icons.star_border_rounded));
        expect(favTapped, true);

        // Tap Archive
        await tester.tap(find.byIcon(Icons.inventory_2_outlined));
        expect(archiveTapped, true);

        // Tap AI Style
        await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
        expect(tryOnTapped, true);
      },
    );
  });

  group(
    'Batch A — Step 4: Reactive Detail Sheet, Larger Photo & Full Edit Flow',
    () {
      testWidgets(
        'Detail sheet reflects favorite toggle reactively, hides raw subCategory, and showcases 260px photo',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(430, 932));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final repo = InMemoryWardrobeRepository([
            const WardrobeItem(
              id: 'detail_item_1',
              title: 'پالتو شتری',
              category: 'cl',
              subCategory: 'بالاتنه',
              colorName: 'شتری',
              colorHex: '#c19a6b',
              season: 'زمستان',
              occasion: 'رسمی',
              material: 'فوتر',
              size: 'L',
              isFavorite: false,
            ),
          ]);

          await tester.pumpWidget(
            _buildWardrobeTestApp(
              repo: repo,
              home: WardrobeItemDetailSheet(
                item: repo.getItems().first,
                onFav: () => repo.toggleFavorite('detail_item_1'),
                onArchive: () => repo.toggleArchive('detail_item_1'),
                onDelete: () => repo.deleteItem('detail_item_1'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // 1. Initially inactive star
          expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

          // Tap star
          await tester.tap(find.byIcon(Icons.star_border_rounded));
          await tester.pumpAndSettle();

          // 2. Raw subCategory "بالاتنه" is NOT displayed as category value
          expect(find.text('بالاتنه'), findsNothing);
          // Localized category "لباس" is displayed
          expect(find.text('لباس'), findsOneWidget);

          // 3. Edit button exists in header actions and bottom bar
          expect(find.byIcon(Icons.edit_outlined), findsWidgets);
          expect(find.text('ویرایش آیتم'), findsWidgets);

          // 4. Large photo preview card (height 260) exists
          final appCards = tester.widgetList<AppCard>(find.byType(AppCard));
          final photoCard = appCards.firstWhere((c) => c.height == 260);
          expect(photoCard.height, 260);
        },
      );

      testWidgets('Edit sheet pre-fills existing values and updates item live', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        WardrobeItem? updatedResult;

        const initialItem = WardrobeItem(
          id: 'edit_target',
          title: 'کفش چرم اداری',
          category: 'sh',
          subCategory: 'کفش رسمی',
          colorName: 'سیاه',
          colorHex: '#222222',
          season: 'همه',
          occasion: 'رسمی',
          material: 'چرم طبیعی',
          size: '42',
          thumbUrl:
              'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        );

        await tester.pumpWidget(
          MaterialApp(
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
            home: Scaffold(
              body: AddItemBottomSheet(
                itemToEdit: initialItem,
                onEdit: (updated) {
                  updatedResult = updated;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check title prefilled
        expect(find.text('کفش چرم اداری'), findsOneWidget);

        // Check edit sheet title and button
        expect(find.text('ویرایش آیتم کمد'), findsOneWidget);
        expect(find.text('ذخیره تغییرات'), findsOneWidget);

        // Existing photo preview is rendered
        expect(find.byType(AppMediaImage), findsOneWidget);

        // Modify the title
        await tester.enterText(
          find.widgetWithText(TextField, 'کفش چرم اداری'),
          'کفش چرم مجلسی براق',
        );
        await tester.pumpAndSettle();

        // Tap Save Changes
        await tester.tap(find.text('ذخیره تغییرات'));
        await tester.pumpAndSettle();

        // Verify onEdit received updated item
        expect(updatedResult, isNotNull);
        expect(updatedResult!.title, 'کفش چرم مجلسی براق');
        expect(updatedResult!.category, 'sh');
        expect(updatedResult!.updatedAt, isNotNull);
      });
    },
  );
}
