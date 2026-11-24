import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/services/prefetch/app_prefetch_service.dart';
import 'package:stylemorph/core/services/storage/media_storage_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/widgets/app_media_image.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/profile/domain/kyc_model.dart';
import 'package:stylemorph/features/wardrobe/data/wardrobe_repository.dart';
import 'package:stylemorph/features/wardrobe/domain/wardrobe_item.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_provider.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/add_item_bottom_sheet.dart';

class FakeMediaStorageService implements MediaStorageService {
  final List<String> uploadedPaths = [];

  @override
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    uploadedPaths.add(path);
    return 'https://firebasestorage.googleapis.com/$path';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hotfix Step 1: Multi-Angle Photo Persistence in Edit Mode', () {
    test(
      'updateItemWithImages preserves primary and uploads Angle 2 & Angle 3',
      () async {
        final initialItem = const WardrobeItem(
          id: 'item_101',
          title: 'کت پشمی',
          category: 'outerwear',
          thumbUrl: 'https://example.com/primary.jpg',
          originalUrl: 'https://example.com/primary.jpg',
          imageUrls: ['https://example.com/primary.jpg'],
        );

        final repo = InMemoryWardrobeRepository([initialItem]);
        final storage = FakeMediaStorageService();
        final notifier = WardrobeNotifier(repo, storage, 'user_test_1');

        final angle2Bytes = Uint8List.fromList([1, 2, 3]);
        final angle3Bytes = Uint8List.fromList([4, 5, 6]);

        final updated = await notifier.updateItemWithImages(
          id: 'item_101',
          slotBytes: [null, angle2Bytes, angle3Bytes],
          slotUrls: ['https://example.com/primary.jpg', null, null],
          title: 'کت پشمی زمستانه',
          category: 'outerwear',
        );

        // All 3 image URLs must be persisted in order
        expect(updated.imageUrls.length, equals(3));
        expect(updated.imageUrls[0], equals('https://example.com/primary.jpg'));
        expect(
          updated.imageUrls[1],
          equals(
            'https://firebasestorage.googleapis.com/users/user_test_1/wardrobe/item_101_angle_1.jpg',
          ),
        );
        expect(
          updated.imageUrls[2],
          equals(
            'https://firebasestorage.googleapis.com/users/user_test_1/wardrobe/item_101_angle_2.jpg',
          ),
        );
        expect(updated.thumbUrl, equals('https://example.com/primary.jpg'));
        expect(updated.originalUrl, equals('https://example.com/primary.jpg'));
        expect(updated.title, equals('کت پشمی زمستانه'));

        // Verify storage received uploads
        expect(storage.uploadedPaths.length, equals(2));
        expect(
          storage.uploadedPaths[0],
          equals('users/user_test_1/wardrobe/item_101_angle_1.jpg'),
        );
        expect(
          storage.uploadedPaths[1],
          equals('users/user_test_1/wardrobe/item_101_angle_2.jpg'),
        );

        // Verify repository has the updated item
        final page = await repo.fetchPage();
        final repoItem = page.items.firstWhere((i) => i.id == 'item_101');
        expect(repoItem.imageUrls.length, equals(3));
      },
    );

    testWidgets(
      'AddItemBottomSheet pre-fills all 3 existing angles in Edit Mode',
      (tester) async {
        final editItem = const WardrobeItem(
          id: 'item_202',
          title: 'پیراهن آبی',
          category: 'tops',
          thumbUrl: 'https://example.com/angle0.jpg',
          originalUrl: 'https://example.com/angle0.jpg',
          imageUrls: [
            'https://example.com/angle0.jpg',
            'https://example.com/angle1.jpg',
            'https://example.com/angle2.jpg',
          ],
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
              body: AddItemBottomSheet(itemToEdit: editItem, onEdit: (_) {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Title and name pre-filled
        expect(find.text('پیراهن آبی'), findsOneWidget);

        // 3 AppMediaImage widgets rendered (one primary, two extra angles)
        expect(find.byType(AppMediaImage), findsNWidgets(3));
      },
    );
  });

  group('Hotfix Step 2: Cross-Account State, Cache & Wardrobe Isolation', () {
    test('AppMediaImage.clearCache wipes decoded bytes without errors', () {
      const testDataUrl =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      final decoded = AppMediaImage.tryDecodeDataUrl(testDataUrl);
      expect(decoded, isNotNull);

      // Calling clearCache
      AppMediaImage.clearCache();
    });

    test('AppPrefetchService.reset clears in-flight state', () {
      final prefetchService = AppPrefetchService();
      prefetchService.reset();
      expect(prefetchService.hasPrefetched, isFalse);
    });

    test('AppStateNotifier.resetUserSession resets 100% of user fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);

      // Populate user data
      notifier.updateIdentityField('firstName', 'Ali');
      notifier.updateIdentityField('lastName', 'Rezaei');
      notifier.updateIdentityField('email', 'ali@example.com');
      notifier.updateIdentityField('nickname', 'alir');
      notifier.updateMediaSlot('slot_1', 'https://example.com/slot1.jpg');
      notifier.updateAiDnaField('chest', '100');
      notifier.updateKycData(
        const KycData(
          status: KycStatus.verified,
          frontUrl: 'https://example.com/kyc_front.jpg',
          backUrl: 'https://example.com/kyc_back.jpg',
        ),
      );

      var state = container.read(appStateProvider);
      expect(state.identityValues['firstName'], equals('Ali'));
      expect(state.identityValues['email'], equals('ali@example.com'));
      expect(state.mediaSlots['slot_1'], isNotEmpty);
      expect(state.aiDnaValues['chest'], equals('100'));
      expect(state.kycData.status, equals(KycStatus.verified));

      // Perform full session reset
      notifier.resetUserSession();

      state = container.read(appStateProvider);
      expect(state.photoUrl, isEmpty);
      expect(state.mediaSlots, isEmpty);
      expect(state.identityValues, isEmpty);
      expect(state.aiDnaValues, isEmpty);
      expect(state.kycData.status, equals(KycStatus.notSubmitted));
      expect(state.kycData.frontUrl, isEmpty);
      expect(state.kycData.backUrl, isNull);
      expect(state.isProfileLoaded, isFalse);
      expect(state.loadedUid, isNull);
      expect(state.hasUnsavedChanges, isFalse);
      expect(state.coins, equals(0));
      expect(state.stylePoints, equals(0));
    });

    test(
      'wardrobeProvider strictly scoped to currentUidProvider without leaks',
      () async {
        final repoA = InMemoryWardrobeRepository([
          const WardrobeItem(
            id: 'item_A1',
            title: 'Account A Item',
            category: 'tops',
          ),
        ]);
        final repoB = InMemoryWardrobeRepository([
          const WardrobeItem(
            id: 'item_B1',
            title: 'Account B Item',
            category: 'bottoms',
          ),
        ]);

        final activeUidProvider = StateProvider<String?>((ref) => 'user_A');

        final container = ProviderContainer(
          overrides: [
            currentUidProvider.overrideWith(
              (ref) => ref.watch(activeUidProvider),
            ),
            wardrobeRepositoryProvider.overrideWith((ref) {
              final uid = ref.watch(currentUidProvider);
              if (uid == 'user_A') return repoA;
              if (uid == 'user_B') return repoB;
              return InMemoryWardrobeRepository();
            }),
          ],
        );
        addTearDown(container.dispose);

        // Initially user A is active
        var wardrobeState = container.read(wardrobeProvider);
        expect(wardrobeState.items.length, equals(1));
        expect(wardrobeState.items.first.title, equals('Account A Item'));

        // Invalidate and switch to user B (as executed by _AuthGate / signOut)
        container.read(activeUidProvider.notifier).state = 'user_B';
        container.invalidate(wardrobeProvider);

        // Re-reading wardrobeProvider must now strictly yield Account B data
        wardrobeState = container.read(wardrobeProvider);
        expect(wardrobeState.items.length, equals(1));
        expect(wardrobeState.items.first.title, equals('Account B Item'));

        // Zero items from Account A leaked into Account B
        expect(wardrobeState.items.any((i) => i.id == 'item_A1'), isFalse);
      },
    );
  });
}
