import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_provider.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_screen.dart';
import 'package:stylemorph/features/profile/data/kyc_model.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/kyc_verification_section.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  Widget buildTestableWidget({
    required Widget child,
    Locale locale = const Locale('fa'),
    AppState? initialState,
    bool isEmailVerified = false,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          appStateProvider.overrideWith(
            (ref) => _TestAppStateNotifier(initialState),
          ),
        emailVerifiedOverrideProvider.overrideWith((ref) => isEmailVerified),
        emailVerificationProvider.overrideWith(
          (ref) => EmailVerificationNotifier(ref)
            ..state = EmailVerificationState(
              isVerified: isEmailVerified,
              cooldownSeconds: 0,
            ),
        ),
      ],
      child: MaterialApp(
        theme: testTheme,
        locale: locale,
        supportedLocales: const [
          Locale('fa'),
          Locale('en'),
          Locale('ar'),
          Locale('tr'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('KycData Model Tests', () {
    test('default KycData has notSubmitted status and nationalId docType', () {
      const kyc = KycData();
      expect(kyc.status, KycStatus.notSubmitted);
      expect(kyc.docType, KycDocType.nationalId);
      expect(kyc.isVerified, false);
      expect(kyc.isPending, false);
      expect(kyc.isRejected, false);
      expect(kyc.frontUrl, '');
      expect(kyc.backUrl, isNull);
    });

    test('serializes and deserializes KycData to/from map correctly', () {
      final now = DateTime.now();
      final kyc = KycData(
        status: KycStatus.verified,
        docType: KycDocType.passport,
        frontUrl: 'https://example.com/front.webp',
        backUrl: 'https://example.com/back.webp',
        submittedAt: now,
        updatedAt: now,
        rejectionReason: null,
      );

      final map = kyc.toMap();
      expect(map['status'], 'verified');
      expect(map['docType'], 'passport');
      expect(map['frontUrl'], 'https://example.com/front.webp');
      expect(map['backUrl'], 'https://example.com/back.webp');

      final fromMap = KycData.fromMap(map);
      expect(fromMap.status, KycStatus.verified);
      expect(fromMap.docType, KycDocType.passport);
      expect(fromMap.frontUrl, 'https://example.com/front.webp');
      expect(fromMap.backUrl, 'https://example.com/back.webp');
      expect(fromMap.isVerified, true);
    });

    test('handles rejected status and custom rejection reason', () {
      final kyc = KycData(
        status: KycStatus.rejected,
        docType: KycDocType.driversLicense,
        rejectionReason: 'Image is blurry. Please upload a clear photo.',
      );

      expect(kyc.status, KycStatus.rejected);
      expect(kyc.isRejected, true);
      expect(
        kyc.rejectionReason,
        'Image is blurry. Please upload a clear photo.',
      );

      final map = kyc.toMap();
      final reconstituted = KycData.fromMap(map);
      expect(reconstituted.isRejected, true);
      expect(
        reconstituted.rejectionReason,
        'Image is blurry. Please upload a clear photo.',
      );
    });
  });

  group('KYC Verification Section Widget Tests', () {
    testWidgets(
      'renders KYC section with title, subtitle and Not Submitted status in Persian',
      (WidgetTester tester) async {
        final faStrings = const AppStrings('fa');
        await tester.pumpWidget(
          buildTestableWidget(
            child: const KycVerificationSection(),
            locale: const Locale('fa'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(faStrings.kycSectionTitle), findsOneWidget);
        expect(find.text(faStrings.kycSectionSubtitle), findsOneWidget);
        expect(find.text(faStrings.kycStatusNotSubmitted), findsOneWidget);
        expect(find.text(faStrings.kycDocNationalId), findsOneWidget);
        expect(find.text(faStrings.kycDocTileNationalIdFront), findsOneWidget);
        expect(find.text(faStrings.kycDocTileNationalIdBack), findsOneWidget);
      },
    );

    testWidgets('renders KYC section in English with international labels', (
      WidgetTester tester,
    ) async {
      final enStrings = const AppStrings('en');
      await tester.pumpWidget(
        buildTestableWidget(
          child: const KycVerificationSection(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(enStrings.kycSectionTitle), findsOneWidget);
      expect(find.text(enStrings.kycStatusNotSubmitted), findsOneWidget);
      expect(find.text(enStrings.kycDocNationalId), findsOneWidget);
      expect(find.text(enStrings.kycDocTileNationalIdFront), findsOneWidget);
      expect(find.text(enStrings.kycDocTileNationalIdBack), findsOneWidget);
    });

    testWidgets(
      'allows toggling document types between National ID, Passport, and Driver\'s License',
      (WidgetTester tester) async {
        final faStrings = const AppStrings('fa');
        await tester.pumpWidget(
          buildTestableWidget(
            child: const KycVerificationSection(),
            locale: const Locale('fa'),
          ),
        );
        await tester.pumpAndSettle();

        // Default: National ID tiles
        expect(find.text(faStrings.kycDocTileNationalIdFront), findsOneWidget);
        expect(find.text(faStrings.kycDocTileNationalIdBack), findsOneWidget);

        // Find passport chip and tap
        final passportChip = find.text(faStrings.kycDocPassport);
        expect(passportChip, findsOneWidget);
        await tester.tap(passportChip);
        await tester.pumpAndSettle();

        // Dynamic Passport tiles
        expect(find.text(faStrings.kycDocTilePassportFront), findsOneWidget);
        expect(find.text(faStrings.kycDocTilePassportBack), findsOneWidget);

        // Find driver's license chip and tap
        final driversLicenseChip = find.text(faStrings.kycDocDriversLicense);
        expect(driversLicenseChip, findsOneWidget);
        await tester.tap(driversLicenseChip);
        await tester.pumpAndSettle();

        // Dynamic Driver's License tiles
        expect(
          find.text(faStrings.kycDocTileDriversLicenseFront),
          findsOneWidget,
        );
        expect(
          find.text(faStrings.kycDocTileDriversLicenseBack),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'displays Pending Review state with status badge and edit/delete actions',
      (WidgetTester tester) async {
        final faStrings = const AppStrings('fa');
        final pendingState = AppState(
          kycData: KycData(
            status: KycStatus.pending,
            docType: KycDocType.nationalId,
            frontUrl: 'https://example.com/front.jpg',
            submittedAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const KycVerificationSection(),
            locale: const Locale('fa'),
            initialState: pendingState,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(faStrings.kycStatusPending), findsOneWidget);
        expect(find.text(faStrings.kycEdit), findsOneWidget);
        expect(find.text(faStrings.kycDelete), findsOneWidget);
      },
    );

    testWidgets('displays Verified state with success badge and doc name', (
      WidgetTester tester,
    ) async {
      final faStrings = const AppStrings('fa');
      final verifiedState = AppState(
        kycData: KycData(
          status: KycStatus.verified,
          docType: KycDocType.passport,
          frontUrl: 'https://example.com/passport.jpg',
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const KycVerificationSection(),
          locale: const Locale('fa'),
          initialState: verifiedState,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(faStrings.kycStatusVerified), findsOneWidget);
      expect(find.text(faStrings.kycDocPassport), findsWidgets);
    });

    testWidgets('displays Rejected state with custom rejection reason', (
      WidgetTester tester,
    ) async {
      final faStrings = const AppStrings('fa');
      const rejectionReason =
          'تصویر ارسالی تار و ناخوانا است. لطفاً در نور مناسب مجدداً بارگذاری نمایید.';
      final rejectedState = AppState(
        kycData: const KycData(
          status: KycStatus.rejected,
          docType: KycDocType.nationalId,
          frontUrl: 'https://example.com/blurry.jpg',
          rejectionReason: rejectionReason,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const KycVerificationSection(),
          locale: const Locale('fa'),
          initialState: rejectedState,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(faStrings.kycStatusRejected), findsOneWidget);
      expect(find.text(rejectionReason), findsOneWidget);
      expect(find.text(faStrings.kycEdit), findsOneWidget);
    });

    testWidgets('tapping Delete Document opens confirmation dialog', (
      WidgetTester tester,
    ) async {
      final faStrings = const AppStrings('fa');
      final pendingState = AppState(
        kycData: const KycData(
          status: KycStatus.pending,
          docType: KycDocType.nationalId,
          frontUrl: 'https://example.com/front.jpg',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const KycVerificationSection(),
          locale: const Locale('fa'),
          initialState: pendingState,
        ),
      );
      await tester.pumpAndSettle();

      final deleteButton = find.text(faStrings.kycDelete);
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text(faStrings.kycDeleteConfirmTitle), findsOneWidget);
      expect(find.text(faStrings.kycDeleteConfirmDesc), findsOneWidget);
      expect(find.text(faStrings.dialogCancel), findsOneWidget);
    });

    testWidgets('embedded within IdentitySubTab seamlessly', (
      WidgetTester tester,
    ) async {
      final faStrings = const AppStrings('fa');
      await tester.pumpWidget(
        buildTestableWidget(
          child: const IdentitySubTab(),
          locale: const Locale('fa'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(faStrings.kycSectionTitle), findsOneWidget);
    });
  });

  group('MainHeader KYC Verified Badge Integration', () {
    testWidgets(
      'shows KYC Verified badge in MainHeader when KYC status is verified',
      (WidgetTester tester) async {
        final verifiedKycState = AppState(
          userName: 'علی رضایی',
          userHandle: '@ali_style',
          kycData: const KycData(
            status: KycStatus.verified,
            docType: KycDocType.passport,
          ),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const MainHeader(),
            locale: const Locale('fa'),
            initialState: verifiedKycState,
          ),
        );
        await tester.pumpAndSettle();

        // User name is visible
        expect(find.text('علی رضایی'), findsOneWidget);
        // Verified circle check icon is rendered beside name
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is FaIcon &&
                w.icon?.codePoint == FontAwesomeIcons.circleCheck.codePoint,
          ),
          findsOneWidget,
        );
        // Handle is omitted from header per Batch C
        expect(find.text('@ali_style'), findsNothing);
      },
    );

    testWidgets(
      'does not show verified badge in MainHeader when KYC is not verified',
      (WidgetTester tester) async {
        final unverifiedState = AppState(
          userName: 'علی رضایی',
          userHandle: '@ali_style',
          kycData: const KycData(),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            child: const MainHeader(),
            locale: const Locale('fa'),
            initialState: unverifiedState,
          ),
        );
        await tester.pumpAndSettle();

        // Name is rendered
        expect(find.text('علی رضایی'), findsOneWidget);
        // Does not contain verified check icon
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is FaIcon &&
                w.icon?.codePoint == FontAwesomeIcons.circleCheck.codePoint,
          ),
          findsNothing,
        );
        // Handle is omitted from header
        expect(find.text('@ali_style'), findsNothing);
      },
    );
  });
}

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initialState) : super() {
    state = initialState;
  }

  @override
  Future<void> loadProfileFromFirestore() async {
    // No-op in test
  }
}
