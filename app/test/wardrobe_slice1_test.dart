import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/services/storage/media_storage_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/features/wardrobe/data/wardrobe_repository.dart';
import 'package:stylemorph/features/wardrobe/domain/wardrobe_item.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_provider.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_tab.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/add_item_bottom_sheet.dart';

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

class _FakeMediaStorageService implements MediaStorageService {
  final List<String> uploadedPaths = [];

  @override
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    uploadedPaths.add(path);
    return 'data:$mimeType;base64,fakeUploadUrl';
  }

  @override
  Future<void> deleteMedia(String urlOrPath) async {}
}

Widget _buildWardrobeTestApp({
  WardrobeRepository? repo,
  Locale locale = const Locale('fa'),
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
        child: const Scaffold(body: WardrobeTab()),
      ),
    ),
  );
}

void main() {
  group('Wardrobe Slice 1: Domain & Firestore Serialization', () {
    test(
      'WardrobeItem serialization toFirestore and fromMap preserves all canonical fields',
      () {
        final now = DateTime(2026, 11, 23, 12, 0, 0);
        final item = WardrobeItem(
          id: 'wardrobe_123',
          title: 'کت فوتر زمستانه',
          category: 'cl',
          subCategory: 'کت و پالتو',
          colorName: 'شتری',
          colorHex: '#c19a6b',
          season: 'زمستان',
          occasion: 'رسمی',
          material: 'فوتر پشمی',
          size: 'L',
          isFavorite: true,
          isArchived: false,
          thumbUrl: 'data:image/webp;base64,thumb123',
          originalUrl: 'data:image/webp;base64,orig123',
          imageHash: 'a' * 64,
          createdAt: now,
          updatedAt: now,
        );

        final map = item.toFirestore();
        expect(map['title'], 'کت فوتر زمستانه');
        expect(map['category'], 'cl');
        expect(map['thumbUrl'], 'data:image/webp;base64,thumb123');
        expect(map['imageHash'], 'a' * 64);
        expect(map['isFavorite'], true);
        expect(map['createdAt'], isA<Timestamp>());

        // Deserialization with fromMap
        final restored = WardrobeItem.fromMap(map, 'wardrobe_123');
        expect(restored.id, 'wardrobe_123');
        expect(restored.title, 'کت فوتر زمستانه');
        expect(restored.name, 'کت فوتر زمستانه'); // Backward-compat alias
        expect(restored.category, 'cl');
        expect(restored.thumbUrl, 'data:image/webp;base64,thumb123');
        expect(restored.imageHash, 'a' * 64);
        expect(restored.createdAt, now);
        expect(restored.isFavorite, true);
      },
    );

    test('WardrobeItem backward-compatibility with legacy name parameter', () {
      const legacyItem = WardrobeItem(
        id: 'legacy_1',
        name: 'پیراهن کتان',
        category: 'cl',
      );
      expect(legacyItem.title, 'پیراهن کتان');
      expect(legacyItem.name, 'پیراهن کتان');
      expect(legacyItem.thumbUrl, '');
      expect(legacyItem.imageHash, '');
    });
  });

  group('Wardrobe Slice 1: SHA-256 Hash & MediaStorageService Integration', () {
    test(
      'addItemWithImage computes exact 64-char SHA-256 and delegates upload',
      () async {
        final fakeStorage = _FakeMediaStorageService();
        final repo = InMemoryWardrobeRepository();
        final notifier = WardrobeNotifier(repo, fakeStorage, 'user_test_999');

        final sampleBytes = Uint8List.fromList([10, 20, 30, 40, 50, 60]);
        final expectedSha = sha256.convert(sampleBytes).toString();
        expect(expectedSha.length, 64);

        final created = await notifier.addItemWithImage(
          imageBytes: sampleBytes,
          mimeType: 'image/jpeg',
          title: 'کفش چرم مجلسی',
          category: 'sh',
          colorHex: '#000000',
          colorName: 'مشکی',
        );

        expect(created.imageHash, expectedSha);
        expect(created.thumbUrl, contains('data:image/jpeg;base64,'));
        expect(fakeStorage.uploadedPaths.length, 1);
        expect(
          fakeStorage.uploadedPaths.first,
          startsWith('users/user_test_999/wardrobe/'),
        );
        expect(notifier.state.items.length, 1);
        expect(notifier.state.items.first.title, 'کفش چرم مجلسی');
      },
    );
  });

  group('Wardrobe Slice 1: Cursor-Based Pagination', () {
    test('fetchPage and loadMore paginate items with limit 20', () async {
      final allItems = List.generate(
        25,
        (i) => WardrobeItem(
          id: 'item_$i',
          title: 'آیتم $i',
          category: 'cl',
          createdAt: DateTime(2026, 1, 1).add(Duration(days: i)),
        ),
      );

      final repo = InMemoryWardrobeRepository(allItems);
      final notifier = WardrobeNotifier(repo);

      // Initial page loads first 20
      await notifier.loadInitial();
      expect(notifier.state.items.length, 20);
      expect(notifier.state.hasMore, true);
      expect(notifier.state.lastCursor, 20);

      // Load more loads the remaining 5 items
      await notifier.loadMore();
      expect(notifier.state.items.length, 25);
      expect(notifier.state.hasMore, false);
      expect(notifier.state.lastCursor, null);
    });
  });

  group('Wardrobe Slice 1: Sidebar Corner Count Badges (Including 0)', () {
    testWidgets(
      'Sidebar category icons render count badges for all categories including 0',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // 1 clothing item, 0 shoes, 0 bags, 0 jewelry, 0 accessories
        final repo = InMemoryWardrobeRepository([
          const WardrobeItem(
            id: 'item_c1',
            title: 'پیراهن بهاری',
            category: 'cl',
          ),
        ]);

        await tester.pumpWidget(_buildWardrobeTestApp(repo: repo));
        await tester.pumpAndSettle();

        // In Persian ('fa'), 0 is '۰' and 1 is '۱'
        // All category total is 1 ('۱')
        // Clothing is 1 ('۱')
        // Shoes, Bags, Jewelry, Accessories are 0 ('۰')
        final zeroCountBadges = find.text('۰');
        expect(zeroCountBadges, findsWidgets);
        // There are 4 categories with 0 items: shoes, bags, jewelry, accessories
        expect(zeroCountBadges, findsNWidgets(4));

        // There are 2 categories/views with 1 item: All ('۱') and Clothing ('۱')
        final oneCountBadges = find.text('۱');
        expect(oneCountBadges, findsWidgets);
      },
    );

    testWidgets(
      'DigitFormatter formats 0 and numbers in English locale with Latin digits',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = InMemoryWardrobeRepository([]);
        await tester.pumpWidget(
          _buildWardrobeTestApp(repo: repo, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        // In English ('en'), all 6 categories (All, Clothing, Shoes, Bags, Jewelry, Accessories) display '0'
        final zeroCountBadgesEn = find.text('0');
        expect(zeroCountBadgesEn, findsWidgets);
      },
    );
  });

  group('Wardrobe Slice 1: Mandatory Photo Validation in AddItemBottomSheet', () {
    testWidgets(
      'Blocks submission and displays inline validation error when no photo selected',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        bool submitted = false;

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
                onAdd: (_) => submitted = true,
                onAddWithImage:
                    ({
                      required Uint8List imageBytes,
                      required String mimeType,
                      required String title,
                      required String category,
                      required String subCategory,
                      required String colorName,
                      required String colorHex,
                      required String season,
                      required String occasion,
                      required String material,
                      required String size,
                    }) async {
                      submitted = true;
                    },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter a valid title
        await tester.enterText(find.byType(TextField).first, 'کت مجلسی');
        await tester.pumpAndSettle();

        // Tap Save button without picking an image
        await tester.tap(find.text('ذخیره در کمد مجازی'));
        await tester.pumpAndSettle();

        // Submission was blocked!
        expect(submitted, false);

        // Inline validation error is displayed
        expect(
          find.text('انتخاب تصویر برای آیتم کمد الزامی است.'),
          findsWidgets,
        );
      },
    );

    testWidgets('Allows submission when photo bytes and title are provided', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool submitted = false;
      String? savedTitle;

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
              initialImageBytes: _kTransparentPng,
              onAddWithImage:
                  ({
                    required Uint8List imageBytes,
                    required String mimeType,
                    required String title,
                    required String category,
                    required String subCategory,
                    required String colorName,
                    required String colorHex,
                    required String season,
                    required String occasion,
                    required String material,
                    required String size,
                  }) async {
                    submitted = true;
                    savedTitle = title;
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byType(TextField).first, 'کت پاییزه بژ');
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('ذخیره در کمد مجازی'));
      await tester.pumpAndSettle();

      expect(submitted, true);
      expect(savedTitle, 'کت پاییزه بژ');
    });
  });
}
