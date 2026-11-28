import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/app_update_installer_io.dart';
import 'package:stylemorph/core/services/app_update_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_update_dialog.dart';
import 'package:stylemorph/features/shop/domain/extracted_web_product.dart';
import 'package:stylemorph/features/shop/domain/shop_query_builder.dart';
import 'package:stylemorph/features/shop/presentation/shop_provider.dart';
import 'package:stylemorph/features/shop/presentation/shop_tab.dart';
import 'package:stylemorph/features/shop/presentation/widgets/shop_web_discovery_view.dart';

void main() {
  group('Fix 1: Persistent & Validated APK Caching + Full Release Notes', () {
    test(
      'isValidApkFile validates ZIP/APK magic header and minimum size',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('apk_val_test_');
        addTearDown(() => tempDir.delete(recursive: true));

        final validFile = File('${tempDir.path}/valid.apk');
        final validBytes = <int>[0x50, 0x4B, 0x03, 0x04, ...List.filled(20, 1)];
        await validFile.writeAsBytes(validBytes);
        expect(await isValidApkFile(validFile, minBytes: 16), isTrue);
        expect(await isValidApkFile(validFile, minBytes: 1024), isFalse);

        final htmlFile = File('${tempDir.path}/error.apk');
        await htmlFile.writeAsString('<html>404 Not Found</html>');
        expect(await isValidApkFile(htmlFile, minBytes: 10), isFalse);
      },
    );

    test(
      'downloadAndInstallApkImpl reuses valid cached APK without re-downloading and rejects HTML error payloads',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('apk_srv_test_');
        addTearDown(() => tempDir.delete(recursive: true));

        var requestCount = 0;
        var serveValidApk = true;
        const url = 'https://example.com/StyleMorph-universal.apk';
        final installedPaths = <String>[];

        Future<List<int>> fakeDownload(Uri _) async {
          requestCount++;
          if (serveValidApk) {
            return [0x50, 0x4B, 0x03, 0x04, ...List.filled(128, 7)];
          }
          return '<html><body>Not Found</body></html>'.codeUnits;
        }

        // 1st call: downloads, validates, and triggers install.
        await downloadAndInstallApkImpl(
          url,
          onProgress: (_) {},
          version: '1.2.3',
          build: 45,
          updatesDirOverride: tempDir,
          minValidBytes: 64,
          downloadBytesOverride: fakeDownload,
          installApkOverride: (path) async => installedPaths.add(path),
        );
        expect(requestCount, 1);
        expect(installedPaths.length, 1);
        expect(installedPaths.first, endsWith('StyleMorph-V1.2.3-B45.apk'));
        expect(File(installedPaths.first).existsSync(), isTrue);

        // 2nd call for same version/build: reuses cached APK with 0 network calls.
        await downloadAndInstallApkImpl(
          url,
          onProgress: (_) {},
          version: '1.2.3',
          build: 45,
          updatesDirOverride: tempDir,
          minValidBytes: 64,
          downloadBytesOverride: fakeDownload,
          installApkOverride: (path) async => installedPaths.add(path),
        );
        expect(requestCount, 1);
        expect(installedPaths.length, 2);

        // Invalid HTML payload for a new version is rejected and deleted.
        serveValidApk = false;
        await expectLater(
          () => downloadAndInstallApkImpl(
            url,
            onProgress: (_) {},
            version: '1.2.4',
            build: 46,
            updatesDirOverride: tempDir,
            minValidBytes: 64,
            downloadBytesOverride: fakeDownload,
            installApkOverride: (path) async => installedPaths.add(path),
          ),
          throwsA(isA<InvalidApkPackageException>()),
        );
        final corruptFile = File('${tempDir.path}/StyleMorph-V1.2.4-B46.apk');
        expect(corruptFile.existsSync(), isFalse);
      },
    );

    testWidgets(
      'AppUpdateDialog renders multi-line releaseNotes inside What\'s New scrollable box',
      (tester) async {
        const notes = '## Release v1.2.3\n- Fixed APK cache\n- Improved Shop';
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.buildTheme(
                palette: AppPalette.editorial,
                isDark: false,
              ),
              locale: const Locale('en'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(
                body: AppUpdateDialog(
                  remoteInfo: RemoteVersionInfo(
                    version: '1.2.3',
                    build: 45,
                    releaseNotes: notes,
                  ),
                  isForced: false,
                  currentVersionOverride: '1.0.0',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("What's New"), findsOneWidget);
        expect(find.text(notes), findsOneWidget);
      },
    );
  });

  group('Fix 2: Generic Connectivity Copy (Zero VPN Mention)', () {
    test(
      'connectivity warning strings contain no VPN mention across all locales',
      () {
        for (final lang in ['fa', 'en', 'ar', 'tr']) {
          final s = AppStrings(lang);
          expect(
            s.connServerUnreachableBanner.toLowerCase(),
            isNot(contains('vpn')),
          );
          expect(
            s.aboutUpdateServerUnreachable.toLowerCase(),
            isNot(contains('vpn')),
          );
        }
      },
    );
  });

  group('Fix 3: 320ms WebView Long-Press Bridge', () {
    test(
      'buildImageLongPressBridgeJs uses 320ms timer and pointerdown + touchstart',
      () {
        final js = ShopWebDiscoveryView.buildImageLongPressBridgeJs();
        expect(js, contains('320'));
        expect(js, contains('pointerdown'));
        expect(js, contains('touchstart'));
        expect(js, contains('capture: true, passive: false'));
        expect(js, contains('webkitTouchCallout'));
      },
    );
  });

  group('Fix 4: Fit For Me Broad Apparel Query in All Category', () {
    test(
      'All category with Fit For Me omits shoeSize and builds apparel query',
      () {
        final allQuery = ShopSearchQueryBuilder.buildQuery(
          filter: const ShopFilter(category: 'all', fitFilter: true),
          localeCode: 'en',
          clothingSize: 'L',
          shoeSize: '43',
          profileGender: 'male',
        );
        expect(allQuery, contains("Men's"));
        expect(allQuery, contains('fashion outfits clothing'));
        expect(allQuery, contains('Size L'));
        expect(allQuery, isNot(contains('Shoe 43')));

        final shoeQuery = ShopSearchQueryBuilder.buildQuery(
          filter: const ShopFilter(category: 'shoe', fitFilter: true),
          localeCode: 'en',
          clothingSize: 'L',
          shoeSize: '43',
          profileGender: 'male',
        );
        expect(shoeQuery, contains('Shoe 43'));
      },
    );
  });

  group('Fix 5: Wishlist View Visibility in ShopTab', () {
    testWidgets(
      'selecting Wishlist chip shows _ShopWishlistView in IndexedStack and keeps ShopWebDiscoveryView offstage',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        const product = ExtractedWebProduct(
          title: 'Cashmere Overcoat',
          imageUrl: '',
          pageUrl: 'https://example.com/coat',
          sourceHost: 'example.com',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.buildTheme(
                palette: AppPalette.editorial,
                isDark: false,
              ),
              locale: const Locale('en'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(body: ShopTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        container.read(shopProvider.notifier).saveWebProductToWishlist(product);
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        await tester.tap(find.text(strings.shopCatFav));
        await tester.pumpAndSettle();

        final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(stack.index, 1);
        expect(find.text('Cashmere Overcoat'), findsOneWidget);
      },
    );
  });
}
