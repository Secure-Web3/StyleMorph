import * as assert from "node:assert/strict";
import * as http from "node:http";
import test from "node:test";
import { computeInputSha256, Sha256ResultCache } from "../cache";
import { buildApp } from "../index";
import { MultiKeyLoadBalancer } from "../keyPool";
import {
  injectMandatoryWatermark,
  MANDATORY_AI_WATERMARK,
  resolveQualityTierRoute,
  validateAnatomicalQuality,
} from "../qualityGuard";

test("MultiKeyLoadBalancer tracks 429 cooldown, quarantine, and fails over cleanly", () => {
  const pool = new MultiKeyLoadBalancer([
    {
      id: "key-fast",
      projectId: "proj-1",
      region: "europe-west3",
      apiKey: "secret-1",
    },
    {
      id: "key-backup",
      projectId: "proj-2",
      region: "europe-west1",
      apiKey: "secret-2",
    },
  ]);

  pool.reportSuccess("key-fast", 45);
  pool.reportSuccess("key-backup", 180);

  // Least-latency key is chosen first
  const first = pool.acquireKey();
  assert.equal(first?.id, "key-fast");

  // 429 puts key-fast in cooldown -> key-backup takes over
  pool.reportFailure("key-fast", 429, "Rate limit exceeded");
  const failover = pool.acquireKey();
  assert.equal(failover?.id, "key-backup");

  // 401 quarantines key-backup -> no healthy keys remain
  pool.reportFailure("key-backup", 401, "Invalid API key");
  const none = pool.acquireKey();
  assert.equal(none, null);
});

test("Sha256ResultCache deduplicates identical payloads and expires TTL", async () => {
  const hashA = computeInputSha256({
    userId: "u1",
    holdId: "h1",
    serviceType: "VIRTUAL_TRYON",
    qualityTier: "STANDARD",
    prompt: "  Summer Linen Blazer  ",
    garmentId: "g_1",
    locale: "fa",
    idempotencyKey: "idem_12345678",
  });
  const hashB = computeInputSha256({
    userId: "u2",
    holdId: "h2",
    serviceType: "VIRTUAL_TRYON",
    qualityTier: "STANDARD",
    prompt: "summer linen blazer",
    garmentId: "g_1",
    locale: "fa",
    idempotencyKey: "idem_87654321",
  });
  assert.equal(hashA, hashB);

  const cache = new Sha256ResultCache(50, 2);
  cache.set({
    inputHash: hashA,
    modelId: "imagen-3.0-generate",
    artifact: injectMandatoryWatermark({
      jobId: "job_1",
      mediaType: "image",
      mediaUrl: "https://storage.stylemorph.local/mock/1.webp",
    }),
    validation: validateAnatomicalQuality({
      serviceType: "VIRTUAL_TRYON",
      qualityTier: "STANDARD",
    }),
    cachedAtMs: Date.now(),
  });

  assert.ok(cache.get(hashA));
  await new Promise((resolve) => setTimeout(resolve, 65));
  assert.equal(cache.get(hashA), null);
});

test("Quality tier routing & mandatory AI watermark injection", () => {
  assert.equal(resolveQualityTierRoute("FAST", "VIRTUAL_TRYON").coinCost, 5);
  assert.equal(resolveQualityTierRoute("STANDARD", "ATELIER_PHOTO").coinCost, 10);
  assert.equal(resolveQualityTierRoute("CINEMATIC", "ATELIER_VIDEO").coinCost, 20);

  const valid = validateAnatomicalQuality({
    serviceType: "VIRTUAL_TRYON",
    qualityTier: "STANDARD",
  });
  assert.equal(valid.passed, true);

  const invalid = validateAnatomicalQuality({
    serviceType: "VIRTUAL_TRYON",
    qualityTier: "STANDARD",
    overrideScore: 0.45,
  });
  assert.equal(invalid.passed, false);

  const watermarked = injectMandatoryWatermark({
    jobId: "j_1",
    mediaType: "image",
    mediaUrl: "https://example.com/a.webp",
  });
  assert.equal(watermarked.watermarked, true);
  assert.equal(watermarked.watermarkText, MANDATORY_AI_WATERMARK);
  assert.equal(watermarked.watermarkText, "ساختهشده با هوش مصنوعی");
});

test("Fastify HTTP endpoints: GET /health and GET /metrics/keys via native inject", async () => {
  const app = buildApp();
  try {
    const health = await app.inject({ method: "GET", url: "/health" });
    assert.equal(health.statusCode, 200);
    const healthBody = JSON.parse(health.body) as Record<string, unknown>;
    assert.equal(healthBody["status"], "ok");
    assert.equal(healthBody["service"], "stylemorph-ai-gateway");
    assert.equal(healthBody["watermark"], MANDATORY_AI_WATERMARK);

    const metrics = await app.inject({ method: "GET", url: "/metrics/keys" });
    assert.equal(metrics.statusCode, 200);
    const metricsBody = JSON.parse(metrics.body) as Record<string, unknown>;
    assert.ok(metricsBody["keys"]);

    const badReq = await app.inject({
      method: "POST",
      url: "/v1/generate",
      payload: { invalid: "payload" },
    });
    assert.equal(badReq.statusCode, 400);
    const badReqBody = JSON.parse(badReq.body) as Record<string, unknown>;
    assert.equal(badReqBody["error"], "INVALID_GENERATE_REQUEST");
  } finally {
    await app.close();
  }
});

test("POST /v1/generate executes Capture on success, hits SHA-256 cache, and Releases on failure", async () => {
  let captureCount = 0;
  let releaseCount = 0;

  // Ephemeral local mock for Cloud Functions captureCoins & releaseCoins
  const mockFunctionsServer = http.createServer((req, res) => {
    res.setHeader("Content-Type", "application/json");
    if (req.url?.endsWith("/captureCoins")) {
      captureCount += 1;
      res.statusCode = 200;
      res.end(
        JSON.stringify({
          holdId: "hold_test",
          ledgerTxId: `cap_tx_${captureCount}`,
          status: "CAPTURED",
          availableBalance: 90,
          heldBalance: 0,
        }),
      );
      return;
    }
    if (req.url?.endsWith("/releaseCoins")) {
      releaseCount += 1;
      res.statusCode = 200;
      res.end(
        JSON.stringify({
          holdId: "hold_test",
          ledgerTxId: `rel_tx_${releaseCount}`,
          status: "RELEASED",
          availableBalance: 100,
          heldBalance: 0,
        }),
      );
      return;
    }
    res.statusCode = 404;
    res.end("{}");
  });

  await new Promise<void>((resolve) =>
    mockFunctionsServer.listen(0, "127.0.0.1", resolve),
  );
  const fnAddr = mockFunctionsServer.address();
  assert.ok(fnAddr && typeof fnAddr === "object");

  process.env["FUNCTIONS_BASE_URL"] = `http://127.0.0.1:${fnAddr.port}`;
  process.env["USE_MOCK_AI"] = "true";
  process.env["MOCK_AI_LATENCY_MS"] = "25";

  const app = buildApp();
  const gatewayUrl = await app.listen({ port: 0, host: "127.0.0.1" });

  try {
    // 1. First request -> mock generation + watermark + captureCoins
    const res1 = await fetch(`${gatewayUrl}/v1/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId: "u_test",
        holdId: "hold_1",
        serviceType: "VIRTUAL_TRYON",
        qualityTier: "STANDARD",
        prompt: "Minimalist beige trench coat",
        garmentId: "garment_42",
        locale: "fa",
        idempotencyKey: "tryon_unit_001",
      }),
    });
    assert.equal(res1.status, 200);
    const body1 = (await res1.json()) as Record<string, unknown>;
    assert.equal(body1["cacheHit"], false);
    assert.equal(captureCount, 1);
    const artifact1 = body1["artifact"] as Record<string, unknown>;
    assert.equal(artifact1["watermarkText"], "ساختهشده با هوش مصنوعی");

    // 2. Identical request -> served from SHA-256 cache
    const res2 = await fetch(`${gatewayUrl}/v1/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId: "u_test",
        holdId: "hold_2",
        serviceType: "VIRTUAL_TRYON",
        qualityTier: "STANDARD",
        prompt: "Minimalist beige trench coat",
        garmentId: "garment_42",
        locale: "fa",
        idempotencyKey: "tryon_unit_002",
      }),
    });
    assert.equal(res2.status, 200);
    const body2 = (await res2.json()) as Record<string, unknown>;
    assert.equal(body2["cacheHit"], true);
    assert.equal(body2["keyIdUsed"], "sha256-cache");
    assert.equal(captureCount, 2);

    // 3. Biometric-aware generation with healthContext
    const res3 = await fetch(`${gatewayUrl}/v1/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId: "u_test",
        holdId: "hold_3",
        serviceType: "STYLIST_CHAT",
        qualityTier: "FAST",
        prompt: "Biometric style recommendation",
        locale: "fa",
        idempotencyKey: "tryon_health_003",
        healthContext: {
          sleepHours: 5.1,
          steps: 11000,
          energyReadinessScore: 65,
          stylistBiometricHint: "low_sleep_comfort_mode",
          sourceDevice: "galaxy_watch",
        },
      }),
    });
    assert.equal(res3.status, 200);
    const body3 = (await res3.json()) as any;
    assert.equal(body3["status"], "COMPLETED");
    assert.equal(body3["artifact"]["extractedTags"]["biometricHint"], "low_sleep_comfort_mode");
    assert.equal(body3["artifact"]["extractedTags"]["energyReadiness"], "65");
    assert.equal(body3["artifact"]["extractedTags"]["sourceDevice"], "galaxy_watch");
    assert.equal(captureCount, 3);

    // 4. Simulated failure -> automatic releaseCoins
    const res4 = await fetch(`${gatewayUrl}/v1/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId: "u_test",
        holdId: "hold_4",
        serviceType: "VIRTUAL_TRYON",
        qualityTier: "STANDARD",
        prompt: "Broken anatomy test",
        locale: "fa",
        idempotencyKey: "tryon_unit_004",
        simulateFailure: true,
      }),
    });
    assert.equal(res4.status, 422);
    const body4 = (await res4.json()) as Record<string, unknown>;
    assert.equal(body4["released"], true);
    assert.equal(releaseCount, 1);
    assert.equal(captureCount, 3);
  } finally {
    await app.close();
    await new Promise<void>((resolve) =>
      mockFunctionsServer.close(() => resolve()),
    );
  }
});
