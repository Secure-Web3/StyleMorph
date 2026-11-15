import { z } from "zod";

export const ServiceTypeSchema = z.enum([
  "VIRTUAL_TRYON",
  "ATELIER_PHOTO",
  "ATELIER_VIDEO",
  "STYLIST_CHAT",
  "WELLNESS_ANALYSIS",
]);
export type ServiceType = z.infer<typeof ServiceTypeSchema>;

export const QualityTierSchema = z.enum(["FAST", "STANDARD", "CINEMATIC"]);
export type QualityTier = z.infer<typeof QualityTierSchema>;

export const HealthContextSchema = z.object({
  sleepHours: z.number().min(0).max(24).optional(),
  deepSleepHours: z.number().min(0).max(24).optional(),
  steps: z.number().min(0).max(200000).optional(),
  heartRateBpm: z.number().min(30).max(250).optional(),
  activeCalories: z.number().min(0).max(20000).optional(),
  energyReadinessScore: z.number().min(0).max(100).optional(),
  weightTrendKg: z.number().min(20).max(300).optional(),
  stylistBiometricHint: z.string().max(256).optional(),
  sourceDevice: z.string().max(64).optional(),
});
export type HealthContext = z.infer<typeof HealthContextSchema>;

export const GenerateRequestSchema = z.object({
  userId: z.string().trim().min(1).max(128),
  holdId: z.string().trim().min(1).max(128),
  serviceType: ServiceTypeSchema,
  qualityTier: QualityTierSchema,
  prompt: z.string().trim().min(1).max(4000),
  inputImageHash: z.string().trim().min(8).max(128).optional(),
  imageBase64: z.string().min(16).optional(),
  garmentId: z.string().trim().min(1).max(128).optional(),
  templateId: z.string().trim().min(1).max(128).optional(),
  locale: z.enum(["fa", "en", "ar", "tr"]).default("fa"),
  idempotencyKey: z
    .string()
    .trim()
    .min(8)
    .max(128)
    .regex(/^[a-zA-Z0-9._:-]+$/),
  healthContext: HealthContextSchema.optional(),
  simulateFailure: z.boolean().optional(),
  mockAnatomicalScore: z.number().min(0).max(1).optional(),
});
export type GenerateRequest = z.infer<typeof GenerateRequestSchema>;

export interface QualityTierRoute {
  tier: QualityTier;
  coinCost: number;
  modelId: string;
  maxRetries: number;
  timeoutMs: number;
}

export interface AnatomicalValidationResult {
  passed: boolean;
  anatomicalScore: number;
  faceConsistencyScore: number;
  garmentAlignmentScore: number;
  safetyPassed: boolean;
  rejectionReason?: string;
}

export interface AiGenerationArtifact {
  jobId: string;
  mediaType: "image" | "video" | "text";
  mediaUrl: string;
  thumbnailUrl?: string;
  watermarkText: string;
  watermarked: boolean;
  extractedTags?: Record<string, string>;
}

export interface GenerateResponse {
  jobId: string;
  status: "COMPLETED";
  serviceType: ServiceType;
  qualityTier: QualityTier;
  coinCost: number;
  modelId: string;
  keyIdUsed: string;
  cacheHit: boolean;
  inputHash: string;
  mockMode: boolean;
  validation: AnatomicalValidationResult;
  artifact: AiGenerationArtifact;
  captureTxId: string;
}
