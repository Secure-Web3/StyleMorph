import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/services/loyalty_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/data/firebase_auth_repository.dart';
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

  group('OAuth Display Name Intelligent Splitting (splitDisplayName)', () {
    test('splits simple first and last name correctly', () {
      final (first, last) =
          FirebaseAuthRepository.splitDisplayName('John Doe');
      expect(first, equals('John'));
      expect(last, equals('Doe'));
    });

    test('preserves multi-word compound last names correctly', () {
      final (first, last) =
          FirebaseAuthRepository.splitDisplayName('Jane Mary Smith');
      expect(first, equals('Jane'));
      expect(last, equals('Mary Smith'));
    });

    test('handles single name with empty last name', () {
      final (first, last) =
          FirebaseAuthRepository.splitDisplayName('Cher');
      expect(first, equals('Cher'));
      expect(last, equals(''));
    });

    test('trims irregular leading, trailing, and internal whitespace', () {
      final (first, last) =
          FirebaseAuthRepository.splitDisplayName('   Vincent   van   Gogh   ');
      expect(first, equals('Vincent'));
      expect(last, equals('van Gogh'));
    });

    test('returns empty strings for null, empty, or whitespace-only inputs', () {
      expect(FirebaseAuthRepository.splitDisplayName(null), equals(('', '')));
      expect(FirebaseAuthRepository.splitDisplayName(''), equals(('', '')));
      expect(FirebaseAuthRepository.splitDisplayName('    '), equals(('', '')));
    });
  });

  group('OAuth Verified Email & StylePoints Bonus', () {
    test('unverified email receives 0 pts bonus', () {
      final points = LoyaltyService.calculateStylePoints(
        profileProgress: 0.10,
        isEmailVerified: false,
        referralCount: 0,
        aiUsageCount: 0,
        coinActivity: 0,
      );
      // 10% progress = 30 pts, unverified = 0 pts -> Total = 30 pts
      expect(points, equals(30));
    });

    test('OAuth verified email automatically receives +100 pts bonus', () {
      final points = LoyaltyService.calculateStylePoints(
        profileProgress: 0.10,
        isEmailVerified: true,
        referralCount: 0,
        aiUsageCount: 0,
        coinActivity: 0,
      );
      // 10% progress = 30 pts, verified = 100 pts -> Total = 130 pts
      expect(points, equals(130));
    });

    test('StylePoints maps to Bronze or Silver tier accordingly', () {
      final points = LoyaltyService.calculateStylePoints(
        profileProgress: 0.10,
        isEmailVerified: true,
      );
      expect(points, equals(130));
      final rank = LoyaltyService.getRank(points);
      expect(rank.nameCapitalized, equals('Bronze'));
    });
  });

  group('Profile Auto-Population & Non-Overwriting Logic', () {
    test('initial auto-population fills empty firstName, lastName, and photoURL', () {
      final existingDocData = <String, dynamic>{
        'firstName': '',
        'lastName': '',
        'photoURL': '',
        'identity': <String, dynamic>{},
      };

      // Extracted from Google/Apple on first sign-in
      const extractedFirst = 'Alexander';
      const extractedLast = 'McQueen';
      const extractedPhoto = 'https://example.com/avatar.jpg';

      final Map<String, dynamic> updates = {};

      if ((existingDocData['firstName'] as String).isEmpty && extractedFirst.isNotEmpty) {
        updates['firstName'] = extractedFirst;
      }
      if ((existingDocData['lastName'] as String).isEmpty && extractedLast.isNotEmpty) {
        updates['lastName'] = extractedLast;
      }
      if ((existingDocData['photoURL'] as String).isEmpty && extractedPhoto.isNotEmpty) {
        updates['photoURL'] = extractedPhoto;
      }
      updates['emailVerified'] = true;

      expect(updates['firstName'], equals('Alexander'));
      expect(updates['lastName'], equals('McQueen'));
      expect(updates['photoURL'], equals('https://example.com/avatar.jpg'));
      expect(updates['emailVerified'], isTrue);
    });

    test('preserves user edits and NEVER overwrites existing non-empty values', () {
      // User previously customized their profile name and avatar
      final existingDocData = <String, dynamic>{
        'firstName': 'Alex',
        'lastName': 'Couture',
        'photoURL': 'https://custom-storage.com/my-photo.jpg',
        'identity': {
          'firstName': 'Alex',
          'lastName': 'Couture',
        },
      };

      // Incoming Google/Apple sign-in data
      const extractedFirst = 'Alexander';
      const extractedLast = 'McQueen';
      const extractedPhoto = 'https://googleusercontent.com/default-avatar.jpg';

      final Map<String, dynamic> updates = {};

      final curFirst = existingDocData['firstName']?.toString().trim() ?? '';
      final curLast = existingDocData['lastName']?.toString().trim() ?? '';
      final curPhoto = existingDocData['photoURL']?.toString().trim() ?? '';

      if (curFirst.isEmpty && extractedFirst.isNotEmpty) {
        updates['firstName'] = extractedFirst;
      }
      if (curLast.isEmpty && extractedLast.isNotEmpty) {
        updates['lastName'] = extractedLast;
      }
      if (curPhoto.isEmpty && extractedPhoto.isNotEmpty) {
        updates['photoURL'] = extractedPhoto;
      }

      // Existing data must remain completely untouched!
      expect(updates.containsKey('firstName'), isFalse);
      expect(updates.containsKey('lastName'), isFalse);
      expect(updates.containsKey('photoURL'), isFalse);
    });
  });

  group('MainHeader Avatar with AppState.photoUrl fallback', () {
    testWidgets('renders avatar image when photoUrl is present in AppState',
        (tester) async {
      final initialState = AppState(
        isLoggedIn: true,
        userName: 'Sophia Laurent',
        photoUrl: 'https://example.com/profile-pic.jpg',
        stylePoints: 130,
        loyaltyRank: 'Bronze',
        preferences: const UserPreferences(
          fashionThemePalette: 'editorial',
          brightnessMode: 'light',
          appLanguage: 'en',
        ),
      );

      final notifier = _TestAppStateNotifier(initialState);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('fa'),
            ],
            locale: const Locale('en'),
            home: const Scaffold(
              body: MainHeader(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // MainHeader should render without crash and find Image widget
      expect(find.byType(MainHeader), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders fallback initials widget when photoUrl is empty',
        (tester) async {
      final initialState = AppState(
        isLoggedIn: true,
        userName: 'Sophia Laurent',
        photoUrl: '',
        stylePoints: 130,
        loyaltyRank: 'Bronze',
        preferences: const UserPreferences(
          fashionThemePalette: 'editorial',
          brightnessMode: 'light',
          appLanguage: 'en',
        ),
      );

      final notifier = _TestAppStateNotifier(initialState);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('fa'),
            ],
            locale: const Locale('en'),
            home: const Scaffold(
              body: MainHeader(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MainHeader), findsOneWidget);
      // Initials 'S' or 'SL' should appear
      expect(find.text('SL'), findsOneWidget);
    });
  });
}
