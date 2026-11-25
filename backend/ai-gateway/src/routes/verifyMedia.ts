import type { FastifyInstance } from "fastify";
import { z } from "zod";

export const VerifyMediaRequestSchema = z.object({
  target: z.enum(["kyc_document", "profile_media", "wardrobe_garment"]),
  sha256Hash: z.string().regex(/^[a-fA-F0-9]{64}$/),
  mimeType: z.string().min(3).max(80),
  fileSizeBytes: z.number().int().positive(),
  imageBase64: z.string().optional(),
});

export type VerifyMediaRequest = z.infer<typeof VerifyMediaRequestSchema>;

export type VerifyMediaStatus =
  | "pending"
  | "reviewing"
  | "approved"
  | "rejected"
  | "needs_manual_review";

export type VerifyMediaIssueCode =
  | "file_too_large"
  | "unsupported_format"
  | "low_resolution"
  | "blurry_or_dark"
  | "missing_subject"
  | "policy_violation";

export interface VerifyMediaResponse {
  status: VerifyMediaStatus;
  confidenceScore: number;
  sha256Hash: string;
  issues: VerifyMediaIssueCode[];
  suggestedTags: string[];
  checkedAt: string;
  isSimulated: boolean;
  cacheHit: boolean;
}

const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const MAX_VIDEO_BYTES = 50 * 1024 * 1024;
const MIN_MEDIA_BYTES = 512;
const ALLOWED_IMAGE_MIMES = new Set([
  "image/jpeg",
  "image/jpg",
  "image/png",
  "image/webp",
]);
const ALLOWED_VIDEO_MIMES = new Set(["video/mp4", "video/quicktime"]);

const MAX_CACHE_ENTRIES = 500;
const verificationCache = new Map<string, VerifyMediaResponse>();

function isMockAiEnabled(): boolean {
  return (process.env["USE_MOCK_AI"] ?? "true").toLowerCase() !== "false";
}

function getCachedVerification(cacheKey: string): VerifyMediaResponse | null {
  const hit = verificationCache.get(cacheKey);
  if (!hit) return null;
  verificationCache.delete(cacheKey);
  verificationCache.set(cacheKey, hit);
  return { ...hit, cacheHit: true };
}

function setCachedVerification(
  cacheKey: string,
  value: VerifyMediaResponse,
): void {
  if (verificationCache.has(cacheKey)) {
    verificationCache.delete(cacheKey);
  } else if (verificationCache.size >= MAX_CACHE_ENTRIES) {
    const oldest = verificationCache.keys().next().value;
    if (oldest !== undefined) {
      verificationCache.delete(oldest);
    }
  }
  verificationCache.set(cacheKey, value);
}

function runPreFlightValidation(req: VerifyMediaRequest): VerifyMediaIssueCode[] {
  const issues: VerifyMediaIssueCode[] = [];
  const mime = req.mimeType.trim().toLowerCase();
  const isVideo = mime.startsWith("video/");

  if (isVideo) {
    if (req.target !== "profile_media" || !ALLOWED_VIDEO_MIMES.has(mime)) {
      issues.push("unsupported_format");
    }
    if (req.fileSizeBytes > MAX_VIDEO_BYTES) {
      issues.push("file_too_large");
    }
  } else {
    if (!ALLOWED_IMAGE_MIMES.has(mime)) {
      issues.push("unsupported_format");
    }
    if (req.fileSizeBytes > MAX_IMAGE_BYTES) {
      issues.push("file_too_large");
    }
  }

  if (req.fileSizeBytes < MIN_MEDIA_BYTES) {
    issues.push("low_resolution");
  }

  return issues;
}

function runMockVisionVerification(
  req: VerifyMediaRequest,
): Omit<VerifyMediaResponse, "cacheHit"> {
  const issues = runPreFlightValidation(req);
  if (issues.length > 0) {
    return {
      status: "rejected",
      confidenceScore: 0.0,
      sha256Hash: req.sha256Hash,
      issues,
      suggestedTags: [],
      checkedAt: new Date().toISOString(),
      isSimulated: true,
    };
  }

  const scoreByTarget: Record<VerifyMediaRequest["target"], number> = {
    kyc_document: 0.94,
    profile_media: 0.92,
    wardrobe_garment: 0.95,
  };

  const tagsByTarget: Record<VerifyMediaRequest["target"], string[]> = {
    kyc_document: ["document_legible", "kyc_ready"],
    profile_media: ["clear_lighting", "subject_centered"],
    wardrobe_garment: ["garment_verified", "clean_background"],
  };

  return {
    status: "approved",
    confidenceScore: scoreByTarget[req.target],
    sha256Hash: req.sha256Hash,
    issues: [],
    suggestedTags: tagsByTarget[req.target],
    checkedAt: new Date().toISOString(),
    isSimulated: true,
  };
}

/**
 * Registers the standalone `POST /v1/verify-media` route for automated
 * quality-control across KYC, Profile Media, and Virtual Wardrobe uploads.
 */
export function registerVerifyMediaRoute(server: FastifyInstance): void {
  server.post("/v1/verify-media", async (req, reply) => {
    const parsed = VerifyMediaRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({
        error: "INVALID_VERIFY_MEDIA_REQUEST",
        details: parsed.error.flatten(),
      });
    }

    const input = parsed.data;
    const cacheKey = `${input.target}:${input.sha256Hash.toLowerCase()}`;
    const cached = getCachedVerification(cacheKey);
    if (cached) {
      return reply.status(200).send(cached);
    }

    if (isMockAiEnabled()) {
      const result: VerifyMediaResponse = {
        ...runMockVisionVerification(input),
        cacheHit: false,
      };
      setCachedVerification(cacheKey, result);
      return reply.status(200).send(result);
    }

    // Live Gemini Vision integration hook when USE_MOCK_AI=false
    return reply.status(501).send({
      error: "LIVE_GEMINI_VISION_NOT_CONFIGURED",
      sha256Hash: input.sha256Hash,
    });
  });
}
