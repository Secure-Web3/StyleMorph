import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_media_image.dart';
import 'package:stylemorph/core/widgets/gender_3d_avatar.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore() async {}

  @override
  Future<bool> saveProfileToFirestore() async {
    state = state.copyWith(hasUnsavedProfileChanges: false);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_theme_palette': 'editorial',
      'user_theme_mode': 'light',
      'app_language_code': 'en',
    });
  });

  // 1x1 transparent PNG data URL for test rendering without network
  const validDataUrl =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

  group('AppState Avatar & Gender Getters (effectiveAvatarUrl, gender)', () {
    test('effectiveAvatarUrl returns front_face when present', () {
      const state = AppState(
        photoUrl: 'https://cdn.example.com/oauth_monogram.jpg',
        mediaSlots: {'front_face': 'https://cdn.example.com/front_face.webp'},
      );
      expect(
        state.effectiveAvatarUrl,
        equals('https://cdn.example.com/front_face.webp'),
      );
    });

    test(
      'effectiveAvatarUrl returns null when front_face is absent even if photoUrl is present',
      () {
        const state = AppState(
          photoUrl: 'https://cdn.example.com/oauth_monogram.jpg',
          mediaSlots: {},
        );
        expect(state.effectiveAvatarUrl, isNull);
      },
    );

    test(
      'effectiveAvatarUrl returns null when front_face is empty or whitespace',
      () {
        const state = AppState(
          photoUrl: 'https://cdn.example.com/oauth_monogram.jpg',
          mediaSlots: {'front_face': '   '},
        );
        expect(state.effectiveAvatarUrl, isNull);
      },
    );

    test('effectiveAvatarUrl returns null when both are absent or empty', () {
      const state = AppState(photoUrl: '', mediaSlots: {});
      expect(state.effectiveAvatarUrl, isNull);
    });

    test('gender getter extracts value from aiDnaValues', () {
      const maleState = AppState(aiDnaValues: {'gender': 'male'});
      expect(maleState.gender, equals('male'));

      const femaleState = AppState(aiDnaValues: {'gender': 'female'});
      expect(femaleState.gender, equals('female'));

      const emptyState = AppState(aiDnaValues: {});
      expect(emptyState.gender, isNull);
    });
  });

  group(
    'Gender3dAvatar Direct Widget Unit Tests & Multilingual Normalization',
    () {
      testWidgets(
        'renders male 3D avatar asset for all male variants (en, fa, ar, tr)',
        (tester) async {
          const maleVariants = [
            'male',
            'MALE',
            'مرد',
            'مردانه',
            'ذكر',
            'erkek',
            'man',
          ];
          for (final val in maleVariants) {
            await tester.pumpWidget(
              MaterialApp(
                theme: testTheme,
                home: Scaffold(body: Gender3dAvatar(gender: val, size: 42)),
              ),
            );

            final imageFinder = find.byType(Image);
            expect(imageFinder, findsOneWidget);
            final image = tester.widget<Image>(imageFinder);
            expect(image.image, isA<AssetImage>());
            final assetImage = image.image as AssetImage;
            expect(assetImage.assetName, equals(Gender3dAvatar.maleAsset));
            expect(image.alignment, equals(Alignment.topCenter));
            expect(image.fit, equals(BoxFit.cover));
          }
        },
      );

      testWidgets(
        'renders female 3D avatar asset for all female variants (en, fa, ar, tr)',
        (tester) async {
          const femaleVariants = [
            'female',
            'Female',
            'زن',
            'زنانه',
            'أنثى',
            'kadın',
            'woman',
          ];
          for (final val in femaleVariants) {
            await tester.pumpWidget(
              MaterialApp(
                theme: testTheme,
                home: Scaffold(body: Gender3dAvatar(gender: val, size: 42)),
              ),
            );

            final imageFinder = find.byType(Image);
            expect(imageFinder, findsOneWidget);
            final image = tester.widget<Image>(imageFinder);
            expect(image.image, isA<AssetImage>());
            final assetImage = image.image as AssetImage;
            expect(assetImage.assetName, equals(Gender3dAvatar.femaleAsset));
            expect(image.alignment, equals(Alignment.topCenter));
            expect(image.fit, equals(BoxFit.cover));
          }
        },
      );

      testWidgets('renders editorial silhouette icon for null gender', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: const Scaffold(body: Gender3dAvatar(gender: null, size: 42)),
          ),
        );

        expect(find.byType(Image), findsNothing);
        expect(find.byType(FaIcon), findsOneWidget);
        final faIcon = tester.widget<FaIcon>(find.byType(FaIcon));
        expect(
          faIcon.icon?.codePoint,
          equals(FontAwesomeIcons.solidUser.codePoint),
        );
      });

      testWidgets('renders editorial silhouette icon for non_binary gender', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: const Scaffold(
              body: Gender3dAvatar(gender: 'non_binary', size: 42),
            ),
          ),
        );

        expect(find.byType(Image), findsNothing);
        expect(find.byType(FaIcon), findsOneWidget);
      });

      testWidgets('renders editorial silhouette icon for empty string gender', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testTheme,
            home: const Scaffold(body: Gender3dAvatar(gender: '   ', size: 42)),
          ),
        );

        expect(find.byType(Image), findsNothing);
        expect(find.byType(FaIcon), findsOneWidget);
      });
    },
  );

  group('MainHeader Avatar Fallback & Priority Integration Tests', () {
    testWidgets(
      'Priority 1: renders front_face AppMediaImage when mediaSlots has front_face',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          userName: 'Alex Smith',
          photoUrl: 'https://example.com/oauth_pic.jpg',
          mediaSlots: const {'front_face': validDataUrl},
          aiDnaValues: const {'gender': 'male'},
          loyaltyRank: 'Gold',
          preferences: const UserPreferences(
            fashionThemePalette: 'editorial',
            brightnessMode: 'light',
            appLanguage: 'en',
          ),
        );

        final notifier = _TestAppStateNotifier(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appStateProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('fa')],
              locale: const Locale('en'),
              home: const Scaffold(body: MainHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainHeader), findsOneWidget);
        final mediaImageFinder = find.byType(AppMediaImage);
        expect(mediaImageFinder, findsOneWidget);
        final mediaImage = tester.widget<AppMediaImage>(mediaImageFinder);
        expect(mediaImage.imageUrl, equals(validDataUrl));
        expect(find.byType(Gender3dAvatar), findsNothing);
      },
    );

    testWidgets(
      'Priority 2: renders Gender3dAvatar when front_face is absent even if photoUrl is set',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          userName: 'Alex Smith',
          photoUrl: 'https://lh3.googleusercontent.com/default_monogram.jpg',
          mediaSlots: const {},
          aiDnaValues: const {'gender': 'male'},
          loyaltyRank: 'Silver',
          preferences: const UserPreferences(
            fashionThemePalette: 'editorial',
            brightnessMode: 'light',
            appLanguage: 'en',
          ),
        );

        final notifier = _TestAppStateNotifier(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appStateProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('fa')],
              locale: const Locale('en'),
              home: const Scaffold(body: MainHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainHeader), findsOneWidget);
        expect(find.byType(AppMediaImage), findsNothing);
        expect(find.byType(Gender3dAvatar), findsOneWidget);

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final image = tester.widget<Image>(imageFinder);
        final asset = image.image as AssetImage;
        expect(asset.assetName, equals(Gender3dAvatar.maleAsset));
      },
    );

    testWidgets(
      'Priority 2 (Female Persian): renders female 3D avatar when gender is زنانه and no front_face',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          userName: 'سارا لورنت',
          photoUrl: 'https://lh3.googleusercontent.com/default_monogram.jpg',
          mediaSlots: const {},
          aiDnaValues: const {'gender': 'زنانه'},
          loyaltyRank: 'Gold',
          preferences: const UserPreferences(
            fashionThemePalette: 'editorial',
            brightnessMode: 'light',
            appLanguage: 'fa',
          ),
        );

        final notifier = _TestAppStateNotifier(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appStateProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('fa')],
              locale: const Locale('fa'),
              home: const Scaffold(body: MainHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainHeader), findsOneWidget);
        expect(find.byType(AppMediaImage), findsNothing);
        expect(find.byType(Gender3dAvatar), findsOneWidget);

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final image = tester.widget<Image>(imageFinder);
        final asset = image.image as AssetImage;
        expect(asset.assetName, equals(Gender3dAvatar.femaleAsset));
      },
    );

    testWidgets(
      'Priority 3 (Neutral): renders silhouette icon when no photo and gender is unselected',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          userName: 'New User',
          photoUrl: '',
          mediaSlots: const {},
          aiDnaValues: const {},
          loyaltyRank: 'Bronze',
          preferences: const UserPreferences(
            fashionThemePalette: 'editorial',
            brightnessMode: 'light',
            appLanguage: 'en',
          ),
        );

        final notifier = _TestAppStateNotifier(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appStateProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('fa')],
              locale: const Locale('en'),
              home: const Scaffold(body: MainHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainHeader), findsOneWidget);
        expect(find.byType(AppMediaImage), findsNothing);
        expect(find.byType(Gender3dAvatar), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(find.byType(FaIcon), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Reactive Updates: uploading and deleting front_face immediately toggles between photo and 3D avatar',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          userName: 'Alex Smith',
          photoUrl: 'https://lh3.googleusercontent.com/default_monogram.jpg',
          mediaSlots: const {},
          aiDnaValues: const {'gender': 'male'},
          loyaltyRank: 'Bronze',
          preferences: const UserPreferences(
            fashionThemePalette: 'editorial',
            brightnessMode: 'light',
            appLanguage: 'en',
          ),
        );

        final notifier = _TestAppStateNotifier(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appStateProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('fa')],
              locale: const Locale('en'),
              home: const Scaffold(body: MainHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially male 3D avatar (photoUrl does NOT block it)
        expect(find.byType(Gender3dAvatar), findsOneWidget);
        expect(find.byType(AppMediaImage), findsNothing);

        // Upload front_face
        notifier.updateMediaSlot('front_face', validDataUrl);
        await tester.pumpAndSettle();

        // Now updates to AppMediaImage immediately
        expect(find.byType(Gender3dAvatar), findsNothing);
        final mediaFinder = find.byType(AppMediaImage);
        expect(mediaFinder, findsOneWidget);
        final media = tester.widget<AppMediaImage>(mediaFinder);
        expect(media.imageUrl, equals(validDataUrl));

        // Delete front_face
        notifier.deleteMediaSlot('front_face');
        await tester.pumpAndSettle();

        // Immediately reverts back to male 3D avatar
        expect(find.byType(AppMediaImage), findsNothing);
        expect(find.byType(Gender3dAvatar), findsOneWidget);
      },
    );

    testWidgets(
      'Reactive Updates: changing gender immediately updates 3D avatar asset',
      (tester) async {
        final state = AppState(
          isLoggedIn: true,
          userName: 'Alex Smith',
          photoUrl: '',
          mediaSlots: const {},
          aiDnaValues: const {'gender': 'male'},
          loyaltyRank: 'Bronze',
          preferences: const UserPreferences(
            fashionThemePalette: 'editorial',
            brightnessMode: 'light',
            appLanguage: 'en',
          ),
        );

        final notifier = _TestAppStateNotifier(state);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appStateProvider.overrideWith((ref) => notifier)],
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('fa')],
              locale: const Locale('en'),
              home: const Scaffold(body: MainHeader()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initial male
        var imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        var image = tester.widget<Image>(imageFinder);
        expect(
          (image.image as AssetImage).assetName,
          equals(Gender3dAvatar.maleAsset),
        );

        // Switch to female via Persian 'زنانه'
        notifier.updateAiDnaField('gender', 'زنانه');
        await tester.pumpAndSettle();

        imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        image = tester.widget<Image>(imageFinder);
        expect(
          (image.image as AssetImage).assetName,
          equals(Gender3dAvatar.femaleAsset),
        );
      },
    );
  });
}
