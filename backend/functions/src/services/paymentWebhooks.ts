import * as crypto from "node:crypto";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import {
  CryptoWebhookPayloadSchema,
  IapWebhookPayloadSchema,
  StripeWebhookPayloadSchema,
  WalletPromoConfigRequestSchema,
  type LedgerEntryRecord,
  type PaymentProvider,
  type WalletPromoConfigDoc,
  type WalletPromoConfigResponse,
  type WebhookCreditResult,
} from "../types/financial";
import { buildIdempotencyDocId, roundCoins } from "./financialEngine";

const DEFAULT_PROMO_CONFIG: WalletPromoConfigDoc = {
  killSwitch: false,
  underReviewBuildNumbers: [],
  webBonusPercent: 20,
  cryptoBonusPercent: 20,
  webPortalUrl: "https://pay.stylemorph.com",
  minAccountAgeHours: 0,
};

function timingSafeMatch(actual: string, expected: string): boolean {
  const actualBuf = Buffer.from(actual, "utf8");
  const expectedBuf = Buffer.from(expected, "utf8");
  if (actualBuf.length !== expectedBuf.length) {
    return false;
  }
  return crypto.timingSafeEqual(actualBuf, expectedBuf);
}

function verifyBearerWebhookSecret(
  authHeader: string | undefined,
  envVarName: string,
): boolean {
  const secret = process.env[envVarName];
  if (!secret) {
    if (process.env["FUNCTIONS_EMULATOR"] === "true") {
      logger.warn(
        `${envVarName} not configured; accepting local emulator webhook call.`,
      );
      return true;
    }
    return false;
  }
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return false;
  }
  return timingSafeMatch(authHeader.slice(7).trim(), secret);
}

function verifyStripeWebhookSignature(
  rawBody: string,
  sigHeader: string | undefined,
): boolean {
  const secret = process.env["STRIPE_WEBHOOK_SECRET"];
  if (!secret) {
    if (process.env["FUNCTIONS_EMULATOR"] === "true") {
      logger.warn(
        "STRIPE_WEBHOOK_SECRET not configured; accepting local emulator webhook call.",
      );
      return true;
    }
    return false;
  }
  if (!sigHeader) {
    return false;
  }

  const parts = sigHeader.split(",").map((p) => p.trim());
  const timestampPart = parts.find((p) => p.startsWith("t="));
  const v1Parts = parts
    .filter((p) => p.startsWith("v1="))
    .map((p) => p.slice(3));

  if (!timestampPart || v1Parts.length === 0) {
    return false;
  }

  const timestamp = Number(timestampPart.slice(2));
  if (!Number.isFinite(timestamp)) {
    return false;
  }

  // Reject signatures older than 5 minutes to prevent replay attacks
  const ageSeconds = Math.abs(Math.floor(Date.now() / 1000) - timestamp);
  if (ageSeconds > 300) {
    return false;
  }

  const expectedSig = crypto
    .createHmac("sha256", secret)
    .update(`${timestamp}.${rawBody}`)
    .digest("hex");

  return v1Parts.some((candidate) => timingSafeMatch(candidate, expectedSig));
}

function verifyCryptoWebhookSignature(
  rawBody: string,
  sigHeader: string | undefined,
): boolean {
  const secret = process.env["CRYPTO_WEBHOOK_SECRET"];
  if (!secret) {
    if (process.env["FUNCTIONS_EMULATOR"] === "true") {
      logger.warn(
        "CRYPTO_WEBHOOK_SECRET not configured; accepting local emulator webhook call.",
      );
      return true;
    }
    return false;
  }
  if (!sigHeader) {
    return false;
  }

  const expectedSig = crypto
    .createHmac("sha512", secret)
    .update(rawBody)
    .digest("hex");

  return timingSafeMatch(sigHeader.trim().toLowerCase(), expectedSig);
}

/**
 * Fetches dynamic billing and promo rules from `system_config/wallet_promo`
 * so bonus percentages, kill-switches, and under-review build lists are
 * never hardcoded in client or server logic.
 */
export async function getDynamicWalletPromoConfig(): Promise<WalletPromoConfigDoc> {
  const db = getFirestore();
  const snap = await db.collection("system_config").doc("wallet_promo").get();
  if (!snap.exists) {
    return DEFAULT_PROMO_CONFIG;
  }

  const data = snap.data() ?? {};
  return {
    killSwitch:
      typeof data["killSwitch"] === "boolean"
        ? data["killSwitch"]
        : DEFAULT_PROMO_CONFIG.killSwitch,
    underReviewBuildNumbers: Array.isArray(data["underReviewBuildNumbers"])
      ? data["underReviewBuildNumbers"].filter(
          (v): v is string => typeof v === "string",
        )
      : DEFAULT_PROMO_CONFIG.underReviewBuildNumbers,
    webBonusPercent:
      typeof data["webBonusPercent"] === "number" &&
      Number.isFinite(data["webBonusPercent"])
        ? data["webBonusPercent"]
        : DEFAULT_PROMO_CONFIG.webBonusPercent,
    cryptoBonusPercent:
      typeof data["cryptoBonusPercent"] === "number" &&
      Number.isFinite(data["cryptoBonusPercent"])
        ? data["cryptoBonusPercent"]
        : DEFAULT_PROMO_CONFIG.cryptoBonusPercent,
    webPortalUrl:
      typeof data["webPortalUrl"] === "string" && data["webPortalUrl"].length > 0
        ? data["webPortalUrl"]
        : DEFAULT_PROMO_CONFIG.webPortalUrl,
    minAccountAgeHours:
      typeof data["minAccountAgeHours"] === "number" &&
      Number.isFinite(data["minAccountAgeHours"])
        ? data["minAccountAgeHours"]
        : DEFAULT_PROMO_CONFIG.minAccountAgeHours,
  };
}

interface CreditWalletWebhookParams {
  userId: string;
  paymentProvider: Extract<PaymentProvider, "IAP" | "STRIPE" | "CRYPTO">;
  idempotencyKey: string;
  externalTxId: string;
  eventId: string;
  baseCoins: number;
  bonusPercent: number;
  isSubscription: boolean;
  metadata: Record<string, unknown>;
}

/**
 * Shared atomic credit transaction used across IAP, Stripe, and Crypto SSV
 * webhooks. Guarantees strict idempotency and immutable ledger logging.
 */
async function creditWalletFromWebhook(
  params: CreditWalletWebhookParams,
): Promise<WebhookCreditResult> {
  const db = getFirestore();
  const idemId = buildIdempotencyDocId(
    `WEBHOOK_${params.paymentProvider}`,
    params.idempotencyKey,
  );
  const idemRef = db.collection("idempotency_keys").doc(idemId);
  const userRef = db.collection("users").doc(params.userId);
  const eventRef = db
    .collection("payment_events")
    .doc(`${params.paymentProvider}_${params.eventId}`);

  const baseCoins = roundCoins(params.baseCoins);
  const bonusCoins =
    params.bonusPercent > 0
      ? roundCoins(baseCoins * (params.bonusPercent / 100))
      : 0;
  const totalCoins = roundCoins(baseCoins + bonusCoins);

  const fingerprint = crypto
    .createHash("sha256")
    .update(
      JSON.stringify({
        userId: params.userId,
        paymentProvider: params.paymentProvider,
        externalTxId: params.externalTxId,
        totalCoins,
      }),
    )
    .digest("hex");

  return db.runTransaction(async (tx) => {
    const [idemSnap, userSnap] = await Promise.all([
      tx.get(idemRef),
      tx.get(userRef),
    ]);

    if (idemSnap.exists) {
      const existingFingerprint = idemSnap.get("fingerprint") as string;
      if (existingFingerprint !== fingerprint) {
        throw new HttpsError(
          "already-exists",
          "Webhook idempotency key mismatch.",
        );
      }
      const cachedResult = idemSnap.get("result") as WebhookCreditResult;
      return { ...cachedResult, idempotentReplay: true };
    }

    const currentAvailable = userSnap.exists
      ? roundCoins(
          typeof userSnap.get("walletBalance") === "number"
            ? (userSnap.get("walletBalance") as number)
            : 0,
        )
      : 0;
    const currentHeld = userSnap.exists
      ? roundCoins(
          typeof userSnap.get("heldBalance") === "number"
            ? (userSnap.get("heldBalance") as number)
            : 0,
        )
      : 0;

    const newAvailable = roundCoins(currentAvailable + totalCoins);
    const ledgerRef = db.collection("ledger").doc();

    const ledgerRecord: LedgerEntryRecord = {
      txId: ledgerRef.id,
      userId: params.userId,
      type: params.isSubscription ? "SUBSCRIPTION" : "TOPUP",
      amount: totalCoins,
      balanceBefore: currentAvailable,
      balanceAfter: newAvailable,
      heldBefore: currentHeld,
      heldAfter: currentHeld,
      paymentProvider: params.paymentProvider,
      baseCoins,
      bonusCoins,
      bonusPercent: params.bonusPercent,
      externalTxId: params.externalTxId,
      idempotencyKey: params.idempotencyKey,
      metadata: params.metadata,
      createdAt: FieldValue.serverTimestamp(),
    };

    const result: WebhookCreditResult = {
      processed: true,
      idempotentReplay: false,
      txId: ledgerRef.id,
      userId: params.userId,
      paymentProvider: params.paymentProvider,
      baseCoins,
      bonusCoins,
      totalCoins,
      availableBalance: newAvailable,
    };

    if (userSnap.exists) {
      tx.update(userRef, {
        walletBalance: newAvailable,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      tx.set(userRef, {
        userId: params.userId,
        walletBalance: newAvailable,
        heldBalance: 0,
        role: "user",
        permissions: [],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.set(ledgerRef, ledgerRecord);
    tx.set(eventRef, {
      eventId: params.eventId,
      userId: params.userId,
      paymentProvider: params.paymentProvider,
      externalTxId: params.externalTxId,
      ledgerTxId: ledgerRef.id,
      baseCoins,
      bonusCoins,
      totalCoins,
      metadata: params.metadata,
      processedAt: FieldValue.serverTimestamp(),
    });
    tx.set(idemRef, {
      operation: `WEBHOOK_${params.paymentProvider}`,
      fingerprint,
      result,
      createdAt: FieldValue.serverTimestamp(),
    });

    return result;
  });
}

// ── Unified SSV Payment Webhook Endpoints ───────────────────────────────────

/**
 * RevenueCat / Native Store IAP (Google Play & Apple App Store) SSV Webhook.
 */
export const iapWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "METHOD_NOT_ALLOWED" });
    return;
  }

  if (
    !verifyBearerWebhookSecret(
      req.headers.authorization,
      "REVENUECAT_WEBHOOK_SECRET",
    )
  ) {
    res.status(401).json({ error: "INVALID_IAP_SIGNATURE" });
    return;
  }

  try {
    const parsed = IapWebhookPayloadSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: "INVALID_IAP_PAYLOAD",
        details: parsed.error.flatten(),
      });
      return;
    }

    const payload = parsed.data;
    const result = await creditWalletFromWebhook({
      userId: payload.appUserId,
      paymentProvider: "IAP",
      idempotencyKey: `iap_${payload.eventId}`,
      externalTxId: payload.transactionId,
      eventId: payload.eventId,
      baseCoins: payload.coinsAmount,
      bonusPercent: 0,
      isSubscription: payload.isSubscription,
      metadata: {
        store: payload.store,
        productId: payload.productId,
        eventType: payload.type,
        priceUsd: payload.priceUsd ?? null,
        currency: payload.currency,
      },
    });

    res.status(200).json(result);
  } catch (err) {
    logger.error("iapWebhook failed", err);
    res.status(500).json({ error: "IAP_WEBHOOK_PROCESSING_FAILED" });
  }
});

/**
 * Stripe Web Fiat Checkout SSV Webhook (applies dynamic Web Bonus %).
 */
export const stripeWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "METHOD_NOT_ALLOWED" });
    return;
  }

  const rawBody = req.rawBody
    ? req.rawBody.toString("utf8")
    : JSON.stringify(req.body ?? {});
  const sigHeader = req.headers["stripe-signature"];
  const sigValue = Array.isArray(sigHeader) ? sigHeader[0] : sigHeader;

  if (!verifyStripeWebhookSignature(rawBody, sigValue)) {
    res.status(401).json({ error: "INVALID_STRIPE_SIGNATURE" });
    return;
  }

  try {
    const parsed = StripeWebhookPayloadSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: "INVALID_STRIPE_PAYLOAD",
        details: parsed.error.flatten(),
      });
      return;
    }

    const payload = parsed.data;
    const promoConfig = await getDynamicWalletPromoConfig();
    const result = await creditWalletFromWebhook({
      userId: payload.userId,
      paymentProvider: "STRIPE",
      idempotencyKey: `stripe_${payload.eventId}`,
      externalTxId: payload.paymentIntentId,
      eventId: payload.eventId,
      baseCoins: payload.baseCoins,
      bonusPercent: promoConfig.webBonusPercent,
      isSubscription: payload.isSubscription,
      metadata: {
        packageId: payload.packageId,
        eventType: payload.type,
        amountUsdCents: payload.amountUsdCents,
        currency: payload.currency,
      },
    });

    res.status(200).json(result);
  } catch (err) {
    logger.error("stripeWebhook failed", err);
    res.status(500).json({ error: "STRIPE_WEBHOOK_PROCESSING_FAILED" });
  }
});

/**
 * Crypto Gateway (NOWPayments / Cryptomus) SSV Webhook (applies dynamic Crypto Bonus %).
 */
export const cryptoWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "METHOD_NOT_ALLOWED" });
    return;
  }

  const rawBody = req.rawBody
    ? req.rawBody.toString("utf8")
    : JSON.stringify(req.body ?? {});
  const sigHeader =
    req.headers["x-nowpayments-sig"] ?? req.headers["x-crypto-sig"];
  const sigValue = Array.isArray(sigHeader) ? sigHeader[0] : sigHeader;

  if (!verifyCryptoWebhookSignature(rawBody, sigValue)) {
    res.status(401).json({ error: "INVALID_CRYPTO_SIGNATURE" });
    return;
  }

  try {
    const parsed = CryptoWebhookPayloadSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: "INVALID_CRYPTO_PAYLOAD",
        details: parsed.error.flatten(),
      });
      return;
    }

    const payload = parsed.data;
    if (
      payload.paymentStatus !== "finished" &&
      payload.paymentStatus !== "confirmed"
    ) {
      res.status(200).json({
        processed: false,
        idempotentReplay: false,
        userId: payload.userId,
        paymentProvider: "CRYPTO",
        status: payload.paymentStatus,
      });
      return;
    }

    const promoConfig = await getDynamicWalletPromoConfig();
    const result = await creditWalletFromWebhook({
      userId: payload.userId,
      paymentProvider: "CRYPTO",
      idempotencyKey: `crypto_${payload.paymentId}`,
      externalTxId: payload.txHash ?? payload.paymentId,
      eventId: payload.paymentId,
      baseCoins: payload.baseCoins,
      bonusPercent: promoConfig.cryptoBonusPercent,
      isSubscription: false,
      metadata: {
        orderId: payload.orderId,
        packageId: payload.packageId,
        payCurrency: payload.payCurrency,
        payAmount: payload.payAmount,
        network: payload.network,
        txHash: payload.txHash ?? null,
      },
    });

    res.status(200).json(result);
  } catch (err) {
    logger.error("cryptoWebhook failed", err);
    res.status(500).json({ error: "CRYPTO_WEBHOOK_PROCESSING_FAILED" });
  }
});

// ── Store Reviewer Shield (Anti-Steering Protection) ────────────────────────

export async function resolveWalletPromoConfig(
  userId: string,
  rawInput: unknown,
): Promise<WalletPromoConfigResponse> {
  const parsed = WalletPromoConfigRequestSchema.safeParse(rawInput);
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid promo config request.",
      parsed.error.flatten(),
    );
  }

  const config = await getDynamicWalletPromoConfig();

  if (config.killSwitch) {
    return {
      showPromoBanner: false,
      reason: "KILL_SWITCH_ACTIVE",
      bonusPercent: 0,
      webPortalUrl: null,
    };
  }

  if (config.underReviewBuildNumbers.includes(parsed.data.buildNumber)) {
    return {
      showPromoBanner: false,
      reason: "BUILD_UNDER_REVIEW",
      bonusPercent: 0,
      webPortalUrl: null,
    };
  }

  if (config.minAccountAgeHours > 0) {
    const userSnap = await getFirestore().collection("users").doc(userId).get();
    const createdAt = userSnap.get("createdAt") as Timestamp | undefined;
    if (!createdAt) {
      return {
        showPromoBanner: false,
        reason: "ACCOUNT_TOO_NEW",
        bonusPercent: 0,
        webPortalUrl: null,
      };
    }
    const ageHours = (Date.now() - createdAt.toMillis()) / (1000 * 60 * 60);
    if (ageHours < config.minAccountAgeHours) {
      return {
        showPromoBanner: false,
        reason: "ACCOUNT_TOO_NEW",
        bonusPercent: 0,
        webPortalUrl: null,
      };
    }
  }

  return {
    showPromoBanner: true,
    reason: "ELIGIBLE",
    bonusPercent: config.webBonusPercent,
    webPortalUrl: config.webPortalUrl,
  };
}

/**
 * Evaluates Store Reviewer Shield (`killSwitch`, `under_review_build_numbers`,
 * and account eligibility) before permitting the client to show the Web Top-Up
 * bonus banner.
 */
export const getWalletPromoConfig = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  return resolveWalletPromoConfig(request.auth.uid, request.data);
});
