export type KeyHealthStatus = "HEALTHY" | "COOLDOWN" | "QUARANTINED";

export interface ApiKeyEntry {
  id: string;
  projectId: string;
  region: string;
  apiKey: string;
  status: KeyHealthStatus;
  latencyEmaMs: number;
  remainingQuota: number;
  error429Count: number;
  consecutiveFailures: number;
  totalRequests: number;
  cooldownUntilMs: number;
  lastError?: string;
}

export interface KeyMetricsSnapshot {
  id: string;
  projectId: string;
  region: string;
  status: KeyHealthStatus;
  latencyEmaMs: number;
  remainingQuota: number;
  error429Count: number;
  totalRequests: number;
  cooldownRemainingMs: number;
}

const DEFAULT_QUOTA = 1000;
const BASE_429_COOLDOWN_MS = 15_000;
const MAX_COOLDOWN_MS = 300_000;

/**
 * Multi-account, multi-project API key pool with Least-Latency & Quota-Aware
 * selection, 429 exponential cooldown, and circuit-breaker quarantine.
 */
export class MultiKeyLoadBalancer {
  private readonly keys: ApiKeyEntry[];

  constructor(initialKeys?: Omit<ApiKeyEntry, "status" | "latencyEmaMs" | "remainingQuota" | "error429Count" | "consecutiveFailures" | "totalRequests" | "cooldownUntilMs">[]) {
    const rawList = initialKeys ?? MultiKeyLoadBalancer.loadFromEnv();
    this.keys = rawList.map((k) => ({
      ...k,
      status: "HEALTHY",
      latencyEmaMs: 120,
      remainingQuota: DEFAULT_QUOTA,
      error429Count: 0,
      consecutiveFailures: 0,
      totalRequests: 0,
      cooldownUntilMs: 0,
    }));
  }

  private static loadFromEnv(): Array<{
    id: string;
    projectId: string;
    region: string;
    apiKey: string;
  }> {
    const rawJson = process.env["AI_KEY_POOL_JSON"];
    if (rawJson) {
      try {
        const parsed = JSON.parse(rawJson) as Array<{
          id: string;
          projectId: string;
          region?: string;
          apiKey: string;
        }>;
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed.map((item, idx) => ({
            id: item.id || `key-${idx + 1}`,
            projectId: item.projectId || `gcp-project-${idx + 1}`,
            region: item.region || "europe-west3",
            apiKey: item.apiKey,
          }));
        }
      } catch {
        // Fallback to comma-separated AI_API_KEYS below
      }
    }

    const csv = process.env["AI_API_KEYS"];
    if (csv && csv.trim().length > 0) {
      return csv
        .split(",")
        .map((s) => s.trim())
        .filter((s) => s.length > 0)
        .map((apiKey, idx) => ({
          id: `pool-key-${idx + 1}`,
          projectId: `stylemorph-pool-${idx + 1}`,
          region: idx % 2 === 0 ? "europe-west3" : "europe-west1",
          apiKey,
        }));
    }

    // Mock-safe default keys when running in USE_MOCK_AI=true mode
    return [
      {
        id: "mock-key-eu-west3-a",
        projectId: "stylemorph-dev-a",
        region: "europe-west3",
        apiKey: "mock-key-a",
      },
      {
        id: "mock-key-eu-west1-b",
        projectId: "stylemorph-dev-b",
        region: "europe-west1",
        apiKey: "mock-key-b",
      },
    ];
  }

  /**
   * Selects the healthiest key using Least-Latency & Quota-Aware scoring,
   * automatically recovering keys whose cooldown window has elapsed.
   */
  public acquireKey(excludedIds: Set<string> = new Set()): ApiKeyEntry | null {
    const now = Date.now();
    const candidates: ApiKeyEntry[] = [];

    for (const entry of this.keys) {
      if (entry.status === "COOLDOWN" && entry.cooldownUntilMs <= now) {
        entry.status = "HEALTHY";
        entry.cooldownUntilMs = 0;
      }

      if (entry.status === "HEALTHY" && !excludedIds.has(entry.id)) {
        candidates.push(entry);
      }
    }

    if (candidates.length === 0) {
      return null;
    }

    candidates.sort((a, b) => {
      // Primary: lowest latency; Secondary: highest remaining quota
      const scoreA = a.latencyEmaMs - Math.min(a.remainingQuota, 500) * 0.05;
      const scoreB = b.latencyEmaMs - Math.min(b.remainingQuota, 500) * 0.05;
      return scoreA - scoreB;
    });

    const chosen = candidates[0];
    chosen.totalRequests += 1;
    chosen.remainingQuota = Math.max(0, chosen.remainingQuota - 1);
    return chosen;
  }

  public reportSuccess(keyId: string, latencyMs: number): void {
    const entry = this.keys.find((k) => k.id === keyId);
    if (!entry) return;
    entry.consecutiveFailures = 0;
    entry.status = "HEALTHY";
    entry.latencyEmaMs = Math.round(entry.latencyEmaMs * 0.7 + latencyMs * 0.3);
  }

  public reportFailure(
    keyId: string,
    statusCode: number,
    message: string,
  ): void {
    const entry = this.keys.find((k) => k.id === keyId);
    if (!entry) return;

    entry.consecutiveFailures += 1;
    entry.lastError = message;

    if (statusCode === 401 || statusCode === 403) {
      entry.status = "QUARANTINED";
      entry.remainingQuota = 0;
      return;
    }

    if (statusCode === 429) {
      entry.error429Count += 1;
      const cooldownMs = Math.min(
        MAX_COOLDOWN_MS,
        BASE_429_COOLDOWN_MS * Math.pow(2, entry.error429Count - 1),
      );
      entry.status = "COOLDOWN";
      entry.cooldownUntilMs = Date.now() + cooldownMs;
      return;
    }

    // Transient 5xx or timeout -> brief cooldown
    entry.status = "COOLDOWN";
    entry.cooldownUntilMs = Date.now() + 10_000;
  }

  public getMetrics(): KeyMetricsSnapshot[] {
    const now = Date.now();
    return this.keys.map((k) => ({
      id: k.id,
      projectId: k.projectId,
      region: k.region,
      status: k.status,
      latencyEmaMs: k.latencyEmaMs,
      remainingQuota: k.remainingQuota,
      error429Count: k.error429Count,
      totalRequests: k.totalRequests,
      cooldownRemainingMs:
        k.status === "COOLDOWN" ? Math.max(0, k.cooldownUntilMs - now) : 0,
    }));
  }
}
