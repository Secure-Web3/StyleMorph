import * as crypto from "node:crypto";
import Fastify, { type FastifyInstance } from "fastify";
import { computeInputSha256, Sha256ResultCache } from "./cache";
import { callCaptureCoins, callReleaseCoins } from "./financialClient";
import { MultiKeyLoadBalancer } from "./keyPool";
import {
  injectMandatoryWatermark,
  MANDATORY_AI_WATERMARK,
  resolveQualityTierRoute,
  validateAnatomicalQuality,
} from "./qualityGuard";
import {
  GenerateRequestSchema,
  type AiGenerationArtifact,
  type AnatomicalValidationResult,
  type GenerateRequest,
  type GenerateResponse,
  type QualityTierRoute,
} from "./types";

const keyPool = new MultiKeyLoadBalancer();
const resultCache = new Sha256ResultCache();

function isMockAiEnabled(): boolean {
  return (process.env["USE_MOCK_AI"] ?? "true").toLowerCase() !== "false";
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

class ProviderError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
    this.name = "ProviderError";
  }
}

async function runMockProviderGeneration(
  req: GenerateRequest,
  route: QualityTierRoute,
  jobId: string,
): Promise<{
  artifact: Omit<AiGenerationArtifact, "watermarkText" | "watermarked">;
  validation: AnatomicalValidationResult;
}> {
  const baseLatencyMs = Number(process.env["MOCK_AI_LATENCY_MS"] ?? "140");
  const jitterMs = Math.floor(Math.random() * 60);
  await sleep(Math.max(20, baseLatencyMs + jitterMs));

  if (req.simulateFailure) {
    throw new ProviderError(503, "SIMULATED_AI_GENERATION_FAILURE");
  }

  const isVideo = req.serviceType === "ATELIER_VIDEO";
  const mediaType =
    req.serviceType === "STYLIST_CHAT"
      ? "text"
      : isVideo
        ? "video"
        : "image";
  const ext = mediaType === "video" ? "mp4" : "webp";

  const validation = validateAnatomicalQuality({
    serviceType: req.serviceType,
    qualityTier: req.qualityTier,
    overrideScore: req.mockAnatomicalScore,
  });

  const artifact: Omit<AiGenerationArtifact, "watermarkText" | "watermarked"> = {
    jobId,
    mediaType,
    mediaUrl: `https://storage.stylemorph.local/mock/${req.userId}/${jobId}.${ext}`,
    thumbnailUrl: `https://storage.stylemorph.local/mock/${req.userId}/${jobId}_thumb.webp`,
    extractedTags: {
      serviceType: req.serviceType,
      qualityTier: route.tier,
      modelId: route.modelId,
      locale: req.locale,
      ...(req.healthContext?.stylistBiometricHint
        ? { biometricHint: req.healthContext.stylistBiometricHint }
        : {}),
      ...(req.healthContext?.energyReadinessScore !== undefined
        ? { energyReadiness: String(req.healthContext.energyReadinessScore) }
        : {}),
      ...(req.healthContext?.sourceDevice
        ? { sourceDevice: req.healthContext.sourceDevice }
        : {}),
    },
  };

  return { artifact, validation };
}

async function executeWithKeyPoolFailover(
  req: GenerateRequest,
  route: QualityTierRoute,
  jobId: string,
): Promise<{
  keyIdUsed: string;
  artifact: AiGenerationArtifact;
  validation: AnatomicalValidationResult;
}> {
  const excludedIds = new Set<string>();
  const maxAttempts = Math.max(2, route.maxRetries + 1);
  let lastError: Error = new Error("NO_HEALTHY_AI_KEYS_AVAILABLE");

  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const keyEntry = keyPool.acquireKey(excludedIds);
    if (!keyEntry) {
      break;
    }

    const startedAt = Date.now();
    try {
      const raw = isMockAiEnabled()
        ? await runMockProviderGeneration(req, route, jobId)
        : await Promise.reject(
            new ProviderError(
              501,
              "LIVE_VERTEX_AI_DISABLED_IN_LOCAL_PHASE4",
            ),
          );

      const latencyMs = Date.now() - startedAt;
      keyPool.reportSuccess(keyEntry.id, latencyMs);

      const watermarkedArtifact = injectMandatoryWatermark(raw.artifact);

      if (!raw.validation.passed) {
        // Attempt one automated Self-Correction pass before failing
        if (attempt === 0 && req.mockAnatomicalScore === undefined) {
          excludedIds.add(keyEntry.id);
          continue;
        }
        throw new Error(
          raw.validation.rejectionReason ?? "ANATOMICAL_VALIDATION_FAILED",
        );
      }

      return {
        keyIdUsed: keyEntry.id,
        artifact: watermarkedArtifact,
        validation: raw.validation,
      };
    } catch (err) {
      excludedIds.add(keyEntry.id);
      if (err instanceof ProviderError) {
        keyPool.reportFailure(keyEntry.id, err.statusCode, err.message);
        lastError = err;
        if (err.statusCode === 429 || err.statusCode >= 500) {
          continue;
        }
        break;
      }
      lastError = err instanceof Error ? err : new Error(String(err));
      break;
    }
  }

  throw lastError;
}

// ── HTTP Factory & Routes ──────────────────────────────────────────────────

function buildApp(): FastifyInstance {
  const server = Fastify({
    logger: false,
    bodyLimit: 10 * 1024 * 1024,
  });

  server.get("/health", async (_req, reply) => {
    return reply.status(200).send({
      status: "ok",
      service: "stylemorph-ai-gateway",
      mockMode: isMockAiEnabled(),
      cacheEntries: resultCache.size(),
      watermark: MANDATORY_AI_WATERMARK,
      keys: keyPool.getMetrics(),
    });
  });

  server.get("/metrics/keys", async (_req, reply) => {
    return reply.status(200).send({
      mockMode: isMockAiEnabled(),
      keys: keyPool.getMetrics(),
    });
  });

  server.post("/v1/generate", async (req, reply) => {
    const parsed = GenerateRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({
        error: "INVALID_GENERATE_REQUEST",
        details: parsed.error.flatten(),
      });
    }

    const input = parsed.data;
    const route = resolveQualityTierRoute(input.qualityTier, input.serviceType);
    const inputHash = computeInputSha256(input);
    const jobId = `job_${crypto.randomUUID()}`;

    // 1. Check SHA-256 Cache before invoking AI provider keys
    const cached = !input.simulateFailure && input.mockAnatomicalScore === undefined
      ? resultCache.get(inputHash)
      : null;

    if (cached) {
      try {
        const capture = await callCaptureCoins({
          holdId: input.holdId,
          idempotencyKey: `cap_${input.idempotencyKey}`,
          metadata: {
            jobId,
            inputHash,
            cacheHit: true,
            modelId: cached.modelId,
            watermark: cached.artifact.watermarkText,
          },
        });

        const response: GenerateResponse = {
          jobId,
          status: "COMPLETED",
          serviceType: input.serviceType,
          qualityTier: input.qualityTier,
          coinCost: route.coinCost,
          modelId: cached.modelId,
          keyIdUsed: "sha256-cache",
          cacheHit: true,
          inputHash,
          mockMode: isMockAiEnabled(),
          validation: cached.validation,
          artifact: cached.artifact,
          captureTxId: capture.ledgerTxId,
        };
        return reply.status(200).send(response);
      } catch (captureErr) {
        const msg =
          captureErr instanceof Error ? captureErr.message : String(captureErr);
        return reply.status(502).send({ error: "CAPTURE_FAILED_ON_CACHE_HIT", detail: msg });
      }
    }

    // 2. Execute generation via Multi-Key Pool + Anatomical Self-Correction
    try {
      const generated = await executeWithKeyPoolFailover(input, route, jobId);

      resultCache.set({
        inputHash,
        modelId: route.modelId,
        artifact: generated.artifact,
        validation: generated.validation,
        cachedAtMs: Date.now(),
      });

      // 3. Finalize hold via captureCoins ONLY after validation & watermark succeed
      const capture = await callCaptureCoins({
        holdId: input.holdId,
        idempotencyKey: `cap_${input.idempotencyKey}`,
        metadata: {
          jobId,
          inputHash,
          cacheHit: false,
          modelId: route.modelId,
          keyIdUsed: generated.keyIdUsed,
          anatomicalScore: generated.validation.anatomicalScore,
          watermark: generated.artifact.watermarkText,
        },
      });

      const response: GenerateResponse = {
        jobId,
        status: "COMPLETED",
        serviceType: input.serviceType,
        qualityTier: input.qualityTier,
        coinCost: route.coinCost,
        modelId: route.modelId,
        keyIdUsed: generated.keyIdUsed,
        cacheHit: false,
        inputHash,
        mockMode: isMockAiEnabled(),
        validation: generated.validation,
        artifact: generated.artifact,
        captureTxId: capture.ledgerTxId,
      };
      return reply.status(200).send(response);
    } catch (genErr) {
      // 4. Automatic Release on AI failure or failed anatomical self-correction
      const reason =
        genErr instanceof Error ? genErr.message : "AI_GENERATION_FAILED";

      try {
        const release = await callReleaseCoins({
          holdId: input.holdId,
          reason,
          idempotencyKey: `rel_${input.idempotencyKey}`,
        });
        return reply.status(422).send({
          error: reason,
          jobId,
          holdId: input.holdId,
          released: true,
          releaseTxId: release.ledgerTxId,
        });
      } catch (releaseErr) {
        const releaseMsg =
          releaseErr instanceof Error ? releaseErr.message : String(releaseErr);
        return reply.status(500).send({
          error: reason,
          releaseError: releaseMsg,
          jobId,
          holdId: input.holdId,
          released: false,
        });
      }
    }
  });

  return server;
}

const app = buildApp();

if (require.main === module) {
  const port = Number(process.env["PORT"] ?? "8081");
  const host = process.env["HOST"] ?? "0.0.0.0";
  app.listen({ port, host }, (err, address) => {
    if (err) {
      process.stderr.write(`Failed to start StyleMorph AI Gateway: ${err.message}\n`);
      process.exit(1);
    }
    process.stdout.write(
      `StyleMorph AI Gateway listening on ${address} (USE_MOCK_AI=${isMockAiEnabled()})\n`,
    );
  });
}

export { app, buildApp, keyPool, resultCache };
