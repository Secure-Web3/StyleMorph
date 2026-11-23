import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemorph/core/services/storage/firebase_cloud_media_storage.dart';
import 'package:stylemorph/core/services/storage/firestore_inline_media_storage.dart';
import 'package:stylemorph/core/services/storage/media_storage_provider.dart';
import 'package:stylemorph/core/services/storage/media_storage_service.dart';
import 'package:stylemorph/core/widgets/app_media_image.dart';
import 'package:stylemorph/features/profile/data/kyc_service.dart';
import 'package:stylemorph/features/profile/data/media_service.dart';

void main() {
  group('FirestoreInlineMediaStorage Tests', () {
    test(
      'Encodes bytes to correct Data URL format with default mimeType',
      () async {
        const storage = FirestoreInlineMediaStorage();
        final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

        final result = await storage.uploadImage(
          path: 'users/test-uid/media/avatar.jpg',
          bytes: sampleBytes,
        );

        final expectedBase64 = base64Encode(sampleBytes);
        expect(result, 'data:image/jpeg;base64,$expectedBase64');
      },
    );

    test('Encodes bytes with custom MIME type', () async {
      const storage = FirestoreInlineMediaStorage();
      final sampleBytes = Uint8List.fromList([10, 20, 30]);

      final result = await storage.uploadImage(
        path: 'users/test-uid/media/banner.png',
        bytes: sampleBytes,
        mimeType: 'image/png',
      );

      final expectedBase64 = base64Encode(sampleBytes);
      expect(result, 'data:image/png;base64,$expectedBase64');
    });

    test(
      'Guards payload size and throws MediaPayloadTooLargeException',
      () async {
        const maxLimit = 100;
        const storage = FirestoreInlineMediaStorage(maxByteSize: maxLimit);
        final oversizedBytes = Uint8List(101);

        expect(
          () => storage.uploadImage(
            path: 'users/test-uid/media/large.jpg',
            bytes: oversizedBytes,
          ),
          throwsA(isA<MediaPayloadTooLargeException>()),
        );
      },
    );

    test('MediaPayloadTooLargeException message contains size details', () {
      const exception = MediaPayloadTooLargeException(
        byteCount: 300 * 1024,
        maxAllowedBytes: 200 * 1024,
      );

      expect(exception.toString(), contains('300 KB'));
      expect(exception.toString(), contains('200 KB'));
    });

    test('deleteMedia completes successfully without error', () async {
      const storage = FirestoreInlineMediaStorage();
      await expectLater(
        storage.deleteMedia('data:image/jpeg;base64,AQID'),
        completes,
      );
    });
  });

  group('FirebaseCloudMediaStorage Fallback Tests', () {
    test(
      'Throws StateError if FirebaseStorage is not initialized on upload',
      () async {
        final cloudStorage = FirebaseCloudMediaStorage();
        final bytes = Uint8List.fromList([1, 2, 3]);

        expect(
          () => cloudStorage.uploadImage(
            path: 'users/test-uid/media/file.jpg',
            bytes: bytes,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'deleteMedia safely handles empty string or Data URLs without crashing',
      () async {
        final cloudStorage = FirebaseCloudMediaStorage();
        await expectLater(cloudStorage.deleteMedia(''), completes);
        await expectLater(
          cloudStorage.deleteMedia('data:image/jpeg;base64,AQID'),
          completes,
        );
      },
    );
  });

  group('Media Storage Providers & Mode Switching Tests', () {
    test(
      'Default mode is firestoreInline and resolves FirestoreInlineMediaStorage',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mode = container.read(storageBackendModeProvider);
        expect(mode, StorageBackendMode.firestoreInline);

        final service = container.read(mediaStorageServiceProvider);
        expect(service, isA<FirestoreInlineMediaStorage>());
      },
    );

    test(
      'Switching storageBackendModeProvider to firebaseStorage resolves FirebaseCloudMediaStorage',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(storageBackendModeProvider.notifier).state =
            StorageBackendMode.firebaseStorage;

        final mode = container.read(storageBackendModeProvider);
        expect(mode, StorageBackendMode.firebaseStorage);

        final service = container.read(mediaStorageServiceProvider);
        expect(service, isA<FirebaseCloudMediaStorage>());
      },
    );
  });

  group('AppMediaImage & DataUrlHelper Tests', () {
    setUp(() {
      AppMediaImage.clearCache();
    });

    test('isDataUrl correctly identifies Data URLs', () {
      expect(AppMediaImage.isDataUrl('data:image/jpeg;base64,AQID'), isTrue);
      expect(AppMediaImage.isDataUrl('  data:image/png;base64,AQID'), isTrue);
      expect(AppMediaImage.isDataUrl('https://example.com/image.jpg'), isFalse);
      expect(AppMediaImage.isDataUrl(null), isFalse);
      expect(AppMediaImage.isDataUrl(''), isFalse);
    });

    test('tryDecodeDataUrl decodes base64 bytes and caches result', () {
      final originalBytes = Uint8List.fromList([7, 8, 9, 10]);
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(originalBytes)}';

      final decoded = AppMediaImage.tryDecodeDataUrl(dataUrl);
      expect(decoded, equals(originalBytes));

      // Cache lookup
      final cached = AppMediaImage.tryDecodeDataUrl(dataUrl);
      expect(identical(decoded, cached), isTrue);
    });

    test('tryDecodeDataUrl returns null for invalid formats', () {
      expect(AppMediaImage.tryDecodeDataUrl('invalid_string'), isNull);
      expect(
        AppMediaImage.tryDecodeDataUrl('data:image/jpeg;notbase64'),
        isNull,
      );
    });

    testWidgets('AppMediaImage renders memory image for valid Data URL', (
      tester,
    ) async {
      // 1x1 transparent PNG bytes
      final onePixelPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );
      final dataUrl = 'data:image/png;base64,${base64Encode(onePixelPng)}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMediaImage(
              dataUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<MemoryImage>());
    });

    testWidgets(
      'AppMediaImage renders errorBuilder for invalid URL or Data URL',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppMediaImage(
                'data:image/png;corrupted',
                errorBuilder: (context, error, stackTrace) =>
                    const Text('ErrorFallback'),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('ErrorFallback'), findsOneWidget);
      },
    );
  });

  group('Profile Services Integration with MediaStorageService Tests', () {
    test(
      'MediaService.uploadMediaSlot uploads via MediaStorageService',
      () async {
        const mockStorage = FirestoreInlineMediaStorage();
        final mediaService = MediaService(mediaStorage: mockStorage);

        final fileBytes = Uint8List.fromList([42, 43, 44]);
        final testFile = XFile.fromData(fileBytes, name: 'selfie.jpg');

        final resultUrl = await mediaService.uploadMediaSlot(
          uid: 'user_123',
          slotKey: 'selfie',
          file: testFile,
        );

        expect(resultUrl, startsWith('data:image/jpeg;base64,'));
        final decoded = AppMediaImage.tryDecodeDataUrl(resultUrl);
        expect(decoded, equals(fileBytes));
      },
    );

    test('KycService.uploadKycImage uploads via MediaStorageService', () async {
      const mockStorage = FirestoreInlineMediaStorage();
      final kycService = KycService(mediaStorage: mockStorage);

      final fileBytes = Uint8List.fromList([99, 100, 101]);
      final testFile = XFile.fromData(fileBytes, name: 'id_front.jpg');

      final resultUrl = await kycService.uploadKycImage(
        uid: 'user_123',
        file: testFile,
        tag: 'front',
      );

      expect(resultUrl, startsWith('data:image/jpeg;base64,'));
      final decoded = AppMediaImage.tryDecodeDataUrl(resultUrl);
      expect(decoded, equals(fileBytes));
    });
  });
}
