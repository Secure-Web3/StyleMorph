import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_http_response.dart';
import 'ai_http_transport_stub.dart'
    if (dart.library.io) 'ai_http_transport_io.dart'
    as http_transport;
import 'emulator_config.dart';

export 'ai_http_response.dart';

const String kMandatoryAiWatermark = 'ساختهشده با هوش مصنوعی';

enum AiExecutionSource { gateway, localFallback }

enum AiServiceType {
  virtualTryOn('VIRTUAL_TRYON'),
  atelierPhoto('ATELIER_PHOTO'),
  atelierVideo('ATELIER_VIDEO'),
  stylistChat('STYLIST_CHAT'),
  wellnessAnalysis('WELLNESS_ANALYSIS');

  final String wireValue;
  const AiServiceType(this.wireValue);
}

enum AiQualityTier {
  fast('FAST', 5),
  standard('STANDARD', 10),
  cinematic('CINEMATIC', 20);

  final String wireValue;
  final int defaultCoins;
  const AiQualityTier(this.wireValue, this.defaultCoins);
}

class AiGenerationRejectedException implements Exception {
  final String message;
  final bool released;

  const AiGenerationRejectedException(this.message, {this.released = true});

  @override
  String toString() => message;
}

class AiGenerationResult {
  final String jobId;
  final String holdId;
  final String idempotencyKey;
  final AiServiceType serviceType;
  final AiQualityTier qualityTier;
  final int coinCost;
  final String modelId;
  final String keyIdUsed;
  final bool cacheHit;
  final String inputHash;
  final double anatomicalScore;
  final double faceConsistencyScore;
  final double garmentAlignmentScore;
  final String watermarkText;
  final String mediaUrl;
  final String captureTxId;
  final AiExecutionSource source;

  const AiGenerationResult({
    required this.jobId,
    required this.holdId,
    required this.idempotencyKey,
    required this.serviceType,
    required this.qualityTier,
    required this.coinCost,
    required this.modelId,
    required this.keyIdUsed,
    required this.cacheHit,
    required this.inputHash,
    required this.anatomicalScore,
    required this.faceConsistencyScore,
    required this.garmentAlignmentScore,
    required this.watermarkText,
    required this.mediaUrl,
    required this.captureTxId,
    required this.source,
  });

  int get anatomicalScorePercent => (anatomicalScore * 100).round();
}

typedef AiTransportInvoker =
    Future<AiHttpResponse> Function({
      required String method,
      required Uri uri,
      Map<String, String>? headers,
      String? body,
      Duration timeout,
    });

/// Client connecting Flutter AI modules (Stylist, Atelier, Wellness) to the
/// local/Cloud Run `ai-gateway` microservice with seamless offline fallback.
class AiGatewayClient {
  final String baseUrl;
  final AiTransportInvoker _send;

  AiGatewayClient({String? baseUrl, AiTransportInvoker? transportInvoker})
    : baseUrl = (baseUrl ?? EmulatorConfig.aiGatewayUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      ),
      _send = transportInvoker ?? http_transport.sendHttpRequest;

  static int _seq = 0;

  /// Generates a collision-resistant idempotency key matching backend regex
  /// `/^[a-zA-Z0-9._:-]+$/`.
  String generateIdempotencyKey(String prefix) {
    _seq += 1;
    final cleanPrefix = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9._:-]'), '_');
    return '${cleanPrefix}_${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  /// Computes a deterministic 64-char hex fingerprint for input deduplication.
  String computeInputHash(Map<String, Object?> payload) {
    final bytes = utf8.encode(jsonEncode(payload));
    var h1 = 0x811c9dc5;
    var h2 = 0x9e3779b9;
    var h3 = 0x85ebca6b;
    var h4 = 0xc2b2ae35;
    for (final b in bytes) {
      h1 = ((h1 ^ b) * 0x01000193) & 0xffffffff;
      h2 = ((h2 ^ (b + 17)) * 0x01000193) & 0xffffffff;
      h3 = ((h3 ^ (b + 31)) * 0x01000193) & 0xffffffff;
      h4 = ((h4 ^ (b + 53)) * 0x01000193) & 0xffffffff;
    }
    return [
      h1,
      h2,
      h3,
      h4,
    ].map((v) => v.toRadixString(16).padLeft(8, '0')).join().padRight(64, '0');
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _send(
        method: 'GET',
        uri: Uri.parse('$baseUrl/health'),
        timeout: const Duration(milliseconds: 1200),
      );
      if (response.statusCode != 200) {
        return false;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Executes `POST /v1/generate` against `ai-gateway`, falling back cleanly
  /// to local simulation if the gateway server is unreachable.
  Future<AiGenerationResult> generate({
    required String userId,
    required AiServiceType serviceType,
    required AiQualityTier qualityTier,
    required String prompt,
    required String locale,
    String? idempotencyKey,
    String? holdId,
    String? garmentId,
    String? templateId,
    Map<String, dynamic>? healthContext,
    bool simulateFailure = false,
  }) async {
    final idemKey =
        idempotencyKey ?? generateIdempotencyKey(serviceType.wireValue);
    final resolvedHoldId = holdId ?? 'hold_$idemKey';
    final inputHash = computeInputHash({
      'serviceType': serviceType.wireValue,
      'qualityTier': qualityTier.wireValue,
      'prompt': prompt.trim().toLowerCase(),
      'garmentId': garmentId,
      'templateId': templateId,
      'locale': locale,
      if (healthContext != null && healthContext.isNotEmpty)
        'healthContext': healthContext,
    });

    final requestBody = <String, Object?>{
      'userId': userId,
      'holdId': resolvedHoldId,
      'serviceType': serviceType.wireValue,
      'qualityTier': qualityTier.wireValue,
      'prompt': prompt,
      'inputImageHash': inputHash,
      'garmentId': ?garmentId,
      'templateId': ?templateId,
      'locale': _supportedLocale(locale),
      'idempotencyKey': idemKey,
      if (healthContext != null && healthContext.isNotEmpty)
        'healthContext': healthContext,
      if (simulateFailure) 'simulateFailure': true,
    };

    try {
      final response = await _send(
        method: 'POST',
        uri: Uri.parse('$baseUrl/v1/generate'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
        timeout: const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validation =
            (json['validation'] as Map<String, dynamic>?) ?? const {};
        final artifact =
            (json['artifact'] as Map<String, dynamic>?) ?? const {};

        return AiGenerationResult(
          jobId: (json['jobId'] as String?) ?? 'job_$idemKey',
          holdId: resolvedHoldId,
          idempotencyKey: idemKey,
          serviceType: serviceType,
          qualityTier: qualityTier,
          coinCost:
              (json['coinCost'] as num?)?.toInt() ?? qualityTier.defaultCoins,
          modelId: (json['modelId'] as String?) ?? 'gemini-2.5-flash-image',
          keyIdUsed: (json['keyIdUsed'] as String?) ?? 'gateway',
          cacheHit: (json['cacheHit'] as bool?) ?? false,
          inputHash: (json['inputHash'] as String?) ?? inputHash,
          anatomicalScore:
              (validation['anatomicalScore'] as num?)?.toDouble() ?? 0.92,
          faceConsistencyScore:
              (validation['faceConsistencyScore'] as num?)?.toDouble() ?? 0.94,
          garmentAlignmentScore:
              (validation['garmentAlignmentScore'] as num?)?.toDouble() ?? 0.91,
          watermarkText:
              (artifact['watermarkText'] as String?) ?? kMandatoryAiWatermark,
          mediaUrl:
              (artifact['mediaUrl'] as String?) ??
              'https://storage.stylemorph.local/mock/$userId/$idemKey.webp',
          captureTxId: (json['captureTxId'] as String?) ?? 'tx_$idemKey',
          source: AiExecutionSource.gateway,
        );
      }

      if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final reason =
            (json['error'] as String?) ?? 'ANATOMICAL_VALIDATION_FAILED';
        final released = (json['released'] as bool?) ?? true;
        throw AiGenerationRejectedException(reason, released: released);
      }
    } on AiGenerationRejectedException {
      rethrow;
    } catch (_) {
      // Unreachable local gateway -> fall through to graceful fallback below
    }

    return _buildLocalFallbackResult(
      userId: userId,
      holdId: resolvedHoldId,
      idempotencyKey: idemKey,
      serviceType: serviceType,
      qualityTier: qualityTier,
      inputHash: inputHash,
      simulateFailure: simulateFailure,
    );
  }

  String _supportedLocale(String locale) {
    final base = locale.toLowerCase().split(RegExp(r'[-_]')).first;
    if (base == 'fa' || base == 'en' || base == 'ar' || base == 'tr') {
      return base;
    }
    return 'fa';
  }

  AiGenerationResult _buildLocalFallbackResult({
    required String userId,
    required String holdId,
    required String idempotencyKey,
    required AiServiceType serviceType,
    required AiQualityTier qualityTier,
    required String inputHash,
    required bool simulateFailure,
  }) {
    if (simulateFailure) {
      throw const AiGenerationRejectedException(
        'SIMULATED_AI_GENERATION_FAILURE',
        released: true,
      );
    }

    final anatomicalScore = qualityTier == AiQualityTier.cinematic
        ? 0.96
        : qualityTier == AiQualityTier.standard
        ? 0.92
        : 0.87;
    final ext = serviceType == AiServiceType.atelierVideo ? 'mp4' : 'webp';

    return AiGenerationResult(
      jobId: 'local_job_$idempotencyKey',
      holdId: holdId,
      idempotencyKey: idempotencyKey,
      serviceType: serviceType,
      qualityTier: qualityTier,
      coinCost: qualityTier.defaultCoins,
      modelId: qualityTier == AiQualityTier.cinematic
          ? 'imagen-3.0-ultra'
          : qualityTier == AiQualityTier.standard
          ? 'imagen-3.0-generate'
          : 'gemini-2.5-flash-image',
      keyIdUsed: 'local-fallback',
      cacheHit: false,
      inputHash: inputHash,
      anatomicalScore: anatomicalScore,
      faceConsistencyScore: (anatomicalScore + 0.02).clamp(0.0, 1.0),
      garmentAlignmentScore: (anatomicalScore - 0.01).clamp(0.0, 1.0),
      watermarkText: kMandatoryAiWatermark,
      mediaUrl:
          'https://storage.stylemorph.local/fallback/$userId/$idempotencyKey.$ext',
      captureTxId: 'local_tx_$idempotencyKey',
      source: AiExecutionSource.localFallback,
    );
  }
}

final aiGatewayClientProvider = Provider<AiGatewayClient>(
  (_) => AiGatewayClient(),
);
