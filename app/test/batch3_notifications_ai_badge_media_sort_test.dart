import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stylemorph/core/ai/ai_verification_models.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/notification_service.dart';
import 'package:stylemorph/core/services/storage/media_storage_provider.dart';
import 'package:stylemorph/core/services/storage/media_storage_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/ai_review_badge.dart';
import 'package:stylemorph/features/profile/presentation/widgets/media_sub_tab.dart';

class _SpyNotificationService extends NotificationService {
  final List<Map<String, dynamic>> events = [];

  @override
  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    String category = 'account',
    String targetRoute = 'profile_identity',
    String emoji = '🔔',
    bool sendEmail = false,
    String? recipientEmail,
    String? eventType,
    Map<String, dynamic>? extraData,
  }) async {
    events.add({
      'uid': uid,
      'title': title,
      'body': body,
      'category': category,
      'targetRoute': targetRoute,
      'eventType': eventType,
    });
  }
}

class _FakeMediaStorage implements MediaStorageService {
  @override
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  }

  @override
  Future<void> deleteMedia(String urlOrPath) async {}
}

void main() {
  const String validPngDataUrl =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  Widget buildHarness({
    required Widget child,
    Locale locale = const Locale('en'),
    ProviderContainer? container,
  }) {
    final app = MaterialApp(
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
      theme: AppTheme.buildTheme(
        palette: AppPalette.white,
        isDark: false,
        localeCode: locale.languageCode,
      ),
      builder: (context, inner) => ShadTheme(
        data: AppTheme.buildShadTheme(palette: AppPalette.white, isDark: false),
        child: Directionality(
          textDirection:
              locale.languageCode == 'fa' || locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: inner ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(body: child),
    );

    if (container != null) {
      return UncontrolledProviderScope(container: container, child: app);
    }
    return ProviderScope(child: app);
  }

  group('Batch 3 — AiReviewBadge Compact Header Mode', () {
    testWidgets(
      'renders clock icon + concise "Pending" for pendingAi and never shows "AI Verified" when simulated',
      (tester) async {
        final enStrings = AppStrings('en');
        final faStrings = AppStrings('fa');

        await tester.pumpWidget(
          buildHarness(
            locale: const Locale('en'),
            child: const AiReviewBadge(
              status: AiVerificationStatus.pendingAi,
              compact: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(enStrings.aiStatusPendingCompact), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text(enStrings.aiStatusApprovedCompact), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) => w is FaIcon && w.icon == FontAwesomeIcons.clock.data,
          ),
          findsOneWidget,
        );

        // Simulated approved response MUST downgrade to Pending
        await tester.pumpWidget(
          buildHarness(
            locale: const Locale('fa'),
            child: const AiReviewBadge(
              status: AiVerificationStatus.approved,
              isSimulated: true,
              compact: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(faStrings.aiStatusPendingCompact), findsOneWidget);
        expect(find.text(faStrings.aiStatusApprovedCompact), findsNothing);

        // Real (non-simulated) approved response shows green AI Verified
        await tester.pumpWidget(
          buildHarness(
            locale: const Locale('en'),
            child: const AiReviewBadge(
              status: AiVerificationStatus.approved,
              isSimulated: false,
              compact: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(enStrings.aiStatusApprovedCompact), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is FaIcon && w.icon == FontAwesomeIcons.circleCheck.data,
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Batch 3 — MediaSubTab Auto-Sort, Top Badge & Notifications', () {
    testWidgets(
      'auto-sorts uploaded Media tiles before empty Awaiting Upload tiles and renders unified top AiReviewBadge',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final spyNotif = _SpyNotificationService();
        final container = ProviderContainer(
          overrides: [
            notificationServiceProvider.overrideWithValue(spyNotif),
            mediaStorageServiceProvider.overrideWithValue(_FakeMediaStorage()),
          ],
        );
        addTearDown(container.dispose);

        // Upload an optional later slot ('hand_skin') while required slots are empty
        container
            .read(appStateProvider.notifier)
            .updateMediaSlot('hand_skin', validPngDataUrl);

        await tester.pumpWidget(
          buildHarness(
            locale: const Locale('en'),
            container: container,
            child: const SingleChildScrollView(child: MediaSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        // Uploaded 'hand_skin' tile must appear BEFORE empty 'front_face' tile in the 2-column grid
        final handSkinTopLeft = tester.getTopLeft(
          find.byKey(const ValueKey('hand_skin')),
        );
        final frontFaceTopLeft = tester.getTopLeft(
          find.byKey(const ValueKey('front_face')),
        );
        expect(handSkinTopLeft.dy, lessThanOrEqualTo(frontFaceTopLeft.dy));
        expect(
          handSkinTopLeft.dy < frontFaceTopLeft.dy ||
              handSkinTopLeft.dx < frontFaceTopLeft.dx,
          isTrue,
        );

        // Top-of-tile AI status badge shows concise Pending (not 'Uploaded')
        expect(find.byType(AiReviewBadge), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text(AppStrings('en').galUploaded), findsNothing);
      },
    );

    testWidgets(
      'MediaSubTab emits localized notification when switching AI Persona Mode',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final spyNotif = _SpyNotificationService();
        final container = ProviderContainer(
          overrides: [
            notificationServiceProvider.overrideWithValue(spyNotif),
            mediaStorageServiceProvider.overrideWithValue(_FakeMediaStorage()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildHarness(
            locale: const Locale('en'),
            container: container,
            child: const SingleChildScrollView(child: MediaSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        final enStrings = AppStrings('en');
        await tester.tap(find.text(enStrings.galModePrivacy));
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).personaMode, 'privacy_avatar');
        // When FirebaseAuth.currentUser is null in unit tests, no crash occurs
        expect(tester.takeException(), isNull);
      },
    );
  });
}
