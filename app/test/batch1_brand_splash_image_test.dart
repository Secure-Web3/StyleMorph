import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/app_typography.dart';
import 'package:stylemorph/core/widgets/app_media_image.dart';
import 'package:stylemorph/core/widgets/brand_wordmark.dart';
import 'package:stylemorph/core/widgets/unified_splash_screen.dart';

void main() {
  // 1x1 transparent PNG encoded as base64 Data URL for deterministic decoding tests.
  const String validPngDataUrl =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  group('Batch 1 — Unified Splash, AppMediaImage & BrandWordmark', () {
    testWidgets(
      'UnifiedSplashScreen renders SM splash logo at exact 168x168 without overflow',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: UnifiedSplashScreen(animate: false)),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final logoContainer = sizedBoxes.where(
          (box) => box.width == 168.0 && box.height == 168.0,
        );
        expect(logoContainer, isNotEmpty);

        final images = tester.widgetList<Image>(find.byType(Image));
        expect(images, isNotEmpty);
        for (final img in images) {
          expect(img.width, 168.0);
          expect(img.height, 168.0);
          expect(img.fit, BoxFit.contain);
        }
      },
    );

    testWidgets(
      'AppMediaImage decodes Data URLs via Image.memory with gaplessPlayback and handles invalid/blob inputs safely',
      (tester) async {
        AppMediaImage.clearCache();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const AppMediaImage(
                    validPngDataUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                  AppMediaImage(
                    'blob:https://stylemorph-preview.web.app/expired-id',
                    width: 64,
                    height: 64,
                    errorBuilder: (_, _, _) => const Text('blob-fallback'),
                  ),
                  AppMediaImage(
                    '',
                    width: 64,
                    height: 64,
                    errorBuilder: (_, _, _) => const Text('empty-fallback'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        final memoryImageFinder = find.byType(Image);
        expect(memoryImageFinder, findsOneWidget);

        final imageWidget = tester.widget<Image>(memoryImageFinder);
        expect(imageWidget.image, isA<MemoryImage>());
        expect(imageWidget.gaplessPlayback, isTrue);

        // Simulate app lifecycle resume (idle/cold reopen recovery)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('blob-fallback'), findsOneWidget);
        expect(find.text('empty-fallback'), findsOneWidget);
      },
    );

    testWidgets(
      'BrandWordmark renders exact mixed-case "StyleMorph" with Brygada1918 in RTL and LTR',
      (tester) async {
        for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.buildTheme(
                palette: AppPalette.white,
                isDark: false,
                localeCode: direction == TextDirection.rtl ? 'fa' : 'en',
              ),
              home: Directionality(
                textDirection: direction,
                child: const Scaffold(body: Center(child: BrandWordmark())),
              ),
            ),
          );
          await tester.pump();

          final textFinder = find.text('StyleMorph');
          expect(textFinder, findsOneWidget);
          expect(find.text('STYLEMORPH'), findsNothing);

          final textWidget = tester.widget<Text>(textFinder);
          expect(textWidget.style?.fontFamily, AppTypography.brandFontFamily);
          expect(textWidget.style?.fontFamily, 'Brygada1918');
          expect(textWidget.textDirection, TextDirection.ltr);
        }
      },
    );
  });
}
