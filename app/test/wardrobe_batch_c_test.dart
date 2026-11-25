import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylemorph/core/services/prefetch/app_prefetch_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/widgets/app_media_image.dart';
import 'package:stylemorph/core/widgets/unified_splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1x1 transparent PNG Base64 Data URL for testing
  const testTransparentPngBase64 =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

  setUp(() {
    AppMediaImage.clearCache();
  });

  group('Batch C - AppMediaImage LRU Caching & Lifecycle Resilience', () {
    test('isDataUrl correctly detects Base64 Data URLs vs HTTP URLs', () {
      expect(AppMediaImage.isDataUrl(testTransparentPngBase64), isTrue);
      expect(
        AppMediaImage.isDataUrl('data:image/jpeg;base64,/9j/4AAQSkZJRg=='),
        isTrue,
      );
      expect(AppMediaImage.isDataUrl('https://example.com/photo.jpg'), isFalse);
      expect(AppMediaImage.isDataUrl(null), isFalse);
      expect(AppMediaImage.isDataUrl(''), isFalse);
    });

    test('tryDecodeDataUrl caches decoded bytes in LRU map', () {
      final bytes1 = AppMediaImage.tryDecodeDataUrl(testTransparentPngBase64);
      expect(bytes1, isNotNull);
      expect(bytes1!.length, greaterThan(0));

      // Second call returns cached byte array
      final bytes2 = AppMediaImage.tryDecodeDataUrl(testTransparentPngBase64);
      expect(identical(bytes1, bytes2), isTrue);
    });

    testWidgets(
      'AppMediaImage renders MemoryImage with gaplessPlayback for Data URLs',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppMediaImage(
                testTransparentPngBase64,
                width: 100,
                height: 100,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);

        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.image, isA<MemoryImage>());
        expect(imageWidget.gaplessPlayback, isTrue);
      },
    );

    testWidgets(
      'AppMediaImage updates render cycle on AppLifecycleState.resumed',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppMediaImage(
                testTransparentPngBase64,
                width: 100,
                height: 100,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final initialImage = tester.widget<Image>(find.byType(Image));
        final initialKey = initialImage.key as ValueKey<String>;
        expect(initialKey.value, contains('_0'));

        // Simulate app switching to background and resuming
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        // Verify key updated with incremented render cycle to recover evicted texture
        final resumedImage = tester.widget<Image>(find.byType(Image));
        final resumedKey = resumedImage.key as ValueKey<String>;
        expect(resumedKey.value, contains('_1'));
      },
    );
  });

  group(
    'Batch C - AppPrefetchService Non-blocking Execution & Deduplication',
    () {
      testWidgets('Prefetches once and deduplicates requests', (tester) async {
        final service = AppPrefetchService();
        expect(service.hasPrefetched, isFalse);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () {
                      service.prefetchOnAuth(ref: ref, context: context);
                    },
                    child: const Text('Prefetch'),
                  );
                },
              ),
            ),
          ),
        );

        // Trigger prefetch
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(service.hasPrefetched, isTrue);

        // Calling again is a no-op
        service.prefetchOnAuth(
          ref: tester.element(find.byType(Consumer)) as WidgetRef,
          context: tester.element(find.byType(Consumer)),
        );
        expect(service.hasPrefetched, isTrue);

        // Reset works
        service.reset();
        expect(service.hasPrefetched, isFalse);
      });
    },
  );

  group('Batch C - UnifiedSplashScreen Rendering', () {
    testWidgets('Renders obsidian background and official sm_logo asset', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: UnifiedSplashScreen(animate: false)),
      );
      await tester.pump();

      expect(find.byType(Image), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0D0D0F));
    });
  });

  group('Batch C - Real-Time Status Bar Theme Sync Logic', () {
    test('Dark theme produces Light icon brightness for high contrast', () {
      const darkColors = AppColors.darkObsidian;
      final isDark = darkColors.bg.computeLuminance() < 0.5;
      expect(isDark, isTrue);

      final iconBrightness = isDark ? Brightness.light : Brightness.dark;
      expect(iconBrightness, equals(Brightness.light));
    });

    test('Light theme produces Dark icon brightness for high contrast', () {
      const lightColors = AppColors.lightWhite;
      final isDark = lightColors.bg.computeLuminance() < 0.5;
      expect(isDark, isFalse);

      final iconBrightness = isDark ? Brightness.light : Brightness.dark;
      expect(iconBrightness, equals(Brightness.dark));
    });
  });
}
