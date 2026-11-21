import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/services/ai_gateway_client.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/features/atelier/domain/atelier_models.dart';
import 'package:stylemorph/features/atelier/presentation/atelier_provider.dart';
import 'package:stylemorph/features/stylist/presentation/stylist_provider.dart';
import 'package:stylemorph/features/wellness/presentation/wellness_provider.dart';

void main() {
  group('Phase 4 Step 4.4: AiGatewayClient & Graceful Fallback Tests', () {
    test(
      'Uses real gateway HTTP 200 payload when ai-gateway is reachable',
      () async {
        final client = AiGatewayClient(
          baseUrl: 'http://localhost:8081',
          transportInvoker:
              ({
                required String method,
                required Uri uri,
                Map<String, String>? headers,
                String? body,
                Duration timeout = const Duration(seconds: 4),
              }) async {
                if (method == 'GET' && uri.path == '/health') {
                  return const AiHttpResponse(
                    statusCode: 200,
                    body: '{"status":"ok"}',
                  );
                }
                return AiHttpResponse(
                  statusCode: 200,
                  body: jsonEncode({
                    'jobId': 'job_gw_123',
                    'status': 'COMPLETED',
                    'coinCost': 10,
                    'modelId': 'imagen-3.0-generate',
                    'keyIdUsed': 'pool-key-1',
                    'cacheHit': true,
                    'inputHash': 'abc12345',
                    'validation': {
                      'passed': true,
                      'anatomicalScore': 0.95,
                      'faceConsistencyScore': 0.97,
                      'garmentAlignmentScore': 0.94,
                    },
                    'artifact': {
                      'watermarkText': kMandatoryAiWatermark,
                      'mediaUrl':
                          'https://storage.stylemorph.local/mock/u1/job_gw_123.webp',
                    },
                    'captureTxId': 'tx_gw_123',
                  }),
                );
              },
        );

        expect(await client.checkHealth(), true);

        final res = await client.generate(
          userId: 'u_demo',
          serviceType: AiServiceType.virtualTryOn,
          qualityTier: AiQualityTier.standard,
          prompt: 'Test try-on',
          locale: 'fa',
        );

        expect(res.source, AiExecutionSource.gateway);
        expect(res.cacheHit, true);
        expect(res.anatomicalScorePercent, 95);
        expect(res.watermarkText, kMandatoryAiWatermark);
        expect(res.captureTxId, 'tx_gw_123');
      },
    );

    test(
      'Falls back gracefully to local simulation when gateway is unreachable',
      () async {
        final client = AiGatewayClient(
          baseUrl: 'http://localhost:8081',
          transportInvoker:
              ({
                required String method,
                required Uri uri,
                Map<String, String>? headers,
                String? body,
                Duration timeout = const Duration(seconds: 4),
              }) async {
                throw Exception('Connection refused');
              },
        );

        expect(await client.checkHealth(), false);

        final res = await client.generate(
          userId: 'u_demo',
          serviceType: AiServiceType.atelierPhoto,
          qualityTier: AiQualityTier.cinematic,
          prompt: 'Editorial portrait',
          locale: 'en',
        );

        expect(res.source, AiExecutionSource.localFallback);
        expect(res.watermarkText, kMandatoryAiWatermark);
        expect(res.anatomicalScorePercent, 96);
      },
    );

    test(
      'StylistNotifier & WellnessNotifier refund held coins on 422 rejection',
      () async {
        final rejectingClient = AiGatewayClient(
          baseUrl: 'http://localhost:8081',
          transportInvoker:
              ({
                required String method,
                required Uri uri,
                Map<String, String>? headers,
                String? body,
                Duration timeout = const Duration(seconds: 4),
              }) async {
                return const AiHttpResponse(
                  statusCode: 422,
                  body:
                      '{"error":"ANATOMICAL_VALIDATION_FAILED","released":true}',
                );
              },
        );

        final container = ProviderContainer(
          overrides: [
            aiGatewayClientProvider.overrideWithValue(rejectingClient),
          ],
        );
        addTearDown(container.dispose);

        container.read(appStateProvider.notifier).addCoins(100);
        final startCoins = container.read(appStateProvider).coins;

        // Stylist Try-On rejection must refund coins
        final stylistNotifier = container.read(stylistProvider.notifier);
        final outfit = container.read(stylistProvider).outfits.first;
        await expectLater(
          stylistNotifier.runTryOnSimulation(outfit),
          throwsA(isA<AiGenerationRejectedException>()),
        );
        expect(container.read(appStateProvider).coins, startCoins);
        expect(container.read(stylistProvider).tryOnStatus, TryOnStatus.idle);

        // Wellness Future Self rejection must refund coins
        final wellnessNotifier = container.read(wellnessProvider.notifier);
        await expectLater(
          wellnessNotifier.runFutureSelfSimulation(),
          throwsA(isA<AiGenerationRejectedException>()),
        );
        expect(container.read(appStateProvider).coins, startCoins);
      },
    );

    test(
      'AtelierNotifier completes creation via AiGatewayClient fallback',
      () async {
        final unreachableClient = AiGatewayClient(
          baseUrl: 'http://localhost:8081',
          transportInvoker:
              ({
                required String method,
                required Uri uri,
                Map<String, String>? headers,
                String? body,
                Duration timeout = const Duration(seconds: 4),
              }) async {
                throw Exception('Connection refused');
              },
        );

        final container = ProviderContainer(
          overrides: [
            aiGatewayClientProvider.overrideWithValue(unreachableClient),
          ],
        );
        addTearDown(container.dispose);

        container.read(appStateProvider.notifier).addCoins(100);
        final startCoins = container.read(appStateProvider).coins;
        final notifier = container.read(atelierProvider.notifier);
        final tpl = container.read(atelierProvider).templates.first;

        notifier.generateTemplate(tpl);
        expect(container.read(appStateProvider).coins, startCoins - tpl.price);
        expect(
          container.read(atelierProvider).creations.first.status,
          CreationStatus.queue,
        );

        // Wait deterministically for async fallback pipeline to finish (250ms + 200ms)
        for (var i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (container.read(atelierProvider).creations.first.status ==
              CreationStatus.ready) {
            break;
          }
        }
        final latest = container.read(atelierProvider).creations.first;
        expect(latest.status, CreationStatus.ready);
        expect(latest.watermarkText, kMandatoryAiWatermark);
        expect(latest.anatomicalScore, isNotNull);
      },
    );
  });
}
