import { z } from "zod";
import type { FieldValue, Timestamp } from "firebase-admin/firestore";

// ── Shared Enums & Value Schemas ────────────────────────────────────────────

export const ServiceTypeSchema = z.enum([
  "VIRTUAL_TRYON",
  "ATELIER_PHOTO",
  "ATELIER_VIDEO",
  "STYLIST_CHAT",
  "WELLNESS_ANALYSIS",
  "WARDROBE_CAPACITY",
]);
export type ServiceType = z.infer<typeof ServiceTypeSchema>;

export const QualityTierSchema = z.enum(["FAST", "STANDARD", "CINEMATIC"]);
export type QualityTier = z.infer<typeof QualityTierSchema>;

export const HoldStatusSchema = z.enum([
  "HELD",
  "CAPTURED",
  "RELEASED",
  "EXPIRED",
]);
export type HoldStatus = z.infer<typeof HoldStatusSchema>;

export const LedgerEntryTypeSchema = z.enum([
  "HOLD",
  "CAPTURE",
  "RELEASE",
  "TOPUP",
  "SUBSCRIPTION",
  "AD_REWARD",
  "REFERRAL_BONUS",
  "ADJUSTMENT",
]);
export type LedgerEntryType = z.infer<typeof LedgerEntryTypeSchema>;

export const PaymentProviderSchema = z.enum([
  "IAP",
  "STRIPE",
  "CRYPTO",
  "ADMOB_SSV",
  "SYSTEM",
]);
export type PaymentProvider = z.infer<typeof PaymentProviderSchema>;

export const PositiveCoinAmountSchema = z
  .number()
  .finite()
  .positive()
  .max(1_000_000)
  .refine((val) => Math.abs(val * 100 - Math.round(val * 100)) < 1e-6, {
    message: "Coin amount supports at most 2 decimal places.",
  });

export const IdempotencyKeySchema = z
  .string()
  .trim()
  .min(8)
  .max(128)
  .regex(/^[a-zA-Z0-9._:-]+$/, {
    message: "Idempotency key contains invalid characters.",
  });

// ── Wallet & Hold Models ────────────────────────────────────────────────────

export interface UserWallet {
  userId: string;
  walletBalance: number;
  heldBalance: number;
  availableBalance: number;
  totalBalance: number;
  activeDeviceId?: string | null;
  activeSessionId?: string | null;
}

export interface CoinHoldRecord {
  holdId: string;
  userId: string;
  amount: number;
  serviceType: ServiceType;
  qualityTier: QualityTier;
  status: HoldStatus;
  idempotencyKey: string;
  holdLedgerTxId: string;
  captureLedgerTxId?: string;
  releaseLedgerTxId?: string;
  releaseReason?: string;
  jobId?: string;
  metadata?: Record<string, unknown>;
  createdAt: Timestamp | FieldValue;
  updatedAt: Timestamp | FieldValue;
  capturedAt?: Timestamp | FieldValue;
  releasedAt?: Timestamp | FieldValue;
}

export interface LedgerEntryRecord {
  txId: string;
  userId: string;
  type: LedgerEntryType;
  amount: number;
  balanceBefore: number;
  balanceAfter: number;
  heldBefore: number;
  heldAfter: number;
  holdId?: string;
  jobId?: string;
  serviceType?: ServiceType;
  qualityTier?: QualityTier;
  paymentProvider: PaymentProvider;
  baseCoins?: number;
  bonusCoins?: number;
  bonusPercent?: number;
  externalTxId?: string;
  idempotencyKey: string;
  reason?: string;
  metadata?: Record<string, unknown>;
  createdAt: Timestamp | FieldValue;
}

// ── Financial Engine Input / Output Schemas ─────────────────────────────────

export const HoldCoinsInputSchema = z.object({
  userId: z.string().trim().min(1).max(128),
  amount: PositiveCoinAmountSchema,
  serviceType: ServiceTypeSchema,
  qualityTier: QualityTierSchema,
  idempotencyKey: IdempotencyKeySchema,
});
export type HoldCoinsInput = z.infer<typeof HoldCoinsInputSchema>;

export const HoldCoinsCallableSchema = HoldCoinsInputSchema.omit({
  userId: true,
});
export type HoldCoinsCallableInput = z.infer<typeof HoldCoinsCallableSchema>;

export interface HoldCoinsResult {
  holdId: string;
  ledgerTxId: string;
  userId: string;
  amount: number;
  availableBalance: number;
  heldBalance: number;
  status: "HELD";
  idempotentReplay: boolean;
}

export const CaptureCoinsInputSchema = z.object({
  holdId: z.string().trim().min(1).max(128),
  idempotencyKey: IdempotencyKeySchema,
  metadata: z.record(z.unknown()).optional(),
});
export type CaptureCoinsInput = z.infer<typeof CaptureCoinsInputSchema>;

export interface CaptureCoinsResult {
  holdId: string;
  ledgerTxId: string;
  userId: string;
  amount: number;
  availableBalance: number;
  heldBalance: number;
  status: "CAPTURED";
  idempotentReplay: boolean;
}

export const ReleaseCoinsInputSchema = z.object({
  holdId: z.string().trim().min(1).max(128),
  reason: z.string().trim().min(2).max(256),
  idempotencyKey: IdempotencyKeySchema,
});
export type ReleaseCoinsInput = z.infer<typeof ReleaseCoinsInputSchema>;

export interface ReleaseCoinsResult {
  holdId: string;
  ledgerTxId: string;
  userId: string;
  amount: number;
  availableBalance: number;
  heldBalance: number;
  status: "RELEASED";
  reason: string;
  idempotentReplay: boolean;
}

// ── Payment Webhook Schemas (IAP / Stripe / Crypto) ─────────────────────────

export const IapWebhookPayloadSchema = z.object({
  eventId: z.string().trim().min(4).max(128),
  type: z.enum([
    "INITIAL_PURCHASE",
    "NON_RENEWING_PURCHASE",
    "RENEWAL",
    "PRODUCT_CHANGE",
  ]),
  appUserId: z.string().trim().min(1).max(128),
  productId: z.string().trim().min(1).max(128),
  store: z.enum(["PLAY_STORE", "APP_STORE"]),
  coinsAmount: PositiveCoinAmountSchema,
  priceUsd: z.number().nonnegative().optional(),
  currency: z.string().trim().min(3).max(8).default("USD"),
  transactionId: z.string().trim().min(4).max(256),
  isSubscription: z.boolean().default(false),
});
export type IapWebhookPayload = z.infer<typeof IapWebhookPayloadSchema>;

export const StripeWebhookPayloadSchema = z.object({
  eventId: z.string().trim().min(4).max(128),
  type: z.enum(["checkout.session.completed", "payment_intent.succeeded"]),
  userId: z.string().trim().min(1).max(128),
  packageId: z.string().trim().min(1).max(128),
  baseCoins: PositiveCoinAmountSchema,
  amountUsdCents: z.number().int().nonnegative(),
  currency: z.string().trim().min(3).max(8).default("USD"),
  paymentIntentId: z.string().trim().min(4).max(256),
  isSubscription: z.boolean().default(false),
});
export type StripeWebhookPayload = z.infer<typeof StripeWebhookPayloadSchema>;

export const CryptoWebhookPayloadSchema = z.object({
  paymentId: z.string().trim().min(4).max(128),
  orderId: z.string().trim().min(4).max(128),
  paymentStatus: z.enum([
    "waiting",
    "confirming",
    "confirmed",
    "sending",
    "partially_paid",
    "finished",
    "failed",
    "expired",
  ]),
  userId: z.string().trim().min(1).max(128),
  packageId: z.string().trim().min(1).max(128).default("crypto_topup"),
  baseCoins: PositiveCoinAmountSchema,
  payCurrency: z.string().trim().min(2).max(16),
  payAmount: z.number().positive(),
  network: z.string().trim().min(2).max(32),
  txHash: z.string().trim().min(6).max(256).optional(),
});
export type CryptoWebhookPayload = z.infer<typeof CryptoWebhookPayloadSchema>;

export interface WebhookCreditResult {
  processed: boolean;
  idempotentReplay: boolean;
  txId?: string;
  userId: string;
  paymentProvider: Extract<PaymentProvider, "IAP" | "STRIPE" | "CRYPTO">;
  baseCoins: number;
  bonusCoins: number;
  totalCoins: number;
  availableBalance: number;
}

// ── Store Reviewer Shield & Dynamic Promo Config ────────────────────────────

export const WalletPromoConfigRequestSchema = z.object({
  buildNumber: z.string().trim().min(1).max(64),
  platform: z.enum(["android", "ios", "web"]).default("android"),
});
export type WalletPromoConfigRequest = z.infer<
  typeof WalletPromoConfigRequestSchema
>;

export interface WalletPromoConfigDoc {
  killSwitch: boolean;
  underReviewBuildNumbers: string[];
  webBonusPercent: number;
  cryptoBonusPercent: number;
  webPortalUrl: string;
  minAccountAgeHours: number;
}

export interface WalletPromoConfigResponse {
  showPromoBanner: boolean;
  reason:
    | "ELIGIBLE"
    | "KILL_SWITCH_ACTIVE"
    | "BUILD_UNDER_REVIEW"
    | "ACCOUNT_TOO_NEW";
  bonusPercent: number;
  webPortalUrl: string | null;
}

// ── Single-Device Session & Audit Trail Schemas ─────────────────────────────

export const RegisterDeviceSessionInputSchema = z.object({
  deviceId: z.string().trim().min(4).max(128),
  deviceName: z.string().trim().min(1).max(128).default("Unknown Device"),
  platform: z.enum(["android", "ios", "web"]),
  appVersion: z.string().trim().min(1).max(32).default("1.0.0"),
});
export type RegisterDeviceSessionInput = z.infer<
  typeof RegisterDeviceSessionInputSchema
>;

export interface RegisterDeviceSessionResult {
  userId: string;
  deviceId: string;
  sessionId: string;
  previousDeviceRevoked: boolean;
}

export type AuditActorRole =
  | "USER"
  | "SYSTEM"
  | "SUPER_ADMIN"
  | "FINANCIAL_ADMIN"
  | "SUPPORT_ADMIN"
  | "SALES_ADMIN"
  | "AI_CONFIG_ADMIN"
  | "SHOP_OWNER";

export interface WriteAuditLogInput {
  actorId: string;
  actorRole: AuditActorRole;
  action: string;
  targetCollection: string;
  targetId: string;
  previousValue?: unknown;
  newValue?: unknown;
  reason?: string;
  ipAddress?: string;
  userAgent?: string;
  deviceId?: string;
}

export interface AuditLogRecord extends WriteAuditLogInput {
  logId: string;
  createdAt: Timestamp | FieldValue;
}
