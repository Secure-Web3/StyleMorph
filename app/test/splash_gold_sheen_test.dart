import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/widgets/unified_splash_screen.dart';

void main() {
  group('UnifiedSplashScreen - Official sm_logo & Diagonal Gold Sheen', () {
    testWidgets(
      'Renders centered sm_logo.png on #0D0D0F with no loading spinner',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: UnifiedSplashScreen(animate: false)),
        );
        await tester.pump();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, kSplashObsidianBackground);
        expect(scaffold.backgroundColor, const Color(0xFF0D0D0F));

        expect(find.byType(CircularProgressIndicator), findsNothing);

        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        expect(images.length, 2);
        for (final img in images) {
          final provider = img.image as AssetImage;
          expect(provider.assetName, 'assets/images/brand/sm_logo.png');
          expect(img.gaplessPlayback, isTrue);
          expect(img.width, 180.0);
          expect(img.height, 180.0);
        }

        final center = tester.getCenter(find.byType(SizedBox).first);
        final screenSize = tester.getSize(find.byType(Scaffold));
        expect(center.dx, closeTo(screenSize.width / 2, 0.01));
        expect(center.dy, closeTo(screenSize.height / 2, 0.01));
      },
    );

    testWidgets(
      'Diagonal gold sheen ticks smoothly and disposes with zero pending timers',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: UnifiedSplashScreen(animate: true)),
        );

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ShaderMask), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        // Unmount and verify clean disposal with zero pending timers.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
