import type { FastifyInstance } from "fastify";
import { z } from "zod";

export const VerifyMediaRequestSchema = z.object({
  target: z.enum(["kyc_document", "profile_media", "wardrobe_garment"]),
  sha256Hash: z.string().regex(/^[a-fA-F0-9]{64}$/),
  mimeType: z.string().min(3).max(80),
  fileSizeBytes: z.number().int().positive(),
  slotContext: z.string().min(1).max(80).optional(),
  imageBase64: z.string().optional(),
});

export type VerifyMediaRequest = z.infer<typeof VerifyMediaRequestSchema>;

export type VerifyMediaStatus =
  | "pending"
  | "pending_ai"
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

/**
 * Structured Vision QA system prompts per verification target.
 * Activated automatically once `USE_MOCK_AI=false` and a Gemini API key is configured.
 */
export function buildVisionVerificationPrompt(
  target: VerifyMediaRequest["target"],
  slotContext?: string,
): string {
  const slot = slotContext ?? "unspecified";
  switch (target) {
    case "kyc_document":
      return [
        "You are a strict KYC Document Verification Vision Assistant.",
        `Expected document slot: ${slot}.`,
        "Verify that the image shows a valid, legible government-issued identity document (or matching KYC selfie) with clear framing and no glare.",
        "Reject unrelated photos, landscapes, cartoons, or blurry/unreadable documents with issue 'missing_subject' or 'blurry_or_dark'.",
        "Respond strictly in JSON: { status: 'approved' | 'rejected' | 'needs_manual_review', confidenceScore: number, issues: string[], suggestedTags: string[] }.",
      ].join(" ");
    case "profile_media":
      return [
        "You are a strict Profile Reference Media QA Assistant for Virtual Try-On.",
        `Target slot context: ${slot}.`,
        "Verify that the framing matches the requested slotContext (for example, reject a close-up face-only portrait uploaded to a 'body_front' or 'full_body_front' slot with issue 'missing_subject').",
        "Check lighting, clarity, and platform safety compliance.",
        "Respond strictly in JSON: { status: 'approved' | 'rejected' | 'needs_manual_review', confidenceScore: number, issues: string[], suggestedTags: string[] }.",
      ].join(" ");
    case "wardrobe_garment":
      return [
        "You are a strict Virtual Wardrobe Garment QA Assistant.",
        `Requested category/slot context: ${slot}.`,
        "Verify that the image clearly depicts a wearable clothing, footwear, bag, jewelry, or accessory item.",
        "Reject standalone human portraits/selfies without a clear garment focus or non-garment objects with issue 'missing_subject'.",
        "Extract concise English suggestedTags for color, garment type, and style.",
        "Respond strictly in JSON: { status: 'approved' | 'rejected' | 'needs_manual_review', confidenceScore: number, issues: string[], suggestedTags: string[] }.",
      ].join(" ");
  }
}

function resolveGeminiApiKey(): string | null {
  const pool = process.env["GEMINI_API_KEY_POOL"]?.trim();
  if (pool) {
    const firstKey = pool
      .split(",")
      .map((k) => k.trim())
      .find((k) => k.length > 0);
    if (firstKey) return firstKey;
  }
  const single = process.env["GEMINI_API_KEY"]?.trim();
  return single && single.length > 0 ? single : null;
}

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

function buildPendingAiResponse(
  req: VerifyMediaRequest,
): Omit<VerifyMediaResponse, "cacheHit"> {
  return {
    status: "pending_ai",
    confidenceScore: 0,
    sha256Hash: req.sha256Hash,
    issues: [],
    suggestedTags: [],
    checkedAt: new Date().toISOString(),
    isSimulated: true,
  };
}

/**
 * Live Gemini Vision adapter. Invoked only when `USE_MOCK_AI=false` and a valid
 * API key is present in `GEMINI_API_KEY_POOL` or `GEMINI_API_KEY`.
 */
async function callGeminiVisionVerifier(
  req: VerifyMediaRequest,
  apiKey: string,
): Promise<Omit<VerifyMediaResponse, "cacheHit">> {
  if (!req.imageBase64) {
    return {
      status: "needs_manual_review",
      confidenceScore: 0,
      sha256Hash: req.sha256Hash,
      issues: [],
      suggestedTags: [],
      checkedAt: new Date().toISOString(),
      isSimulated: false,
    };
  }

  const prompt = buildVisionVerificationPrompt(req.target, req.slotContext);
  const model = process.env["GEMINI_VISION_MODEL"] ?? "gemini-2.5-flash";
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: req.mimeType,
                data: req.imageBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.1,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`GEMINI_VISION_HTTP_${response.status}`);
  }

  const json = (await response.json()) as {
    candidates?: Array<{
      content?: { parts?: Array<{ text?: string }> };
    }>;
  };
  const rawText = json.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
  const parsed = JSON.parse(rawText) as {
    status?: VerifyMediaStatus;
    confidenceScore?: number;
    issues?: VerifyMediaIssueCode[];
    suggestedTags?: string[];
  };

  return {
    status: parsed.status ?? "needs_manual_review",
    confidenceScore:
      typeof parsed.confidenceScore === "number"
        ? Math.max(0, Math.min(1, parsed.confidenceScore))
        : 0,
    sha256Hash: req.sha256Hash,
    issues: Array.isArray(parsed.issues) ? parsed.issues : [],
    suggestedTags: Array.isArray(parsed.suggestedTags)
      ? parsed.suggestedTags
      : [],
    checkedAt: new Date().toISOString(),
    isSimulated: false,
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
    const preFlightIssues = runPreFlightValidation(input);
    if (preFlightIssues.length > 0) {
      return reply.status(200).send({
        status: "rejected",
        confidenceScore: 0,
        sha256Hash: input.sha256Hash,
        issues: preFlightIssues,
        suggestedTags: [],
        checkedAt: new Date().toISOString(),
        isSimulated: false,
        cacheHit: false,
      } satisfies VerifyMediaResponse);
    }

    const cacheKey = `${input.target}:${input.slotContext ?? "default"}:${input.sha256Hash.toLowerCase()}`;
    const cached = getCachedVerification(cacheKey);
    if (cached) {
      return reply.status(200).send(cached);
    }

    const apiKey = resolveGeminiApiKey();
    if (isMockAiEnabled() || !apiKey) {
      const result: VerifyMediaResponse = {
        ...buildPendingAiResponse(input),
        cacheHit: false,
      };
      setCachedVerification(cacheKey, result);
      return reply.status(200).send(result);
    }

    try {
      const live = await callGeminiVisionVerifier(input, apiKey);
      const result: VerifyMediaResponse = { ...live, cacheHit: false };
      setCachedVerification(cacheKey, result);
      return reply.status(200).send(result);
    } catch {
      const fallback: VerifyMediaResponse = {
        ...buildPendingAiResponse(input),
        cacheHit: false,
      };
      return reply.status(200).send(fallback);
    }
  });
}
