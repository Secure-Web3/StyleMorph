import * as crypto from "node:crypto";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import {
  CaptureCoinsInputSchema,
  HoldCoinsCallableSchema,
  HoldCoinsInputSchema,
  ReleaseCoinsInputSchema,
  type CaptureCoinsResult,
  type CoinHoldRecord,
  type HoldCoinsResult,
  type LedgerEntryRecord,
  type QualityTier,
  type ReleaseCoinsResult,
  type ServiceType,
} from "../types/financial";
import { verifyActiveSession } from "./sessionGuard";

/**
 * Rounds coin values to 2 decimal places to prevent IEEE-754 float drift
 * (supports fractional rewards such as 0.3 / 0.4 AdMob SSV coins).
 */
export function roundCoins(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function buildIdempotencyDocId(
  operation: string,
  idempotencyKey: string,
): string {
  const hash = crypto
    .createHash("sha256")
    .update(`${operation}:${idempotencyKey}`)
    .digest("hex");
  return `${operation}_${hash}`;
}

function buildPayloadFingerprint(payload: Record<string, unknown>): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(payload))
    .digest("hex");
}

function readNumberField(value: unknown, fallback = 0): number {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

/**
 * Atomically reserves `amount` coins from `users/{userId}.walletBalance`
 * into `heldBalance`, creates a `wallet_holds/{holdId}` record, and appends
 * an immutable `HOLD` entry to `ledger/{txId}`.
 */
export async function holdCoins(
  userId: string,
  amount: number,
  serviceType: ServiceType,
  qualityTier: QualityTier,
  idempotencyKey: string,
): Promise<HoldCoinsResult> {
  const parsed = HoldCoinsInputSchema.safeParse({
    userId,
    amount,
    serviceType,
    qualityTier,
    idempotencyKey,
  });
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid holdCoins arguments.",
      parsed.error.flatten(),
    );
  }

  const input = parsed.data;
  const normalizedAmount = roundCoins(input.amount);
  if (normalizedAmount <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Hold amount must be greater than zero.",
    );
  }

  const db = getFirestore();
  const idemId = buildIdempotencyDocId("HOLD", input.idempotencyKey);
  const idemRef = db.collection("idempotency_keys").doc(idemId);
  const userRef = db.collection("users").doc(input.userId);
  const fingerprint = buildPayloadFingerprint({
    userId: input.userId,
    amount: normalizedAmount,
    serviceType: input.serviceType,
    qualityTier: input.qualityTier,
  });

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
          "Idempotency key was already used with a different hold payload.",
        );
      }
      const cachedResult = idemSnap.get("result") as HoldCoinsResult;
      return { ...cachedResult, idempotentReplay: true };
    }

    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User wallet profile does not exist.");
    }

    const availableBefore = roundCoins(
      readNumberField(userSnap.get("walletBalance")),
    );
    const heldBefore = roundCoins(readNumberField(userSnap.get("heldBalance")));

    if (availableBefore < normalizedAmount) {
      throw new HttpsError(
        "failed-precondition",
        "INSUFFICIENT_FUNDS",
      );
    }

    const availableAfter = roundCoins(availableBefore - normalizedAmount);
    const heldAfter = roundCoins(heldBefore + normalizedAmount);

    const holdRef = db.collection("wallet_holds").doc();
    const ledgerRef = db.collection("ledger").doc();

    const holdRecord: CoinHoldRecord = {
      holdId: holdRef.id,
      userId: input.userId,
      amount: normalizedAmount,
      serviceType: input.serviceType,
      qualityTier: input.qualityTier,
      status: "HELD",
      idempotencyKey: input.idempotencyKey,
      holdLedgerTxId: ledgerRef.id,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    const ledgerRecord: LedgerEntryRecord = {
      txId: ledgerRef.id,
      userId: input.userId,
      type: "HOLD",
      amount: normalizedAmount,
      balanceBefore: availableBefore,
      balanceAfter: availableAfter,
      heldBefore,
      heldAfter,
      holdId: holdRef.id,
      serviceType: input.serviceType,
      qualityTier: input.qualityTier,
      paymentProvider: "SYSTEM",
      idempotencyKey: input.idempotencyKey,
      createdAt: FieldValue.serverTimestamp(),
    };

    const result: HoldCoinsResult = {
      holdId: holdRef.id,
      ledgerTxId: ledgerRef.id,
      userId: input.userId,
      amount: normalizedAmount,
      availableBalance: availableAfter,
      heldBalance: heldAfter,
      status: "HELD",
      idempotentReplay: false,
    };

    tx.update(userRef, {
      walletBalance: availableAfter,
      heldBalance: heldAfter,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(holdRef, holdRecord);
    tx.set(ledgerRef, ledgerRecord);
    tx.set(idemRef, {
      operation: "HOLD",
      fingerprint,
      result,
      createdAt: FieldValue.serverTimestamp(),
    });

    return result;
  });
}

/**
 * Atomically captures a `HELD` reservation upon successful AI job completion,
 * permanently deducting `heldBalance` and writing an immutable `CAPTURE`
 * entry in `ledger/{txId}`.
 */
export async function captureCoins(
  holdId: string,
  idempotencyKey: string,
  metadata?: Record<string, unknown>,
): Promise<CaptureCoinsResult> {
  const parsed = CaptureCoinsInputSchema.safeParse({
    holdId,
    idempotencyKey,
    metadata,
  });
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid captureCoins arguments.",
      parsed.error.flatten(),
    );
  }

  const input = parsed.data;
  const db = getFirestore();
  const idemId = buildIdempotencyDocId("CAPTURE", input.idempotencyKey);
  const idemRef = db.collection("idempotency_keys").doc(idemId);
  const holdRef = db.collection("wallet_holds").doc(input.holdId);
  const fingerprint = buildPayloadFingerprint({ holdId: input.holdId });

  return db.runTransaction(async (tx) => {
    const [idemSnap, holdSnap] = await Promise.all([
      tx.get(idemRef),
      tx.get(holdRef),
    ]);

    if (idemSnap.exists) {
      const existingFingerprint = idemSnap.get("fingerprint") as string;
      if (existingFingerprint !== fingerprint) {
        throw new HttpsError(
          "already-exists",
          "Idempotency key was already used for a different holdId.",
        );
      }
      const cachedResult = idemSnap.get("result") as CaptureCoinsResult;
      return { ...cachedResult, idempotentReplay: true };
    }

    if (!holdSnap.exists) {
      throw new HttpsError("not-found", "Coin hold record not found.");
    }

    const holdData = holdSnap.data() as CoinHoldRecord;
    if (holdData.status !== "HELD") {
      throw new HttpsError(
        "failed-precondition",
        `Cannot capture hold in status '${holdData.status}'.`,
      );
    }

    const userRef = db.collection("users").doc(holdData.userId);
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User wallet profile does not exist.");
    }

    const availableBefore = roundCoins(
      readNumberField(userSnap.get("walletBalance")),
    );
    const heldBefore = roundCoins(readNumberField(userSnap.get("heldBalance")));
    const amount = roundCoins(holdData.amount);

    if (heldBefore < amount) {
      throw new HttpsError(
        "failed-precondition",
        "HELD_BALANCE_INVARIANT_VIOLATION",
      );
    }

    const heldAfter = roundCoins(heldBefore - amount);
    const ledgerRef = db.collection("ledger").doc();
    const jobId =
      input.metadata && typeof input.metadata["jobId"] === "string"
        ? input.metadata["jobId"]
        : undefined;

    const ledgerRecord: LedgerEntryRecord = {
      txId: ledgerRef.id,
      userId: holdData.userId,
      type: "CAPTURE",
      amount,
      balanceBefore: availableBefore,
      balanceAfter: availableBefore,
      heldBefore,
      heldAfter,
      holdId: holdData.holdId,
      ...(jobId ? { jobId } : {}),
      serviceType: holdData.serviceType,
      qualityTier: holdData.qualityTier,
      paymentProvider: "SYSTEM",
      idempotencyKey: input.idempotencyKey,
      ...(input.metadata ? { metadata: input.metadata } : {}),
      createdAt: FieldValue.serverTimestamp(),
    };

    const result: CaptureCoinsResult = {
      holdId: holdData.holdId,
      ledgerTxId: ledgerRef.id,
      userId: holdData.userId,
      amount,
      availableBalance: availableBefore,
      heldBalance: heldAfter,
      status: "CAPTURED",
      idempotentReplay: false,
    };

    tx.update(userRef, {
      heldBalance: heldAfter,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(holdRef, {
      status: "CAPTURED",
      captureLedgerTxId: ledgerRef.id,
      ...(jobId ? { jobId } : {}),
      ...(input.metadata ? { metadata: input.metadata } : {}),
      capturedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(ledgerRef, ledgerRecord);
    tx.set(idemRef, {
      operation: "CAPTURE",
      fingerprint,
      result,
      createdAt: FieldValue.serverTimestamp(),
    });

    return result;
  });
}

/**
 * Atomically releases a `HELD` reservation back to `walletBalance`
 * (e.g., on AI pipeline failure or cancellation) and writes an immutable
 * `RELEASE` entry in `ledger/{txId}`.
 */
export async function releaseCoins(
  holdId: string,
  reason: string,
  idempotencyKey: string,
): Promise<ReleaseCoinsResult> {
  const parsed = ReleaseCoinsInputSchema.safeParse({
    holdId,
    reason,
    idempotencyKey,
  });
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid releaseCoins arguments.",
      parsed.error.flatten(),
    );
  }

  const input = parsed.data;
  const db = getFirestore();
  const idemId = buildIdempotencyDocId("RELEASE", input.idempotencyKey);
  const idemRef = db.collection("idempotency_keys").doc(idemId);
  const holdRef = db.collection("wallet_holds").doc(input.holdId);
  const fingerprint = buildPayloadFingerprint({
    holdId: input.holdId,
    reason: input.reason,
  });

  return db.runTransaction(async (tx) => {
    const [idemSnap, holdSnap] = await Promise.all([
      tx.get(idemRef),
      tx.get(holdRef),
    ]);

    if (idemSnap.exists) {
      const existingFingerprint = idemSnap.get("fingerprint") as string;
      if (existingFingerprint !== fingerprint) {
        throw new HttpsError(
          "already-exists",
          "Idempotency key was already used for a different release payload.",
        );
      }
      const cachedResult = idemSnap.get("result") as ReleaseCoinsResult;
      return { ...cachedResult, idempotentReplay: true };
    }

    if (!holdSnap.exists) {
      throw new HttpsError("not-found", "Coin hold record not found.");
    }

    const holdData = holdSnap.data() as CoinHoldRecord;
    if (holdData.status !== "HELD") {
      throw new HttpsError(
        "failed-precondition",
        `Cannot release hold in status '${holdData.status}'.`,
      );
    }

    const userRef = db.collection("users").doc(holdData.userId);
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new HttpsError("not-found", "User wallet profile does not exist.");
    }

    const availableBefore = roundCoins(
      readNumberField(userSnap.get("walletBalance")),
    );
    const heldBefore = roundCoins(readNumberField(userSnap.get("heldBalance")));
    const amount = roundCoins(holdData.amount);

    if (heldBefore < amount) {
      throw new HttpsError(
        "failed-precondition",
        "HELD_BALANCE_INVARIANT_VIOLATION",
      );
    }

    const availableAfter = roundCoins(availableBefore + amount);
    const heldAfter = roundCoins(heldBefore - amount);
    const ledgerRef = db.collection("ledger").doc();

    const ledgerRecord: LedgerEntryRecord = {
      txId: ledgerRef.id,
      userId: holdData.userId,
      type: "RELEASE",
      amount,
      balanceBefore: availableBefore,
      balanceAfter: availableAfter,
      heldBefore,
      heldAfter,
      holdId: holdData.holdId,
      serviceType: holdData.serviceType,
      qualityTier: holdData.qualityTier,
      paymentProvider: "SYSTEM",
      idempotencyKey: input.idempotencyKey,
      reason: input.reason,
      createdAt: FieldValue.serverTimestamp(),
    };

    const result: ReleaseCoinsResult = {
      holdId: holdData.holdId,
      ledgerTxId: ledgerRef.id,
      userId: holdData.userId,
      amount,
      availableBalance: availableAfter,
      heldBalance: heldAfter,
      status: "RELEASED",
      reason: input.reason,
      idempotentReplay: false,
    };

    tx.update(userRef, {
      walletBalance: availableAfter,
      heldBalance: heldAfter,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(holdRef, {
      status: "RELEASED",
      releaseLedgerTxId: ledgerRef.id,
      releaseReason: input.reason,
      releasedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(ledgerRef, ledgerRecord);
    tx.set(idemRef, {
      operation: "RELEASE",
      fingerprint,
      result,
      createdAt: FieldValue.serverTimestamp(),
    });

    return result;
  });
}

// ── Cloud Function Endpoints ────────────────────────────────────────────────

function assertInternalServiceSecret(
  authHeader: string | undefined,
  serviceHeader: string | string[] | undefined,
): boolean {
  const configuredSecret = process.env["INTERNAL_SERVICE_SECRET"];
  if (!configuredSecret) {
    if (process.env["FUNCTIONS_EMULATOR"] === "true") {
      logger.warn(
        "INTERNAL_SERVICE_SECRET is not set; allowing internal call in local emulator.",
      );
      return true;
    }
    return false;
  }

  const candidate =
    typeof serviceHeader === "string"
      ? serviceHeader
      : authHeader?.startsWith("Bearer ")
        ? authHeader.slice(7).trim()
        : "";

  const expectedBuf = Buffer.from(configuredSecret, "utf8");
  const actualBuf = Buffer.from(candidate, "utf8");
  if (expectedBuf.length !== actualBuf.length) {
    return false;
  }
  return crypto.timingSafeEqual(expectedBuf, actualBuf);
}

/**
 * Client-callable Hold endpoint. Derives `userId` strictly from `request.auth.uid`
 * and enforces Single-Device Session validity.
 */
export const holdCoinsCallable = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  await verifyActiveSession(
    request.auth.uid,
    request.auth.token as Record<string, unknown>,
  );

  const parsed = HoldCoinsCallableSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid hold request payload.",
      parsed.error.flatten(),
    );
  }

  const { amount, serviceType, qualityTier, idempotencyKey } = parsed.data;
  return holdCoins(
    request.auth.uid,
    amount,
    serviceType,
    qualityTier,
    idempotencyKey,
  );
});

/**
 * Internal backend-only endpoint for AI Gateway / Cloud Tasks workers to
 * capture coins once an AI job passes quality validation.
 */
export const captureCoinsInternal = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "METHOD_NOT_ALLOWED" });
    return;
  }

  if (
    !assertInternalServiceSecret(
      req.headers.authorization,
      req.headers["x-internal-service-secret"],
    )
  ) {
    res.status(401).json({ error: "UNAUTHORIZED_INTERNAL_CALL" });
    return;
  }

  try {
    const parsed = CaptureCoinsInputSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: "INVALID_PAYLOAD",
        details: parsed.error.flatten(),
      });
      return;
    }

    const result = await captureCoins(
      parsed.data.holdId,
      parsed.data.idempotencyKey,
      parsed.data.metadata,
    );
    res.status(200).json(result);
  } catch (err) {
    if (err instanceof HttpsError) {
      const status =
        err.code === "not-found"
          ? 404
          : err.code === "failed-precondition"
            ? 409
            : 400;
      res.status(status).json({ error: err.message });
      return;
    }
    logger.error("captureCoinsInternal failed", err);
    res.status(500).json({ error: "INTERNAL_ERROR" });
  }
});

/**
 * Internal backend-only endpoint for AI Gateway / Cloud Tasks workers to
 * release held coins back to the user on job failure or cancellation.
 */
export const releaseCoinsInternal = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "METHOD_NOT_ALLOWED" });
    return;
  }

  if (
    !assertInternalServiceSecret(
      req.headers.authorization,
      req.headers["x-internal-service-secret"],
    )
  ) {
    res.status(401).json({ error: "UNAUTHORIZED_INTERNAL_CALL" });
    return;
  }

  try {
    const parsed = ReleaseCoinsInputSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: "INVALID_PAYLOAD",
        details: parsed.error.flatten(),
      });
      return;
    }

    const result = await releaseCoins(
      parsed.data.holdId,
      parsed.data.reason,
      parsed.data.idempotencyKey,
    );
    res.status(200).json(result);
  } catch (err) {
    if (err instanceof HttpsError) {
      const status =
        err.code === "not-found"
          ? 404
          : err.code === "failed-precondition"
            ? 409
            : 400;
      res.status(status).json({ error: err.message });
      return;
    }
    logger.error("releaseCoinsInternal failed", err);
    res.status(500).json({ error: "INTERNAL_ERROR" });
  }
});
