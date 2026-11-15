import * as crypto from "node:crypto";
import type {
  AiGenerationArtifact,
  AnatomicalValidationResult,
  GenerateRequest,
} from "./types";

export interface CachedAiOutput {
  inputHash: string;
  modelId: string;
  artifact: AiGenerationArtifact;
  validation: AnatomicalValidationResult;
  cachedAtMs: number;
}

const DEFAULT_TTL_MS = 60 * 60 * 1000; // 1 hour
const DEFAULT_MAX_ENTRIES = 500;

/**
 * Computes a deterministic SHA-256 fingerprint over the AI generation inputs
 * so identical prompts, images, and quality tiers reuse cached results
 * without consuming provider tokens.
 */
export function computeInputSha256(req: GenerateRequest): string {
  const imagePart = req.inputImageHash
    ? req.inputImageHash
    : req.imageBase64
      ? crypto.createHash("sha256").update(req.imageBase64).digest("hex")
      : "no-image";

  const canonical = JSON.stringify({
    serviceType: req.serviceType,
    qualityTier: req.qualityTier,
    prompt: req.prompt.trim().toLowerCase(),
    imageHash: imagePart,
    garmentId: req.garmentId ?? null,
    templateId: req.templateId ?? null,
    locale: req.locale,
    healthContext: req.healthContext
      ? {
          hint: req.healthContext.stylistBiometricHint ?? null,
          energy: req.healthContext.energyReadinessScore ?? null,
          sleep: req.healthContext.sleepHours ?? null,
          steps: req.healthContext.steps ?? null,
        }
      : null,
  });

  return crypto.createHash("sha256").update(canonical).digest("hex");
}

/**
 * Bounded in-memory SHA-256 cache with TTL expiration and LRU eviction.
 */
export class Sha256ResultCache {
  private readonly store = new Map<string, CachedAiOutput>();

  constructor(
    private readonly ttlMs: number = DEFAULT_TTL_MS,
    private readonly maxEntries: number = DEFAULT_MAX_ENTRIES,
  ) {}

  public get(inputHash: string): CachedAiOutput | null {
    const entry = this.store.get(inputHash);
    if (!entry) {
      return null;
    }

    if (Date.now() - entry.cachedAtMs > this.ttlMs) {
      this.store.delete(inputHash);
      return null;
    }

    // Refresh insertion order for LRU behavior
    this.store.delete(inputHash);
    this.store.set(inputHash, entry);
    return entry;
  }

  public set(entry: CachedAiOutput): void {
    if (this.store.has(entry.inputHash)) {
      this.store.delete(entry.inputHash);
    } else if (this.store.size >= this.maxEntries) {
      const oldestKey = this.store.keys().next().value;
      if (oldestKey !== undefined) {
        this.store.delete(oldestKey);
      }
    }
    this.store.set(entry.inputHash, entry);
  }

  public size(): number {
    return this.store.size;
  }
}
