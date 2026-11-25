import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/ai/ai_verification_models.dart';
import 'package:stylemorph/core/ai/ai_verification_service.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/ai_http_response.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/ai_review_badge.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  Widget buildBadgeHarness({
    required Widget child,
    Locale locale = const Locale('fa'),
  }) {
    return MaterialApp(
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
      theme: testTheme,
      home: Scaffold(
        body: Directionality(
          textDirection: locale.languageCode == 'fa'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Center(child: SizedBox(width: 280, child: child)),
        ),
      ),
    );
  }

  group('AiVerificationService — Stage 1 Pre-Flight, Honesty & Caching', () {
    test('rejects oversized image locally with zero network calls', () async {
      var networkCalls = 0;
      final service = AiVerificationService(
        transportInvoker:
            ({
              required String method,
              required Uri uri,
              Map<String, String>? headers,
              String? body,
              Duration timeout = const Duration(seconds: 3),
            }) async {
              networkCalls += 1;
              return const AiHttpResponse(statusCode: 200, body: '{}');
            },
      );

      final oversizedBytes = Uint8List(
        AiVerificationService.maxImageBytes + 1024,
      );
      final result = await service.verifyKycDocument(
        bytes: oversizedBytes,
        fileNameOrMime: 'national_id.jpg',
      );

      expect(networkCalls, 0);
      expect(result.status, AiVerificationStatus.rejected);
      expect(result.isRejected, isTrue);
      expect(result.isApproved, isFalse);
      expect(result.issues, contains(AiVerificationIssueCode.fileTooLarge));
      expect(result.isSimulated, isFalse);
    });

    test(
      'rejects unsupported format locally with zero network calls',
      () async {
        var networkCalls = 0;
        final service = AiVerificationService(
          transportInvoker:
              ({
                required String method,
                required Uri uri,
                Map<String, String>? headers,
                String? body,
                Duration timeout = const Duration(seconds: 3),
              }) async {
                networkCalls += 1;
                return const AiHttpResponse(statusCode: 200, body: '{}');
              },
        );

        final validSizedBytes = Uint8List(2048);
        final result = await service.verifyKycDocument(
          bytes: validSizedBytes,
          fileNameOrMime: 'document.gif',
        );

        expect(networkCalls, 0);
        expect(result.status, AiVerificationStatus.rejected);
        expect(
          result.issues,
          contains(AiVerificationIssueCode.unsupportedFormat),
        );
      },
    );

    test(
      'caches SHA-256 verification results and avoids duplicate gateway calls',
      () async {
        var networkCalls = 0;
        final service = AiVerificationService(
          transportInvoker:
              ({
                required String method,
                required Uri uri,
                Map<String, String>? headers,
                String? body,
                Duration timeout = const Duration(seconds: 3),
              }) async {
                networkCalls += 1;
                return AiHttpResponse(
                  statusCode: 200,
                  body: jsonEncode({
                    'status': 'approved',
                    'confidenceScore': 0.96,
                    'issues': <String>[],
                    'suggestedTags': ['garment_verified'],
                    'isSimulated': false,
                  }),
                );
              },
        );

        final sampleBytes = Uint8List.fromList(List<int>.filled(2048, 42));
        final first = await service.verifyWardrobeGarment(
          bytes: sampleBytes,
          fileNameOrMime: 'image/webp',
          category: 'tops',
        );
        final second = await service.verifyWardrobeGarment(
          bytes: sampleBytes,
          fileNameOrMime: 'image/webp',
          category: 'tops',
        );

        expect(networkCalls, 1);
        expect(first.sha256Hash, second.sha256Hash);
        expect(first.status, AiVerificationStatus.approved);
        expect(first.isApproved, isTrue);
        expect(second.status, AiVerificationStatus.approved);
        expect(service.cacheSize, 1);
      },
    );

    test(
      'simulated/keyless mode returns honest pendingAi and NEVER approved',
      () async {
        final service = AiVerificationService(forceSimulation: true);
        final bytes = Uint8List.fromList(List<int>.filled(4096, 7));

        final kyc = await service.verifyKycDocument(
          bytes: bytes,
          fileNameOrMime: 'passport.png',
          docType: 'passport_front',
        );
        final mediaPhoto = await service.verifyProfileMedia(
          bytes: bytes,
          fileNameOrMime: 'front.jpg',
          slotKey: 'front_face',
        );
        final mediaVideo = await service.verifyProfileMedia(
          bytes: bytes,
          fileNameOrMime: 'scan.mp4',
          slotKey: 'scan_360',
          isVideo: true,
        );
        final wardrobe = await service.verifyWardrobeGarment(
          bytes: bytes,
          fileNameOrMime: 'jacket.webp',
          category: 'outerwear',
        );

        for (final res in [kyc, mediaPhoto, mediaVideo, wardrobe]) {
          expect(res.status, AiVerificationStatus.pendingAi);
          expect(res.isPendingAi, isTrue);
          expect(res.isApproved, isFalse);
          expect(res.isSimulated, isTrue);
        }
      },
    );

    test(
      'downgrades simulated gateway approved response to pendingAi honestly',
      () async {
        final service = AiVerificationService(
          transportInvoker:
              ({
                required String method,
                required Uri uri,
                Map<String, String>? headers,
                String? body,
                Duration timeout = const Duration(seconds: 3),
              }) async {
                return AiHttpResponse(
                  statusCode: 200,
                  body: jsonEncode({
                    'status': 'approved',
                    'confidenceScore': 0.99,
                    'issues': <String>[],
                    'suggestedTags': <String>[],
                    'isSimulated': true,
                  }),
                );
              },
        );

        final bytes = Uint8List.fromList(List<int>.filled(2048, 99));
        final result = await service.verifyProfileMedia(
          bytes: bytes,
          fileNameOrMime: 'image/jpeg',
          slotKey: 'body_front',
        );

        expect(result.status, AiVerificationStatus.pendingAi);
        expect(result.isApproved, isFalse);
        expect(result.isSimulated, isTrue);
      },
    );
  });

  group('AiReviewBadge — RTL & LTR Rendering', () {
    testWidgets(
      'renders all statuses cleanly in Persian RTL without AI Verified on pendingAi',
      (tester) async {
        final strings = AppStrings('fa');

        await tester.pumpWidget(
          buildBadgeHarness(
            locale: const Locale('fa'),
            child: const AiReviewBadge(status: AiVerificationStatus.pendingAi),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.aiStatusPendingAi), findsOneWidget);
        expect(find.text(strings.aiStatusApproved), findsNothing);
        expect(tester.takeException(), isNull);

        for (final status in [
          AiVerificationStatus.reviewing,
          AiVerificationStatus.approved,
          AiVerificationStatus.rejected,
          AiVerificationStatus.needsManualReview,
        ]) {
          await tester.pumpWidget(
            buildBadgeHarness(
              locale: const Locale('fa'),
              child: AiReviewBadge(
                status: status,
                issues: status == AiVerificationStatus.rejected
                    ? const [AiVerificationIssueCode.blurryOrDark]
                    : const [],
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'renders pendingAi, approved, and rejected cleanly in English LTR',
      (tester) async {
        final strings = AppStrings('en');

        await tester.pumpWidget(
          buildBadgeHarness(
            locale: const Locale('en'),
            child: const AiReviewBadge(status: AiVerificationStatus.pendingAi),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.aiStatusPendingAi), findsOneWidget);
        expect(find.text(strings.aiStatusApproved), findsNothing);

        await tester.pumpWidget(
          buildBadgeHarness(
            locale: const Locale('en'),
            child: const AiReviewBadge(status: AiVerificationStatus.approved),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.aiStatusApproved), findsOneWidget);

        await tester.pumpWidget(
          buildBadgeHarness(
            locale: const Locale('en'),
            child: const AiReviewBadge(
              status: AiVerificationStatus.rejected,
              issues: [AiVerificationIssueCode.fileTooLarge],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.aiStatusRejected), findsOneWidget);
        expect(find.text(strings.aiIssueFileTooLarge), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
