import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_gateway_client.dart';
import '../services/ai_http_transport_stub.dart'
    if (dart.library.io) '../services/ai_http_transport_io.dart'
    as http_transport;
import '../services/emulator_config.dart';
import 'ai_verification_models.dart';

/// Cost-controlled 2-stage AI verification service for KYC, Profile Media,
/// and Virtual Wardrobe uploads.
///
/// Stage 1 runs locally at zero cloud cost (size, format, minimum byte sanity
/// check, and deterministic SHA-256 deduplication cache).
/// Stage 2 calls `POST /v1/verify-media` on `ai-gateway` with a graceful,
/// deterministic local preview fallback when offline or in preview mode.
class AiVerificationService {
  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoBytes = 50 * 1024 * 1024; // 50 MB
  static const int minImageBytes = 512;
  static const int minVideoBytes = 1024;

  static const Set<String> _allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  static const Set<String> _allowedVideoExtensions = {'mp4', 'mov'};

  static const Map<String, String> _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };

  final String baseUrl;
  final AiTransportInvoker _send;
  final bool forceSimulation;
  final Map<String, AiVerificationResult> _cache = {};

  AiVerificationService({
    String? baseUrl,
    AiTransportInvoker? transportInvoker,
    this.forceSimulation = false,
  }) : baseUrl = (baseUrl ?? EmulatorConfig.aiGatewayUrl).replaceAll(
         RegExp(r'/+$'),
         '',
       ),
       _send = transportInvoker ?? http_transport.sendHttpRequest;

  int get cacheSize => _cache.length;

  void clearCache() => _cache.clear();

  /// Computes a deterministic SHA-256 hex digest for [bytes].
  String computeSha256(Uint8List bytes) => sha256.convert(bytes).toString();

  /// Typed entry point for KYC identity document & selfie verification.
  Future<AiVerificationResult> verifyKycDocument({
    required Uint8List bytes,
    required String fileNameOrMime,
    String? docType,
  }) {
    return _verifyMedia(
      target: AiVerificationTarget.kycDocument,
      bytes: bytes,
      fileNameOrMime: fileNameOrMime,
      isVideo: false,
      contextHint: docType,
    );
  }

  /// Typed entry point for Profile Media (base body photos & 360° scan video).
  Future<AiVerificationResult> verifyProfileMedia({
    required Uint8List bytes,
    required String fileNameOrMime,
    required String slotKey,
    bool isVideo = false,
  }) {
    return _verifyMedia(
      target: AiVerificationTarget.profileMedia,
      bytes: bytes,
      fileNameOrMime: fileNameOrMime,
      isVideo: isVideo,
      contextHint: slotKey,
    );
  }

  /// Typed entry point for Virtual Wardrobe garment quality & tag verification.
  Future<AiVerificationResult> verifyWardrobeGarment({
    required Uint8List bytes,
    required String fileNameOrMime,
    String? category,
  }) {
    return _verifyMedia(
      target: AiVerificationTarget.wardrobeGarment,
      bytes: bytes,
      fileNameOrMime: fileNameOrMime,
      isVideo: false,
      contextHint: category,
    );
  }

  Future<AiVerificationResult> _verifyMedia({
    required AiVerificationTarget target,
    required Uint8List bytes,
    required String fileNameOrMime,
    required bool isVideo,
    String? contextHint,
  }) async {
    final hash = computeSha256(bytes);
    final cacheKey = '${target.wireValue}:$hash';

    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    // ── Stage 1: Free Local Pre-Flight Gate (Zero Cloud Cost) ────────────────
    final resolvedMime = _resolveMimeType(fileNameOrMime, isVideo: isVideo);
    final preFlightIssues = <AiVerificationIssueCode>[];

    if (resolvedMime == null) {
      preFlightIssues.add(AiVerificationIssueCode.unsupportedFormat);
    }

    final maxBytes = isVideo ? maxVideoBytes : maxImageBytes;
    final minBytes = isVideo ? minVideoBytes : minImageBytes;

    if (bytes.length > maxBytes) {
      preFlightIssues.add(AiVerificationIssueCode.fileTooLarge);
    } else if (bytes.length < minBytes) {
      preFlightIssues.add(AiVerificationIssueCode.lowResolution);
    }

    if (preFlightIssues.isNotEmpty) {
      final rejected = AiVerificationResult(
        status: AiVerificationStatus.rejected,
        confidenceScore: 0.0,
        sha256Hash: hash,
        issues: List.unmodifiable(preFlightIssues),
        suggestedTags: const [],
        checkedAt: DateTime.now(),
        isSimulated: false,
      );
      _cache[cacheKey] = rejected;
      return rejected;
    }

    // ── Stage 2: AI Gateway Verification with Graceful Preview Fallback ──────
    if (!forceSimulation) {
      try {
        final payload = <String, Object?>{
          'target': target.wireValue,
          'sha256Hash': hash,
          'mimeType': resolvedMime,
          'fileSizeBytes': bytes.length,
          if (!isVideo && bytes.length <= 2 * 1024 * 1024)
            'imageBase64': base64Encode(bytes),
        };

        final response = await _send(
          method: 'POST',
          uri: Uri.parse('$baseUrl/v1/verify-media'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
          timeout: const Duration(seconds: 3),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final result = AiVerificationResult.fromJson(
              decoded,
              fallbackHash: hash,
            );
            _cache[cacheKey] = result;
            return result;
          }
        }
      } catch (_) {
        // Fall through cleanly to deterministic local preview simulation.
      }
    }

    final simulated = _runLocalPreviewSimulation(
      target: target,
      hash: hash,
      contextHint: contextHint,
    );
    _cache[cacheKey] = simulated;
    return simulated;
  }

  String? _resolveMimeType(String input, {required bool isVideo}) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    String? ext;
    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      if (parts.length == 2) {
        final subtype = parts[1].split(';').first.trim();
        if (subtype == 'quicktime') {
          ext = 'mov';
        } else {
          ext = subtype;
        }
      }
    } else if (normalized.contains('.')) {
      ext = normalized.split('.').last;
    } else {
      ext = normalized;
    }

    if (ext == null) return null;
    if (isVideo) {
      return _allowedVideoExtensions.contains(ext)
          ? _mimeByExtension[ext]
          : null;
    }
    return _allowedImageExtensions.contains(ext) ? _mimeByExtension[ext] : null;
  }

  AiVerificationResult _runLocalPreviewSimulation({
    required AiVerificationTarget target,
    required String hash,
    String? contextHint,
  }) {
    final tags = <String>[];
    double score = 0.93;

    switch (target) {
      case AiVerificationTarget.kycDocument:
        score = 0.94;
        if (contextHint != null && contextHint.isNotEmpty) {
          tags.add(contextHint);
        }
        break;
      case AiVerificationTarget.profileMedia:
        score = 0.92;
        if (contextHint != null && contextHint.isNotEmpty) {
          tags.add(contextHint);
        }
        break;
      case AiVerificationTarget.wardrobeGarment:
        score = 0.95;
        tags.add('garment_verified');
        if (contextHint != null && contextHint.isNotEmpty) {
          tags.add(contextHint);
        }
        break;
    }

    return AiVerificationResult(
      status: AiVerificationStatus.approved,
      confidenceScore: score,
      sha256Hash: hash,
      issues: const [],
      suggestedTags: List.unmodifiable(tags),
      checkedAt: DateTime.now(),
      isSimulated: true,
    );
  }
}

final aiVerificationServiceProvider = Provider<AiVerificationService>((ref) {
  return AiVerificationService();
});
